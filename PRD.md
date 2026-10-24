# PRD: LINAKAN — Limbah Pangan ke Peternak

> Platform mobile yang menghubungkan limbah pangan (roti kering, tepung afkir, sisa makanan olahan, sayuran mentah) dari penjual (bakery/IRT/UMKM) ke peternak (ayam, bebek, sapi, kambing, kelinci, babi) secara lokal, berbasis kecocokan kategori + lokasi + kapasitas, dengan sistem dompet elektronik dan biaya platform 5%.

---

## 1. Ringkasan Eksekutif

**LINAKAN** (Limbah → Pakan) adalah aplikasi mobile Flutter yang memungkinkan:
- **Penjual** (bakery, IRT, UMKM makanan) mendaftarkan limbah pangan yang tidak terpakai dengan kategori dan berat tertentu.
- **Peternak** menemukan limbah pangan terdekat berdasarkan kecocokan ternak, lokasi (≤15 km), dan kapasitas.
- Sistem **mencocokkan otomatis** dan menandai **Instant Match** jika skor ≥85%.
- Transaksi melalui **dompet elektronik linakan** dengan biaya layanan platform **5%**.

### Asumsi & Kendala
- **Demo/offline-first:** tidak ada backend real-time. Semua data disimpan via `shared_preferences`. Seed data dimuat pada first run (versi `linakan-v1`).
- **Simulasi pembayaran:** dompet diisi via top-up simulasi (bank/ewallet). Tidak ada gateway payment real.
- **Simulasi lokasi/OTP:** lokasi dimasukkan manual di onboarding; OTP generates 6-digit lokal.
- **Tidur kadaluarsa otomatis:** item kadaluarsa otomatis dihapus dari hasil pencocokan (bukan dihapus dari storage).

### Ruang Lingkup
- **Termasuk:** Auth (HP+OTP), profil penjual/peternak, CRUD listing limbah, sistem pencocokan + instant match, checkout dengan dompet, riwayat transaksi, ekspor CSV (admin).
- **Tidak termasuk:** integrasi payment gateway asli, live location/GPS, notifikasi push, backend server, real-time sync, upload gambar ke cloud.

---

## 2. Stakeholder

| Peran | Deskripsi | Peran di App |
|---|---|---|
| Peternak (Farmer) | Pemilik ternak (ayam, bebek, sapi, kambing, kelinci) | Mencari limbah pakan, beli via dompet |
| Penjual (Seller) | Bakery, IRT, UMKM makanan | Jual limbah pangan, lihat transaksi, tarik dana |
| Admin | Pengelola platform | Kelola listing/transaksi, ekspor CSV, lihat statistik |

---

## 3. Fitur Utama

### Fitur 1: Autentikasi & Akun
- **Login/Register via nomor HP + password + OTP simulasi** (`AuthService`)
- OTP 6-digit digenerate lokal, berlaku 5 menit
- Password minimal 6 karakter
- Pilihan peran saat register: Seller (Bakery/IRT/UMKM) atau Peternak

### Fitur 2: Profil & Onboarding
- **Seller:** nama, tipe usaha (bakery/IRT/UMKM), lokasi, nomor HP
- **Farmer onboarding (multi-step):** jenis ternak (filter chip multi-select), kebutuhan pakan, kapasitas (kg/minggu), lokasi (nama + lat/lng manual)

### Fitur 3: Manajemen Listing Limbah (Seller)
- Buat listing: nama limbah, kategori, berat (≥2 kg), alamat, harga rekomendasi otomatis, harga manual (±50% rule), foto placeholder (demo), lokasi pickup (map placeholder demo)
- Preview listing sebelum publish
- List/edit/delete listing pribadi
- Status: `available` → `reserved` → `completed` / `expired`

### Fitur 4: Pencocokan & Marketplace (Farmer)
- **Skor kecocokan** = Kategori (40%) + Lokasi (40%) + Kapasitas (20%)
- Instant Match otomatis jika skor ≥85%
- Marketplace filter: kategori, pencarian nama, sort (terbaik/harga/terdekat)
- Detail listing: progress bar masa simpan, countdown timer, kompatibilitas breakdown, kontak seller (demo WA)

