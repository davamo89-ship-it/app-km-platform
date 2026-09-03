import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/redemptions/pending_redemption_confirmation.dart';
import '../../services/redemptions/redemptions_backend_api_service.dart';

class PendingRedemptionDecisionScreen
    extends StatefulWidget {
  const PendingRedemptionDecisionScreen({
    super.key,
    required this.pending,
    this.onNavigateMainSection,
  });

  final PendingRedemptionConfirmation pending;
  final ValueChanged<int>? onNavigateMainSection;

  @override
  State<PendingRedemptionDecisionScreen> createState() =>
      _PendingRedemptionDecisionScreenState();
}

class _PendingRedemptionDecisionScreenState
    extends State<PendingRedemptionDecisionScreen> {
  final RedemptionsBackendApiService _api =
      RedemptionsBackendApiService();

  bool _isProcessing = false;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isProcessing) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar canje'),
          content: Text(
            '¿Desea confirmar el canje de '
            '${widget.pending.proposedPoints} KM Points '
            'con ${widget.pending.merchantName}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (accepted != true || !mounted) return;

    await _process(
      action: () => _api.confirm(
        code: widget.pending.code,
      ),
      successMessage: 'Canje confirmado correctamente.',
    );
  }

  Future<void> _cancel() async {
    if (_isProcessing) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar canje'),
          content: Text(
            '¿Desea cancelar el canje de '
            '${widget.pending.proposedPoints} KM Points '
            'con ${widget.pending.merchantName}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: const Text('Cancelar canje'),
            ),
          ],
        );
      },
    );

    if (accepted != true || !mounted) return;

    await _process(
      action: () => _api.reject(
        code: widget.pending.code,
      ),
      successMessage: 'Canje cancelado correctamente.',
    );
  }

  Future<void> _process({
    required Future<Object> Function() action,
    required String successMessage,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.of(context).pop(true);
    } on RedemptionsBackendApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No fue posible completar la operación.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _goToMainSection(int index) {
    final navigate = widget.onNavigateMainSection;
    if (navigate == null) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
    navigate(index);
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.pending;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Revisar canje',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.primary,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color:
                    AppColors.primary.withValues(alpha: 0.20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Solicitud de canje',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  label: 'Comercio',
                  value: pending.merchantName,
                ),
                _DetailRow(
                  label: 'Puntos',
                  value:
                      '${pending.proposedPoints} KM Points',
                ),
                _DetailRow(
                  label: 'Código',
                  value: pending.code,
                ),
                _DetailRow(
                  label: 'Vence',
                  value:
                      _formatDateTime(pending.expiresAtUtc),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Confirme únicamente si reconoce esta solicitud y el monto es correcto.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isProcessing ? null : _confirm,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar canje'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _cancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar canje'),
          ),
        ],
      ),
      bottomNavigationBar: widget.onNavigateMainSection == null
          ? null
          : NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: _goToMainSection,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions_run_outlined),
                  selectedIcon: Icon(Icons.directions_run),
                  label: 'Actividad',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Historial',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/${local.year} $hour:$minute';
}
