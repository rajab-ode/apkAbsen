const router = require('express').Router();
const ctrl = require('../controllers/izinController');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { uploadSurat } = require('../middleware/upload');

router.use(authMiddleware);

router.post('/', requireRole('siswa'), uploadSurat.single('file_surat'), ctrl.ajukan);
router.get('/', requireRole('guru', 'admin'), ctrl.getAll);
router.get('/siswa/:idSiswa', ctrl.getMySiswa);
router.put('/:id/status', requireRole('guru', 'admin'), ctrl.updateStatus);

module.exports = router;
