import '../negocio/SessionNegocio.dart';
import '../vista/interfaces/splash_screen_state.dart';

class SplashController {
  final SplashScreenState splashScreenState;
  final SessionNegocio sessionNegocio;

  // Constructor
  SplashController(this.splashScreenState, this.sessionNegocio);
  // Initialize the controller
  void init() {
    print('Initializing SplashController');
    // Check if user is logged in
    checkUserLoggedIn();
  }

  void checkUserLoggedIn() async {
    // Logic to check if user is logged in
    // For example, check if user session exists in the database
    await sessionNegocio.getSession().then((user) {
      print('User session: $user');
      if (user != null) {
        // User is logged in, navigate to home
        splashScreenState.navigateHome();
      } else {
        // User is not logged in, navigate to login
        splashScreenState.navigateToLogin();
      }
    }).catchError((error) {
      // Handle error
      print('Error checking user session: $error');
    });
  }
}
