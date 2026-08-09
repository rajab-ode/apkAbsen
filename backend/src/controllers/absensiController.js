const db = require('../config/db');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const { cosineSimilarity } = require('../utils/math');

const THRESHOLD = 0.80;

// Cache embedding di memory agar tidak full-scan DB setiap absensi
let _embeddingCache = null;
let _cacheTime = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 menit

async function getEmbeddingCache() {
  const now = Date.now();
  if (_embeddingCache && (now - _cacheTime) < CACHE_TTL_MS) return _embeddingCache;
  const [rows] = await db.query(
    'SELECT id_siswa, nama_siswa, NIS, foto, data_wajah FROM siswa WHERE data_wajah IS NOT NULL'
  );
  _embeddingCache = rows.map(r => ({ ...r, embedding: JSON.parse(r.data_wajah) }));
  _cacheTime = now;
  return _embeddingCache;
}

function invalidateEmbeddingCache() { _embeddingCache = null; }

// Waktu WIB (UTC+7) — server Docker berjalan di UTC
function getWIBDateTime() {
  const wib = new Date(Date.now() + 7 * 60 * 60 * 1000);
  return {
    date: wib.toISOString().slice(0, 10),
    time: wib.toISOString().slice(11, 19),
  };
}

async function recognize(req, res) {
  const { embedding } = req.body;
  if (!embedding || !Array.isArray(embedding) || embedding.length !== 192) {
    return res.status(400).json({ success: false, message: 'Embedding tidak valid' });
  }

  try {
    const students = await getEmbeddingCache();

    if (students.length === 0) {
      return res.status(404).json({ success: false, message: 'Belum ada wajah terdaftar' });
    }

    let bestMatch = null;
    let bestScore = -1;

    for (const s of students) {
      const score = cosineSimilarity(embedding, s.embedding);
      if (score > bestScore) { bestScore = score; bestMatch = s; }
    }

    if (bestScore < THRESHOLD) {
      return res.status(404).json({ success: false, message: 'Wajah tidak dikenali. Pastikan wajah terlihat jelas.' });
    }

    const { date: today, time: now } = getWIBDateTime();

    // INSERT IGNORE + UNIQUE KEY (id_siswa, tanggal) mencegah duplikat & race condition
    const [result] = await db.query(
      'INSERT IGNORE INTO absensi (id_siswa, tanggal, waktu, status) VALUES (?, ?, ?, "hadir")',
      [bestMatch.id_siswa, today, now]
    );

    if (result.affectedRows === 0) {
      return res.status(409).json({ success: false, message: 'Absensi hari ini sudah tercatat' });
    }

    res.status(201).json({
      success: true,
      message: 'Absensi berhasil',
      data: {
        id_absensi: result.insertId,
        nama_siswa: bestMatch.nama_siswa,
        NIS: bestMatch.NIS,
        foto: bestMatch.foto,
        tanggal: today,
        waktu: now,
        status: 'hadir',
        similarity: bestScore.toFixed(4),
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal memproses absensi' });
  }
}

async function getAll(req, res) {
  const { tanggal, search = '', page = 1, limit = 10 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  const like = `%${search}%`;

  const dateFilter = tanggal ? 'AND a.tanggal = ?' : '';
  const params = tanggal
    ? [like, like, tanggal, parseInt(limit), offset]
    : [like, like, parseInt(limit), offset];

  try {
    const [rows] = await db.query(
      `SELECT a.id_absensi, s.nama_siswa, s.NIS, s.kelas, s.foto, a.tanggal, a.waktu, a.status
       FROM absensi a
       JOIN siswa s ON a.id_siswa = s.id_siswa
       WHERE (s.nama_siswa LIKE ? OR s.NIS LIKE ?) ${dateFilter}
       ORDER BY a.waktu DESC
       LIMIT ? OFFSET ?`,
      params
    );

    const countParams = tanggal ? [like, like, tanggal] : [like, like];
    const [[{ total }]] = await db.query(
      `SELECT COUNT(*) AS total FROM absensi a JOIN siswa s ON a.id_siswa = s.id_siswa
       WHERE (s.nama_siswa LIKE ? OR s.NIS LIKE ?) ${dateFilter}`,
      countParams
    );

    const [[stats]] = await db.query(
      `SELECT
         COUNT(CASE WHEN a.status = 'hadir' THEN 1 END) AS hadir,
         COUNT(CASE WHEN a.status = 'izin' THEN 1 END) AS izin,
         COUNT(CASE WHEN a.status = 'tidak_hadir' THEN 1 END) AS tidak_hadir
       FROM absensi a ${tanggal ? 'WHERE a.tanggal = ?' : ''}`,
      tanggal ? [tanggal] : []
    );

    res.json({
      success: true,
      data: rows,
      total,
      page: parseInt(page),
      hadir: stats.hadir,
      izin: stats.izin,
      tidakHadir: stats.tidak_hadir,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data absensi' });
  }
}

async function getMySiswa(req, res) {
  const idSiswa = req.params.idSiswa;
  try {
    const [rows] = await db.query(
      `SELECT a.id_absensi, s.nama_siswa, s.NIS, s.foto, a.tanggal, a.waktu, a.status
       FROM absensi a JOIN siswa s ON a.id_siswa = s.id_siswa
       WHERE a.id_siswa = ? ORDER BY a.tanggal DESC, a.waktu DESC`,
      [idSiswa]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil riwayat absensi' });
  }
}

async function downloadPdf(req, res) {
  const { tanggal } = req.query;
  if (!tanggal) return res.status(400).json({ success: false, message: 'Parameter tanggal wajib diisi' });

  try {
    const [rows] = await db.query(
      `SELECT s.nama_siswa, s.NIS, s.kelas, a.waktu, a.status
       FROM absensi a JOIN siswa s ON a.id_siswa = s.id_siswa
       WHERE a.tanggal = ? ORDER BY s.nama_siswa`,
      [tanggal]
    );

    const doc = new PDFDocument({ margin: 50, size: 'A4' });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=laporan_absensi_${tanggal}.pdf`);
    doc.pipe(res);

    doc.fontSize(16).font('Helvetica-Bold').text('LAPORAN ABSENSI SISWA', { align: 'center' });
    doc.fontSize(11).font('Helvetica').text(`SMK Negeri 5 Kendari`, { align: 'center' });
    doc.fontSize(10).text(`Tanggal: ${tanggal}`, { align: 'center' });
    doc.moveDown(1.5);

    // Table header
    const cols = [40, 200, 100, 100, 80, 80];
    const headers = ['No', 'Nama Siswa', 'NIS', 'Kelas', 'Waktu', 'Status'];
    let y = doc.y;

    doc.font('Helvetica-Bold').fontSize(10);
    let x = 50;
    headers.forEach((h, i) => { doc.text(h, x, y, { width: cols[i] }); x += cols[i]; });
    doc.moveTo(50, y + 15).lineTo(550, y + 15).stroke();
    doc.moveDown(0.5);

    doc.font('Helvetica').fontSize(9);
    rows.forEach((r, idx) => {
      y = doc.y;
      x = 50;
      const vals = [idx + 1, r.nama_siswa, r.NIS, r.kelas || '-', r.waktu || '-', r.status];
      vals.forEach((v, i) => { doc.text(String(v), x, y, { width: cols[i] }); x += cols[i]; });
      doc.moveDown(0.3);
    });

    doc.end();
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal membuat laporan PDF' });
  }
}

async function downloadExcel(req, res) {
  const { tanggal } = req.query;
  if (!tanggal) return res.status(400).json({ success: false, message: 'Parameter tanggal wajib diisi' });

  try {
    const [rows] = await db.query(
      `SELECT s.nama_siswa, s.NIS, s.kelas, s.jurusan, a.waktu, a.status
       FROM absensi a JOIN siswa s ON a.id_siswa = s.id_siswa
       WHERE a.tanggal = ? ORDER BY s.nama_siswa`,
      [tanggal]
    );

    const wb = new ExcelJS.Workbook();
    wb.creator = 'Absensi SMKN5';
    const ws = wb.addWorksheet('Absensi');

    ws.mergeCells('A1:F1');
    ws.getCell('A1').value = 'LAPORAN ABSENSI SISWA — SMK NEGERI 5 KENDARI';
    ws.getCell('A1').font = { bold: true, size: 13 };
    ws.getCell('A1').alignment = { horizontal: 'center' };

    ws.mergeCells('A2:F2');
    ws.getCell('A2').value = `Tanggal: ${tanggal}`;
    ws.getCell('A2').alignment = { horizontal: 'center' };

    ws.addRow([]);
    ws.addRow(['No', 'Nama Siswa', 'NIS', 'Kelas', 'Jurusan', 'Waktu Hadir', 'Status']);
    ws.getRow(4).font = { bold: true };
    ws.getRow(4).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A1A2E' } };
    ws.getRow(4).font = { bold: true, color: { argb: 'FFFFFFFF' } };

    rows.forEach((r, i) => {
      const row = ws.addRow([i + 1, r.nama_siswa, r.NIS, r.kelas || '-', r.jurusan || '-', r.waktu || '-', r.status]);
      const statusCell = row.getCell(7);
      if (r.status === 'hadir') statusCell.font = { color: { argb: 'FF10B981' }, bold: true };
      else if (r.status === 'izin') statusCell.font = { color: { argb: 'FFF59E0B' }, bold: true };
      else statusCell.font = { color: { argb: 'FFEF4444' }, bold: true };
    });

    ws.columns = [
      { width: 5 }, { width: 30 }, { width: 15 }, { width: 12 },
      { width: 20 }, { width: 14 }, { width: 14 },
    ];

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=laporan_absensi_${tanggal}.xlsx`);
    await wb.xlsx.write(res);
    res.end();
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal membuat laporan Excel' });
  }
}

module.exports = { recognize, getAll, getMySiswa, downloadPdf, downloadExcel };
