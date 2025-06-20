class ResponseModel {
  bool isSuccess;
  bool isRequest;
  bool isMessageError;
  String? message;
  dynamic messageError;
  dynamic data;
  int statusCode;

  ResponseModel({
    required this.statusCode,
    required this.isSuccess,
    required this.isRequest,
    required this.isMessageError,
    this.message,
    this.messageError,
    this.data,
  });

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    print('ResponseModel.fromJson: $json');
    return ResponseModel(
      statusCode: int.tryParse(json['statusCode']) ?? 500,
      isSuccess: json['isSuccess'] ?? false,
      isRequest: json['isRequest'] ?? false,
      isMessageError: json['isMessageError'] ?? true,
      message: json['message'],
      messageError: json['messageError'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'isSuccess': isSuccess,
      'isRequest': isRequest,
      'isMessageError': isMessageError,
      'message': message,
      'messageError': messageError,
      'data': data,
    };
  }
}