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

  // Form Keys (ఫారమ్ వ్యాలిడేషన్ కోసం)
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Password ను దాచడానికి / చూపించడానికి పారామితులు
  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;

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
    if (!_loginFormKey.currentState!.validate()) return;

    final phone = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text.trim();

    setState(() => isLoading = true);
    try {
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
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage('ఎర్రర్ వచ్చింది: ${e.toString()}');
    }
  }

  // Handle Merchant Registration
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final storeName = _storeNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final location = _locationController.text.trim();
    final password = _regPasswordController.text.trim();

    setState(() => isLoading = true);
    try {
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
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage('ఎర్రర్ వచ్చింది: ${e.toString()}');
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
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'లాగిన్'),
                        Tab(text: 'రిజిస్టర్'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginForm(),
                        _buildRegisterForm(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Header Logo UI
  Widget _buildHeaderLogo() {
    return Column(
      children: const [
        Icon(Icons.storefront_rounded, size: 60, color: Colors.indigo),
        SizedBox(height: 8),
        Text(
          'మర్చంట్ పోర్టల్',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Login UI Form
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _loginPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'ఫోన్ నెంబర్',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'ఫోన్ నెంబర్ ఎంటర్ చేయండి' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              decoration: InputDecoration(
                labelText: 'పాస్‌వర్డ్',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureLoginPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureLoginPassword = !_obscureLoginPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'పాస్‌వర్డ్ ఎంటర్ చేయండి' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('లాగిన్ అవ్వండి',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Register UI Form
  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'స్టోర్ పేరు',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'స్టోర్ పేరు ఎంటర్ చేయండి' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'ఓనర్ పేరు',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'ఓనర్ పేరు ఎంటర్ చేయండి' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'ఫోన్ నెంబర్',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'ఫోన్ నెంబర్ ఎంటర్ చేయండి' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'కేటగిరీ',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'లొకేషన్ / అడ్రస్',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'లొకేషన్ ఎంటర్ చేయండి' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regPasswordController,
              obscureText: _obscureRegPassword,
              decoration: InputDecoration(
                labelText: 'పాస్‌వర్డ్',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureRegPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureRegPassword = !_obscureRegPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'పాస్‌వర్డ్ ఎంటర్ చేయండి' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('రిజిస్టర్ చేసుకోండి',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}                      ),
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
