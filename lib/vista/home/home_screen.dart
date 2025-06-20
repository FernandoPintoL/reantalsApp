import 'package:flutter/material.dart';
import '../../models/user_model.dart';

// This is a temporary fix to avoid Provider-related errors
// Remove this when Firebase is properly initialized
class Provider {
  static T of<T>(BuildContext context, {bool listen = true}) {
    throw UnimplementedError('Provider is temporarily disabled');
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Temporarily using mock data instead of fetching from Firebase
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a delay to show loading indicator
    await Future.delayed(const Duration(seconds: 1));

    // Create a mock user model
    final mockUserModel = UserModel(
      id: 0,
      email: 'user@example.com',
      name: 'Demo User',
      photoPath: null,
      tipoUsuario: "Cliente", // Set to true to see owner screens
    );

    setState(() {
      _userModel = mockUserModel;
      _isLoading = false;
    });

    // Original code commented out
    /*
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userModel = await authService.getUserProfile();

      setState(() {
        _userModel = userModel;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
    */
  }

  // Temporarily bypassing Firebase signOut
  Future<void> _signOut() async {
    // Simply navigate to login screen without actual sign out
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');

    // Original code commented out
    /*
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user data failed to load
    if (_userModel == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load user data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Determine which screens to show based on user type
    final List<Widget> _screens = _userModel!.tipoUsuario == "Propietario"
        ? [
            _buildOwnerDashboard(),
            _buildMyProperties(),
            _buildAppointments(),
            _buildContracts(),
            _buildProfile(),
          ]
        : [
            _buildRenterDashboard(),
            _buildExploreProperties(),
            _buildAppointments(),
            _buildContracts(),
            _buildProfile(),
          ];

    final List<BottomNavigationBarItem> _navItems = _userModel!.tipoUsuario == "Propietario"
        ? [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'My Properties',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Contracts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ]
        : [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Explore',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Contracts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_currentIndex].label!),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }

  // Owner screens
  Widget _buildOwnerDashboard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 100, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Welcome, ${_userModel!.name}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This is your property owner dashboard',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          // TODO: Add dashboard widgets for property owners
          const Text('Coming soon: Property statistics and management tools'),
        ],
      ),
    );
  }

  Widget _buildMyProperties() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home, size: 100, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'My Properties',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to add property screen
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Property'),
          ),
          const SizedBox(height: 16),
          // TODO: Add list of owner's properties
          const Text('Coming soon: List of your properties'),
        ],
      ),
    );
  }

  // Renter screens
  Widget _buildRenterDashboard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 100, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Welcome, ${_userModel!.name}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find your perfect rental property',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          // TODO: Add dashboard widgets for renters
          const Text('Coming soon: Recommended properties and saved searches'),
        ],
      ),
    );
  }

  Widget _buildExploreProperties() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 100, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Explore Properties',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          // TODO: Add property search and filtering
          const Text('Coming soon: Property search and filtering'),
        ],
      ),
    );
  }

  // Common screens
  Widget _buildAppointments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 100, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Appointments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          // TODO: Add appointments list
          const Text('Coming soon: Your scheduled appointments'),
        ],
      ),
    );
  }

  Widget _buildContracts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, size: 100, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Contracts',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Secured by blockchain technology',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          // TODO: Add contracts list
          const Text('Coming soon: Your rental contracts'),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade300,
            child: Text(
              _userModel!.name.isNotEmpty ? _userModel!.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userModel!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _userModel!.email,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _userModel!.tipoUsuario == "Propietario" ? 'Property Owner' : 'Renter',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to edit profile screen
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
}
