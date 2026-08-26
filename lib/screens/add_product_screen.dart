import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

// Variant Model with Present Stock & Dynamic Addition Calculation
class ProductVariantItem {
  final TextEditingController unitController;
  final TextEditingController priceController;
  final TextEditingController stockController;
  int presentStock;

  ProductVariantItem({
    String unit = '1 kg',
    String price = '',
    String stock = '',
    this.presentStock = 0,
  })  : unitController = TextEditingController(text: unit),
        priceController = TextEditingController(text: price),
        stockController = TextEditingController(text: stock);

  int get enteredStock => int.tryParse(stockController.text.trim()) ?? 0;
  int get totalStock => presentStock > 0 ? (presentStock + enteredStock) : enteredStock;

  void dispose() {
    unitController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}

class AddProductScreen extends StatefulWidget {
  // ఎడిట్ మోడ్ కోసం పారామీటర్లు
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const AddProductScreen({
    super.key,
    this.editDocId,
    this.editData,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Grocery / Supermarket');
  final _descriptionController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  String? _selectedExistingDocId;

  List<ProductVariantItem> _variants = [
    ProductVariantItem(unit: '1 kg', price: '', stock: '100', presentStock: 0),
  ];

  List<QueryDocumentSnapshot> _allProducts = [];
  String _topStockFilter = 'All';
  bool _isLoadingProducts = true;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isLoading = false;

  // Theme Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryPurple = Color(0xFF4F46E5);
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);

  final List<String> _popularBrands = ['Aashirvaad', 'Tata', 'Freedom', 'Heritage', 'Amul', 'Fortune', 'Patanjali'];

  @override
  void initState() {
    super.initState();
    _initEditModeOrFetchAll();
  }

  void _initEditModeOrFetchAll() {
    // కార్డ్ నుండి ఎడిట్ మోడ్‌లో ఓపెన్ అయినప్పుడు వివరాలు లోడ్ చేయడం
    if (widget.editDocId != null && widget.editData != null) {
      _selectedExistingDocId = widget.editDocId;
      final data = widget.editData!;
      _nameController.text = data['name'] ?? '';
      _brandController.text = data['brand'] ?? '';
      _categoryController.text = data['category'] ?? 'Grocery / Supermarket';
      _descriptionController.text = data['description'] ?? '';

      final String img = data['imageBase64'] ?? '';
      if (img.isNotEmpty) {
        try {
          _imageBytes = base64Decode(img);
        } catch (_) {}
      }

      final rawVariants = data['variants'] as List<dynamic>?;
      if (rawVariants != null && rawVariants.isNotEmpty) {
        _variants.clear();
        for (var item in rawVariants) {
          final m = item as Map<String, dynamic>;
          final int existingStock = (m['stock'] is int ? m['stock'] : int.tryParse('${m['stock']}')) ?? 0;
          _variants.add(
            ProductVariantItem(
              unit: m['unit'] ?? '1 kg',
              price: '${m['price'] ?? ''}',
              stock: '',
              presentStock: existingStock,
            ),
          );
        }
      } else {
        final int existingStock = (data['stock'] is int ? data['stock'] : int.tryParse('${data['stock']}')) ?? 0;
        _variants = [
          ProductVariantItem(
            unit: data['unit'] ?? '1 kg',
            price: '${data['price'] ?? ''}',
            stock: '',
            presentStock: existingStock,
          ),
        ];
      }
    }

    _fetchAllStoreProducts();
  }

  Future<void> _fetchAllStoreProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('merchantId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _allProducts = snapshot.docs;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _selectProductFromInventory(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      _selectedExistingDocId = doc.id;
      _nameController.text = data['name'] ?? '';
      _brandController.text = data['brand'] ?? '';
      _categoryController.text = data['category'] ?? 'Grocery / Supermarket';
      _descriptionController.text = data['description'] ?? '';

      final String imageBase64 = data['imageBase64'] ?? '';
      if (imageBase64.isNotEmpty) {
        try {
          _imageBytes = base64Decode(imageBase64);
        } catch (_) {
          _imageBytes = null;
        }
      } else {
        _imageBytes = null;
      }

      for (var v in _variants) {
        v.dispose();
      }
      _variants.clear();

      final rawVariants = data['variants'] as List<dynamic>?;
      if (rawVariants != null && rawVariants.isNotEmpty) {
        for (var item in rawVariants) {
          final m = item as Map<String, dynamic>;
          final int existingStock = (m['stock'] is int ? m['stock'] : int.tryParse('${m['stock']}')) ?? 0;
          _variants.add(
            ProductVariantItem(
              unit: m['unit'] ?? '1 kg',
              price: '${m['price'] ?? ''}',
              stock: '',
              presentStock: existingStock,
            ),
          );
        }
      } else {
        final int existingStock = (data['stock'] is int ? data['stock'] : int.tryParse('${data['stock']}')) ?? 0;
        _variants.add(
          ProductVariantItem(
            unit: data['unit'] ?? '1 kg',
            price: '${data['price'] ?? ''}',
            stock: '',
            presentStock: existingStock,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded "${data['name']}". Edit details & save!'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetFormForNewProduct() {
    setState(() {
      _selectedExistingDocId = null;
      _nameController.clear();
      _brandController.clear();
      _categoryController.text = 'Grocery / Supermarket';
      _descriptionController.clear();
      _imageBytes = null;
      for (var v in _variants) {
        v.dispose();
      }
      _variants = [
        ProductVariantItem(unit: '1 kg', price: '', stock: '100', presentStock: 0),
      ];
    });
  }

  void _addVariant() {
    setState(() {
      _variants.add(ProductVariantItem(unit: '500 gm', price: '', stock: '50', presentStock: 0));
    });
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() {
        _variants[index].dispose();
        _variants.removeAt(index);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (e) {
      _showMessage('Image pick error: $e');
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Product Image',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt_rounded, color: primaryBlue, size: 30),
                            SizedBox(height: 8),
                            Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library_rounded, color: textDark, size: 30),
                            SizedBox(height: 8),
                            Text('From Gallery', style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageBase64 = '';
      if (_imageBytes != null) {
        imageBase64 = base64Encode(_imageBytes!);
      }

      final List<Map<String, dynamic>> variantDataList = _variants.map((v) {
        return {
          'unit': v.unitController.text.trim(),
          'price': double.tryParse(v.priceController.text.trim()) ?? 0.0,
          'stock': v.totalStock,
        };
      }).toList();

      final primaryPrice = variantDataList.isNotEmpty ? variantDataList.first['price'] : 0.0;
      final primaryUnit = variantDataList.isNotEmpty ? variantDataList.first['unit'] : '';
      final int totalStock = variantDataList.fold<int>(0, (sum, v) => sum + ((v['stock'] as int?) ?? 0));

      final docData = {
        'merchantId': user.uid,
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': primaryPrice,
        'unit': primaryUnit,
        'stock': totalStock,
        'variants': variantDataList,
        if (imageBase64.isNotEmpty) 'imageBase64': imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_selectedExistingDocId != null) {
        // Firestore లో ప్రొడక్ట్‌ను అప్‌డేట్ చేయడం
        await FirebaseFirestore.instance
            .collection('products')
            .doc(_selectedExistingDocId)
            .update(docData);
        _showMessage('Product updated & saved successfully!');
      } else {
        // కొత్త ప్రొడక్ట్ యాడ్ చేయడం
        final newDocRef = FirebaseFirestore.instance.collection('products').doc();
        docData['productId'] = newDocRef.id;
        docData['createdAt'] = FieldValue.serverTimestamp();
        await newDocRef.set(docData);
        _showMessage('New product added successfully!');
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    for (var v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = _selectedExistingDocId != null;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        centerTitle: true,
        title: Text(
          isEditMode ? 'Edit / Update Product' : 'Add Product & Quantities',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textDark),
        ),
        actions: [
          if (isEditMode)
            TextButton.icon(
              onPressed: _resetFormForNewProduct,
              icon: const Icon(Icons.add, size: 16, color: primaryBlue),
              label: const Text('New Product', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP INVENTORY SUGGESTIONS
                    _buildAllStoreStockSelector(),
                    const SizedBox(height: 14),

                    // CARD 1: PRODUCT & BRAND DETAILS
                    _buildFormCard(
                      title: isEditMode ? 'Product Details (Editing)' : 'Product & Brand Details',
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            label: 'Product Name',
                            hint: 'Enter product name',
                            icon: Icons.shopping_basket_outlined,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter product name' : null,
                          ),
                          const SizedBox(height: 14),

                          // Brand Field
                          _buildTextField(
                            controller: _brandController,
                            label: 'Brand Name',
                            hint: 'e.g. Aashirvaad, Heritage, Freedom, Tata',
                            icon: Icons.branding_watermark_outlined,
                          ),
                          const SizedBox(height: 8),

                          // Brand quick chips
                          const Text(
                            'Quick Brands:',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _popularBrands.map((b) {
                              return InkWell(
                                onTap: () => setState(() => _brandController.text = b),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: _brandController.text == b ? primaryPurple.withOpacity(0.12) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _brandController.text == b ? primaryPurple : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    b,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _brandController.text == b ? primaryPurple : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          _buildTextField(
                            controller: _categoryController,
                            label: 'Category',
                            hint: 'e.g. Grocery, Dairy, Veg, Meat, Snacks',
                            icon: Icons.category_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CARD 2: QUANTITY, PRICING & STOCK
                    _buildFormCard(
                      title: 'Quantities, Prices & Stock',
                      icon: Icons.layers_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ధర మరియు స్టాక్ మార్పులు చేయండి:',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _variants.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final variant = _variants[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Option ${index + 1}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
                                        ),
                                        if (_variants.length > 1)
                                          InkWell(
                                            onTap: () => _removeVariant(index),
                                            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Qty / Unit
                                        Expanded(
                                          flex: 4,
                                          child: _buildTextField(
                                            controller: variant.unitController,
                                            label: 'Qty/Unit',
                                            hint: '1 kg, 500gm',
                                            icon: Icons.scale_outlined,
                                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter qty' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Price
                                        Expanded(
                                          flex: 4,
                                          child: _buildTextField(
                                            controller: variant.priceController,
                                            label: 'Price (₹)',
                                            hint: '50',
                                            icon: Icons.currency_rupee_rounded,
                                            keyboardType: TextInputType.number,
                                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter price' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Stock Box + Live Addition Badge
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildTextField(
                                                controller: variant.stockController,
                                                label: variant.presentStock > 0 ? '+ Add Qty' : 'Stock Qty',
                                                hint: variant.presentStock > 0 ? 'e.g. 50' : '100',
                                                icon: Icons.inventory_outlined,
                                                keyboardType: TextInputType.number,
                                                onChanged: (val) => setState(() {}),
                                                validator: (val) {
                                                  if (variant.presentStock == 0 && (val == null || val.trim().isEmpty)) {
                                                    return 'Enter stock';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 4),

                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: variant.presentStock > 0
                                                      ? const Color(0xFFFEF3C7)
                                                      : const Color(0xFFEEF2FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: variant.presentStock > 0
                                                        ? const Color(0xFFFDE68A)
                                                        : const Color(0xFFC7D2FE),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Text(
                                                  variant.presentStock > 0
                                                      ? 'Present: ${variant.presentStock} + Added: ${variant.enteredStock} = ${variant.totalStock} Total'
                                                      : 'Total Stock: ${variant.enteredStock}',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: variant.presentStock > 0
                                                        ? const Color(0xFF92400E)
                                                        : primaryBlue,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryBlue,
                              side: const BorderSide(color: primaryBlue, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            ),
                            onPressed: _addVariant,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: const Text('+ Add Another Quantity / Pack', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CARD 3: DESCRIPTION
                    _buildFormCard(
                      title: 'Description (Optional)',
                      icon: Icons.description_outlined,
                      child: _buildTextField(
                        controller: _descriptionController,
                        label: 'Product Details',
                        hint: 'Highlights, brand quality...',
                        icon: Icons.edit_note_rounded,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. SQUARE IMAGE UPLOADER
                    Center(
                      child: _buildSquareImageUploader(),
                    ),
                    const SizedBox(height: 24),

                    // 5. SAVE / UPDATE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEditMode ? Colors.teal : primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submitProduct,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEditMode ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEditMode ? 'Update Product & Stock' : 'Save Product & Stock',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // --- ALL STORE STOCKS SELECTOR ---
  Widget _buildAllStoreStockSelector() {
    if (_isLoadingProducts) {
      return const SizedBox(
        height: 50,
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_allProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final filteredDisplayList = _allProducts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final stock = data['stock'] is int ? data['stock'] : int.tryParse('${data['stock']}') ?? 0;

      if (_topStockFilter == 'Low Stock') return stock > 0 && stock < 100;
      if (_topStockFilter == 'Out of Stock') return stock <= 0;
      if (_topStockFilter == 'In Stock') return stock >= 100;
      return true;
    }).toList();

    final int totalCount = _allProducts.length;
    final int lowCount = _allProducts.where((d) {
      final s = (d.data() as Map<String, dynamic>)['stock'] ?? 0;
      return s > 0 && s < 100;
    }).length;
    final int outCount = _allProducts.where((d) {
      final s = (d.data() as Map<String, dynamic>)['stock'] ?? 0;
      return s <= 0;
    }).length;
    final int inCount = _allProducts.where((d) {
      final s = (d.data() as Map<String, dynamic>)['stock'] ?? 0;
      return s >= 100;
    }).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: primaryBlue, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Pick Existing Product:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
              ),
              const Spacer(),
              if (_selectedExistingDocId != null)
                InkWell(
                  onTap: _resetFormForNewProduct,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Clear Selection',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _stockFilterTab('All ($totalCount)', 'All', primaryBlue),
                _stockFilterTab('Low Stock ($lowCount)', 'Low Stock', Colors.orange),
                _stockFilterTab('Out of Stock ($outCount)', 'Out of Stock', Colors.redAccent),
                _stockFilterTab('In Stock ($inCount)', 'In Stock', Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (filteredDisplayList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No products under $_topStockFilter',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: filteredDisplayList.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Product';
                  final brand = data['brand'] ?? '';
                  final price = data['price'] ?? 0;
                  final stock = data['stock'] ?? 0;
                  final isSelected = _selectedExistingDocId == doc.id;

                  Color statusColor = Colors.green;
                  if (stock <= 0) statusColor = Colors.redAccent;
                  if (stock > 0 && stock < 100) statusColor = Colors.orange;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _selectProductFromInventory(doc),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryBlue.withOpacity(0.08) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: statusColor.withOpacity(0.15),
                              child: Icon(Icons.touch_app_rounded, color: statusColor, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textDark),
                                ),
                                Row(
                                  children: [
                                    if (brand.isNotEmpty) ...[
                                      Text(
                                        brand,
                                        style: const TextStyle(fontSize: 10.5, color: primaryPurple, fontWeight: FontWeight.bold),
                                      ),
                                      const Text(' • ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                    Text(
                                      '₹$price',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                    ),
                                    const Text(' • ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(
                                      stock <= 0
                                          ? 'Out of Stock'
                                          : stock < 100
                                              ? 'Low: $stock'
                                              : 'Stock: $stock',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stockFilterTab(String label, String value, Color color) {
    final isSelected = _topStockFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _topStockFilter = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: isSelected ? color : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // Square Image Box
  Widget _buildSquareImageUploader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourceBottomSheet,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _imageBytes != null ? primaryBlue : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (_imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _imageBytes!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: primaryBlue, size: 26),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '+ Add Product\nImage',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Image Upload',
                          style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _imageBytes != null ? Colors.black.withOpacity(0.65) : primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (_imageBytes != null)
          TextButton.icon(
            onPressed: () => setState(() => _imageBytes = null),
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
            label: const Text('Remove Image', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: textDark),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontSize: 13.5, color: textDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}