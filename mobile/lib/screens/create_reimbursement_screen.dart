import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../models/reimbursement.dart';
import '../services/api_exception.dart';
import '../services/reimbursement_api_service.dart';
import '../utils/formatters.dart';

class CreateReimbursementScreen extends StatefulWidget {
  const CreateReimbursementScreen({super.key, required this.api, required this.onCreated});

  final ReimbursementApiService api;
  final ValueChanged<Reimbursement> onCreated;

  @override
  State<CreateReimbursementScreen> createState() => _CreateReimbursementScreenState();
}

class _CreateReimbursementScreenState extends State<CreateReimbursementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _category;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  int? get _amount => int.tryParse(_amountCtrl.text);

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final created = await widget.api.createReimbursement(
        employeeName: ApiConfig.employeeName,
        amount: _amount!,
        category: _category!,
        description: _descriptionCtrl.text.trim(),
      );
      if (!mounted) return;

      final msg = created.status == ReimbursementStatus.approved
          ? 'Solicitud aprobada automáticamente.'
          : 'Solicitud registrada. Queda pendiente de aprobación.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      _formKey.currentState!.reset();
      _amountCtrl.clear();
      _descriptionCtrl.clear();
      setState(() => _category = null);
      widget.onCreated(created);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: e.isConnectionError
            ? SnackBarAction(label: 'Reintentar', textColor: Colors.white, onPressed: _submit)
            : null,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    final willAutoApprove = amount != null && amount > 0 && amount <= ApiConfig.autoApprovalLimit;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Registrar un gasto', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Empleado: ${ApiConfig.employeeName}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountCtrl,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: InputDecoration(
                labelText: 'Monto (COP)',
                prefixText: r'$ ',
                border: const OutlineInputBorder(),
                helperText: amount == null || amount <= 0
                    ? 'Hasta ${formatCop(ApiConfig.autoApprovalLimit)} se aprueba automáticamente'
                    : '${formatCop(amount)} · ${willAutoApprove ? 'se aprobará automáticamente' : 'requerirá aprobación'}',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                final n = int.tryParse(v);
                if (n == null) return 'Monto inválido';
                if (n <= 0) return 'El monto debe ser mayor a cero';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: ApiConfig.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Selecciona una categoría' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              enabled: !_saving,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej.: Taxi a reunión con cliente',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Describe brevemente el gasto' : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Guardando…' : 'Guardar solicitud'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
