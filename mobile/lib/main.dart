import 'package:flutter/material.dart';

import 'models/reimbursement.dart';
import 'screens/create_reimbursement_screen.dart';
import 'screens/my_reimbursements_screen.dart';
import 'services/reimbursement_api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reembolsos Consware',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF13507A),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _api = ReimbursementApiService();
  final _listKey = GlobalKey<MyReimbursementsScreenState>();
  int _index = 0;

  void _onCreated(Reimbursement _) {
    setState(() => _index = 0);
    _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Mis solicitudes' : 'Nuevo gasto'),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
              onPressed: () => _listKey.currentState?.reload(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          MyReimbursementsScreen(key: _listKey, api: _api),
          CreateReimbursementScreen(api: _api, onCreated: _onCreated),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 0) _listKey.currentState?.reload();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Mis solicitudes'),
          NavigationDestination(icon: Icon(Icons.add_card), label: 'Nuevo gasto'),
        ],
      ),
    );
  }
}
