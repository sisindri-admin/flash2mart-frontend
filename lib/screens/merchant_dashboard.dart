import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'add_product_screen.dart';
import 'orders_screen.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Inventory Dropdown & Dynamic Filters State
  bool _isInventoryExpanded = true;
  String _selectedCategory = 'All';
  String _stockFilter = 'All'; // 'All', 'In Stock', 'Low Stock', 'Out of Stock'
  String _sortBy = 'Default'; // 'Default', 'Price: Low to High', 'Price: High to Low', 'Name: A-Z'

  // Primary Theme Colors (Matching Flash2Mart UI style)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryPurple = Color(0xFF4F46E5);
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

                    // 1. Dynamic Unique Categories Extraction from Products
                    final Set<String> dynamicCategories = {'All'};
                    for (var doc in products) {
                      final data = doc.data() as Map<String, dynamic>;
                      final cat = (data['category'] ?? '').toString().trim();
                      if (cat.isNotEmpty) {
                        dynamicCategories.add(cat);
                      }
                    }

                    // 2. Filter products by search query, category, and Stock Conditions (Out of stock == 0, Low Stock < 100)
                    var filteredProducts = products.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final category = (data['category'] ?? '').toString();
                      final stock = data['stock'] is int
                          ? data['stock']
                          : int.tryParse('${data['stock']}') ?? 0;

                      // Search text filter
                      final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
                          category.toLowerCase().contains(_searchQuery.toLowerCase());
                      if (!matchesSearch) return false;

                      // Category filter
                      if (_selectedCategory != 'All' && category != _selectedCategory) {
                        return false;
                      }

                      // Updated Stock Status Filter Conditions:
                      // In Stock >= 100
                      if (_stockFilter == 'In Stock' && stock < 100) return false;
                      // Low Stock < 100 and > 0
                      if (_stockFilter == 'Low Stock' && (stock <= 0 || stock >= 100)) return false;
                      // Out of Stock == 0
                      if (_stockFilter == 'Out of Stock' && stock > 0) return false;

                      return true;
                    }).toList();

                    // 3. Sorting Filter
                    if (_sortBy == 'Price: Low to High') {
                      filteredProducts.sort((a, b) {
                        final pA = (a.data() as Map<String, dynamic>)['price'] ?? 0;
                        final pB = (b.data() as Map<String, dynamic>)['price'] ?? 0;
                        return (pA as num).compareTo(pB as num);
                      });
                    } else if (_sortBy == 'Price: High to Low') {
                      filteredProducts.sort((a, b) {
                        final pA = (a.data() as Map<String, dynamic>)['price'] ?? 0;
                        final pB = (b.data() as Map<String, dynamic>)['price'] ?? 0;
                        return (pB as num).compareTo(pA as num);
                      });
                    } else if (_sortBy == 'Name: A-Z') {
                      filteredProducts.sort((a, b) {
                        final nA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString();
                        final nB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString();
                        return nA.compareTo(nB);
                      });
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Top Header (Logo + Greeting + Status + Notification)
                          _buildTopHeader(
                            ownerName: ownerName,
                            location: location,
                            pendingCount: pendingOrders,
                            isOnline: isOnline,
                            merchantId: merchantId,
                          ),
                          const SizedBox(height: 16),

                          // 2. Main Search Bar
                          _buildSearchBar(),
                          const SizedBox(height: 16),

                          // 3. Hero Promo Banner
                          _buildHeroBanner(isOnline: isOnline, storeName: storeName),
                          const SizedBox(height: 20),

                          // 4. Action Cards ("What are you looking for?")
                          _buildSectionTitle('What are you looking for?'),
                          const SizedBox(height: 12),
                          _buildMainActionCards(
                            context: context,
                            totalProducts: totalProducts,
                            pendingOrders: pendingOrders,
                            totalRevenue: totalRevenue,
                          ),
                          const SizedBox(height: 22),

                          // 5. Store Overview Metrics
                          _buildMetricsHeader('Store Metrics'),
                          const SizedBox(height: 12),
                          _buildQuickMetricsRow(
                            revenue: totalRevenue,
                            pending: pendingOrders,
                            totalOrders: totalOrders,
                            products: totalProducts,
                          ),
                          const SizedBox(height: 22),

                          // 6. DROPDOWN STORE INVENTORY & DYNAMIC FILTERS SECTION
                          _buildInventoryDropdownCard(
                            totalProducts: totalProducts,
                            filteredCount: filteredProducts.length,
                            categories: dynamicCategories.toList(),
                          ),
                          const SizedBox(height: 12),

                          // 7. Products List (Rendered when expanded)
                          if (_isInventoryExpanded)
                            _buildProductsList(filteredProducts)
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Center(
                                child: Text(
                                  'Tap "Store Inventory" above to expand $totalProducts products',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ),
                            ),

                          const SizedBox(height: 80), // Space for floating button
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

  // --- 1. TOP HEADER ---
  Widget _buildTopHeader({
    required String ownerName,
    required String location,
    required int pendingCount,
    required bool isOnline,
    required String merchantId,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shopping_bag_rounded, color: primaryPurple, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Flash2Mart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _toggleOnlineStatus(merchantId, isOnline),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10,
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
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Hello, $ownerName 👋',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.location_on, size: 12, color: primaryPurple),
                  Flexible(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: textDark),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),
            ),
            if (pendingCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '$pendingCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
          onPressed: () => _confirmLogout(context),
        ),
      ],
    );
  }

  // --- 2. SEARCH BAR ---
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search products, categories...',
          hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : Container(
                  margin: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, color: primaryPurple, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // --- 3. HERO BANNER ---
  Widget _buildHeroBanner({required bool isOnline, required String storeName}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B41C5), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage store & live deliveries faster',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFE0E7FF)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [
                    _bannerPill('⚡ Fast'),
                    _bannerPill('• Reliable'),
                    _bannerPill('• Realtime'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.electric_moped_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- 4. ACTION CARDS ---
  Widget _buildMainActionCards({
    required BuildContext context,
    required int totalProducts,
    required int pendingOrders,
    required double totalRevenue,
  }) {
    return Column(
      children: [
        _actionCard(
          title: 'Products & Stock',
          subtitle: '$totalProducts items in store inventory',
          icon: Icons.inventory_2_rounded,
          iconBgColor: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Live Orders',
          subtitle: pendingOrders > 0 ? '$pendingOrders orders need action' : 'View & manage customer orders',
          icon: Icons.receipt_long_rounded,
          iconBgColor: const Color(0xFF06B6D4),
          badge: pendingOrders > 0 ? '$pendingOrders New' : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Store Revenue',
          subtitle: '₹${totalRevenue.toStringAsFixed(0)} total earnings recorded',
          icon: Icons.account_balance_wallet_rounded,
          iconBgColor: const Color(0xFF3B82F6),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconBgColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          color: textDark,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. METRICS ROW ---
  Widget _buildQuickMetricsRow({
    required double revenue,
    required int pending,
    required int totalOrders,
    required int products,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metricSquircle(
          label: 'Revenue',
          value: '₹${revenue.toStringAsFixed(0)}',
          icon: Icons.currency_rupee_rounded,
          color: Colors.teal,
        ),
        _metricSquircle(
          label: 'Pending',
          value: '$pending',
          icon: Icons.pending_actions_rounded,
          color: Colors.deepOrange,
        ),
        _metricSquircle(
          label: 'Orders',
          value: '$totalOrders',
          icon: Icons.shopping_cart_outlined,
          color: primaryBlue,
        ),
        _metricSquircle(
          label: 'Items',
          value: '$products',
          icon: Icons.category_outlined,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _metricSquircle({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. DROPDOWN STORE INVENTORY CARD & DYNAMIC FILTERS ---
  Widget _buildInventoryDropdownCard({
    required int totalProducts,
    required int filteredCount,
    required List<String> categories,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown Clickable Header
          InkWell(
            onTap: () => setState(() => _isInventoryExpanded = !_isInventoryExpanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Store Inventory',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        Text(
                          'Showing $filteredCount of $totalProducts Total Products',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalProducts Items',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isInventoryExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Filters Bar (Dynamic Categories & Status Filter)
          if (_isInventoryExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header & Horizontal Scrollable Category Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Category:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      // Sort Dropdown
                      PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (val) => setState(() => _sortBy = val),
                        child: Row(
                          children: [
                            const Icon(Icons.sort_rounded, size: 14, color: primaryBlue),
                            const SizedBox(width: 3),
                            Text(
                              _sortBy,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryBlue),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16, color: primaryBlue),
                          ],
                        ),
                        itemBuilder: (ctx) => [
                          'Default',
                          'Price: Low to High',
                          'Price: High to Low',
                          'Name: A-Z',
                        ].map((s) => PopupMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) => setState(() => _selectedCategory = cat),
                            selectedColor: primaryBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(
                              color: isSelected ? primaryBlue : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stock Availability Filters (Out of stock == 0, Low stock < 100, In stock >= 100)
                  Row(
                    children: [
                      const Text(
                        'Stock:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      ...['All', 'In Stock', 'Low Stock', 'Out of Stock'].map((status) {
                        final isSelected = _stockFilter == status;
                        Color statusColor = primaryPurple;
                        if (status == 'In Stock') statusColor = Colors.green;
                        if (status == 'Low Stock') statusColor = Colors.orange;
                        if (status == 'Out of Stock') statusColor = Colors.redAccent;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _stockFilter = status),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? statusColor.withOpacity(0.15) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? statusColor : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? statusColor : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 7. PRODUCTS LIST ---
  Widget _buildProductsList(List<QueryDocumentSnapshot> products) {
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text(
              'No products match the selected filters',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _stockFilter = 'All';
                  _sortBy = 'Default';
                });
              },
              child: const Text('Reset All Filters', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final doc = products[index];
        final data = doc.data() as Map<String, dynamic>;

        return _productCard(
          docId: doc.id,
          name: data['name'] ?? 'Product',
          price: data['price'] ?? 0,
          unit: data['unit'] ?? '',
          stock: data['stock'] ?? 0,
          category: data['category'] ?? '',
          imageBase64: data['imageBase64'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
        );
      },
    );
  }

  Widget _productCard({
    required String docId,
    required String name,
    required dynamic price,
    required String unit,
    required dynamic stock,
    required String category,
    required String imageBase64,
    required String imageUrl,
  }) {
    final int stockQty = stock is int ? stock : int.tryParse('$stock') ?? 0;
    
    // Updated Stock Conditions
    final bool isOutOfStock = stockQty <= 0;
    final bool isLowStock = stockQty > 0 && stockQty < 100;

    Widget imageWidget;
    if (imageBase64.isNotEmpty) {
      try {
        imageWidget = Image.memory(
          base64Decode(imageBase64),
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32, color: Colors.grey),
        );
      } catch (_) {
        imageWidget = const Icon(Icons.broken_image, size: 32, color: Colors.grey);
      }
    } else if (imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl,
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32, color: Colors.grey),
      );
    } else {
      imageWidget = Container(
        width: 68,
        height: 68,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.storefront_rounded, color: Colors.grey, size: 32),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: textDark),
                ),
                if (category.isNotEmpty)
                  Text(category, style: const TextStyle(fontSize: 11.5, color: primaryPurple)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price & Unit Display
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹$price',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: textDark,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '/ $unit',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Stock Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? const Color(0xFFFEE2E2)
                            : isLowStock
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'Out of Stock'
                            : isLowStock
                                ? 'Low Stock: $stockQty'
                                : '$stockQty in stock',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock
                              ? const Color(0xFF991B1B)
                              : isLowStock
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION TITLE HELPERS ---
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: textDark),
    );
  }

  Widget _buildMetricsHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: textDark),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            );
          },
          child: const Row(
            children: [
              Text('View all', style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 16, color: primaryBlue),
            ],
          ),
        ),
      ],
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