### Fitur 5: Checkout & Dompet (Farmer & Seller)
- Checkout: subtotal + biaya platform (5%) + total
- Validasi saldo dompet (warning jika kurang)
- Top-up simulasi (50rb/100rb/200rb/500rb + custom), pilih bank/ewallet
- Withdrawal (seller): masukkan jumlah + rekening
- Riwayat transaksi: masuk (seller), keluar (farmer)

### Fitur 6: Dashboard
- **Seller:** KPI (listing aktif, kadaluarsa, dipesan, selesai, estimasi pendapatan) + grafik garis aktivitas
- **Farmer:** Instant Match card slider + KPI + tombol pasar
- **Admin:** KPI (listing aktif, total limbah, instant match, dipesan, selesai, segera kadaluarsa) + bar chart kategori + distribusi ternak + total pendapatan platform

### Fitur 7: Admin Tools
- Filter listing by status
- CSV export listing & transaksi (id, nama, kategori, berat, status, harga, tanggal)
- SnackBar konfirmasi penyimpanan file ke temp dir

---

## 4. Alur Bisnis (BPMN Ringkas)

### Alur Sebelum (Manual)
1. Penjual mengumpulkan limbah harian
2. Catat di buku/hitung pakai kalkulator
3. Telepon/WA ke peternak secara eksis
4. Sepakat harga → bayar tunai/transfer
5. Bukti disimpan fisik

### Alur Sesudah (LINAKAN)
1. **Seller** buat listing di app
2. Sistem **otomatis cocokkan** ke peternak ≤15 km
3. Jika instant match → notifikasi
4. **Farmer** beli via dompet (5% fee)
5. **Transaction confirmed** (listing → reserved, dompet update)
6. Seller dapat notifikasi → hubungi farmer → serah ambil
7. Farmer konfirmasi selesai (listing → completed)
8. Seller tarik dana

---

## 5. Aturan Bisnis Kunci

| Aturan | Nilai |
|---|---|
| Berat minimum listing | **2 kg** |
| Radius pencocokan maksimal | **15 km** (Haversine) |
| Instant Match threshold | **≥85%** skor kompatibilitas |
| Biaya platform | **5%** (`kPlatformFeeRate = 0.05`) |
| Masa simpan (Roti Kering) | **14 hari / 336 jam** |
| Masa simpan (Tepung Afkir) | **14 hari / 336 jam** |
| Masa simpan (Sisa Makanan Olahan) | **24 jam** |
| Masa simpan (Sayur Mentah) | **48 jam** |
| Bobot matching | Kategori 40% + Lokasi 40% + Kapasitas 20% |
| Ketersediaan listing | Hanya `available` + not `expired` muncul di matching |
| Transaksi | Membutuhkan konfirmasi buyer sebelum `reserved` |

---

## 6. Desain & UX

### Palet Warna
- **Primary:** Biru laut `#3368A0` (CTA, navigasi, brand)
- **Accent:** Lime `#BBDC12` (badge energi, sorotan)
- **Secondary:** Coral `#FF6B6B` (warning, badge sekunder)
- **Lavender:** `#6C5FA8` (aksent variasi)
- **Background:** Krem `#F2EFE7`
- **Surface:** Putih `#FFFFFF`
- **Text:** Gelap `#1F2D3D`, sekunder `#4A5D73`, muted `#7A899C`

### Typography
- **Font:** Plus Jakarta Sans (via `google_fonts`)
- Display Large (36sp), Heading (24/20/16), Body (14/12.5), Caption (11.5)

### Radius & Motion
- Card = 20px, Field = 14px, Button = 14px, Chip = full round
- Motion: Fast 180ms, Base 320ms, Slow 560ms, Curve: easeOutCubic

### Komponen UI Kunci
- **LinakanButton:** primary/filled, secondary/outline, text + loading state
- **LinakanBadge:** rounded label
- **StatusBadge:** Warna per status (available=green, reserved=amber, completed=blue, expired=red)
- **ListingCard:** gambar, badge kategori, berat, harga/kg, jarak, countdown, instant match badge
- **MatchCard:** ListingCard + score bar, % cocok, alasan kompatibilitas
- **CountdownWidget:** Timer per menit, warna green→amber→red
- **ShelfLifeBar:** Progress bar 0→1, warna senyeren
- **WalletBalanceCard:** Saldo + tombol top up
- **BottomNav:** Seller (Dasbor/Daftar/Transaksi/Profil) vs Farmer (Dasbor/Instant Match/Pasar/Dompet)
- **LoadingErrorState:** Spinner atau banner error + tombol coba lagi

