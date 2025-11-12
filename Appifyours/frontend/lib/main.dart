import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define PriceUtils class
class PriceUtils {
  static String formatPrice(double price, {String currency = '\$'}) {
    return '$currency\${price.toStringAsFixed(2)}';
  }
  
  // Extract numeric value from price string with any currency symbol
  static double parsePrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    // Remove all currency symbols and non-numeric characters except decimal point
    String numericString = priceString.replaceAll(RegExp(r'[^\\d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  
  // Detect currency symbol from price string
  static String detectCurrency(String priceString) {
    if (priceString.contains('₹')) return '₹';
    if (priceString.contains('\$')) return '\$';
    if (priceString.contains('€')) return '€';
    if (priceString.contains('£')) return '£';
    if (priceString.contains('¥')) return '¥';
    if (priceString.contains('₩')) return '₩';
    if (priceString.contains('₽')) return '₽';
    if (priceString.contains('₦')) return '₦';
    if (priceString.contains('₨')) return '₨';
    return '\$'; // Default to dollar
  }
  
  static double calculateDiscountPrice(double originalPrice, double discountPercentage) {
    return originalPrice * (1 - discountPercentage / 100);
  }
  
  static double calculateTotal(List<double> prices) {
    return prices.fold(0.0, (sum, price) => sum + price);
  }
  
  static double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }
  
  static double applyShipping(double total, double shippingFee, {double freeShippingThreshold = 100.0}) {
    return total >= freeShippingThreshold ? total : total + shippingFee;
  }
}

// Cart item model
class CartItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  int quantity;
  final String? image;
  
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.quantity = 1,
    this.image,
  });
  
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
  double get totalPrice => effectivePrice * quantity;
}

// Cart manager
class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
  
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }
  
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  void updateQuantity(String id, int quantity) {
    final item = _items.firstWhere((i) => i.id == id);
    item.quantity = quantity;
    notifyListeners();
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  double get totalWithTax {
    final tax = PriceUtils.calculateTax(subtotal, 8.0); // 8% tax
    return subtotal + tax;
  }
  
  double get totalDiscount {
    return _items.fold(0.0, (sum, item) => 
      sum + ((item.price - item.effectivePrice) * item.quantity));
  }
  
  double get gstAmount {
    return PriceUtils.calculateTax(subtotal, 18.0); // 18% GST
  }
  
  double get finalTotal {
    return subtotal + gstAmount;
  }
  
  double get finalTotalWithShipping {
    return PriceUtils.applyShipping(totalWithTax, 5.99); // $5.99 shipping
  }
}

// Wishlist item model
class WishlistItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  final String? image;
  
  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.image,
  });
  
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
}

// Wishlist manager
class WishlistManager extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  
  List<WishlistItem> get items => List.unmodifiable(_items);
  
  void addItem(WishlistItem item) {
    if (!_items.any((i) => i.id == item.id)) {
      _items.add(item);
      notifyListeners();
    }
  }
  
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  bool isInWishlist(String id) {
    return _items.any((item) => item.id == id);
  }
}


// Base URL for API calls - Change this to your IP address
const String baseUrl = 'http://192.168.224.5:5000';

// Dynamic product data - will be fetched from MongoDB
List<Map<String, dynamic>> productCards = [];
bool isLoadingProducts = true;

Future<void> fetchProducts() async {
  try {
    final response = await http.get(
      Uri.parse('\$baseUrl/api/products/\$adminObjectId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        productCards = List<Map<String, dynamic>>.from(data['data'] ?? []);
        isLoadingProducts = false;
      }
    }
  } catch (e) {
    print('Error fetching products: $e');
    isLoadingProducts = false;
  }
}


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Generated E-commerce App',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
      appBarTheme: const AppBarTheme(
        elevation: 4,
        shadowColor: Colors.black38,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Colors.grey,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    ),
    home: const SplashScreen(),
    debugShowCheckedModeBanner: false,
  );
}

