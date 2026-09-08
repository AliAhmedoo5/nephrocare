/// Standard checksum computation (Adler-32) for data integrity validation.
String computeChecksum(String input) {
  int a = 1;
  int b = 0;
  final codeUnits = input.codeUnits;
  for (var i = 0; i < codeUnits.length; i++) {
    a = (a + codeUnits[i]) % 65521;
    b = (b + a) % 65521;
  }
  final sum = (b << 16) | a;
  return sum.toRadixString(16).padLeft(8, '0');
}

/// A discrete frame in an Animated Multi-Frame QR code stream.
class AnimatedQrFrame {
  final int seq;
  final int total;
  final String checksum;
  final String data;

  const AnimatedQrFrame({
    required this.seq,
    required this.total,
    required this.checksum,
    required this.data,
  });

  /// Wire format: NFQR|v1|seq|total|checksum|data
  String toWireFormat() => 'NFQR|v1|$seq|$total|$checksum|$data';

  /// Parses an incoming QR scan string into an [AnimatedQrFrame].
  static AnimatedQrFrame? tryParse(String raw) {
    if (!raw.startsWith('NFQR|v1|')) return null;

    final parts = raw.split('|');
    if (parts.length < 6) return null;

    final seq = int.tryParse(parts[2]);
    final total = int.tryParse(parts[3]);
    final checksum = parts[4];

    if (seq == null || total == null || seq < 1 || seq > total || checksum.isEmpty) {
      return null;
    }

    // Recover raw chunk data even if it contains pipe characters
    final prefixLength = parts.take(5).fold<int>(0, (sum, p) => sum + p.length) + 5;
    final data = raw.substring(prefixLength);

    return AnimatedQrFrame(
      seq: seq,
      total: total,
      checksum: checksum,
      data: data,
    );
  }
}

/// Chunks and sequences a string payload into cycling frames for visual QR streaming.
class AnimatedQrEncoder {
  static List<AnimatedQrFrame> encode(String payload, {int chunkSize = 250}) {
    if (payload.isEmpty) {
      return [
        AnimatedQrFrame(
          seq: 1,
          total: 1,
          checksum: computeChecksum(''),
          data: '',
        ),
      ];
    }

    final checksum = computeChecksum(payload);
    final chunks = <String>[];
    for (int i = 0; i < payload.length; i += chunkSize) {
      final end = (i + chunkSize < payload.length) ? i + chunkSize : payload.length;
      chunks.add(payload.substring(i, end));
    }

    final total = chunks.length;
    return List.generate(
      total,
      (index) => AnimatedQrFrame(
        seq: index + 1,
        total: total,
        checksum: checksum,
        data: chunks[index],
      ),
    );
  }
}

/// Receives scanned QR frames out-of-order, deduplicates, and reassembles
/// the complete dataset once all sequence indices are acquired.
class AnimatedQrReassembler {
  int? _total;
  String? _expectedChecksum;
  final Map<int, String> _receivedChunks = {};

  bool get isComplete => _total != null && _receivedChunks.length == _total;
  int get receivedCount => _receivedChunks.length;
  int get totalCount => _total ?? 0;
  double get progress => _total == null || _total == 0 ? 0.0 : _receivedChunks.length / _total!;

  /// Returns the reconstructed payload when [isComplete] is true and verified.
  String? get reassembledPayload {
    if (!isComplete) return null;
    final buffer = StringBuffer();
    for (int i = 1; i <= _total!; i++) {
      buffer.write(_receivedChunks[i]);
    }
    final assembled = buffer.toString();
    if (computeChecksum(assembled) != _expectedChecksum) {
      return null;
    }
    return assembled;
  }

  /// Ingests a raw scanned string. Returns true if frame was accepted.
  bool addFrame(String rawFrame) {
    final frame = AnimatedQrFrame.tryParse(rawFrame);
    if (frame == null) return false;

    if (_expectedChecksum != null && _expectedChecksum != frame.checksum) {
      return false; // Mismatched stream session
    }

    _expectedChecksum ??= frame.checksum;
    _total ??= frame.total;

    if (frame.total != _total) return false;
    if (frame.seq < 1 || frame.seq > _total!) return false;

    _receivedChunks[frame.seq] = frame.data;
    return true;
  }

  /// Resets state for a new scan session.
  void reset() {
    _total = null;
    _expectedChecksum = null;
    _receivedChunks.clear();
  }
}
