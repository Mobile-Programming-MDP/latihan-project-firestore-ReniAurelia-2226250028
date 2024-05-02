import 'package:flutter/material.dart';
import 'package:flutterlist/useritem.dart';
import 'package:flutterlist/userlist.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(UserList());
}
