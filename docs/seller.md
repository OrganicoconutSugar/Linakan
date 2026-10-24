Tolong ubah TAMPILAN (visual/layout saja) halaman seller dashboard di project Flutter saya agar mirip dengan screenshot referensi yang saya lampirkan (gaya wallet fintech: header biru, sheet putih yang bisa ditarik ke atas, navbar melayang).

File yang terkait:
- lib/presentation/.../seller_dashboard_screen.dart (SellerDashboardScreen, _DashboardBanner, _AnimKpiCard, _EarningsCard, _RecentListingTile, _EarningsChart)
- lib/presentation/common/bottom_nav.dart (LinakanBottomNav)
- core/constants/app_colors.dart, app_text_styles.dart, core/theme/app_theme.dart (AppRadius)
(sesuaikan path dengan project)

ATURAN WAJIB (JANGAN DILANGGAR):
- Jangan ubah logic: semua variabel hasil perhitungan di build() (activeListings, expiringSoon, reserved, completed, earnings, sellerName, sellerType), provider (AuthProvider, ListingProvider, TransactionProvider), repository, ShelfLifeService, routing go_router, dan _onNavTap tetap sama persis.
- Jangan rename/pindah file, class, atau parameter publik. Signature LinakanBottomNav (currentIndex, onTap, userType) harus tetap sama karena dipakai halaman lain.
- Jangan tambah package baru. Pakai yang sudah ada (flutter_animate, phosphor_flutter, fl_chart).
- Pertahankan animasi yang ada (stagger fade/slide, AnimatedCounter, PressableScale) dan fungsi logout, onRefresh, serta navigasi ke /seller/create-listing dan /seller/listings.
- Gunakan AppColors/AppRadius/AppTextStyles yang sudah ada. Kalau butuh warna atau radius baru, tambahkan di file constants yang sama, jangan hardcode.
- Sebelum mengedit, tulis dulu rencana: file mana yang diubah dan bagian mana. Setelah selesai, jalankan flutter analyze dan rangkum perubahan.

TARGET TAMPILAN:

1. Header wallet (ganti isi _DashboardBanner, parameternya tetap)
- Background gradient biru (kPrimaryDark -> kPrimary) dengan sudut bawah membulat besar. Gambar seller_profile.png dan shimmer boleh dipertahankan sebagai tekstur halus, atau dihapus kalau mengganggu tampilan bersih.
- Kiri atas: teks/logo "LINAKAN". Kanan atas: tombol logout bulat semi-transparan (onLogout tetap dipanggil).
- Tengah: angka besar = Total Pendapatan (nilai earnings yang sama, format formatRupiah, tetap pakai AnimatedCounter) dengan label kecil di bawahnya. Di bawahnya "Selamat Datang, {sellerName}" dan badge tipe seller.
- Baris 3 tombol aksi bergaya ikon kotak membulat efek glass (putih semi-transparan) + label di bawah. Tombol pertama putih solid (primer). Isi: "Tambah Limbah" (go /seller/create-listing), "Listing" (go /seller/listings), "Transaksi" (go /seller/transactions).
- Di bawahnya kartu biru lebih gelap ala "Available to spend", berisi ringkasan singkat dari data yang sudah ada (misalnya jumlah Listing Aktif). Letaknya sedikit tertutup sheet putih.

2. Sheet putih yang bisa ditarik (ganti struktur body)
- Stack: lapisan bawah = header wallet (tetap di tempat), lapisan atas = DraggableScrollableSheet (initialChildSize ~0.58, minChildSize ~0.58, maxChildSize ~0.95) dengan sudut atas membulat besar, background putih (kColorBackground/Surface), dan handle kecil di atas.
- Seluruh konten body lama dipindah ke dalam sheet tanpa diubah isinya: "Ringkasan Hari Ini" + 4 KPI card, _EarningsCard, _EarningsChart, dan "Listing Terbaru". Semua pakai scrollController dari builder DraggableScrollableSheet (ganti CustomScrollView menjadi yang memakai controller itu) supaya ditarik naik dulu baru isi bisa discroll.
- Pull-to-refresh: pertahankan fungsinya (loadAll + loadTransactions), tapi karena bentrok dengan drag sheet, pasang di dalam sheet hanya saat sheet sudah penuh, atau ganti dengan tombol refresh kecil di header. Pilih yang paling aman dan jelaskan pilihannya.
- Tambahkan padding bawah cukup besar di akhir list supaya konten tidak tertutup navbar melayang.
- Judul section dan KPI card disesuaikan agar nuansanya sama dengan referensi: ikon kotak membulat biru muda, kartu putih bersih dengan border tipis, spacing lega.

3. Bottom navbar melayang (ubah tampilan LinakanBottomNav saja)
- Bentuk pill dengan margin kiri/kanan/bawah, sudut sangat membulat, efek glass (BackdropFilter blur + putih semi-transparan) dan shadow halus.
- Tab aktif diberi highlight pill biru muda dengan ikon dan label berwarna biru; tab lain abu-abu.
- Pakai extendBody: true di Scaffold halaman agar konten terlihat di belakang navbar. Cek juga halaman lain yang memakai LinakanBottomNav agar tidak ada yang tertutup atau rusak.
- Callback onTap, currentIndex, dan userType (seller/buyer) tetap berfungsi sama.

4. Tombol "Tambah Limbah" (FloatingActionButton.extended)
- Karena sekarang sudah ada tombol "Tambah Limbah" di header, hapus FAB dari halaman ini atau pindahkan posisinya agar tidak menumpuk dengan navbar melayang. Pastikan navigasi ke /seller/create-listing tetap tersedia.

HASIL AKHIR:
- Aplikasi berjalan seperti sebelumnya, hanya tampilan yang berubah.
- Tidak ada error di flutter analyze.
- Berikan ringkasan file yang diubah dan keputusan desain yang diambil (terutama soal refresh dan FAB).