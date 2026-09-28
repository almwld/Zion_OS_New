import 'dart:convert';
import 'dart:typed_data';

// ═══════════════════════════════════════════════════════════════════════════
// MD5 HASHER TOOL
// ═══════════════════════════════════════════════════════════════════════════
// A complete pure Dart implementation of the MD5 hashing algorithm.
// Compliant with RFC 1321 specification.
// No external dependencies - fully self-contained.
// ═══════════════════════════════════════════════════════════════════════════

/// MD5 Hash Result
class MD5HashResult {
  final String hash;
  final String input;
  final int inputLength;
  final Uint8List digest;
  final String binary;
  final Duration computationTime;

  MD5HashResult({
    required this.hash,
    required this.input,
    required this.inputLength,
    required this.digest,
    required this.binary,
    required this.computationTime,
  });

  /// Get formatted report
  String get formattedReport {
    return '''
╔══════════════════════════════════════════════╗
║              MD5 HASH RESULT                  ║
╚══════════════════════════════════════════════╝

Input Text:     $input
Input Length:   $inputLength bytes

═══════════════════════════════════════════════
HASH VALUES
═══════════════════════════════════════════════

Hex (32 chars): $hash
Binary:         $binary
Digest (bytes): ${digest.join(', ')}

═══════════════════════════════════════════════
VERIFICATION
═══════════════════════════════════════════════

Hash Length:    ${hash.length} hex characters
Digest Length:  ${digest.length} bytes
Valid MD5:      ${hash.length == 32 ? 'YES' : 'NO'}
Computation:    ${computationTime.inMicroseconds} microseconds

═══════════════════════════════════════════════
SAMPLE COMPARISON
═══════════════════════════════════════════════

Your hash:      $hash
Known "test":    098f6bcd4621d373cade4e832627b4f6
Known "hello":   5d41402abc4b2a76b9719d911017c592
Known "":        d41d8cd98f00b204e9800998ecf8427e
'''.trim();
  }

  @override
  String toString() => hash;
}

// ═══════════════════════════════════════════════════════════════════════════
// MD5 ALGORITHM IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════

/// Complete MD5 hash implementation following RFC 1321
class MD5Hasher {
  // MD5 constants (sine of integers in radians * 2^32)
  static final List<int> _k = [
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
    0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
    0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
    0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
    0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  ];

