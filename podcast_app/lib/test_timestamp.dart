import 'package:firebase_data_connect/firebase_data_connect.dart';

void main() {
  Timestamp t1 = Timestamp(DateTime.now());
  Timestamp t2 = Timestamp.fromDate(DateTime.now());
  Timestamp t3 = Timestamp.fromDateTime(DateTime.now());
}
