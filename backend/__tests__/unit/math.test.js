const { cosineSimilarity } = require('../../src/utils/math');

describe('cosineSimilarity', () => {
  const dim = 128;

  test('identical vectors returns 1.0', () => {
    const v = Array.from({ length: dim }, (_, i) => i + 1);
    expect(cosineSimilarity(v, v)).toBeCloseTo(1.0, 6);
  });

  test('opposite vectors returns -1.0', () => {
    const a = Array.from({ length: dim }, (_, i) => i + 1);
    const b = a.map(x => -x);
    expect(cosineSimilarity(a, b)).toBeCloseTo(-1.0, 6);
  });

  test('orthogonal vectors returns 0.0', () => {
    const a = Array.from({ length: dim }, (_, i) => (i % 2 === 0 ? 1.0 : 0.0));
    const b = Array.from({ length: dim }, (_, i) => (i % 2 === 1 ? 1.0 : 0.0));
    expect(cosineSimilarity(a, b)).toBeCloseTo(0.0, 6);
  });

  test('zero vector returns 0', () => {
    const zero = new Array(dim).fill(0);
    const v = new Array(dim).fill(1);
    expect(cosineSimilarity(zero, v)).toBe(0);
    expect(cosineSimilarity(v, zero)).toBe(0);
  });

  test('unit vectors in same direction return 1.0', () => {
    const a = new Array(dim).fill(0); a[0] = 1.0;
    const b = new Array(dim).fill(0); b[0] = 1.0;
    expect(cosineSimilarity(a, b)).toBeCloseTo(1.0, 6);
  });

  test('unit vectors in different directions return 0.0', () => {
    const a = new Array(dim).fill(0); a[0] = 1.0;
    const b = new Array(dim).fill(0); b[1] = 1.0;
    expect(cosineSimilarity(a, b)).toBeCloseTo(0.0, 6);
  });

  test('similarity above 0.80 threshold means match', () => {
    const THRESHOLD = 0.80;
    const base = Array.from({ length: dim }, () => Math.random());
    // Slightly perturbed vector should still be above threshold
    const similar = base.map(x => x + (Math.random() - 0.5) * 0.01);
    const score = cosineSimilarity(base, similar);
    expect(score).toBeGreaterThan(THRESHOLD);
  });
});
