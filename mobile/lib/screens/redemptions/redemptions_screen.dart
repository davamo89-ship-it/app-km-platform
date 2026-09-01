import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/redemptions/create_redemption_result.dart';
import '../../models/redemptions/pending_redemption_confirmation.dart';
import '../../models/redemptions/redemption_request_item.dart';
import '../../services/points/points_backend_api_service.dart';
import '../../services/redemptions/redemptions_backend_api_service.dart';

class RedemptionsScreen extends StatefulWidget {
  const RedemptionsScreen({super.key});

  @override
  State<RedemptionsScreen> createState() =>
      _RedemptionsScreenState();
}

class _RedemptionsScreenState
    extends State<RedemptionsScreen> {
  final RedemptionsBackendApiService _redemptionsApi =
      RedemptionsBackendApiService();

  final PointsBackendApiService _pointsApi =
      PointsBackendApiService();

  int _balance = 0;
  List<RedemptionRequestItem> _requests = const [];
  PendingRedemptionConfirmation? _pendingConfirmation;

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _redemptionsApi.dispose();
    _pointsApi.dispose();
    super.dispose();
  }

  Future<void> _load({
    bool showSuccessMessage = false,
  }) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final balanceFuture = _pointsApi.getBalance();
      final requestsFuture = _redemptionsApi.getAll();
      final pendingFuture =
          _redemptionsApi.getPendingConfirmation();

      final balance = await balanceFuture;
      final requests = await requestsFuture;
      final pending = await pendingFuture;

      requests.sort(
        (a, b) => b.createdAtUtc.compareTo(a.createdAtUtc),
      );

      if (!mounted) return;

      setState(() {
        _balance = balance;
        _requests = requests;
        _pendingConfirmation = pending;
        _isLoading = false;
      });

      if (showSuccessMessage) {
        _showMessage('Canjes actualizados.');
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  Future<void> _createRedemption() async {
    final requestedPoints = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateRedemptionSheet(
          balance: _balance,
        );
      },
    );

    if (requestedPoints == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _redemptionsApi.create(
        requestedPoints: requestedPoints,
      );

      if (!mounted) return;

      await _showCreatedCode(result);
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        _friendlyError(error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _showCreatedCode(
    CreateRedemptionResult result,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return _CreatedCodeSheet(
          result: result,
        );
      },
    );
  }

  Future<void> _cancel(
    RedemptionRequestItem request,
  ) async {
    final confirmed = await _confirmDialog(
      title: 'Cancelar canje',
      message:
          '¿Desea cancelar el código ${request.code}?',
      confirmText: 'Cancelar canje',
    );

    if (!confirmed) {
      return;
    }

    await _runAction(
      () => _redemptionsApi.cancel(
        code: request.code,
      ),
      successMessage: 'Canje cancelado.',
    );
  }

  Future<void> _confirmMerchantProposal() async {
    final pending = _pendingConfirmation;
    if (pending == null) return;

    final confirmed = await _confirmDialog(
      title: 'Confirmar canje',
      message:
          '${pending.merchantName} propone canjear '
          '${pending.proposedPoints} KM Points. '
          'Al confirmar, el backend completará el canje.',
      confirmText: 'Confirmar',
    );

    if (!confirmed) {
      return;
    }

    await _runAction(
      () => _redemptionsApi.confirm(
        code: pending.code,
      ),
      successMessage: 'Canje confirmado correctamente.',
    );
  }

  Future<void> _rejectMerchantProposal() async {
    final pending = _pendingConfirmation;
    if (pending == null) return;

    final confirmed = await _confirmDialog(
      title: 'Rechazar propuesta',
      message:
          '¿Desea rechazar la propuesta de '
          '${pending.merchantName} por '
          '${pending.proposedPoints} KM Points?',
      confirmText: 'Rechazar',
    );

    if (!confirmed) {
      return;
    }

    await _runAction(
      () => _redemptionsApi.reject(
        code: pending.code,
      ),
      successMessage: 'Propuesta rechazada.',
    );
  }

  Future<void> _runAction(
    Future<Object?> Function() action, {
    required String successMessage,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await action();

      if (!mounted) return;

      _showMessage(successMessage);
      await _load();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _friendlyError(error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _friendlyError(Object error) {
    if (error is RedemptionsBackendApiException) {
      return error.message;
    }

    if (error is PointsBackendApiException) {
      return error.message;
    }

    return 'No fue posible procesar el canje.';
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Canjes'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                _isProcessing ? null : () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _load(
              showSuccessMessage: true,
            ),
            child: _buildBody(),
          ),
          if (_isProcessing)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x22000000),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _isLoading || _errorMessage != null
              ? null
              : FloatingActionButton.extended(
                  onPressed:
                      _isProcessing
                          ? null
                          : _createRedemption,
                  icon: const Icon(
                    Icons.qr_code_2_rounded,
                  ),
                  label:
                      const Text('Crear canje'),
                ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 120),
        children: const [
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          80,
          20,
          24,
        ),
        children: [
          _ErrorCard(
            message: _errorMessage!,
            onRetry: _load,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        110,
      ),
      children: [
        _BalanceCard(balance: _balance),
        if (_pendingConfirmation != null) ...[
          const SizedBox(height: 20),
          _PendingConfirmationCard(
            pending: _pendingConfirmation!,
            onConfirm: _confirmMerchantProposal,
            onReject: _rejectMerchantProposal,
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Mis solicitudes',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Genere un código y muéstrelo al comercio. '
          'Los puntos solo se descuentan cuando usted '
          'confirma la propuesta del comercio.',
          style: TextStyle(
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (_requests.isEmpty)
          const _EmptyRedemptions()
        else
          ..._requests.map(
            (request) => Padding(
              padding:
                  const EdgeInsets.only(bottom: 12),
              child: _RedemptionCard(
                request: request,
                onCancel: request.isPending
                    ? () => _cancel(request)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
  });

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Puntos disponibles',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$balance KM Points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingConfirmationCard
    extends StatelessWidget {
  const _PendingConfirmationCard({
    required this.pending,
    required this.onConfirm,
    required this.onReject,
  });

  final PendingRedemptionConfirmation pending;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              AppColors.primary.withValues(alpha: 0.30),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirmación pendiente',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            pending.merchantName,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${pending.proposedPoints} KM Points',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Código: ${pending.code}',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Vence: ${_formatDateTime(pending.expiresAtUtc)}',
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard({
    required this.request,
    this.onCancel,
  });

  final RedemptionRequestItem request;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      statusColor.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.code,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.requestedPoints} KM Points',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                status: request.status,
              ),
            ],
          ),
          const SizedBox(height: 15),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text:
                'Creado: ${_formatDateTime(request.createdAtUtc)}',
          ),
          const SizedBox(height: 7),
          _InfoRow(
            icon: Icons.timer_outlined,
            text:
                'Vence: ${_formatDateTime(request.expiresAtUtc)}',
          ),
          if (request.completedAtUtc != null) ...[
            const SizedBox(height: 7),
            _InfoRow(
              icon: Icons.check_circle_outline,
              text:
                  'Completado: ${_formatDateTime(request.completedAtUtc!)}',
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(
                  Icons.close_rounded,
                ),
                label:
                    const Text('Cancelar código'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.black38,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateRedemptionSheet
    extends StatefulWidget {
  const _CreateRedemptionSheet({
    required this.balance,
  });

  final int balance;

  @override
  State<_CreateRedemptionSheet> createState() =>
      _CreateRedemptionSheetState();
}

class _CreateRedemptionSheetState
    extends State<_CreateRedemptionSheet> {
  final TextEditingController _controller =
      TextEditingController();

  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final points =
        int.tryParse(_controller.text.trim());

    if (points == null || points <= 0) {
      setState(() {
        _errorText =
            'Ingrese una cantidad válida de puntos.';
      });
      return;
    }

    if (points > widget.balance) {
      setState(() {
        _errorText =
            'No puede solicitar más puntos que su saldo disponible.';
      });
      return;
    }

    Navigator.pop(context, points);
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        24 + bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Crear código de canje',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Saldo disponible: ${widget.balance} KM Points',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Puntos a solicitar',
                hintText: 'Ej. 500',
                errorText: _errorText,
                prefixIcon:
                    const Icon(Icons.stars_outlined),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(
                  Icons.qr_code_2_rounded,
                ),
                label:
                    const Text('Generar código'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatedCodeSheet
    extends StatelessWidget {
  const _CreatedCodeSheet({
    required this.result,
  });

  final CreateRedemptionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        14,
        24,
        28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 88,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Muestre este código al comercio',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              result.code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 27,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              '${result.requestedPoints} KM Points',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Expira: ${_formatDateTime(result.expiresAtUtc)}',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El comercio utilizará este código para '
              'proponer el monto. Después usted deberá '
              'confirmar o rechazar la propuesta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRedemptions extends StatelessWidget {
  const _EmptyRedemptions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 55,
            color: Colors.black26,
          ),
          SizedBox(height: 14),
          Text(
            'Todavía no tiene canjes',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Cuando cree un código, aparecerá aquí '
            'junto con su estado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black45,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Colors.black38,
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'completed':
      return Colors.green;
    case 'expired':
      return Colors.red;
    case 'cancelled':
    case 'canceled':
      return Colors.blueGrey;
    case 'merchantproposed':
    case 'pendingathleteconfirmation':
      return AppColors.primary;
    case 'rejected':
      return Colors.redAccent;
    default:
      return AppColors.primary;
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Pendiente';
    case 'completed':
      return 'Completado';
    case 'expired':
      return 'Vencido';
    case 'cancelled':
    case 'canceled':
      return 'Cancelado';
    case 'merchantproposed':
    case 'pendingathleteconfirmation':
      return 'Por confirmar';
    case 'rejected':
      return 'Rechazado';
    default:
      if (status.isEmpty) {
        return 'Sin estado';
      }

      return status;
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();

  final day = local.day.toString().padLeft(2, '0');
  final month =
      local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  final hour = local.hour.toString().padLeft(2, '0');
  final minute =
      local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
