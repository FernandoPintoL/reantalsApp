import 'package:flutter/material.dart';
import 'package:rentals/controller/SplashController.dart';
import 'package:rentals/negocio/SessionNegocio.dart';
import 'interfaces/splash_screen_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> implements SplashScreenState {
  late SessionNegocio sessionNegocio;
  late SplashController splashController;
  @override
  void initState() {
    super.initState();
    sessionNegocio = SessionNegocio();
    splashController = SplashController(this, sessionNegocio);
    splashController.init();
  }

  Future<void> navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds

    if (!mounted) return;

    // Always navigate to login screen for now
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> navigateHome() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds

    if (!mounted) return;

    // Always navigate to login screen for now
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Icon(
              Icons.home,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            // App name
            const Text(
              'Propiedades para alquiler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              'Encuentra tu hogar perfecto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 50),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
