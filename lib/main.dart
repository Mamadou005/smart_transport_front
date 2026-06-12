import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/bagage_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/providers/reservation_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BagageProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const SmartTransportApp(),
    ),
  );
}