const router = require('express').Router();
const ctrl = require('../controllers/jadwalController');
const { authMiddleware, requireRole } = require('../middleware/auth');

router.use(authMiddleware);

router.get('/', requireRole('guru'), ctrl.getMine);
router.post('/', requireRole('guru'), ctrl.create);
router.delete('/:id', requireRole('guru'), ctrl.remove);

module.exports = router;
