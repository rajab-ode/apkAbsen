const db = require('../config/db');

async function get(req, res) {
  try {
    const [rows] = await db.query('SELECT * FROM geofence WHERE id = 1');
    res.json({ success: true, data: rows.length ? rows[0] : null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data geofence' });
  }
}

async function set(req, res) {
  const { latitude, longitude, radius_meter } = req.body;

  const lat = Number(latitude);
  const lng = Number(longitude);
  const radius = Number(radius_meter);

  if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
    return res.status(400).json({ success: false, message: 'Latitude tidak valid (harus -90 s/d 90)' });
  }
  if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
    return res.status(400).json({ success: false, message: 'Longitude tidak valid (harus -180 s/d 180)' });
  }
  if (!Number.isFinite(radius) || radius <= 0) {
    return res.status(400).json({ success: false, message: 'Radius harus lebih besar dari 0' });
  }

  try {
    await db.query(
      `INSERT INTO geofence (id, latitude, longitude, radius_meter) VALUES (1, ?, ?, ?)
       ON DUPLICATE KEY UPDATE latitude = ?, longitude = ?, radius_meter = ?`,
      [lat, lng, radius, lat, lng, radius]
    );
    res.json({ success: true, message: 'Pengaturan geofencing berhasil disimpan' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menyimpan pengaturan geofencing' });
  }
}

module.exports = { get, set };