---

## 7. Backend & Data Layer

### Storage
- **Lokasi:** `shared_preferences` (offline-first)
- **Seed Data Version:** `linakan-v1`
- **Keys (lihat `app_constants.dart`):**
  - `linakan_sellers`, `linakan_farmers`, `linakan_listings`, `linakan_transactions`
  - `linakan_current_user`, `linakan_accounts` (HP→credentials), `linakan_data_version`, `linakan_intro_seen`

### Struktur Data (Model)

| Model | Fields |
|---|---|
| **User** (base) | id, name, email, phone, location, lat, lng, walletBalance |
| **SellerModel** | +type (irt/bakery/umkm_food), verified, rating, totalTransactions |
| **FarmerModel** | +livestock[], feedRequirements, capacity, verified |
| **ListingModel** | id, seller info, wasteName, category, weight, pricePerKg/totalPrice/suggestedPrice/finalPrice, imageUrl, lat/lng/pickupAddress, createdAt, status, quality, notes |
| **TransactionModel** | id, listingId, farmerId, sellerId, wasteName, category, weight, totalPrice, platformFee, sellerReceives, farmerPays, status, createdAt |
| **MatchResultModel** | listing, score, isInstantMatch, expired flag, category/location/capacity score, distance, capacityPercentage, reasons |
| **NotificationModel** | id, userId, type, message, isRead, createdAt |

### Repositori (Repository Pattern)
Masing-masing persisten via JSON di StorageService:
- `SellerRepository`
- `FarmerRepository`
- `ListingRepository`
- `TransactionRepository`

### Domain Service (Pure Dart, no Flutter imports)
| Service | Tanggung Jawab |
|---|---|
| `ShelfLifeService` | Hitung expiry, status (fresh/expiring/expired), countdown, progress bar |
| `MatchingService` | Score komponen, compatibility, instant match, filter expired/15km |
| `PricingService` | Harga dasar per kategori, multiplier berat, fee 5%, validasi ±50% |
| `WalletService` | processTransaction, topUp, getSeller/FarmerSummary, requestWithdrawal |

### Formula Scoring
- **Category:** 100 jika ada ternak match, 0 jika tidak
- **Location:** 100 ≤5km, linear turun ke 0 di 15km
- **Capacity:** proporsional 50% kapasitas mingguan
- **Final Score:** `(cat×0.4 + loc×0.4 + cap×0.2).round()`

---

## 8. Arsitektur Teknis

### Framework & Dependency
- **Flutter SDK** ≥3.19.0 (Dart ≥3.0)
- **State management:** `provider` (ChangeNotifier)
- **Routing:** `go_router`
- **HTTP:** (opsional) n8n webhook via `chatbotApi.js`
- **Images:** `cached_network_image` + `flutter_svg`
- **Charts:** `fl_chart`
- **Animasi:** `flutter_animate`, native Flutter animations

### Arsitektur Folder
```
linakan_app/
├── android/        iOS-style native scaffolds
├── ios/
├── lib/
│   ├── main.dart   → init SP, seed, MultiProvider
│   ├── app.dart    → GoRouter + Theme
│   ├── core/
│   │   ├── constants/   → app_constants, app_colors, app_text_styles
│   │   ├── utils/       → currency_formatter, date_formatter, haversine, csv_exporter
│   │   ├── services/    → storage_service
│   │   └── theme/       → app_theme
│   ├── data/
│   │   ├── models/    → 8 models
│   │   ├── repositories/ → 4 repos
│   │   └── seeds/   → seed_data.dart
│   ├── domain/       → 4 service (pure dart)
│   ├── providers/    → 5 ChangeNotifier
│   ├── core/services/auth_service.dart
│   └── ui/
│       ├── common/widgets/ → 11 reusable widgets
│       ├── auth/           → login, otp, register, role_select
│       ├── seller/         → 5 screens
│       ├── farmer/         → 7 screens
│       ├── wallet/         → wallet_screen
│       └── admin/          → 3 screens
├── test/domain/   → 3 unit test (shelf_life, matching, pricing)
└── pubspec.yaml
```

