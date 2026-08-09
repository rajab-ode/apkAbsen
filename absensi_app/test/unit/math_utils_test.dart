import 'package:flutter_test/flutter_test.dart';
import 'package:absensi_app/core/utils/math_utils.dart';

void main() {
  const dim = 128;

  List<double> unitVec(int activeDim) {
    final v = List<double>.filled(dim, 0.0);
    v[activeDim] = 1.0;
    return v;
  }

  List<double> constVec(double val) => List<double>.filled(dim, val);

  group('cosineSimilarity', () {
    test('identical vectors return 1.0', () {
      final v = constVec(0.5);
      expect(cosineSimilarity(v, v), closeTo(1.0, 1e-6));
    });

    test('opposite vectors return -1.0', () {
      final a = constVec(1.0);
      final b = constVec(-1.0);
      expect(cosineSimilarity(a, b), closeTo(-1.0, 1e-6));
    });

    test('orthogonal unit vectors return 0.0', () {
      final a = unitVec(0);
      final b = unitVec(1);
      expect(cosineSimilarity(a, b), closeTo(0.0, 1e-6));
    });

    test('zero vector returns 0.0', () {
      final zero = List<double>.filled(dim, 0.0);
      final v = constVec(1.0);
      expect(cosineSimilarity(zero, v), 0.0);
      expect(cosineSimilarity(v, zero), 0.0);
    });

    test('same direction unit vectors return 1.0', () {
      final a = unitVec(5);
      final b = unitVec(5);
      expect(cosineSimilarity(a, b), closeTo(1.0, 1e-6));
    });

    test('result is symmetric: sim(a,b) == sim(b,a)', () {
      final a = unitVec(0);
      final b = unitVec(3);
      expect(cosineSimilarity(a, b), equals(cosineSimilarity(b, a)));
    });

    test('slightly perturbed vector stays above 0.80 threshold', () {
      const threshold = 0.80;
      final base = List<double>.generate(dim, (i) => (i % 10) * 0.1 + 0.01);
      // Add tiny noise
      final similar = List<double>.generate(dim, (i) => base[i] + (i % 3 == 0 ? 0.001 : 0.0));
      final score = cosineSimilarity(base, similar);
      expect(score, greaterThan(threshold));
    });

    test('very different vectors fall below 0.80 threshold', () {
      const threshold = 0.80;
      final a = unitVec(0);
      final b = unitVec(64); // completely different direction
      final score = cosineSimilarity(a, b);
      expect(score, lessThan(threshold));
    });

    test('result is in range [-1, 1] for random-like input', () {
      final a = List<double>.generate(dim, (i) => (i * 7 % 13) * 0.1 - 0.5);
      final b = List<double>.generate(dim, (i) => (i * 3 % 11) * 0.1 - 0.3);
      final score = cosineSimilarity(a, b);
      expect(score, greaterThanOrEqualTo(-1.0));
      expect(score, lessThanOrEqualTo(1.0));
    });
  });
}
