import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matching_provider.dart';
import '../../core/theme/app_theme.dart';

/// Opsi jenis ternak (id sesuai compatibleLivestock, label tampilan BI).
const List<String> _livestockIds = [
  'bebek',
  'ayam',
  'unggas_lainnya',
  'sapi',
  'kambing',
  'kelinci',
];

const List<String> _livestockLabels = [
  'Bebek',
  'Ayam',
  'Unggas Lainnya',
  'Sapi',
  'Kambing',
  'Kelinci',
];

const String _customLivestockLabel = 'Lainnya';

/// Layar onboarding peternak — formulir multi-langkah.
/// Langkah 1: Jenis Ternak (FilterChip multi-pilih, minimal satu).
/// Langkah 2: Kebutuhan Pakan (deskripsi).
/// Langkah 3: Kapasitas & Lokasi (kapasitas, nama lokasi, lat, lng).
class FarmerOnboardingScreen extends StatefulWidget {
  const FarmerOnboardingScreen({super.key});

  @override
  State<FarmerOnboardingScreen> createState() => _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState extends State<FarmerOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // State formulir
  final Set<String> _selectedLivestock = {};
  final List<String> _customLivestock = [];
  final TextEditingController _customLivestockController =
      TextEditingController();
  bool _showCustomInput = false;
  final TextEditingController _feedController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  double _lat = -6.2297;
  double _lng = 106.8419;
  bool _settingLocation = false;
  bool _locationSet = false;

  String? _livestockError;
  String? _capacityError;

