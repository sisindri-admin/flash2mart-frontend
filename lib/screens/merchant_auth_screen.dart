import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

class MerchantAuthScreen extends StatefulWidget {
  const MerchantAuthScreen({super.key});

  @override
  State<MerchantAuthScreen> createState() => _MerchantAuthScreenState();
}

class _MerchantAuthScreenState extends State<MerchantAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;

  // Login Controllers
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Register Controllers
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();

  String selectedCategory = 'Grocery / Supermarket';
  final List<String> categories = [
    'Grocery / Supermarket',
    'Food / Restaurant',
    'Pharmacy / Medical',
    'Electronics Store',
    'AC / Home Services',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _regPhoneController.dispose();
    _locationController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  // Handle Merchant Login
  Future<void> _handleLogin() async {
    final phone = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showMessage('దయచేసి అన్ని వివరాలు ఎంటర్ చేయండి.');
      return;
    }

    setState(() => isLoading = true);
    final response = await ApiService.merchantLogin(phone, password);
    setState(() => isLoading = false);

    if (response['success'] == true) {
      if (mounted) {
        _showMessage('లాగిన్ సక్సెస్ అయింది!');
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      _showMessage(response['message'] ?? 'లాగిన్ ఫెయిల్ అయింది');
    }
  }

  // Handle Merchant Registration
  Future<void> _handleRegister() async {
    final storeName = _storeNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final location = _locationController.text.trim();
    final password = _regPasswordController.text.trim();

    if (storeName.isEmpty || ownerName.isEmpty || phone.isEmpty || location.isEmpty || password.isEmpty) {
      _showMessage('దయచేసి అన్ని వివరాలు ఎంటర్ చేయండి.');
      return;
    }

    setState(() => isLoading = true);
    final response = await ApiService.merchantRegister(
      storeName: storeName,
      ownerName: ownerName,
      phone: phone,
      category: selectedCategory,
      location: location,
      password: password,
    );
    setState(() => isLoading = false);

    if (response['success'] == true) {
      if (mounted) {
        _showMessage('రిజిస్ట్రేషన్ పూర్తయింది! ఇప్పుడు లాగిన్ చేయండి.');
        _tabController.animateTo(0);
      }
    } else {
      _showMessage(response['message'] ?? 'రిజిస్ట్రేషన్ ఫెయిల్ అయింది');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
      ],
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _loginPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _storeNameController,
            decoration: const InputDecoration(
              labelText: 'Business / Store Name',
              prefixIcon: Icon(Icons.store),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerNameController,
            decoration: const InputDecoration(
              labelText: 'Owner Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            items: categories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) => setState(() => selectedCategory = val!),
            decoration: const InputDecoration(
              labelText: 'Business Category',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'City / Location',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleRegister,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: const Text('REGISTER BUSINESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}