import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';

class MerchantAuthScreen extends StatefulWidget {
  const MerchantAuthScreen({super.key});

  @override
  State<MerchantAuthScreen> createState() => _MerchantAuthScreenState();
}

class _MerchantAuthScreenState extends State<MerchantAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'Grocery / Supermarket';

  final List<String> categories = [
    'Grocery / Supermarket',
    'Food / Restaurant',
    'Pharmacy / Medical',
    'Electronics Store',
    'AC / Home Services',
    'Delivery Partner',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeaderLogo(),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textDark,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Merchant Login'),
                  Tab(text: 'Register Business'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildRegisterTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLogo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.darkBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Flash', style: TextStyle(color: Colors.blue)),
                  TextSpan(text: '2', style: TextStyle(color: Colors.red)),
                  TextSpan(text: 'Mart ', style: TextStyle(color: Colors.black)),
                  TextSpan(
                    text: 'Partner',
                    style: TextStyle(color: AppColors.primary, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage your business & services easily',
          style: TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CustomTextField(
            label: 'Registered Mobile / Email',
            hint: 'Enter mobile number or email',
            icon: Icons.person_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Password',
            hint: 'Enter password',
            icon: Icons.lock_outline,
            isPassword: true,
            suffixIcon: Icon(Icons.visibility_off, color: AppColors.textGrey),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'LOGIN TO PARTNER PORTAL',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomTextField(
            label: 'Business / Store Name',
            hint: 'e.g., Prakash Supermarket',
            icon: Icons.store_outlined,
          ),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Owner Name',
            hint: 'Enter owner full name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Mobile Number',
            hint: '10 digit mobile number',
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'REGISTER AS PARTNER',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            backgroundColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}
