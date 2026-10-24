import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/listing_status.dart';
import '../../data/models/waste_category.dart';
import '../../data/repositories/seller_repository.dart';
import '../../domain/pricing_service.dart';
import '../../domain/shelf_life_service.dart';
import '../../providers/auth_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

/// Layar pembuatan listing limbah pangan oleh seller.
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _beratController = TextEditingController();
  final _alamatController = TextEditingController();
  final _hargaOverrideController = TextEditingController();
  final _customCatCtr = TextEditingController();

  WasteCategory? _selectedCategory;
  String? _selectedCategoryValue;
  bool _isCustomCategory = false;

  final PricingService _pricingService = PricingService();

  PriceSuggestion? _priceSuggestion;
  String _priceOverrideWarning = '';
  bool _priceOverrideValid = true;

  @override
  void dispose() {
    _namaController.dispose();
    _beratController.dispose();
    _alamatController.dispose();
    _hargaOverrideController.dispose();
    _customCatCtr.dispose();
    super.dispose();
  }

  // Perbarui harga rekomendasi ketika kategori atau berat berubah
  void _updatePriceSuggestion() {
    final weight = double.tryParse(_beratController.text.trim());
    final category = _selectedCategory ?? WasteCategory.rotiKering;
    if ((_selectedCategory != null || _isCustomCategory) &&
        weight != null &&
        weight >= AppConstants.kMinListingWeight) {
      setState(() {
        _priceSuggestion =
            _pricingService.calculateSuggestedPrice(category, weight);
      });
      if (_hargaOverrideController.text.trim().isNotEmpty) {
        _validateOverride(_hargaOverrideController.text.trim());
      }
    } else {
      setState(() {
        _priceSuggestion = null;
        _priceOverrideWarning = '';
        _priceOverrideValid = true;
      });
    }
  }

  void _validateOverride(String value) {
    if (_priceSuggestion == null) return;
    final override = int.tryParse(value);
    if (override == null || override <= 0) {
      setState(() {
        _priceOverrideWarning = '';
        _priceOverrideValid = true;
      });
      return;
    }
    final result = _pricingService.validatePriceOverride(
      _priceSuggestion!.pricePerKg,
      override,
    );
    setState(() {
      _priceOverrideWarning = result.warning;
      _priceOverrideValid = result.isValid;
    });
  }

  void _onPratinjau() {
    if (!_formKey.currentState!.validate()) return;
    if (!_priceOverrideValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Harga override tidak valid. Maksimal ±50% dari rekomendasi.'),
          backgroundColor: AppColors.kColorDanger,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final sellerId = authProvider.currentUserId;
    final seller = sellerId == null
        ? null
        : context.read<SellerRepository>().getById(sellerId);
    if (seller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil seller tidak ditemukan. Silakan login ulang.'),
          backgroundColor: AppColors.kColorDanger,
        ),
      );
      return;
    }

    final weight = double.parse(_beratController.text.trim());
    final category = _selectedCategory ?? WasteCategory.rotiKering;
    final priceSuggestion =
        _pricingService.calculateSuggestedPrice(category, weight);

    int finalPricePerKg = priceSuggestion.pricePerKg;
    final overrideText = _hargaOverrideController.text.trim();
    if (overrideText.isNotEmpty) {
      final override = int.tryParse(overrideText);
      if (override != null && override > 0) {
        finalPricePerKg = override;
      }
    }

    final totalPrice = (finalPricePerKg * weight).round();

    final listing = ListingModel(
      id: 'listing_${DateTime.now().millisecondsSinceEpoch}',
      sellerId: seller.id,
      sellerName: seller.name,
      sellerType: seller.type,
      wasteName: _namaController.text.trim(),
      category: _selectedCategory ?? WasteCategory.rotiKering,
      customCategory: _isCustomCategory ? _customCatCtr.text.trim() : null,
      weight: weight,
      pricePerKg: finalPricePerKg,
      totalPrice: totalPrice,
      suggestedPrice: priceSuggestion.pricePerKg,
      finalPrice: totalPrice,
      imageUrl: null,
      location: seller.location,
      lat: seller.lat,
      lng: seller.lng,
      pickupAddress: _alamatController.text.trim(),
      createdAt: DateTime.now(),
      status: ListingStatus.available,
      quality: 'Baik',
      notes: null,
    );

    context.go('/seller/listing-preview', extra: listing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: const Text('Tambah Listing Limbah'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Nama Limbah
            const _SectionLabel(label: 'Nama Limbah'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _namaController,
              decoration: _inputDecoration('Contoh: Roti Kering Sisa Produksi'),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nama limbah wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 2. Kategori
            const _SectionLabel(label: 'Kategori Limbah'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategoryValue,
              decoration: _inputDecoration('Pilih kategori'),
              items: [
                ...WasteCategory.values.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )),
                const DropdownMenuItem(value: 'custom', child: Text('Lainnya')),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedCategoryValue = v;
                  if (v == 'custom') {
                    _isCustomCategory = true;
                    _selectedCategory = null;
                  } else {
                    _isCustomCategory = false;
                    _selectedCategory = WasteCategoryExtension.fromId(v!);
                  }
                });
                _updatePriceSuggestion();
              },
              validator: (v) => (_isCustomCategory || v != null)
                  ? null
                  : 'Pilih kategori limbah',
            ),
            if (_isCustomCategory) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customCatCtr,
                decoration: _inputDecoration('Masukkan kategori khusus'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Kategori khusus wajib diisi'
                    : null,
              ),
            ],
            const SizedBox(height: 20),

            // 3. Berat
            const _SectionLabel(label: 'Berat (kg)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _beratController,
              decoration: _inputDecoration('Minimal 2 kg'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => _updatePriceSuggestion(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Berat wajib diisi';
                final weight = double.tryParse(v.trim());
                if (weight == null || weight <= 0) {
                  return 'Masukkan angka yang valid';
                }
                if (weight < AppConstants.kMinListingWeight) {
                  return 'LINAKAN membutuhkan minimal 2 kg per listing';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 4. Foto Limbah (placeholder)
            const _SectionLabel(label: 'Foto Limbah'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Fitur upload foto aktif saat backend tersedia'),
                  ),
                );
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppSurfaces.ivory,
                  boxShadow: AppSurfaces.raisedShadow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.kColorBorder,
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      PhosphorIconsLight.camera,
                      size: 36,
                      color: AppColors.kColorMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ketuk untuk tambah foto',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.kColorMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Alamat Pengambilan
            const _SectionLabel(label: 'Alamat Pengambilan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _alamatController,
              decoration: _inputDecoration('Contoh: Jl. Raya No. 42, Jakarta'),
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Alamat pengambilan wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 6. Kartu Harga Rekomendasi (muncul jika data valid)
            if (_priceSuggestion != null) ...[
              const _SectionLabel(label: 'Rekomendasi Harga'),
              const SizedBox(height: 8),
              _PriceRecommendationCard(priceSuggestion: _priceSuggestion!),
              const SizedBox(height: 20),
            ],

            // 7. Harga Anda (override opsional)
            const _SectionLabel(label: 'Harga Anda / kg (opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _hargaOverrideController,
              decoration: _inputDecoration(
                _priceSuggestion != null
                    ? 'Rekomendasi: ${formatRupiah(_priceSuggestion!.pricePerKg)}/kg'
                    : 'Kosongkan untuk gunakan rekomendasi',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _validateOverride,
            ),
            // Tampilkan peringatan override
            if (_priceOverrideWarning.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _priceOverrideWarning,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _priceOverrideValid
                        ? AppColors.kColorWarning
                        : AppColors.kColorDanger,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // 8. Kartu Shelf Life (muncul jika kategori dipilih atau custom)
            if (_selectedCategory != null || _isCustomCategory) ...[
              _ShelfLifeInfoCard(
                  category: _selectedCategory ?? WasteCategory.rotiKering),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 20),

            // Tombol Pratinjau
            ElevatedButton(
              onPressed: _onPratinjau,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kColorPrimary,
                foregroundColor: AppColors.kColorOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonBorder,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Pratinjau Listing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.kColorMuted),
      filled: true,
      fillColor: AppColors.kColorSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.kColorBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.kColorBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.kColorPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.kColorDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.kColorDanger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.heading3,
    );
  }
}

class _PriceRecommendationCard extends StatelessWidget {
  final PriceSuggestion priceSuggestion;

  const _PriceRecommendationCard({required this.priceSuggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kColorPrimary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.kColorPrimary.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsLight.lightbulb,
                size: 18,
                color: AppColors.kColorPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Rekomendasi LINAKAN',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.kColorPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harga per kg:',
                style: AppTextStyles.body,
              ),
              Text(
                '${formatRupiah(priceSuggestion.pricePerKg)}/kg',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.kColorPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: AppTextStyles.body),
              Text(
                formatRupiah(priceSuggestion.totalPrice),
                style: AppTextStyles.price,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Anda tetap dapat mengubah harga di kolom di bawah.',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.kColorMuted),
          ),
        ],
      ),
    );
  }
}

class _ShelfLifeInfoCard extends StatelessWidget {
  final WasteCategory category;

  const _ShelfLifeInfoCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final shelfLifeService = ShelfLifeService();
    final now = DateTime.now();
    final expiry = shelfLifeService.getExpiryDate(category, now);
    final hours = category.shelfLifeHours;
    final days = (hours / 24).round();
    final expiryStr = formatDate(expiry);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsLight.clock,
            color: AppColors.kColorAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masa Simpan: $days hari ($hours jam)',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Layak tayang hingga $expiryStr',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.kColorMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
