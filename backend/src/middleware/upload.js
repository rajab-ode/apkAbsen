const multer = require('multer');
const path = require('path');
const fs = require('fs');

function makeStorage(subfolder, allowedExts) {
  const dir = path.join(__dirname, '../../uploads', subfolder);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  return multer.diskStorage({
    destination: (_, __, cb) => cb(null, dir),
    filename: (_, file, cb) => {
      const unique = Date.now() + '-' + Math.round(Math.random() * 1e6);
      cb(null, unique + path.extname(file.originalname).toLowerCase());
    },
  });
}

const uploadFoto = multer({
  storage: makeStorage('foto', ['.jpg', '.jpeg', '.png']),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    const ok = ['.jpg', '.jpeg', '.png'].includes(
      path.extname(file.originalname).toLowerCase()
    );
    cb(ok ? null : new Error('Format foto harus JPG/PNG'), ok);
  },
});

const uploadSurat = multer({
  storage: makeStorage('surat', ['.pdf']),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    const ok = path.extname(file.originalname).toLowerCase() === '.pdf';
    cb(ok ? null : new Error('Format surat harus PDF'), ok);
  },
});

module.exports = { uploadFoto, uploadSurat };
