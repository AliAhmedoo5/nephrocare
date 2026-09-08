import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/sync/domain/animated_qr_codec.dart';

void main() {
  group('Channel 1: Animated Multi-Frame QR Seam', () {
    test('Splits large payload into sequenced frames with checksum and wire format', () {
      final largePayload = jsonEncode({
        'action': 'sync',
        'records': List.generate(50, (i) => {'index': i, 'uuid': 'record-uuid-$i', 'val': 'test-$i'}),
      });

      final frames = AnimatedQrEncoder.encode(largePayload, chunkSize: 150);
      expect(frames.length, greaterThan(1));

      for (var i = 0; i < frames.length; i++) {
        final frame = frames[i];
        expect(frame.seq, equals(i + 1));
        expect(frame.total, equals(frames.length));
        expect(frame.checksum, isNotEmpty);
        expect(frame.data.length, lessThanOrEqualTo(150));
        expect(frame.toWireFormat(), startsWith('NFQR|v1|'));
      }
    });

    test('Reassembles frames arriving in random order and ignores duplicate frames', () {
      final samplePayload = '{"patient":"Alice","status":"hemodialysis","logs":[1,2,3,4,5,6,7,8,9,10]}';
      final frames = AnimatedQrEncoder.encode(samplePayload, chunkSize: 20);
      expect(frames.length, greaterThan(2));

      final reassembler = AnimatedQrReassembler();
      expect(reassembler.isComplete, isFalse);
      expect(reassembler.progress, equals(0.0));

      // Feed frames out of order with a duplicate
      final wireFrames = frames.map((f) => f.toWireFormat()).toList();
      
      // Feed frame 2 first
      final success1 = reassembler.addFrame(wireFrames[1]);
      expect(success1, isTrue);
      expect(reassembler.isComplete, isFalse);
      expect(reassembler.receivedCount, equals(1));

      // Feed frame 2 again (duplicate)
      final successDup = reassembler.addFrame(wireFrames[1]);
      expect(successDup, isTrue);
      expect(reassembler.receivedCount, equals(1));

      // Feed all remaining frames in arbitrary order
      for (var i = wireFrames.length - 1; i >= 0; i--) {
        reassembler.addFrame(wireFrames[i]);
      }

      expect(reassembler.isComplete, isTrue);
      expect(reassembler.progress, equals(1.0));
      expect(reassembler.reassembledPayload, equals(samplePayload));
    });

    test('Rejects corrupted frame wire format or mismatched checksum', () {
      final reassembler = AnimatedQrReassembler();
      
      // Invalid format
      expect(reassembler.addFrame('INVALID_PAYLOAD_STRING'), isFalse);
      
      // Corrupt checksum format
      expect(reassembler.addFrame('NFQR|v1|1|2|corrupt123|chunkdata'), isTrue);
      expect(reassembler.addFrame('NFQR|v1|2|2|wrongchecksum|otherchunk'), isFalse); // Checksum mismatch across frames
    });
  });
}