  @override
  void initState() {
    super.initState();
    _prefillFromExistingFarmer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customLivestockController.dispose();
    _feedController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Isi formulir dengan data peternak yang sudah ada (jika ada).
  void _prefillFromExistingFarmer() {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;
    final farmer = context.read<FarmerRepository>().getById(userId);
    if (farmer == null) return;
    _selectedLivestock.addAll(farmer.livestock);
    _customLivestock.addAll(
      farmer.livestock.where((l) => !_livestockIds.contains(l)),
    );
    _feedController.text = farmer.feedRequirements;
    _capacityController.text =
        farmer.capacity > 0 ? farmer.capacity.toStringAsFixed(0) : '';
    _locationController.text = farmer.location;
    _lat = farmer.lat;
    _lng = farmer.lng;
    _locationSet = farmer.lat != 0 && farmer.lng != 0;
  }

  bool get _isLastStep => _currentStep == 2;

  bool _validateCurrentStep() {
    setState(() {
      _livestockError = null;
      _capacityError = null;
    });

    if (_currentStep == 0) {
      if (_selectedLivestock.isEmpty) {
        setState(() => _livestockError = 'Pilih minimal satu jenis ternak.');
        return false;
      }
    }

    if (_currentStep == 2) {
      final capacity = double.tryParse(_capacityController.text.trim());
      if (capacity == null || capacity <= 0) {
        setState(() => _capacityError =
            'Masukkan kapasitas mingguan yang valid (lebih dari 0).');
        return false;
      }
    }
    return true;
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_isLastStep) {
      _saveProfile();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
  }

  void _back() {
    if (_currentStep == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
  }

  Future<void> _saveProfile() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    final farmerRepo = context.read<FarmerRepository>();
    final existing = farmerRepo.getById(userId);
    if (existing == null) return;

    final updated = existing.copyWith(
      livestock: _selectedLivestock.toList(),
      feedRequirements: _feedController.text.trim().isEmpty
          ? existing.feedRequirements
          : _feedController.text.trim(),
      capacity: double.parse(_capacityController.text.trim()),
      location: _locationController.text.trim().isEmpty
          ? existing.location
          : _locationController.text.trim(),
      lat: _lat,
      lng: _lng,
    );

    farmerRepo.update(updated);

    // Hitung ulang kecocokan dengan profil baru.
    await context.read<MatchingProvider>().computeMatches(updated);

    if (!mounted) return;
    context.go('/farmer/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: Text('Lengkapi Profil Peternak',
            style:
                AppTextStyles.heading1.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, totalSteps: 3),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildLivestockStep(),
                _buildFeedStep(),
                _buildCapacityLocationStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Langkah 1 — Jenis Ternak
  // ---------------------------------------------------------------------------
  Widget _buildLivestockStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jenis Ternak',
              style:
                  AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Pilih jenis ternak yang Anda pelihara. Pilih minimal satu.',
            style: AppTextStyles.body.copyWith(color: AppColors.kColorMuted),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(_livestockIds.length, (i) {
                final id = _livestockIds[i];
                return _livestockChip(
                  label: _livestockLabels[i],
                  selected: _selectedLivestock.contains(id),
                  onTap: () => setState(() {
                    if (_selectedLivestock.contains(id)) {
                      _selectedLivestock.remove(id);
                    } else {
                      _selectedLivestock.add(id);
                    }
                    _livestockError = null;
                  }),
                );
              }),
              // Ternak kustom hasil ketikan manual pengguna.
              ..._customLivestock.map(
                (custom) => _livestockChip(
                  label: custom,
                  selected: true,
                  isCustom: true,
                  onTap: () => setState(() {
                    _selectedLivestock.remove(custom);
                    _customLivestock.remove(custom);
                  }),
                ),
              ),
              _livestockChip(
                label: _customLivestockLabel,
                selected: _showCustomInput,
                icon: PhosphorIconsLight.plus,
                onTap: () => setState(() {
                  _showCustomInput = !_showCustomInput;
                  if (!_showCustomInput) {
                    _customLivestockController.clear();
                  }
                }),
              ),
            ],
          ),
          if (_showCustomInput) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _customLivestockController,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'mis. Domba, Kelinci Dutch',
                      filled: true,
                      fillColor: AppColors.kColorSurface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.kColorBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.kColorBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.kColorPrimary, width: 1.8),
                      ),
                    ),
                    onSubmitted: (_) => _addCustomLivestock(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _addCustomLivestock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kColorPrimary,
                      foregroundColor: AppColors.kColorOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonBorder,
                      ),
                    ),
                    child: const Text('Tambah'),
                  ),
                ),
              ],
            ),
          ],
          if (_livestockError != null) ...[
            const SizedBox(height: 12),
            Text(
              _livestockError!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.kColorDanger),
            ),
          ],
        ],
      ),
    );
  }

  /// Tambah jenis ternak kustom dari ketikan manual pengguna.
  void _addCustomLivestock() {
    final value = _customLivestockController.text.trim();
    if (value.isEmpty) return;
    final key = value.toLowerCase();
    setState(() {
      if (!_customLivestock.contains(key) && !_livestockIds.contains(key)) {
        _customLivestock.add(key);
        _selectedLivestock.add(key);
      }
      _customLivestockController.clear();
      _showCustomInput = false;
      _livestockError = null;
    });
  }

  Widget _livestockChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isCustom = false,
    IconData? icon,
  }) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(
        isCustom ? PhosphorIconsLight.x : (icon ?? PhosphorIconsLight.check),
        size: 13,
        color: selected ? AppColors.kColorOnPrimary : AppColors.kColorMuted,
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.kColorPrimary,
      labelStyle: TextStyle(
        color: selected ? AppColors.kColorOnPrimary : AppColors.kColorText,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.kColorSurface,
      side: const BorderSide(color: AppColors.kColorBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Langkah 2 — Kebutuhan Pakan
  // ---------------------------------------------------------------------------
  Widget _buildFeedStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kebutuhan Pakan',
              style:
                  AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Jelaskan kebutuhan pakan ternak Anda secara singkat.',
            style: AppTextStyles.body.copyWith(color: AppColors.kColorMuted),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _feedController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'mis. Tepung, sisa roti, sayuran',
              filled: true,
              fillColor: AppColors.kColorSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.kColorBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.kColorPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Langkah 3 — Kapasitas & Lokasi
  // ---------------------------------------------------------------------------
  Widget _buildCapacityLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kapasitas & Lokasi',
              style:
                  AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Kapasitas pakan per minggu dan lokasi peternakan Anda.',
            style: AppTextStyles.body.copyWith(color: AppColors.kColorMuted),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _capacityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Kapasitas (kg/minggu)',
              filled: true,
              fillColor: AppColors.kColorSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.kColorBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.kColorPrimary),
              ),
            ),
          ),
          if (_capacityError != null) ...[
            const SizedBox(height: 8),
            Text(
              _capacityError!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.kColorDanger),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Nama Lokasi',
              hintText: 'mis. Cilandak',
              filled: true,
              fillColor: AppColors.kColorSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.kColorBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.kColorPrimary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _settingLocation ? null : _useCurrentLocation,
            icon: _settingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(PhosphorIconsLight.mapPin, size: 20),
            label: Text(_settingLocation
                ? 'Mengambil lokasi...'
                : 'Set lokasi sekarang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kColorPrimary,
              side: const BorderSide(color: AppColors.kColorPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (_locationSet) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(PhosphorIconsLight.checkCircle,
                    size: 16, color: AppColors.kColorSuccess),
                const SizedBox(width: 6),
                Text(
                  'Lokasi diset: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.kColorSuccess),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Ambil lokasi terkini (GPS) — fallback ke koordinat default.
  Future<void> _useCurrentLocation() async {
    setState(() => _settingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationSnack('Izin lokasi ditolak. Lokasi tidak di-set.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationSet = true;
      });
      _showLocationSnack('Lokasi berhasil di-set.');
    } catch (_) {
      _showLocationSnack('Gagal mengambil lokasi. Coba lagi.');
    } finally {
      if (mounted) setState(() => _settingLocation = false);
    }
  }

  void _showLocationSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // Bottom bar (Back / Next / Simpan)
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.kColorSurface,
          border: Border(top: BorderSide(color: AppColors.kColorBorder)),
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: _back,
                child: const Text('Kembali'),
              )
            else
              const SizedBox(width: 0),
            const Spacer(),
            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kColorPrimary,
                foregroundColor: AppColors.kColorOnPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonBorder,
                ),
              ),
              child: Text(_isLastStep ? 'Simpan Profil' : 'Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indikator langkah (titik) di bagian atas.
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final active = i <= currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 8),
              height: 6,
              decoration: BoxDecoration(
                color:
                    active ? AppColors.kColorPrimary : AppColors.kColorBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}
