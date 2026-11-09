import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/reimbursement.dart';
import '../services/api_exception.dart';
import '../services/reimbursement_api_service.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';

class MyReimbursementsScreen extends StatefulWidget {
  const MyReimbursementsScreen({super.key, required this.api});

  final ReimbursementApiService api;

  @override
  State<MyReimbursementsScreen> createState() => MyReimbursementsScreenState();
}

class MyReimbursementsScreenState extends State<MyReimbursementsScreen> {
  List<Reimbursement> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.getMyReimbursements(ApiConfig.employeeName);
      if (!mounted) return;
      setState(() => _items = items);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _MessageView(
        icon: Icons.cloud_off,
        title: 'No se pudieron cargar tus solicitudes',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: reload,
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _MessageView(
              icon: Icons.receipt_long,
              title: 'Aún no tienes solicitudes',
              message: 'Registra tu primer gasto desde la pestaña "Nuevo gasto".',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ReimbursementCard(item: _items[i]),
      ),
    );
  }
}

class _ReimbursementCard extends StatelessWidget {
  const _ReimbursementCard({required this.item});

  final Reimbursement item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(formatCop(item.amount),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.category, style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(item.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text('Creada: ${formatLocalDate(item.createdAtUtc)} · #${item.id}',
                style: theme.textTheme.bodySmall),
            if (item.status == ReimbursementStatus.rejected && item.rejectionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Motivo del rechazo: ${item.rejectionReason}',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
