const router = require('express').Router();
const ctrl = require('../controllers/kelasController');
const { authMiddleware, requireRole } = require('../middleware/auth');

router.use(authMiddleware);

router.get('/', requireRole('admin', 'guru'), ctrl.getAll);
router.post('/', requireRole('admin'), ctrl.create);
router.delete('/:id', requireRole('admin'), ctrl.remove);

module.exports = router;
