const { cosineSimilarity, haversineDistance } = require('../../src/utils/math');

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

describe('haversineDistance', () => {
  test('same point returns 0', () => {
    expect(haversineDistance(-3.9778, 122.5194, -3.9778, 122.5194)).toBeCloseTo(0, 3);
  });

  test('1 degree of latitude is approximately 111.2km', () => {
    const dist = haversineDistance(0, 0, 1, 0);
    expect(dist).toBeGreaterThan(110000);
    expect(dist).toBeLessThan(112000);
  });

  test('is symmetric', () => {
    const a = haversineDistance(-3.9778, 122.5194, -3.99, 122.53);
    const b = haversineDistance(-3.99, 122.53, -3.9778, 122.5194);
    expect(a).toBeCloseTo(b, 6);
  });

  test('a point ~50m away is within a 100m radius', () => {
    // ~0.00045 deg latitude ≈ 50m
    const dist = haversineDistance(-3.9778, 122.5194, -3.9778 + 0.00045, 122.5194);
    expect(dist).toBeLessThan(100);
  });
});
