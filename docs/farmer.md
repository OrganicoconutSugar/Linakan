Tolong ubah TAMPILAN (visual/layout saja) halaman farmer dashboard (FarmerDashboardScreen) agar sama gayanya dengan referensi (gambar terlampir) dan dengan seller dashboard yang sudah saya ubah sebelumnya: header wallet biru, sheet putih yang bisa ditarik ke atas, navbar melayang.

File terkait (sesuaikan path):
- lib/presentation/.../farmer_dashboard_screen.dart (FarmerDashboardScreen, _GreetingBanner, _KpiCard, _TransactionChart)
- lib/presentation/common/bottom_nav.dart (LinakanBottomNav)
- core/constants/app_colors.dart, app_text_styles.dart, core/theme/app_theme.dart

ATURAN WAJIB:
- Jangan ubah logic: initState, _initData (termasuk redirect ke /farmer/onboarding), _refresh, _onNavTap, setState untuk _currentNavIndex, serta semua provider/repository (AuthProvider, ListingProvider, TransactionProvider, MatchingProvider, FarmerRepository) dan perhitungan instantMatches, allMatches, reservedCount, completedCount tetap sama persis.
- Jangan rename/pindah file, class, atau parameter publik. Signature LinakanBottomNav (currentIndex, onTap, userType) tidak boleh berubah. Tab tetap 4 (dashboard, matches, marketplace, wallet), jangan ditambah.
- Jangan ubah MatchCard, EmptyState, FadeSlideIn, PressableScale, AnimatedCounter. Cukup pakai seperti sekarang.
- Jangan tambah package baru. Pakai AppColors/AppRadius/AppTextStyles yang ada; kalau butuh token baru, tambahkan di file constants yang sama.
- Kalau seller dashboard sudah punya komponen header wallet dan sheet tarik, JANGAN duplikasi kode. Ekstrak ke widget bersama di folder common/widgets (file baru), lalu pakai di kedua halaman. Perubahan di seller dashboard hanya boleh berupa penyesuaian pemakaian widget tanpa mengubah tampilan atau logic-nya. Kalau belum ada, buat widget bersamanya dari awal.
- Sebelum mengedit, tulis rencana: file yang diubah/ditambah. Setelah selesai jalankan flutter analyze dan rangkum.

TARGET TAMPILAN:

1. Hapus AppBar, ganti dengan header wallet (gradient biru kPrimaryDark -> kPrimary, sudut bawah membulat besar)
- Kiri atas: "LINAKAN". Kanan atas: tombol logout bulat semi-transparan (logika logout yang sama: logout() lalu go /auth/login).
- Tengah: angka besar = allMatches.length (pakai AnimatedCounter) dengan label "Total Cocok" di bawahnya. Di bawahnya sapaan "Halo, {farmerName}" dan badge "Instant Match aktif" (konten _GreetingBanner dipindah ke header ini, tanpa mengubah teksnya).
- Baris 3 tombol aksi ikon kotak membulat efek glass + label: "Instant Match" (go /farmer/matches, tombol putih solid sebagai primer), "Pasar" (go /farmer/marketplace), "Dompet" (go /wallet).
- Kartu biru lebih gelap di bawahnya (gaya "Available to spend") berisi ringkasan dari data yang ada, misalnya jumlah Instant Match (instantMatches.length). Sedikit tertutup sheet putih.

2. Sheet putih bisa ditarik (DraggableScrollableSheet)
- Stack: header wallet di lapisan bawah, DraggableScrollableSheet di atas (initialChildSize ~0.58, minChildSize ~0.58, maxChildSize ~0.95), sudut atas membulat besar, background putih, ada handle kecil.
- Pindahkan semua isi ListView lama ke dalam sheet tanpa mengubah isinya: "Instant Match untuk Anda" (list horizontal MatchCard + EmptyState), "Ringkasan" (3 KPI card), "Aktivitas Transaksi" (chart), "Jelajahi Pasar". Gunakan scrollController dari sheet agar scroll konsisten.
- Perhatikan list horizontal Instant Match di dalam scroll vertikal: pastikan tidak ada konflik gesture dan tinggi tetap 430.
- RefreshIndicator bentrok dengan drag sheet. Pertahankan fungsi _refresh dengan cara yang paling aman (aktif hanya saat sheet penuh, atau tombol refresh kecil di header), dan jelaskan pilihannya.
- Ganti SizedBox(height: 80) di akhir dengan padding bawah yang cukup supaya konten tidak tertutup navbar melayang.
- Section title dan KPI card disesuaikan nuansanya dengan referensi: ikon kotak membulat biru muda, kartu putih bersih dengan border tipis, spacing lega.

3. Navbar melayang
- Pakai LinakanBottomNav versi baru (pill, glass blur, tab aktif highlight biru muda). Kalau sudah diubah di tahap seller, cukup pastikan tampil benar untuk UserType.farmer dengan 4 tab. Pakai extendBody: true di Scaffold halaman ini.

HASIL AKHIR:
- Aplikasi berjalan seperti sebelumnya, hanya tampilan yang berubah.
- flutter analyze tanpa error.
- Ringkasan file yang diubah/ditambah dan keputusan desain (terutama refresh dan widget bersama).