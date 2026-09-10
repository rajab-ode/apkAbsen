const router = require('express').Router();
const ctrl = require('../controllers/geofenceController');
const { authMiddleware, requireRole } = require('../middleware/auth');

router.use(authMiddleware);

router.get('/', requireRole('admin'), ctrl.get);
router.put('/', requireRole('admin'), ctrl.set);

module.exports = router;
