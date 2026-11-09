import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Se puede sobrescribir al ejecutar:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.50:5000/api/reimbursements
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // En el emulador Android, 10.0.2.2 apunta al PC anfitrión.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/reimbursements';
    }
    // Web, Windows, iOS Simulator, etc.
    return 'http://localhost:5000/api/reimbursements';
  }

  static const requestTimeout = Duration(seconds: 10);

  /// Identificación simplificada permitida por el enunciado (sin login).
  static const employeeName = 'Empleado Demo';

  static const categories = <String>[
    'Alimentación',
    'Transporte',
    'Hospedaje',
    'Papelería',
    'Otros',
  ];

  static const autoApprovalLimit = 500000;
}
