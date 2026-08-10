import 'package:flutter/material.dart';
import 'delivery_login_screen.dart'; // డెలివరీ లాగిన్ స్క్రీన్ ఇంపార్ట్

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> roles = [
      {
        'title': 'Customer',
        'subtitle': 'షాపింగ్ & ఆర్డర్స్',
        'image': 'assets/images/customer role icon.png',
        'primaryColor': Colors.blue.shade700,
        'gradient': [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.5)],
        'shadowColor': Colors.blue.withOpacity(0.2),
      },
      {
        'title': 'Retailer',
        'subtitle': 'షాప్ మేనేజ్‌మెంట్',
        'image': 'assets/images/retailer role icon.png',
        'primaryColor': Colors.purple.shade700,
        'gradient': [Colors.purple.shade50, Colors.purple.shade100.withOpacity(0.5)],
        'shadowColor': Colors.purple.withOpacity(0.2),
      },
      {
        'title': 'Delivery Partner',
        'subtitle': 'ఆర్డర్ డెలివరీ',
        'image': 'assets/images/delevery partner role icon.png',
        'primaryColor': Colors.teal.shade700,
        'gradient': [Colors.teal.shade50, Colors.teal.shade100.withOpacity(0.5)],
        'shadowColor': Colors.teal.withOpacity(0.2),
      },
      {
        'title': 'Flash Rider',
        'subtitle': 'అతివేగ డెలివరీ',
        'image': 'assets/images/flashrider role icon.png',
        'primaryColor': Colors.orange.shade800,
        'gradient': [Colors.orange.shade50, Colors.orange.shade100.withOpacity(0.5)],
        'shadowColor': Colors.orange.withOpacity(0.2),
      },
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF1F5F9),
              Colors.blue.shade50.withOpacity(0.3),
              const Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // === TOP FLASH2MART HEADER CARD ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade500, Colors.deepOrange.shade600],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flash2Mart',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'స్పీడ్ & స్మార్ట్ డెలివరీ ఎకోసిస్టమ్',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // === TITLE SECTION ===
                const Text(
                  'మీ పాత్రను ఎంచుకోండి',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'మీ ప్రొఫైల్ రకాన్ని సెలెక్ట్ చేయండి.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 25),

                // === ROLE CARDS GRID ===
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: roles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.92,
                    ),
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      return _buildRoleCard(
                        context,
                        title: role['title'],
                        subtitle: role['subtitle'],
                        imagePath: role['image'],
                        primaryColor: role['primaryColor'],
                        gradientColors: role['gradient'],
                        shadowColor: role['shadowColor'],
                        index: index,
                      );
                    },
                  ),
                ),
                
                // === FOOTER ===
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Powered by Flash2Mart Ecosystem',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- INDIVIDUAL ROLE CARD DESIGN ---
  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imagePath,
    required Color primaryColor,
    required List<Color> gradientColors,
    required Color shadowColor,
    required int index,
  }) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => _navigateToLogin(context, title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryColor.withOpacity(isHovered ? 0.4 : 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: isHovered ? 15 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, size: 50, color: primaryColor);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String roleName) {
    if (roleName == 'Delivery Partner') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeliveryLoginScreen()),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$roleName ఎంచుకోబడింది',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'లాగిన్ మరియు సైన్-అప్ స్క్రీన్ త్వరలో వస్తుంది!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }
}