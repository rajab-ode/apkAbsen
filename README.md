# Absensi Siswa — SMK Negeri 5 Kendari

Aplikasi absensi siswa berbasis mobile dengan *face recognition*. Pengenalan wajah
berjalan sepenuhnya **di perangkat** (MobileFaceNet TFLite, embedding 192 dimensi);
server hanya mencocokkan embedding dengan *cosine similarity* dan mencatat kehadiran.

| Komponen | Teknologi |
|:---|:---|
| `absensi_app/` | Flutter 3.35 / Dart 3.9 — ML Kit (deteksi wajah) + TFLite (embedding) |
| `backend/` | Node.js 18+ / Express 4 + MySQL (MariaDB), JWT auth |

Produksi berjalan di cPanel: `https://apismk.codingrame.com`

## Dokumentasi

Dokumentasi lengkap **tidak** disimpan di repo ini, melainkan di:

```
D:\CODING RAME\DOCS-PROJECTS\absenFR\
  └── SETUP-LOKAL-XAMPP.md     panduan setup lokal + troubleshooting
```

README ini memuat ringkasan yang cukup untuk menjalankan proyek dari nol.

---

## Setup Development Lokal

XAMPP **tidak** menggantikan seluruh stack — di dalamnya tidak ada Node.js. Yang
dipakai dari XAMPP hanya MariaDB-nya; backend tetap dijalankan sendiri dengan Node.
Apache/PHP tidak diperlukan kecuali ingin memakai phpMyAdmin.

| Komponen | Dijalankan oleh | Port |
|:---|:---|:---|
| Database | MariaDB bawaan XAMPP | 3306 |
| Backend API | `node app.js` (bukan XAMPP) | 3000 |

> Jangan menjalankan Docker dan XAMPP bersamaan — keduanya mengikat port 3306.

### 1. Database

Nyalakan MySQL dari **XAMPP Control Panel**, lalu:

```bash
cd backend
cp .env.example .env     # default-nya sudah cocok dengan XAMPP: root, password kosong

# klien mysql XAMPP tidak terdaftar di PATH — pakai path lengkapnya
MYSQL=/d/xampp/mysql/bin/mysql.exe

$MYSQL -u root -e "CREATE DATABASE IF NOT EXISTS absensi_smkn5 CHARACTER SET utf8mb4;"
$MYSQL -u root absensi_smkn5 < database.sql      # skema + akun admin
$MYSQL -u root absensi_smkn5 < seed_local.sql    # data uji — JANGAN di produksi
```

Alternatif lewat phpMyAdmin: start Apache juga, buka `http://localhost/phpmyadmin`,
**pilih dulu** database `absensi_smkn5`, lalu tab Import.

`database.sql` sengaja tidak memuat `CREATE DATABASE`/`USE` (menyesuaikan batasan
shared hosting cPanel), jadi databasenya harus dibuat lebih dulu. Diawali
`DROP TABLE`: aman di database baru, tetapi **menghapus seluruh data** bila diimpor
ulang — untuk database yang sudah berisi data, pakai `migration_*.sql`.

### 2. Backend

```bash
cd backend
npm install
npm run dev                                 # nodemon, port 3000
curl http://localhost:3000/api/health       # harus {"status":"ok", ...}
```

### 3. Aplikasi

`AppConstants.serverUrl` memakai `String.fromEnvironment`, jadi URL lokal diberikan
lewat flag tanpa mengedit file — build rilis tanpa flag tetap menunjuk produksi.

```bash
cd absensi_app
flutter pub get

# Emulator Android (10.0.2.2 = alias localhost PC dari dalam emulator)
flutter run --dart-define=SERVER_URL=http://10.0.2.2:3000

# HP fisik, satu Wi-Fi dengan PC — cek IP dengan: ipconfig
flutter run --dart-define=SERVER_URL=http://192.168.x.x:3000
```

Nilai `--dart-define` di-*compile* ke binary, jadi mengubahnya butuh `flutter run`
ulang — hot reload tidak cukup.

### Akun uji

Dari `database.sql` + `seed_local.sql`:

| Username | Password | Role |
|:---|:---|:---|
| `admin` | `admin123` | admin |
| `guru1` | `guru123` | guru — 6 jadwal, Senin–Sabtu |
| `siswa1` | `siswa123` | siswa — NIS 2024001, kelas XI TKJ |

`data_wajah` **tidak bisa** di-seed: embedding hanya dihasilkan model TFLite di
perangkat. Sebelum wajah didaftarkan lewat aplikasi, `POST /api/absensi/recognize`
akan menjawab `404 "Belum ada wajah terdaftar"` — itu perilaku yang benar.

Tabel `geofence` dibiarkan kosong oleh seed → absen tidak dibatasi lokasi
(*fail-open*), jadi pengujian di luar area sekolah tidak terblokir.

### Alternatif tanpa XAMPP

```bash
cd backend
docker compose up -d db     # HANYA database; skema & seed terimpor otomatis
npm run dev                 # backend tetap native
```

Perlu mengubah `.env` → `DB_PASSWORD=root`. Jangan `docker compose up` telanjang:
itu juga menyalakan container backend di port 3001, sehingga ada dua backend aktif.

---

## Testing

```bash
cd backend      && npm test          # Jest — unit, integration, e2e (DB dimock)
cd absensi_app  && flutter test      # unit + widget
cd absensi_app  && flutter analyze
```

Catatan: 9 tes backend saat ini gagal karena fixture `unitVec()` masih membuat
vektor 128 dimensi, sedangkan validasi sudah menuntut 192, dan antrian mock
`db.query` belum menghitung query *geofence* + *jadwal* yang ditambahkan kemudian.
Bukan kegagalan environment.
