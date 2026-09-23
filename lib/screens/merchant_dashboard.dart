import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/permission_service.dart';
import '../widgets/new_order_popup_sheet.dart';
import '../widgets/store_location_sheet.dart';
import '../widgets/dashboard/product_card_widget.dart';
import '../widgets/dashboard/summary_panel_widget.dart';
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

  // Stream Subscription & Order Popup Control
  StreamSubscription<QuerySnapshot>? _orderSubscription;
  bool _isPopupShowing = false;

  // Theme Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryPurple = Color(0xFF4F46E5);
  static const Color cardGreenBorder = Color(0xFF16A34A);
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _listenForNewOrders();
    _saveMerchantFcmToken();

    // Foreground Task & Notification Permission check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OverlayPermissionHandler.checkAndRequestOverlayPermission(context);
    });
  }

  // 🚀 FCM Device Token saved to Firestore
  Future<void> _saveMerchantFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('merchants')
            .doc(user.uid)
            .set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("FCM Token saved successfully: $token");
      }
    } catch (e) {
      debugPrint("Error saving FCM Token: $e");
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- REALTIME NEW ORDERS LISTENER ---
  void _listenForNewOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('merchantId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final orderData = change.doc.data() as Map<String, dynamic>?;
          if (orderData == null) continue;

          final String rawStatus = (orderData['orderStatus'] ?? orderData['status'] ?? '').toString();
          final String status = rawStatus.trim().toLowerCase();

          if ((status == 'pending' || status == 'placed' || status == 'ordered') && !_isPopupShowing) {
            
            // 🚀 Trigger Notification & Ringtone sound with High Priority
            OverlayPermissionHandler.triggerOrderSoundNotification(
              change.doc.id,
              orderData['customerName'] ?? orderData['userName'] ?? 'Customer',
            );

            // Show Modal Sheet inside App UI if foreground
            _showNewOrderBottomSheet(change.doc.id, orderData);
          }
        }
      }
    });
  }

  void _showNewOrderBottomSheet(String orderId, Map<String, dynamic> orderData) {
    if (!mounted || _isPopupShowing) return;

    setState(() {
      _isPopupShowing = true;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewOrderPopupSheet(
        orderId: orderId,
        orderData: orderData,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isPopupShowing = false;
        });
      }
    });
  }

  // --- LOCATION BOTTOM SHEET ---
  void _showLocationEditBottomSheet(BuildContext context, String merchantId, String currentSavedLocation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StoreLocationSheet(
        merchantId: merchantId,
        currentSavedLocation: currentSavedLocation,
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

  Future<void> _toggleOnlineStatus(String merchantId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(merchantId)
          .set({
        'isOnline': !currentStatus,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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

                    final Set<String> dynamicCategories = {'All'};
                    for (var doc in products) {
                      final data = doc.data() as Map<String, dynamic>;
                      final cat = (data['category'] ?? '').toString().trim();
                      if (cat.isNotEmpty) {
                        dynamicCategories.add(cat);
                      }
                    }

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

                          if (_isSearchOpen) ...[
                            _buildToggledSearchBar(),
                            const SizedBox(height: 10),
                          ],

                          Center(
                            child: _buildAdjustedStoreImageCard(
                              merchantId: merchantId,
                              storeName: storeName,
                              storeImage: storeImage,
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildActionButtons(context, pendingOrders),
                          const SizedBox(height: 14),

                          _buildCleanInventoryControlBar(
                            totalProducts: totalProducts,
                            categories: dynamicCategories.toList(),
                          ),
                          const SizedBox(height: 10),

                          if (_isInventoryExpanded)
                            _buildProductsSquareGrid(filteredProducts)
                          else
                            const SizedBox.shrink(),
                          const SizedBox(height: 18),

                          SummaryPanelWidget(
                            totalProducts: totalProducts,
                            pendingOrders: pendingOrders,
                            totalOrders: totalOrders,
                            totalRevenue: totalRevenue,
                          ),
                          const SizedBox(height: 75),
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

  Widget _buildCleanInventoryControlBar({
    required int totalProducts,
    required List<String> categories,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
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

        return ProductCardWidget(
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
          onEdit: _editProduct,
          onDelete: _deleteProduct,
        );
      },
    );
  }

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
                leading: const Icon(Icons.layers_rounded, color: primaryBlue),
                title: const Text('Display Over Other Apps Permission', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Enable for background order alerts', style: TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right_rounded, color: primaryBlue),
                onTap: () {
                  Navigator.pop(ctx);
                  OverlayPermissionHandler.checkAndRequestOverlayPermission(context);
                },
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location_rounded, color: Colors.redAccent),
                title: const Text('Edit / Update Shop Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Set live GPS or custom address', style: TextStyle(fontSize: 11, color: Colors.grey)),
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

  int _countPending(List<QueryDocumentSnapshot> orders) {
    int count = 0;
    for (final doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['orderStatus'] ?? data['status'] ?? '').toString().toLowerCase();
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
      final amount = data['grandTotal'] ?? data['totalAmount'] ?? data['price'];
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