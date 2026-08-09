const router = require('express').Router();
const ctrl = require('../controllers/absensiController');
const { authMiddleware, requireRole } = require('../middleware/auth');

router.use(authMiddleware);

router.post('/recognize', requireRole('siswa'), ctrl.recognize);
router.get('/', requireRole('guru', 'admin'), ctrl.getAll);
router.get('/siswa/:idSiswa', ctrl.getMySiswa);
router.get('/laporan/pdf', requireRole('guru', 'admin'), ctrl.downloadPdf);
router.get('/laporan/excel', requireRole('guru', 'admin'), ctrl.downloadExcel);

module.exports = router;
