import 'dart:math';

/// Cosine similarity between two float vectors. Returns value in [-1, 1].
/// Returns 0.0 if either vector has zero magnitude.
double cosineSimilarity(List<double> a, List<double> b) {
  assert(a.length == b.length, 'Vectors must have the same length');
  double dot = 0.0, normA = 0.0, normB = 0.0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0.0 || normB == 0.0) return 0.0;
  return dot / (sqrt(normA) * sqrt(normB));
}