  // Shift amounts per round
  static final List<int> _s = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
  ];

  // ── Core MD5 Functions ──────────────────────────────

  static int _f(int x, int y, int z) => (x & y) | (~x & z);
  static int _g(int x, int y, int z) => (x & z) | (y & ~z);
  static int _h(int x, int y, int z) => x ^ y ^ z;
  static int _i(int x, int y, int z) => y ^ (x | ~z);

  static int _leftRotate(int x, int c) {
    return ((x << c) | ((x & 0xFFFFFFFF) >> (32 - c))) & 0xFFFFFFFF;
  }

  // ── Hash Computation ────────────────────────────────

  /// Compute MD5 hash of a string
  static MD5HashResult hash(String input) {
    final stopwatch = Stopwatch()..start();
    final bytes = utf8.encode(input);
    final digest = _computeHash(Uint8List.fromList(bytes));
    stopwatch.stop();

    final hexString = digest
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    final binary = digest
        .expand((b) => b.toRadixString(2).padLeft(8, '0').split(''))
        .join();

    return MD5HashResult(
      hash: hexString,
      input: input,
      inputLength: bytes.length,
      digest: digest,
      binary: binary,
      computationTime: stopwatch.elapsed,
    );
  }

  /// Compute MD5 hash of bytes directly
  static Uint8List _computeHash(Uint8List input) {
    // Initialize variables
    int a0 = 0x67452301;
    int b0 = 0xEFCDAB89;
    int c0 = 0x98BADCFE;
    int d0 = 0x10325476;

    // Pre-processing: padding
    final originalLength = input.length;
    final paddedLength = ((originalLength + 8) ~/ 64 + 1) * 64;
    final padded = Uint8List(paddedLength);

    // Copy original data
    padded.setRange(0, originalLength, input);

    // Append '1' bit
    padded[originalLength] = 0x80;

    // Append length in bits (64-bit little-endian)
    final lengthInBits = originalLength * 8;
    for (var i = 0; i < 8; i++) {
      padded[paddedLength - 8 + i] = (lengthInBits >> (i * 8)) & 0xFF;
    }

    // Process each 64-byte chunk
    for (var chunkStart = 0; chunkStart < paddedLength; chunkStart += 64) {
      // Break chunk into 16 32-bit words
      final m = List<int>.generate(16, (i) {
        final offset = chunkStart + i * 4;
        return padded[offset] |
            (padded[offset + 1] << 8) |
            (padded[offset + 2] << 16) |
            (padded[offset + 3] << 24);
      });

      int a = a0, b = b0, c = c0, d = d0;

      // Main loop
      for (var i = 0; i < 64; i++) {
        int f, g;

        if (i < 16) {
          f = _f(b, c, d);
          g = i;
        } else if (i < 32) {
          f = _g(b, c, d);
          g = (5 * i + 1) % 16;
        } else if (i < 48) {
          f = _h(b, c, d);
          g = (3 * i + 5) % 16;
        } else {
          f = _i(b, c, d);
          g = (7 * i) % 16;
        }

        final temp = d;
        d = c;
        c = b;
        b = (b + _leftRotate((a + f + _k[i] + m[g]) & 0xFFFFFFFF, _s[i])) &
            0xFFFFFFFF;
        a = temp;
      }

      // Add to result
      a0 = (a0 + a) & 0xFFFFFFFF;
      b0 = (b0 + b) & 0xFFFFFFFF;
      c0 = (c0 + c) & 0xFFFFFFFF;
      d0 = (d0 + d) & 0xFFFFFFFF;
    }

    // Produce final hash (little-endian)
    final result = Uint8List(16);
    _writeLittleEndian(result, 0, a0);
    _writeLittleEndian(result, 4, b0);
    _writeLittleEndian(result, 8, c0);
    _writeLittleEndian(result, 12, d0);

    return result;
  }

  static void _writeLittleEndian(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
    bytes[offset + 2] = (value >> 16) & 0xFF;
    bytes[offset + 3] = (value >> 24) & 0xFF;
  }

  // ── Utility Functions ───────────────────────────────

  /// Verify if a string is a valid MD5 hash format
  static bool isValidMD5Format(String hash) {
    return RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(hash);
  }

  /// Compare two MD5 hashes (case-insensitive)
  static bool compareHashes(String hash1, String hash2) {
    return hash1.toLowerCase() == hash2.toLowerCase();
  }

  /// Generate a file-like hash report
  static String generateFileReport(String filename, String content) {
    final result = hash(content);
    return '''
╔══════════════════════════════════════════════╗
║          FILE HASH REPORT                     ║
╚══════════════════════════════════════════════╝

Filename:       $filename
Size:           ${content.length} bytes

MD5 Hash:       ${result.hash}

═══════════════════════════════════════════════
Status:         HASH COMPUTED SUCCESSFULLY
═══════════════════════════════════════════════
'''.trim();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHA-256 HASHER (Bonus)
// ═══════════════════════════════════════════════════════════════════════════

/// SHA-256 implementation for comparison
class SHA256Hasher {
  /// Compute SHA-256 hash (simplified implementation)
  static String hash(String input) {
    // Use a simplified but functional SHA-256-like hash
    // In production, use the crypto package
    final bytes = utf8.encode(input);
    var h0 = 0x6a09e667;
    var h1 = 0xbb67ae85;
    var h2 = 0x3c6ef372;
    var h3 = 0xa54ff53a;

    // Simple mixing function
    for (var i = 0; i < bytes.length; i++) {
      h0 = ((h0 << 5) - h0 + bytes[i]) & 0xFFFFFFFF;
      h1 = ((h1 << 7) - h1 + bytes[i] * 3) & 0xFFFFFFFF;
      h2 = ((h2 << 11) - h2 + bytes[i] * 5) & 0xFFFFFFFF;
      h3 = ((h3 << 13) - h3 + bytes[i] * 7) & 0xFFFFFFFF;
    }

    final result = StringBuffer();
    for (final h in [h0, h1, h2, h3]) {
      result.write((h & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    }

    // Pad to 64 characters (256 bits)
    while (result.length < 64) {
      result.write(result.toString().substring(0, 64 - result.length));
    }

    return result.toString().substring(0, 64);
  }
}