// Splash Screen - First screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _appName = 'Loading...';
  final String _adminObjectId = '6911f0e70c45b790ce0115d2';

  @override
  void initState() {
    super.initState();
    _fetchAppNameAndNavigate();
  }

  Future<void> _fetchAppNameAndNavigate() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/app-config/$_adminObjectId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _appName = data['data']?['appName'] ?? data['data']?['shopName'] ?? 'AppifyYours';
          });
        }
      }
    } catch (e) {
      print('Error fetching app name: $e');
      if (mounted) {
        setState(() {
          _appName = 'AppifyYours';
        });
      }
    }
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage(adminObjectId: _adminObjectId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.shopping_bag,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                _appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Colors.white),
              const Spacer(),
              const Text(
                'Powered by AppifyYours',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Sign In Page - Second screen
class SignInPage extends StatefulWidget {
  final String adminObjectId;
  
  const SignInPage({super.key, required this.adminObjectId});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'adminObjectId': widget.adminObjectId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage(adminObjectId: widget.adminObjectId)),
            );
          }
        } else {
          throw Exception(data['error'] ?? 'Sign in failed');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Invalid credentials');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.shopping_bag,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign In', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAccountPage(adminObjectId: widget.adminObjectId),
                    ),
                  );
                },
                child: const Text('Create Your Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create Account Page - Third screen
class CreateAccountPage extends StatefulWidget {
  final String adminObjectId;
  
  const CreateAccountPage({super.key, required this.adminObjectId});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[w-.]+@([w-]+.)+[w-]{2,4}$').hasMatch(email);
  }

  bool _validatePhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> _createAccount() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!_validateEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (!_validatePhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    if (!_validatePassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'adminObjectId': widget.adminObjectId,
          'countryCode': '+91',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully! Please sign in.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception(data['error'] ?? 'Failed to create account');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create account');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Join Us Today',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '10 digit number',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email ID',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Account', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String adminObjectId;
  
  const HomePage({super.key, required this.adminObjectId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  final CartManager _cartManager = CartManager();
  final WishlistManager _wishlistManager = WishlistManager();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _filteredProducts = List.from(productCards);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPageIndex = index);

  void _onItemTapped(int index) {
    setState(() => _currentPageIndex = index);
    _pageController.jumpToPage(index);
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(productCards);
      } else {
        _filteredProducts = productCards.where((product) {
          final productName = (product['productName'] ?? '').toString().toLowerCase();
          final price = (product['price'] ?? '').toString().toLowerCase();
          final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return productName.contains(searchLower) || price.contains(searchLower) || discountPrice.contains(searchLower);
        }).toList();
      }
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'person':
        return Icons.person;
      default:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _currentPageIndex,
      children: [
        _buildHomePage(),
        _buildCartPage(),
        _buildWishlistPage(),
        _buildProfilePage(),
      ],
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );

  Widget _buildHomePage() {
    return Column(
      children: [
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                                                Container(
                          width: 32,
                          height: 32,
                          child: Image.memory(
                                base64Decode('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'),
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.store, size: 32, color: Colors.white),
                              ),
                        ),
                        
                        const SizedBox(width: 8),
                        Text(
                          'priya',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Stack(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                            if (_cartManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_cartManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          children: [
                            const Icon(Icons.favorite, color: Colors.white, size: 20),
                            if (_wishlistManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_wishlistManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                  Container(
                    height: 160,
                    child: Stack(
                      children: [
                        Container(color: Color(0xFFBDBDBD)),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome to Our Store!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black,
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('Shop Now', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                            enableInfiniteScroll: true,
                            viewportFraction: 0.8,
                            enlargeFactor: 0.3,
                          ),
                          items: [
                            Builder(
                              builder: (BuildContext context) => Container(
                                width: 300,
                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                                                const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6.0, height: 6.0, margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.4))),
                          ],
                        ),
                        
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: _cartManager,
        builder: (context, child) {
          return _cartManager.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.items[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: item.image != null && item.image!.isNotEmpty
                                    ? (item.image!.startsWith('data:image/')
                                    ? Image.memory(
                                  base64Decode(item.image!.split(',')[1]),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                )
                                    : Image.network(
                                  item.image!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                ))
                                    : const Icon(Icons.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    // Show current price (effective price)
                                    Text(
                                      PriceUtils.formatPrice(item.effectivePrice),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    // Show original price if there's a discount
                                    if (item.discountPrice > 0 && item.price != item.discountPrice)
                                      Text(
                                        PriceUtils.formatPrice(item.price),
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        _cartManager.updateQuantity(item.id, item.quantity - 1);
                                      } else {
                                        _cartManager.removeItem(item.id);
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    onPressed: () {
                                      _cartManager.updateQuantity(item.id, item.quantity + 1);
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bill Summary Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(PriceUtils.formatPrice(_cartManager.subtotal), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (_cartManager.totalDiscount > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text('-$0.00', style: const TextStyle(fontSize: 14, color: Colors.green)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GST (18%)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(PriceUtils.formatPrice(_cartManager.gstAmount), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Divider(thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text(PriceUtils.formatPrice(_cartManager.finalTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
        },
      ),
    );
  }

  Widget _buildWishlistPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        automaticallyImplyLeading: false,
      ),
      body: _wishlistManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your wishlist is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _wishlistManager.items.length,
              itemBuilder: (context, index) {
                final item = _wishlistManager.items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: item.image != null && item.image!.isNotEmpty
                          ? (item.image!.startsWith('data:image/')
                          ? Image.memory(
                        base64Decode(item.image!.split(',')[1]),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      )
                          : Image.network(
                        item.image!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      ))
                          : const Icon(Icons.image),
                    ),
                    title: Text(item.name),
                    subtitle: Text(PriceUtils.formatPrice(item.effectivePrice)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final cartItem = CartItem(
                              id: item.id,
                              name: item.name,
                              price: item.price,
                              discountPrice: item.discountPrice,
                              image: item.image,
                            );
                            _cartManager.addItem(cartItem);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                        ),
                        IconButton(
                          onPressed: () {
                            _wishlistManager.removeItem(item.id);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfilePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(250, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Refund button action
                    },
                    child: const Text(
                      'Refund',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Log out and navigate to sign in page
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignInPage(adminObjectId: '6911f0e70c45b790ce0115d2'),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_cartManager.items.length}'),
            isLabelVisible: _cartManager.items.length > 0,
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_wishlistManager.items.length}'),
            isLabelVisible: _wishlistManager.items.length > 0,
            child: const Icon(Icons.favorite),
          ),
          label: 'Wishlist',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

}
