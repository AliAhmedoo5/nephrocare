import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

import 'nephro_archive_codec.dart';
import 'patient_sync_bundle.dart';

/// Exception thrown when authentication against a Local Wi-Fi Handshake server fails.
class LocalWifiHandshakeAuthException implements Exception {
  final String message;
  LocalWifiHandshakeAuthException(this.message);

  @override
  String toString() => 'LocalWifiHandshakeAuthException: $message';
}

/// Pairing metadata shared via QR code to establish a direct local Wi-Fi / Hotspot link.
class LocalWifiPairingInfo {
  final String host;
  final int port;
  final String authToken;

  const LocalWifiPairingInfo({
    required this.host,
    required this.port,
    required this.authToken,
  });

  /// Formats pairing info for embedding in a pairing QR code.
  String toQrPayload() => jsonEncode({
        'type': 'nephro_wifi_handshake',
        'host': host,
        'port': port,
        'token': authToken,
      });

  /// Parses scanned pairing QR code data.
  static LocalWifiPairingInfo? tryParseQr(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['type'] != 'nephro_wifi_handshake') return null;
      final host = map['host'] as String?;
      final port = map['port'] as int?;
      final token = map['token'] as String?;
      if (host != null && port != null && token != null) {
        return LocalWifiPairingInfo(host: host, port: port, authToken: token);
      }
    } catch (_) {}
    return null;
  }
}

/// Ephemeral on-device HTTP server for direct local Wi-Fi / Hotspot bulk transfers.
class LocalWifiHandshakeHost {
  final HttpServer _server;
  final LocalWifiPairingInfo pairingInfo;

  LocalWifiHandshakeHost._({
    required HttpServer server,
    required this.pairingInfo,
  }) : _server = server;

  /// Starts an ephemeral on-device HTTP server with QR-paired authorization
  /// and AES-256-GCM authenticated payload encryption.
  static Future<LocalWifiHandshakeHost> start({
    required PatientSyncBundle bundle,
    InternetAddress? address,
    int port = 0,
    String? authToken,
  }) async {
    final token = authToken ?? const Uuid().v4();
    final bindAddress = address ?? InternetAddress.anyIPv4;
    final server = await HttpServer.bind(bindAddress, port);

    // Determine discoverable host IP
    String hostIp;
    if (bindAddress.isLoopback) {
      hostIp = '127.0.0.1';
    } else {
      hostIp = await _resolveLocalIp();
    }

    final pairing = LocalWifiPairingInfo(
      host: hostIp,
      port: server.port,
      authToken: token,
    );

    // Encrypt the patient dataset in transit with AES-256-GCM using the QR-paired token
    final encryptedBundleBytes = await NephroArchiveCodec.encryptBundle(
      bundle,
      passphrase: token,
    );

    server.listen((HttpRequest request) async {
      try {
        if (request.uri.path == '/sync') {
          final clientToken = request.headers.value('X-Nephro-Token') ??
              request.uri.queryParameters['token'];

          if (clientToken == token) {
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.binary;
            request.response.add(encryptedBundleBytes);
            await request.response.close();
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({'error': 'Unauthorized: invalid or missing pairing token'}),
            );
            await request.response.close();
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      } catch (_) {
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } catch (_) {}
      }
    });

    return LocalWifiHandshakeHost._(
      server: server,
      pairingInfo: pairing,
    );
  }

  /// Shuts down the ephemeral server cleanly.
  Future<void> close({bool force = false}) async {
    await _server.close(force: force);
  }

  /// Resolves the device's local network IPv4 address.
  static Future<String> _resolveLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      ).timeout(const Duration(milliseconds: 300), onTimeout: () => []);
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }
}

/// Client connecting to a peer device's ephemeral Local Wi-Fi Handshake server.
class LocalWifiHandshakeClient {
  final HttpClient _httpClient;

  LocalWifiHandshakeClient({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  /// Connects using a [LocalWifiPairingInfo] container.
  Future<PatientSyncBundle> fetchWithPairingInfo(
    LocalWifiPairingInfo pairingInfo, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    return fetchBundle(
      host: pairingInfo.host,
      port: pairingInfo.port,
      authToken: pairingInfo.authToken,
      timeout: timeout,
    );
  }

  /// Connects over local Wi-Fi / hotspot, authenticates via pairing token, downloads,
  /// and decrypts the AES-256-GCM encrypted patient dataset.
  Future<PatientSyncBundle> fetchBundle({
    required String host,
    required int port,
    required String authToken,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final uri = Uri.parse('http://$host:$port/sync');
      final request = await _httpClient.getUrl(uri).timeout(timeout);
      request.headers.set('X-Nephro-Token', authToken);

      final response = await request.close().timeout(timeout);

      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        throw LocalWifiHandshakeAuthException(
          'Authentication failed: pairing token was rejected by peer host.',
        );
      }

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Server returned status ${response.statusCode}');
      }

      final responseBytes = await response.fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );
      final encryptedBytes = Uint8List.fromList(responseBytes);

      // Decrypt using the QR-paired token
      return await NephroArchiveCodec.decryptBundle(
        encryptedBytes,
        passphrase: authToken,
      );
    } catch (e) {
      if (e is LocalWifiHandshakeAuthException) rethrow;
      throw Exception('Local Wi-Fi Handshake failed: $e');
    }
  }
}
