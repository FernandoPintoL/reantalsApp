import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/response_model.dart';

class ResponseHandler {

  static ResponseModel processResponse(http.Response response) {
    final dynamic body = jsonDecode(response.body);
    final int statusCode = response.statusCode;
    final String? message = body['message'];
    final dynamic messageError = body['messageError'];
    final bool? isRequest = body['isRequest'];
    final bool? isSuccess = body['isSuccess'];
    final bool? isError = body['isMessageError'];
    final dynamic data = body['data'];

    return ResponseModel(
      statusCode: statusCode,
      isSuccess: isSuccess ?? (statusCode >= 200 && statusCode < 300),
      isRequest: isRequest ?? true,
      isMessageError: isError ?? false,
      message: message,
      messageError: messageError,
      data: data,
    );
  }
}