### Provider Dependency Graph
```
main.dart
 ├─ StorageService.instance       (singleton)
 ├─ SellerRepository(StorageService)
 ├─ FarmerRepository(StorageService)
 ├─ ListingRepository(StorageService)
 ├─ TransactionRepository(StorageService)
 ├─ PricingService()
 ├─ ShelfLifeService()
 ├─ MatchingService(ShelfLifeService)
 └─ MultiProvider[5]:
      ├─ AuthProvider(StorageService, SellerRepo, FarmerRepo)
      ├─ ListingProvider(ListingRepo, ShelfLifeService)
      ├─ MatchingProvider(MatchingService, ListingProvider)
      ├─ TransactionProvider(TransactionRepo, WalletService, ListingProvider)
      └─ WalletProvider(WalletService, SellerRepo, FarmerRepo)
```

### Testing
- Unit test (pure-Dart domain services): `shelf_life_service_test.dart`, `matching_service_test.dart`, `pricing_service_test.dart`
- Widget smoke test: `test/widget_test.dart`

---

## 9. Mock Data

| Seller | Nama | Lokasi | Produk |
|---|---|---|---|
| seller1 | Bakery Sejahtera | Jakarta Selatan (-6.2297, 106.8146) | Roti Kering 12kg |
| seller2 | IRT Roti Lezat | Tangerang (-6.2356, 106.6852) | Tepung Afkir 20kg |

| Farmer | Nama | Ternak | Kapasitas | Lokasi |
|---|---|---|---|---|
| farmer1 | Pak Budi | Ayam, Bebek | 20 kg/minggu | Cilandak (-6.2784, 106.8027) |
| farmer2 | Kebun Sayur Mandiri | Sapi, Kambing | 200 kg/minggu | Depok (-6.4000, 106.7800) |

Listing: 3 seed listings (roti_kering, tepung_afkir, sayuran_mentah).

---

## 10. Rencana Fitur / Roadmap

| FASE | FITUR | STATUS |
|---|---|---|
| 1 | Scaffold, core, model, service, auth, role select | ✅ (FEAT-001) |
| 2 | Providers, routing, widget library | ✅ (FEAT-002) |
| 3 | Seller flow (dashboard, create listing, transaksi) | ✅ (FEAT-003) |
| 4 | Farmer flow + wallet + checkout | ✅ (FEAT-004) |
| 5 | Admin panel, CSV export, responsive, aksesibilitas | ✅ (FEAT-005) |
| 6 | Chatbot AI, foto upload to cloud, real OTP | ⏳ (future) |
| 7 | Backend real-time (Supabase/Firebase) | ⏳ (future) |

---

## 11. Ketergantungan & Risiko

| Risiko | Mitigasi |
|---|---|
| Flutter SDK tidak tersedia di laptop | File ditulis manual; dilaporkan — perlu install untuk build/test |
| Shared preferences sebagai storage | Data hilang saat clear app — tidak persistent cloud |
| Simulasi OTP/location/payment | Dokumentasi jelas ini demo, bukan produksi |
| Geolocator removed (FIX-6) | Lokasi tetap manual input |
| `num.clamp()` → butuh `.toDouble()` | Sudah fix di semua service |
| CSV export pakai `dart:io` (temp dir) | Dibungkang try/catch → error message |
| Error kompilasi tersembunyi | Perlu `flutter analyze` setelah install |

---

## 12. Referensi
- Source: `/Users/macbook/Documents/Folder Kuliah/Kelas Coding/MOBILE APPS LINAKAN/linakan_app/`
- Agensi: `.agents/tasks/{features/FEAT-00x.json, fixes.md, plan.md, context.json, review.json}`
- Web app asli: `99foods.vercel.app` (proyek terkait, mirip domain)
- Git log: HEAD `876ff1f` feat: palet warna lebih hidup
