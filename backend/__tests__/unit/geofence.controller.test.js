jest.mock('../../src/config/db');

const db = require('../../src/config/db');
const ctrl = require('../../src/controllers/geofenceController');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

beforeEach(() => jest.resetAllMocks());

describe('geofenceController.get', () => {
  test('returns null when not configured yet', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.get({}, res);
    expect(res.json).toHaveBeenCalledWith({ success: true, data: null });
  });

  test('returns the single row when configured', async () => {
    const row = { id: 1, latitude: '-3.9778000', longitude: '122.5194000', radius_meter: 100 };
    db.query.mockResolvedValueOnce([[row]]);
    const res = mockRes();
    await ctrl.get({}, res);
    expect(res.json).toHaveBeenCalledWith({ success: true, data: row });
  });
});

describe('geofenceController.set', () => {
  const validBody = { latitude: -3.9778, longitude: 122.5194, radius_meter: 100 };

  test('returns 400 when latitude out of range', async () => {
    const res = mockRes();
    await ctrl.set({ body: { ...validBody, latitude: 200 } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when longitude out of range', async () => {
    const res = mockRes();
    await ctrl.set({ body: { ...validBody, longitude: -200 } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when radius is not positive', async () => {
    const res = mockRes();
    await ctrl.set({ body: { ...validBody, radius_meter: 0 } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when latitude is not a number', async () => {
    const res = mockRes();
    await ctrl.set({ body: { ...validBody, latitude: 'abc' } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('upserts the single row on success', async () => {
    db.query.mockResolvedValueOnce([{ affectedRows: 1 }]);
    const res = mockRes();
    await ctrl.set({ body: validBody }, res);
    expect(db.query).toHaveBeenCalledWith(
      expect.stringContaining('ON DUPLICATE KEY UPDATE'),
      [-3.9778, 122.5194, 100, -3.9778, 122.5194, 100]
    );
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});
