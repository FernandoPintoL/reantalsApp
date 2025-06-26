import 'package:rentals/models/session_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../services/ApiService.dart';
import '../utils/HandlerDateTime.dart';
import 'SessionNegocio.dart';
import 'UserNegocio.dart';

class AuthenticatedNegocio {
  final ApiService apiService;
  final SessionNegocio sessionNegocio = SessionNegocio();
  final UserNegocio userNegocio = UserNegocio();

  AuthenticatedNegocio({ApiService? apiService}) : this.apiService = apiService ?? ApiService.getInstance();

  // iniciar sesión de usuario
  Future<SessionModelo?> initSession(UserModel user) async {
    UserModel? existingUser = await userNegocio.getUser(user.id);
    if(existingUser != null) {
      // Si el usuario ya existe, no lo insertamos de nuevo
      return await sessionNegocio.getSession();
    }
    int resultUser = await userNegocio.insertUser(user);
    SessionModelo session = SessionModelo(
      id: user.id,
      userId: user.id,
      status: 'active',
      createdAt: HandlerDateTime.getDateTimeNow(),
      updatedAt: HandlerDateTime.getDateTimeNow(),
    );
    int resultSession = await sessionNegocio.createSession(session);
    return resultSession > 0 && resultUser > 0 ? session : null;
  }

  Future<SessionModelo?> getSession() async {
    return await sessionNegocio.getSession();
  }

  Future<UserModel?> getUserSession() async {
    SessionModelo? session = await sessionNegocio.getSession();
    if (session != null) {
      return await userNegocio.getUser(session.userId!);
    }
    return null;
  }

  // Obtener el usuario autenticado desde una API
  Future<ResponseModel> login(String email, String password) async {
    final String endpoint = 'login';
    final Map<String, dynamic> body = {'email': email, 'password': password};
    try {
      ResponseModel response = await apiService.post(endpoint, body);
      UserModel user = UserModel.mapToModel(response.data);
      SessionModelo? session = await initSession(user);
      return ResponseModel(
        isSuccess: session != null && response.isSuccess,
        isRequest: response.isRequest,
        isMessageError: session != null && response.isMessageError,
        statusCode: response.statusCode,
        message: session != null ? response.message : "Error al iniciar sesión",
        messageError: session != null ? response.messageError : "No se pudo crear la sesión",
        data: user.toMap(), // Retornamos la sesión iniciada
      );
    } catch (e) {
      // Manejar la excepción
      print("Error al realizar la solicitud: $e");
      return ResponseModel(
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        statusCode: 500,
        message: 'Error al realizar la solicitud',
        messageError: e.toString(),
        data: null,
      );
    }
  }

  // Cerrar sesión de usuario
  Future<ResponseModel> logout(int userId) async {
    final String endpoint = 'logout';
    try {
      ResponseModel response = await apiService.post(endpoint, {});
      if (response.isSuccess) {
        bool resultSession = await sessionNegocio.deleteSession(userId);
        bool resultUser = await userNegocio.deleteUser(userId.toString());
        return ResponseModel(
          isSuccess: resultSession && resultUser,
          isRequest: response.isRequest,
          isMessageError: response.isMessageError,
          statusCode: response.statusCode,
          message: response.message,
          messageError: response.messageError,
          data: null, // No hay datos que retornar en este caso
        );
      } else {
        return ResponseModel(
          isSuccess: false,
          isRequest: response.isRequest,
          isMessageError: true,
          statusCode: response.statusCode,
          message: 'Error al cerrar sesión',
          messageError: response.messageError,
          data: null,
        );
      }
    } catch (e) {
      // Manejar la excepción
      print("Error al realizar la solicitud de cierre de sesión: $e");
      return ResponseModel(
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        statusCode: 500,
        message: 'Error al realizar la solicitud de cierre de sesión',
        messageError: e.toString(),
        data: null,
      );
    }
  }

  Future<ResponseModel> createUser(UserModel user,String password, String passwordConfirmation) async {
    final String endpoint = 'create/user';
    final Map<String, dynamic> body = user.toMap();
    body['password'] = password;
    body['password_confirmation'] = passwordConfirmation;
    print("Cuerpo de la solicitud: $body");
    try {
      ResponseModel response = await apiService.post(endpoint, body);
      UserModel user = UserModel.mapToModel(response.data);
      SessionModelo? session = await initSession(user);
      return ResponseModel(
        isSuccess: session != null && response.isSuccess,
        isRequest: response.isRequest,
        isMessageError: session != null && response.isMessageError,
        statusCode: response.statusCode,
        message: session != null ? response.message : "Error al iniciar sesión",
        messageError: session != null ? response.messageError : "No se pudo crear la sesión",
        data: user.toMap(), // Retornamos la sesión iniciada
      );
    } catch (e) {
      // Manejar la excepción
      print("Error al realizar la solicitud: $e");
      return ResponseModel(
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        statusCode: 500,
        message: 'Error al realizar la solicitud',
        messageError: e.toString(),
        data: null,
      );
    }
  }

  // Actualizar perfil de usuario
  Future<ResponseModel> updateUserProfile(UserModel user) async {
    final String endpoint = 'users/${user.id}';
    print("Cuerpo de la solicitud de actualización: ${user.toMap()}");
    try {
      ResponseModel response = await apiService.put(endpoint, user.toMap());
      print("Respuesta de la API: ${response.data}");
      if (response.isSuccess) {
        // Actualizar el usuario en la sesión local
        UserModel updatedUser = UserModel.mapToModel(response.data);
        await userNegocio.updateUser(updatedUser);
        return ResponseModel(
          isSuccess: true,
          isRequest: response.isRequest,
          isMessageError: response.isMessageError,
          statusCode: response.statusCode,
          message: "Perfil actualizado correctamente",
          messageError: response.messageError,
          data: updatedUser.toMap(),
        );
      } else {
        return ResponseModel(
          isSuccess: false,
          isRequest: response.isRequest,
          isMessageError: true,
          statusCode: response.statusCode,
          message: "Error al actualizar el perfil",
          messageError: response.messageError,
          data: null,
        );
      }
    } catch (e) {
      // Manejar la excepción
      print("Error al realizar la solicitud de actualización de perfil: $e");
      return ResponseModel(
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        statusCode: 500,
        message: 'Error al realizar la solicitud de actualización de perfil',
        messageError: e.toString(),
        data: null,
      );
    }
  }

  // getUser
  Future<ResponseModel> getUser(int id) async {
    try{
      final String endpoint = 'users/$id';
      ResponseModel response = await apiService.get(endpoint);
      if (response.isSuccess) {
        UserModel user = UserModel.mapToModel(response.data);
        return ResponseModel(
          isSuccess: true,
          isRequest: response.isRequest,
          isMessageError: response.isMessageError,
          statusCode: response.statusCode,
          message: "Usuario obtenido correctamente",
          messageError: response.messageError,
          data: user.toMap(),
        );
      } else {
        return ResponseModel(
          isSuccess: false,
          isRequest: response.isRequest,
          isMessageError: true,
          statusCode: response.statusCode,
          message: "Error al obtener el usuario",
          messageError: response.messageError,
          data: null,
        );
      }
    }catch (e) {
      // Manejar la excepción
      print("Error al realizar la solicitud de obtención de usuario: $e");
      return ResponseModel(
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        statusCode: 500,
        message: 'Error al realizar la solicitud de obtención de usuario',
        messageError: e.toString(),
        data: null,
      );
    }
  }
}
