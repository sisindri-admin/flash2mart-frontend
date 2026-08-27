import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../services/location_service.dart';
import 'add_product_screen.dart';
import 'orders_screen.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  bool _isSearchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Inventory Toggle & Filter
  bool _isInventoryExpanded = true;
  String _selectedCategory = 'All';

  // Theme Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryPurple = Color(0xFF4F46E5);
  static const Color cardGreenBorder = Color(0xFF16A34A); // Outer Green Border
  static const Color productNameGold = Color(0xFFFDE047); // Matching Warm Gold Accent
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOCATION BOTTOM SHEET (LIVE GPS + MANUAL ADDRESS INPUT) ---
  void _showLocationEditBottomSheet(BuildContext context, String merchantId, String currentSavedLocation) {
    final TextEditingController manualLocationController = TextEditingController();
    String liveDetectedAddress = currentSavedLocation;
    bool isDetecting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Set Shop Location',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  'Live GPS అడ్రస్ లేదా మీ సొంత అడ్రస్‌ను మాన్యువల్‌గా సెట్ చేసుకోండి:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // FIELD 1: AUTO DETECTED LIVE GPS LOCATION
                const Text(
                  '1. Live GPS Location (Auto-Detected)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.my_location_rounded, color: primaryBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              liveDetectedAddress.isNotEmpty ? liveDetectedAddress : 'Detecting GPS...',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Google Maps ఆధారంగా తీసుకున్న లైవ్ అడ్రస్',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: isDetecting
                            ? null
                            : () async {
                                setModalState(() => isDetecting = true);
                                final res = await LocationService.instance.getCurrentLiveLocation();
                                if (res.success) {
                                  setModalState(() {
                                    liveDetectedAddress = res.address;
                                    isDetecting = false;
                                  });
                                } else {
                                  setModalState(() => isDetecting = false);
                                  _showSnackBar(res.errorMessage ?? 'GPS Error', Colors.redAccent);
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isDetecting)
                                const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5))
                              else
                                const Icon(Icons.refresh_rounded, size: 12, color: primaryBlue),
                              const SizedBox(width: 3),
                              const Text('Re-Detect', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primaryBlue)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // FIELD 2: MANUAL CUSTOM ADDRESS INPUT
                const Text(
                  '2. Manual Custom Address (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: manualLocationController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: textDark),
                  decoration: InputDecoration(
                    hintText: 'ఉదా: Shop No. 5, Opp. RTC Bus Stand, Trunk Road, Nellore',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.edit_location_alt_outlined, color: primaryPurple, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'మాన్యువల్ అడ్రస్ ఎంటర్ చేస్తే అది సేవ్ అవుతుంది, లేకపోతే లైవ్ GPS అడ్రస్ సేవ్ అవుతుంది.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),

                // SAVE LOCATION BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final manualText = manualLocationController.text.trim();
                      final finalLocation = manualText.isNotEmpty ? manualText : liveDetectedAddress;

                      await FirebaseFirestore.instance.collection('merchants').doc(merchantId).set({
                        'location': finalLocation,
                        'isManualLocation': manualText.isNotEmpty,
                        'lastLocationUpdate': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                      if (mounted) {
                        Navigator.pop(ctx);
                        _showSnackBar(
                          manualText.isNotEmpty
                              ? 'Manual address saved: $finalLocation'
                              : 'Live GPS address saved: $finalLocation',
                          Colors.teal,
                        );
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Save Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(String message, Color bgColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Delete Product with Confirmation Dialog
  Future<void> _deleteProduct(String docId, String productName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$productName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('products').doc(docId).delete();
        _showSnackBar('Product "$productName" deleted successfully.', Colors.redAccent);
      } catch (e) {
        _showSnackBar('Failed to delete product: $e', Colors.red);
      }
    }
  }

  // Navigate to Edit Product
  void _editProduct(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
          editDocId: docId,
          editData: data,
        ),
      ),
    );
  }

  // Pick Store Image from Gallery & Save to Firestore
  Future<void> _pickAndUploadStoreImage(String merchantId) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 70,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final String base64String = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(merchantId)
          .set({
        'storeImageBase64': base64String,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackBar('Store image updated successfully!', Colors.teal);
    } catch (e) {
      _showSnackBar('Failed to update store image: $e', Colors.redAccent);
    }
  }

  // Toggle Store Online/Offline status in Firestore
  Future<void> _toggleOnlineStatus(String merchantId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(merchantId)
          .update({
        'isOnline': !currentStatus,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showSnackBar('Failed to update status: $e', Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final merchantId = user?.uid ?? '';

    if (merchantId.isEmpty) {
      return Scaffold(
        backgroundColor: bgGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Session expired. Please login again.',
                style: TextStyle(fontWeight: FontWeight.w600, color: textDark),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('merchants')
              .doc(merchantId)
              .snapshots(),
          builder: (context, merchantSnapshot) {
            final merchantData = merchantSnapshot.data?.data() as Map<String, dynamic>?;
            final storeName = merchantData?['storeName'] ?? 'Flash2Mart Store';
            final ownerName = merchantData?['ownerName'] ?? 'Prakash';
            final location = merchantData?['location'] ?? 'Nellore, Andhra Pradesh';
            final storeImage = merchantData?['storeImageBase64'] ?? merchantData?['storeImage'] ?? '';
            final category = merchantData?['category'] ?? 'Supermarket';
            final bool isOnline = merchantData?['isOnline'] ?? true;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('merchantId', isEqualTo: merchantId)
                  .snapshots(),
              builder: (context, productSnapshot) {
                final products = productSnapshot.data?.docs ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('merchantId', isEqualTo: merchantId)
                      .snapshots(),
                  builder: (context, orderSnapshot) {
                    final orders = orderSnapshot.data?.docs ?? [];

                    final int totalProducts = products.length;
                    final int totalOrders = orders.length;
                    final int pendingOrders = _countPending(orders);
                    final double totalRevenue = _sumRevenue(orders);

                    // Dynamic Categories
                    final Set<String> dynamicCategories = {'All'};
                    for (var doc in products) {
                      final data = doc.data() as Map<String, dynamic>;
                      final cat = (data['category'] ?? '').toString().trim();
                      if (cat.isNotEmpty) {
                        dynamicCategories.add(cat);
                      }
                    }

                    // Product Filter Logic
                    var filteredProducts = products.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final brand = (data['brand'] ?? '').toString().toLowerCase();
                      final pCategory = (data['category'] ?? '').toString();

                      final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
                          brand.contains(_searchQuery.toLowerCase()) ||
                          pCategory.toLowerCase().contains(_searchQuery.toLowerCase());
                      if (!matchesSearch) return false;

                      if (_selectedCategory != 'All' && pCategory != _selectedCategory) {
                        return false;
                      }

                      return true;
                    }).toList();

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. TOP HEADER WITH CLICKABLE LOCATION (OPENS BOTTOM SHEET)
                          _buildTopHeader(
                            storeName: storeName,
                            location: location,
                            ownerName: ownerName,
                            category: category,
                            isOnline: isOnline,
                            merchantId: merchantId,
                            pendingCount: pendingOrders,
                          ),
                          const SizedBox(height: 10),

                          // EXPANDABLE SEARCH BOX
                          if (_isSearchOpen) ...[
                            _buildToggledSearchBar(),
                            const SizedBox(height: 10),
                          ],

                          // 2. STORE IMAGE CARD
                          Center(
                            child: _buildAdjustedStoreImageCard(
                              merchantId: merchantId,
                              storeName: storeName,
                              storeImage: storeImage,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. ACTION BUTTONS
                          _buildActionButtons(context, pendingOrders),
                          const SizedBox(height: 14),

                          // 4. CLEAN MINI INVENTORY CONTROL BAR
                          _buildCleanInventoryControlBar(
                            totalProducts: totalProducts,
                            categories: dynamicCategories.toList(),
                          ),
                          const SizedBox(height: 10),

                          // 5. PRODUCT CARDS GRID
                          if (_isInventoryExpanded)
                            _buildProductsSquareGrid(filteredProducts)
                          else
                            const SizedBox.shrink(),
                          const SizedBox(height: 18),

                          // 6. BOTTOM SUMMARY PANEL
                          _buildBottomSummaryPanel(
                            totalProducts: totalProducts,
                            pendingOrders: pendingOrders,
                            totalOrders: totalOrders,
                            totalRevenue: totalRevenue,
                          ),
                          const SizedBox(height: 75), // Space for FAB
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
      ),
    );
  }

  // --- 1. TOP HEADER (LOCATION CLICKS OPEN BOTTOM SHEET) ---
  Widget _buildTopHeader({
    required String storeName,
    required String location,
    required String ownerName,
    required String category,
    required bool isOnline,
    required String merchantId,
    required int pendingCount,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Store Name & Clickable Location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _toggleOnlineStatus(merchantId, isOnline),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isOnline ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // CLICKABLE LOCATION ROW (OPENS BOTTOM SHEET)
              InkWell(
                onTap: () => _showLocationEditBottomSheet(context, merchantId, location),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_location_rounded, size: 11, color: primaryBlue),
                            SizedBox(width: 2),
                            Text('Edit', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryBlue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Small Search Icon Button
        IconButton(
          tooltip: 'Search products',
          icon: Icon(
            _isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
            color: _isSearchOpen ? primaryBlue : const Color(0xFF475569),
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isSearchOpen = !_isSearchOpen;
              if (!_isSearchOpen) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),

        // Notifications Icon
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: textDark, size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
            ),
            if (pendingCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$pendingCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),

        // Profile Avatar
        GestureDetector(
          onTap: () => _showProfileMenu(context, ownerName, storeName, location, category, merchantId),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 4),
              ],
            ),
            child: Center(
              child: Text(
                ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'M',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- TOGGLED SEARCH BAR ---
  Widget _buildToggledSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search products by name or brand...',
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  // --- 2. STORE IMAGE CARD ---
  Widget _buildAdjustedStoreImageCard({
    required String merchantId,
    required String storeName,
    required String storeImage,
  }) {
    const double cardWidth = 260;
    const double cardHeight = 145;

    if (storeImage.isNotEmpty) {
      Widget img;
      if (storeImage.startsWith('http')) {
        img = Image.network(
          storeImage,
          width: cardWidth,
          height: cardHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildEmptyTallCard(merchantId, cardWidth, cardHeight),
        );
      } else {
        try {
          img = Image.memory(
            base64Decode(storeImage),
            width: cardWidth,
            height: cardHeight,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildEmptyTallCard(merchantId, cardWidth, cardHeight),
          );
        } catch (_) {
          img = _buildEmptyTallCard(merchantId, cardWidth, cardHeight);
        }
      }

      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              img,
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _pickAndUploadStoreImage(merchantId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'Change',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildEmptyTallCard(merchantId, cardWidth, cardHeight);
  }

  Widget _buildEmptyTallCard(String merchantId, double width, double height) {
    return GestureDetector(
      onTap: () => _pickAndUploadStoreImage(merchantId),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: primaryBlue, size: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              '+ Add store image',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Tap to select from gallery',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. ACTION BUTTONS ---
  Widget _buildActionButtons(BuildContext context, int pendingOrders) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: primaryBlue.withOpacity(0.18), blurRadius: 4),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_rounded, color: primaryPurple, size: 16),
                  const SizedBox(width: 6),
                  const Text('Orders', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (pendingOrders > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(6)),
                      child: Text('$pendingOrders', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. CLEAN MINI INVENTORY CONTROL BAR ---
  Widget _buildCleanInventoryControlBar({
    required int totalProducts,
    required List<String> categories,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Store Inventory Toggle Button
          InkWell(
            onTap: () => setState(() => _isInventoryExpanded = !_isInventoryExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isInventoryExpanded ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isInventoryExpanded ? primaryBlue : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 14,
                    color: _isInventoryExpanded ? Colors.white : primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Store Inventory ($totalProducts)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _isInventoryExpanded ? Colors.white : textDark,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    _isInventoryExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _isInventoryExpanded ? Colors.white : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Small Category Chips
          ...categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = cat),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primaryPurple : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 5. PRODUCTS GRID ---
  Widget _buildProductsSquareGrid(List<QueryDocumentSnapshot> products) {
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardGreenBorder.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            _searchQuery.isNotEmpty ? 'No products matching "$_searchQuery"' : 'No products in inventory',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final doc = products[index];
        final data = doc.data() as Map<String, dynamic>;

        return _highVisibilityProductCard(
          docId: doc.id,
          rawDoc: doc,
          name: data['name'] ?? 'Product',
          brand: data['brand'] ?? '',
          price: data['price'] ?? 0,
          unit: data['unit'] ?? '',
          stock: data['stock'] ?? 0,
          variants: data['variants'] ?? [],
          category: data['category'] ?? '',
          imageBase64: data['imageBase64'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
        );
      },
    );
  }

  // --- PRODUCT CARD WITH EDIT & DELETE BUTTONS ---
  Widget _highVisibilityProductCard({
    required String docId,
    required QueryDocumentSnapshot rawDoc,
    required String name,
    required String brand,
    required dynamic price,
    required String unit,
    required dynamic stock,
    required List<dynamic> variants,
    required String category,
    required String imageBase64,
    required String imageUrl,
  }) {
    final int stockQty = stock is int ? stock : int.tryParse('$stock') ?? 0;
    final bool isOutOfStock = stockQty <= 0;
    final bool isLowStock = stockQty > 0 && stockQty < 100;

    Widget imageWidget;
    if (imageBase64.isNotEmpty) {
      try {
        imageWidget = Image.memory(
          base64Decode(imageBase64),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFE2E8F0),
            child: const Icon(Icons.broken_image, size: 28, color: Colors.grey),
          ),
        );
      } catch (_) {
        imageWidget = Container(
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.broken_image, size: 28, color: Colors.grey),
        );
      }
    } else if (imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.broken_image, size: 28, color: Colors.grey),
        ),
      );
    } else {
      imageWidget = Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Icon(Icons.storefront_rounded, color: Colors.grey, size: 36),
        ),
      );
    }

    Color stockBadgeBg = const Color(0xFF15803D); // Dark Green
    Color stockBadgeText = Colors.white;
    String stockText = 'Stock: $stockQty';

    if (isOutOfStock) {
      stockBadgeBg = const Color(0xFFDC2626); // Red
      stockBadgeText = Colors.white;
      stockText = 'Out of Stock';
    } else if (isLowStock) {
      stockBadgeBg = const Color(0xFFD97706); // Amber/Orange
      stockBadgeText = Colors.white;
      stockText = 'Low: $stockQty left';
    }

    return GestureDetector(
      onTap: () => _editProduct(docId, rawDoc.data() as Map<String, dynamic>),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cardGreenBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.5),
          child: Stack(
            children: [
              // 1. PRODUCT BACKGROUND IMAGE (FULL CARD)
              Positioned.fill(
                child: imageWidget,
              ),

              // 2. BRAND / CATEGORY BADGE ON TOP LEFT
              if (brand.isNotEmpty || category.isNotEmpty)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24, width: 0.6),
                    ),
                    child: Text(
                      brand.isNotEmpty ? brand : category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

              // 3. EDIT & DELETE BUTTONS ON TOP RIGHT
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // EDIT BUTTON
                    GestureDetector(
                      onTap: () => _editProduct(docId, rawDoc.data() as Map<String, dynamic>),
                      child: Container(
                        padding: const EdgeInsets.all(4.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF60A5FA), width: 0.8),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // DELETE BUTTON
                    GestureDetector(
                      onTap: () => _deleteProduct(docId, name),
                      child: Container(
                        padding: const EdgeInsets.all(4.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent.withOpacity(0.8), width: 0.8),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 13,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. DETAILS AT BOTTOM WITH MATCHING GOLD PRODUCT NAME
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.96),
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.50),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.8, 1.0],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name (Matching Warm Gold)
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: productNameGold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Price & Unit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹$price',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                              color: Color(0xFF4ADE80),
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                          ),
                          if (unit.isNotEmpty) ...[
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '/ $unit',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Stock Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: stockBadgeBg,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
                          ],
                        ),
                        child: Text(
                          stockText,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: stockBadgeText,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 6. BOTTOM SUMMARY PANEL ---
  Widget _buildBottomSummaryPanel({
    required int totalProducts,
    required int pendingOrders,
    required int totalOrders,
    required double totalRevenue,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Store Performance Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Live', style: TextStyle(fontSize: 9.5, color: primaryPurple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomStatItem('Total Items', '$totalProducts', Icons.inventory_2_outlined, primaryBlue),
              _buildBottomStatItem('Active Orders', '$pendingOrders', Icons.pending_actions_rounded, Colors.deepOrange),
              _buildBottomStatItem('Total Orders', '$totalOrders', Icons.shopping_bag_outlined, Colors.indigo),
              _buildBottomStatItem('Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee_rounded, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: textDark),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --- PROFILE MENU BOTTOM SHEET ---
  void _showProfileMenu(BuildContext context, String ownerName, String storeName, String location, String category, String merchantId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryBlue,
                    child: Text(
                      ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'M',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                        Text('Owner: $ownerName • $category', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(location, style: const TextStyle(fontSize: 11.5, color: primaryPurple)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 22, color: Color(0xFFF1F5F9)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location_rounded, color: Colors.redAccent),
                title: const Text('Edit / Update Shop Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Live GPS లేదా మాన్యువల్ అడ్రస్ సెట్ చేసుకోండి', style: TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right_rounded, color: primaryBlue),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLocationEditBottomSheet(context, merchantId, location);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_rounded, color: primaryBlue),
                title: const Text('View All Orders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_box_outlined, color: primaryPurple),
                title: const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmLogout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC HELPERS ---
  int _countPending(List<QueryDocumentSnapshot> orders) {
    int count = 0;
    for (final doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'pending' || status == 'placed' || status == 'ordered' || status == 'preparing') {
        count++;
      }
    }
    return count;
  }

  double _sumRevenue(List<QueryDocumentSnapshot> orders) {
    double total = 0.0;
    for (final doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = data['totalAmount'] ?? data['price'];
      if (amount is num) {
        total += amount.toDouble();
      } else if (amount is String) {
        total += double.tryParse(amount) ?? 0.0;
      }
    }
    return total;
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out from Merchant Hub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}