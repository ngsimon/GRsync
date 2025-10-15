import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/gr_sync_service.dart';

void main() {
  runApp(const GRSyncApp());
}

class GRSyncApp extends StatelessWidget {
  const GRSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GRSyncService(),
      child: MaterialApp(
        title: 'GR Sync',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}