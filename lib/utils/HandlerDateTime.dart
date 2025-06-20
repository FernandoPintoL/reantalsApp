import 'package:cloud_firestore/cloud_firestore.dart';

class HandlerDateTime{
  static Timestamp getDateTimeNow() {
    DateTime now = DateTime.now();
    Timestamp timestamp = Timestamp.fromDate(now);
    return timestamp;
  }

  static Timestamp getDateTimeDateTime(int timestamp){
    DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(timestamp);
    return Timestamp.fromDate(dateTime);
  }

  static Timestamp getDateTimeOfString(String strDateTime) {
    DateTime dateTime = DateTime.parse(strDateTime);
    return Timestamp.fromDate(dateTime);
  }

  static String getDateTimeOfDT(Timestamp ts) {
    return ts.toDate().toString();
  }
}