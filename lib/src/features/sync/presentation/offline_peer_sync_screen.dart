import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/animated_qr_codec.dart';
import '../domain/local_wifi_handshake.dart';
import '../domain/nephro_archive_codec.dart';
import '../domain/patient_sync_bundle.dart';
import '../domain/sync_merge_engine.dart';
import 'animated_qr_display_widget.dart';

/// Primary interface for Triple-Channel Offline Peer-to-Peer Synchronization.
///
/// Supports bidirectional, zero-cloud patient data exchange across:
/// 1. Animated Multi-Frame QR (air-gapped visual camera-to-screen stream)
/// 2. Local Wi-Fi Handshake (ephemeral on-device HTTP server with QR pairing)
/// 3. Encrypted Patient Export (AES-256-GCM .nephro archive for OS sharing)
class OfflinePeerSyncScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const OfflinePeerSyncScreen({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<OfflinePeerSyncScreen> createState() => _OfflinePeerSyncScreenState();
}

class _OfflinePeerSyncScreenState extends ConsumerState<OfflinePeerSyncScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Send State
  List<AnimatedQrFrame>? _qrFrames;
  LocalWifiHandshakeHost? _wifiHost;
  bool _isHostingWifi = false;
  String _sendPassphrase = 'NephroCarePassphrase2026';
  int? _exportedArchiveBytesLength;
  String? _exportedFilePath;

  // Receive State
  bool _asCaregiverMirror = false;
  final AnimatedQrReassembler _reassembler = AnimatedQrReassembler();
  final TextEditingController _frameInputController = TextEditingController();
  final TextEditingController _wifiHostController = TextEditingController();
  final TextEditingController _wifiPortController = TextEditingController();
  final TextEditingController _wifiTokenController = TextEditingController();
  final TextEditingController _receivePassphraseController =
      TextEditingController(text: 'NephroCarePassphrase2026');
  final TextEditingController _nephroPathController = TextEditingController();
  SyncMergeResult? _lastMergeResult;
  String? _receiveErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wifiHost?.close();
    _frameInputController.dispose();
    _wifiHostController.dispose();
    _wifiPortController.dispose();
    _wifiTokenController.dispose();
    _receivePassphraseController.dispose();
    _nephroPathController.dispose();
    super.dispose();
  }

  Future<PatientSyncBundle> _getExportBundle() {
    final db = ref.read(databaseProvider);
    return PatientSyncBundle.fromDatabase(
      database: db,
      patientId: widget.patient.id,
    );
  }

  Future<void> _startAnimatedQrStreaming() async {
    final bundle = await _getExportBundle();
    final jsonPayload = jsonEncode(bundle.toJson());
    final frames = AnimatedQrEncoder.encode(jsonPayload, chunkSize: 180);

    setState(() {
      _qrFrames = frames;
    });
  }

  Future<void> _toggleWifiHost() async {
    if (_isHostingWifi) {
      final host = _wifiHost;
      setState(() {
        _wifiHost = null;
        _isHostingWifi = false;
      });
      await host?.close(force: true);
    } else {
      final bundle = await _getExportBundle();
      final host = await LocalWifiHandshakeHost.start(bundle: bundle);
      if (mounted) {
        setState(() {
          _wifiHost = host;
          _isHostingWifi = true;
        });
      }
    }
  }

  Future<void> _generateEncryptedArchive() async {
    final bundle = await _getExportBundle();
    final bytes = await NephroArchiveCodec.encryptBundle(
      bundle,
      passphrase: _sendPassphrase,
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final sanitized = widget.patient.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final file = File('${tempDir.path}/${sanitized}_patient_export.nephro');
      await file.writeAsBytes(bytes);
      _exportedFilePath = file.path;
    } catch (_) {}

    setState(() {
      _exportedArchiveBytesLength = bytes.length;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generated AES-256 encrypted .nephro archive (${bytes.length} bytes)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _ingestManualFrame() {
    final text = _frameInputController.text.trim();
    if (text.isEmpty) return;

    final accepted = _reassembler.addFrame(text);
    _frameInputController.clear();

    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or mismatched frame format'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {});

    if (_reassembler.isComplete) {
      _finalizeQrReassembly();
    }
  }

  Future<void> _finalizeQrReassembly() async {
    final payload = _reassembler.reassembledPayload;
    if (payload == null) {
      setState(() {
        _receiveErrorMessage = 'Checksum verification failed during reassembly.';
      });
      return;
    }

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final bundle = PatientSyncBundle.fromJson(map);
      final db = ref.read(databaseProvider);
      final result = await SyncMergeEngine(db).mergeBundle(
        bundle,
        asCaregiverMirror: _asCaregiverMirror,
      );

      setState(() {
        _lastMergeResult = result;
        _receiveErrorMessage = null;
      });
    } catch (e) {
      setState(() {
        _receiveErrorMessage = 'Failed to merge bundle: $e';
      });
    }
  }

  Future<void> _connectWifiClient() async {
    final host = _wifiHostController.text.trim();
    final port = int.tryParse(_wifiPortController.text.trim());
    final token = _wifiTokenController.text.trim();

    if (host.isEmpty || port == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid Host, Port, and Auth Token'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final client = LocalWifiHandshakeClient();
      final bundle = await client.fetchBundle(
        host: host,
        port: port,
        authToken: token,
      );

      final db = ref.read(databaseProvider);
      final result = await SyncMergeEngine(db).mergeBundle(
        bundle,
        asCaregiverMirror: _asCaregiverMirror,
      );

      setState(() {
        _lastMergeResult = result;
        _receiveErrorMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync successful! Processed ${result.totalProcessed} records.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _receiveErrorMessage = e.toString();
      });
    }
  }

  Future<void> _decryptAndImportNephroFile() async {
    final path = _nephroPathController.text.trim();
    final passphrase = _receivePassphraseController.text.trim();

    if (path.isEmpty || passphrase.isEmpty) {
      setState(() {
        _receiveErrorMessage = 'Please specify both the file path and decryption passphrase.';
      });
      return;
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _receiveErrorMessage = 'Specified file does not exist: $path';
        });
        return;
      }

      final archiveBytes = await file.readAsBytes();
      final bundle = await NephroArchiveCodec.decryptBundle(
        archiveBytes,
        passphrase: passphrase,
      );

      final db = ref.read(databaseProvider);
      final result = await SyncMergeEngine(db).mergeBundle(
        bundle,
        asCaregiverMirror: _asCaregiverMirror,
      );

      setState(() {
        _lastMergeResult = result;
        _receiveErrorMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${result.totalProcessed} records from .nephro file!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _receiveErrorMessage = 'Failed to decrypt .nephro archive: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Peer-to-Peer Sync'),
        backgroundColor: theme.colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload_rounded), text: 'Send / Export'),
            Tab(icon: Icon(Icons.download_rounded), text: 'Receive / Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendView(theme),
          _buildReceiveView(theme),
        ],
      ),
    );
  }

  Widget _buildSendView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Patient Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ready to export complete clinical dataset',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Channel 1: Animated Multi-Frame QR
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Animated Multi-Frame QR',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Air-gapped visual transmission cycling sequenced QR frames on-screen for camera capture without network connectivity.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_qrFrames == null)
                    FilledButton.icon(
                      key: const Key('start_animated_qr_button'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Animated QR Stream'),
                      onPressed: _startAnimatedQrStreaming,
                    )
                  else ...[
                    AnimatedQrDisplayWidget(frames: _qrFrames!),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => setState(() => _qrFrames = null),
                      child: const Text('Stop QR Stream'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Channel 2: Local Wi-Fi Handshake
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi_tethering_rounded, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Local Wi-Fi Handshake',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Embedded ephemeral HTTP server on local Wi-Fi or mobile hotspot for sub-second encrypted bulk transfer.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (!_isHostingWifi)
                    FilledButton.icon(
                      key: const Key('start_wifi_host_button'),
                      icon: const Icon(Icons.portable_wifi_off_rounded),
                      label: const Text('Host Local Wi-Fi Handshake'),
                      onPressed: _toggleWifiHost,
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Local Wi-Fi Host Active',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Host: ${_wifiHost!.pairingInfo.host}:${_wifiHost!.pairingInfo.port}'),
                          Text(
                            'Token: ${_wifiHost!.pairingInfo.authToken.substring(0, 8)}...',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: QrImageView(
                              data: _wifiHost!.pairingInfo.toQrPayload(),
                              version: QrVersions.auto,
                              size: 160,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('stop_wifi_host_button'),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop Wi-Fi Host'),
                      onPressed: _toggleWifiHost,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Channel 3: Encrypted Patient Export (.nephro)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Encrypted Patient Export (.nephro)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AES-256-GCM authenticated archive file shareable via OS share sheet, USB, or local storage.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _sendPassphrase,
                    decoration: const InputDecoration(
                      labelText: 'Encryption Passphrase',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    onChanged: (val) => _sendPassphrase = val,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('export_nephro_file_button'),
                    icon: const Icon(Icons.file_download_rounded),
                    label: const Text('Export .nephro Archive'),
                    onPressed: _generateEncryptedArchive,
                  ),
                  if (_exportedArchiveBytesLength != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Exported $_exportedArchiveBytesLength bytes.\n'
                      '${_exportedFilePath != null ? "Saved to: $_exportedFilePath" : "Ready to share via OS sheet."}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Caregiver Mirror Option
          CheckboxListTile(
            key: const Key('caregiver_mirror_checkbox'),
            title: const Text('Import as Caregiver Mirror'),
            subtitle: const Text('Mark imported patient as monitoring replica on this device'),
            value: _asCaregiverMirror,
            onChanged: (val) => setState(() => _asCaregiverMirror = val ?? false),
          ),
          const Divider(),

          // Merge Feedback Banner
          if (_lastMergeResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Records Ingested Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Inserted: ${_lastMergeResult!.totalInserted} records'),
                  Text('Updated: ${_lastMergeResult!.totalUpdated} records'),
                  Text('Skipped (LWW): ${_lastMergeResult!.recordsSkipped} records'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_receiveErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _receiveErrorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Channel 1: Reassemble Animated QR Stream
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Animated Multi-Frame QR',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Frames Received: ${_reassembler.receivedCount} / ${_reassembler.totalCount} '
                    '(${(_reassembler.progress * 100).toInt()}%)',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _reassembler.progress),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('manual_frame_input'),
                    controller: _frameInputController,
                    decoration: const InputDecoration(
                      labelText: 'Scan or Paste NFQR Frame',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.qr_code_scanner_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('ingest_frame_button'),
                    onPressed: _ingestManualFrame,
                    child: const Text('Ingest Frame'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Channel 2: Connect Local Wi-Fi Client
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Local Wi-Fi Handshake',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('wifi_host_input'),
                    controller: _wifiHostController,
                    decoration: const InputDecoration(
                      labelText: 'Host IP (e.g. 192.168.1.5)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('wifi_port_input'),
                    controller: _wifiPortController,
                    decoration: const InputDecoration(
                      labelText: 'Port (e.g. 8080)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('wifi_token_input'),
                    controller: _wifiTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Pairing Token',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('connect_wifi_button'),
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: const Text('Connect & Download Dataset'),
                    onPressed: _connectWifiClient,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Channel 3: Encrypted Patient Export (.nephro)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Encrypted Patient Export (.nephro)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Decrypt and import an AES-256-GCM .nephro archive received via OS file sharing.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('nephro_file_path_input'),
                    controller: _nephroPathController,
                    decoration: const InputDecoration(
                      labelText: 'Path to .nephro file',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_file_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('nephro_passphrase_input'),
                    controller: _receivePassphraseController,
                    decoration: const InputDecoration(
                      labelText: 'Decryption Passphrase',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('decrypt_nephro_file_button'),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Decrypt & Ingest .nephro File'),
                    onPressed: _decryptAndImportNephroFile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
