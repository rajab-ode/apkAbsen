const router = require('express').Router();
const ctrl = require('../controllers/siswaController');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { uploadFoto } = require('../middleware/upload');

router.use(authMiddleware);

router.get('/', ctrl.getAll);
router.get('/:id', ctrl.getById);
router.post('/', requireRole('admin'), uploadFoto.single('foto'), ctrl.create);
router.put('/:id', requireRole('admin'), uploadFoto.single('foto'), ctrl.update);
router.delete('/:id', requireRole('admin'), ctrl.remove);
router.post('/:id/wajah', requireRole('admin', 'siswa'), ctrl.registerFace);

module.exports = router;
