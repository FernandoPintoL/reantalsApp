import '../models/response_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../negocio/AuthenticatedNegocio.dart';
import '../negocio/SessionNegocio.dart';
import '../negocio/UserNegocio.dart';
import '../providers/authenticated_provider.dart';
import '../utils/HandlerDateTime.dart';

class AuthenticatedController {
  late AuthenticatedProvider authenticatedProvider;
  late AuthenticatedNegocio authenticatedNegocio;
  late SessionNegocio sessionNegocio;
  late UserNegocio userNegocio;

  AuthenticatedController(AuthenticatedProvider provider, AuthenticatedNegocio negocio) {
    authenticatedProvider = provider;
    authenticatedNegocio = negocio;
    sessionNegocio = SessionNegocio();
    userNegocio = UserNegocio();
  }

  Future<SessionModelo?> getSession() async {
    try {
      // Call the business logic layer to get session
      SessionModelo? response = await sessionNegocio.getSession();
      return response;
    } catch (e) {
      print('Error in controller getSession: $e');
      return null;
    }
  }

  Future<ResponseModel> login(String email, String password) async {
    try {
      // Call the business logic layer to perform login
      ResponseModel response = await authenticatedNegocio.login(
        email,
        password,
      );

      // If login is successful, navigate to home screen
      if (response.statusCode >= 200 && response.statusCode <= 300) {
        UserModel user = UserModel.mapToModel(response.data['user']);
        int register = await userNegocio.insertUser(user);
        if (register > 0) {
          print('User registered successfully');
          // Save the session
          SessionModelo session = SessionModelo(
            id: user.id,
            userId: user.id,
            status: "active",
            createdAt: HandlerDateTime.getDateTimeNow(),
            updatedAt: HandlerDateTime.getDateTimeNow(),
          );
          int sessionRegister = await sessionNegocio.createSession(session);
          return ResponseModel(
            isSuccess: true,
            isRequest: true,
            isMessageError: false,
            statusCode: 200,
            data: {
              'user': user,
              'session': session,
            },
            message: 'Login successful',
            messageError: '',
          );
        } else {
          print('Error registering user');
          return ResponseModel(
            isSuccess: false,
            isRequest: true,
            isMessageError: true,
            statusCode: 500,
            data: null,
            message: 'Error registering user',
            messageError: 'Failed to register user in the database',
          );
        }
      }
      return response;
    } catch (e) {
      print('Error in controller login: $e');
      return ResponseModel(
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        statusCode: 500,
        data: null,
        message: 'Login failed',
        messageError: e.toString(),
      );
    }
  }
}
