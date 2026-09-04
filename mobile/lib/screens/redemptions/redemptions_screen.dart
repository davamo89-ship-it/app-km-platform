import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/redemptions/create_redemption_result.dart';
import '../../models/redemptions/pending_redemption_confirmation.dart';
import '../../models/redemptions/redemption_request_item.dart';
import '../../services/points/points_backend_api_service.dart';
import '../../services/redemptions/pending_redemptions_backend_api_service.dart';
import '../../services/redemptions/redemptions_backend_api_service.dart';
import '../../services/realtime/redemption_realtime_service.dart';
import '../dashboard/dashboard_screen.dart';

class RedemptionsScreen extends StatefulWidget {
  const RedemptionsScreen({
    super.key,
    this.onNavigateMainSection,
  });

  final ValueChanged<int>? onNavigateMainSection;

  @override
  State<RedemptionsScreen> createState() =>
      _RedemptionsScreenState();
}

class _RedemptionsScreenState extends State<RedemptionsScreen>
    with WidgetsBindingObserver {
  final RedemptionsBackendApiService _redemptionsApi =
      RedemptionsBackendApiService();
  final PendingRedemptionsBackendApiService _pendingRedemptionsApi =
      PendingRedemptionsBackendApiService();
  final PointsBackendApiService _pointsApi =
      PointsBackendApiService();
  late final RedemptionRealtimeService _realtimeService;

  int _balance = 0;
  List<RedemptionRequestItem> _requests = const [];
  List<PendingRedemptionConfirmation> _pendingConfirmations = const [];

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;
  String? _noticeTitle;
  String? _noticeMessage;
  bool _noticeIsError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _realtimeService = RedemptionRealtimeService(
      onRedemptionChanged: _handleRealtimeRedemptionChanged,
    );
    _realtimeService.start();
    _load();
  }

  Future<void> _handleRealtimeRedemptionChanged() async {
    if (!mounted) {
      return;
    }

    await _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_isProcessing &&
        !_isLoading) {
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _redemptionsApi.dispose();
    _pendingRedemptionsApi.dispose();
    _pointsApi.dispose();
    _realtimeService.dispose();
    super.dispose();
  }

  Future<void> _load({
    bool showSuccessMessage = false,
  }) async {
    if (_isLoading && _hasLoadedOnce) {
      return;
    }

    final isInitialLoad = !_hasLoadedOnce;

    if (mounted) {
      setState(() {
        if (isInitialLoad) {
          _isLoading = true;
        }
        _errorMessage = null;
      });
    }

    try {
      final balanceFuture = _pointsApi.getBalance();
      final requestsFuture = _redemptionsApi.getAll();
      final pendingFuture =
          _pendingRedemptionsApi.getPendingConfirmations();

      final balance = await balanceFuture;
      final requests = await requestsFuture;
      final pending = await pendingFuture;

      requests.sort(
        (a, b) => b.createdAtUtc.compareTo(a.createdAtUtc),
      );
      pending.sort(
        (a, b) => b.merchantProposedAtUtc.compareTo(
          a.merchantProposedAtUtc,
        ),
      );

      if (!mounted) return;

      setState(() {
        _balance = balance;
        _requests = requests;
        _pendingConfirmations = pending;
        _isLoading = false;
        _hasLoadedOnce = true;
        _errorMessage = null;
      });

      if (showSuccessMessage) {
        _showSnackMessage('Canjes actualizados.');
      }
    } catch (error) {
      if (!mounted) return;

      final friendlyMessage = _friendlyError(error);

      if (isInitialLoad) {
        setState(() {
          _isLoading = false;
          _errorMessage = friendlyMessage;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _noticeMessage =
            '$friendlyMessage Se mantienen los últimos datos disponibles.';
        _noticeIsError = true;
      });
    }
  }

  Future<void> _refreshFromUserAction({
    bool showSuccessMessage = false,
  }) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() {
      _noticeTitle = null;
      _noticeMessage = null;
      _noticeIsError = false;
    });

    await _load(
      showSuccessMessage: showSuccessMessage,
    );
  }

  Future<void> _refreshExpiredState() async {
    if (!mounted || _isProcessing || _isLoading) {
      return;
    }

    await _load();
  }

  bool _isExpiredRedemptionError(Object error) {
    return error is RedemptionsBackendApiException &&
        (error.code == 'Athletes.Redemption.Expired' ||
            error.code == 'Merchants.Redemption.Expired');
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
      _noticeTitle = null;
      _noticeMessage = null;
      _noticeIsError = false;
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

      setState(() {
        _noticeTitle = 'No pudimos crear el canje';
        _noticeMessage = _friendlyError(error);
        _noticeIsError = true;
      });
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
      message: '¿Deseas cancelar el código ${request.code}?',
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

  Future<void> _confirmMerchantProposal(
    PendingRedemptionConfirmation pending,
  ) async {
    final confirmed = await _confirmDialog(
      title: 'Confirmar canje',
      message:
          '${pending.merchantName} solicita canjear '
          '${pending.proposedPoints} KM Points. '
          'Los puntos se descontarán al confirmar.',
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

  Future<void> _rejectMerchantProposal(
    PendingRedemptionConfirmation pending,
  ) async {
    final confirmed = await _confirmDialog(
      title: 'Cancelar canje',
      message:
          '¿Deseas cancelar el canje en '
          '${pending.merchantName} por '
          '${pending.proposedPoints} KM Points?',
      confirmText: 'Sí, cancelar',
      cancelText: 'Volver',
    );

    if (!confirmed) {
      return;
    }

    await _runAction(
      () => _redemptionsApi.reject(
        code: pending.code,
      ),
      successMessage: 'Canje cancelado.',
    );
  }

  Future<void> _runAction(
    Future<Object?> Function() action, {
    required String successMessage,
  }) async {
    setState(() {
      _isProcessing = true;
      _noticeTitle = null;
      _noticeMessage = null;
      _noticeIsError = false;
    });

    try {
      await action();

      if (!mounted) return;

      await _load();
      _showSnackMessage(successMessage);
    } catch (error) {
      if (!mounted) return;

      final expired = _isExpiredRedemptionError(error);

      if (expired) {
        // El backend convierte el canje a Expired al detectar
        // el vencimiento. Volvemos a consultar inmediatamente
        // para que desaparezca de pendientes y pase a historial.
        await _load();

        if (!mounted) return;

        setState(() {
          _noticeTitle = 'Código vencido';
          _noticeMessage =
              'Este código ya venció y fue movido al historial.';
          _noticeIsError = true;
        });
      } else {
        setState(() {
          _noticeTitle = 'No pudimos completar la acción';
          _noticeMessage = _friendlyError(error);
          _noticeIsError = true;
        });
      }
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
    String cancelText = 'Volver',
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
              child: Text(cancelText),
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
      switch (error.code) {
        case 'Athletes.Redemption.InsufficientAvailableBalance':
          return 'No tienes suficientes puntos disponibles para crear un canje por esa cantidad.';
        case 'Athletes.Redemption.InvalidPoints':
          return 'Ingresa una cantidad válida de KM Points.';
        case 'Athletes.Redemption.Expired':
        case 'Merchants.Redemption.Expired':
          return 'Este código de canje ya venció.';
        case 'Athletes.Redemption.NotPending':
        case 'Merchants.Redemption.NotPending':
          return 'Este canje ya no está pendiente.';
        default:
          return 'No fue posible procesar el canje. Inténtalo nuevamente.';
      }
    }

    if (error is PendingRedemptionsBackendApiException) {
      return 'No fue posible consultar las confirmaciones pendientes.';
    }

    if (error is PointsBackendApiException) {
      return 'No fue posible consultar tus KM Points en este momento.';
    }

    return 'No fue posible comunicarse con el servicio de canjes.';
  }

  void _showSnackMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _goToMainSection(int index) {
    final navigate = widget.onNavigateMainSection;

    if (navigate != null) {
      Navigator.of(context).pop();
      navigate(index);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => DashboardScreen(
          initialIndex: index,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Canjes',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.primary,
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isProcessing
                ? null
                : () => _refreshFromUserAction(),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _refreshFromUserAction(
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
      bottomNavigationBar: NavigationBar(
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

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
        children: [
          _ErrorCard(
            message: _errorMessage!,
            onRetry: _load,
          ),
        ],
      );
    }

    final now = DateTime.now();

    final activeRequests = _requests
        .where(
          (request) =>
              request.status.toLowerCase() == 'pending' &&
              request.expiresAtUtc.toLocal().isAfter(now),
        )
        .toList();

    final historyRequests = _requests
        .where(
          (request) =>
              _isClosedRedemptionStatus(request.status) ||
              (request.status.toLowerCase() == 'pending' &&
                  !request.expiresAtUtc.toLocal().isAfter(now)),
        )
        .toList();

    final currentPending = _pendingConfirmations.isEmpty
        ? null
        : _pendingConfirmations.first;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        _BalanceCard(balance: _balance),
        const SizedBox(height: 12),
        _CreateRedemptionButton(
          onPressed: _isProcessing ? null : _createRedemption,
        ),
        if (_noticeMessage != null) ...[
          const SizedBox(height: 14),
          _NoticeCard(
            title: _noticeTitle,
            message: _noticeMessage!,
            isError: _noticeIsError,
            onDismiss: () {
              setState(() {
                _noticeTitle = null;
                _noticeMessage = null;
              });
            },
          ),
        ],
        if (currentPending != null) ...[
          const SizedBox(height: 26),
          _SectionHeader(
            title: 'Confirmación pendiente',
            subtitle: _pendingConfirmations.length == 1
                ? 'Completa el canje confirmándolo o cancelándolo.'
                : 'Tienes ${_pendingConfirmations.length} canjes por decidir. Al resolver uno, aparecerá el siguiente.',
          ),
          const SizedBox(height: 12),
          _PendingConfirmationCard(
            pending: currentPending,
            position: 1,
            total: _pendingConfirmations.length,
            onConfirm: () =>
                _confirmMerchantProposal(currentPending),
            onReject: () =>
                _rejectMerchantProposal(currentPending),
            onExpired: _refreshExpiredState,
          ),
        ],
        const SizedBox(height: 26),
        const _SectionHeader(
          title: 'Códigos activos',
          subtitle:
              'Muestra el código al comercio. El comercio no puede cambiar la cantidad solicitada.',
        ),
        const SizedBox(height: 14),
        if (activeRequests.isEmpty)
          const _EmptyActiveRedemptions()
        else
          ...activeRequests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RedemptionCard(
                request: request,
                showCountdown: true,
                onCancel: () => _cancel(request),
                onExpired: _refreshExpiredState,
              ),
            ),
          ),
        const SizedBox(height: 22),
        const _SectionHeader(
          title: 'Historial',
          subtitle:
              'Aquí quedan los canjes completados, cancelados o vencidos.',
        ),
        const SizedBox(height: 14),
        if (historyRequests.isEmpty)
          const _EmptyHistoryRedemptions()
        else
          ...historyRequests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RedemptionCard(
                request: request,
                effectiveStatus:
                    _effectiveStatus(request, now),
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Puntos disponibles',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$balance KM Points',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateRedemptionButton extends StatelessWidget {
  const _CreateRedemptionButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: double.infinity,
          height: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crear canje',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Genera un código para canjear tus puntos.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.message,
    required this.isError,
    required this.onDismiss,
    this.title,
  });

  final String? title;
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ??
                      (isError
                          ? 'No pudimos completar la acción'
                          : 'Listo'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Cerrar',
            onPressed: onDismiss,
            icon: Icon(
              Icons.close_rounded,
              color: color,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PendingConfirmationCard extends StatelessWidget {
  const _PendingConfirmationCard({
    required this.pending,
    required this.position,
    required this.total,
    required this.onConfirm,
    required this.onReject,
    required this.onExpired,
  });

  final PendingRedemptionConfirmation pending;
  final int position;
  final int total;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) {
    const accent = Colors.orange;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatusBadge(
                            status: 'AwaitingAthleteConfirmation',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pending.code,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${pending.proposedPoints} KM Points',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pending.merchantName,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _CountdownPanel(
                          expiresAtUtc: pending.expiresAtUtc,
                          onExpired: onExpired,
                        ),
                      ],
                    ),
                    if (total > 1) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Solicitud $position de $total',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accent,
                              side: const BorderSide(color: accent),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: onConfirm,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                            ),
                            child: const Text('Confirmar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard({
    required this.request,
    this.showCountdown = false,
    this.effectiveStatus,
    this.onCancel,
    this.onExpired,
  });

  final RedemptionRequestItem request;
  final bool showCountdown;
  final String? effectiveStatus;
  final VoidCallback? onCancel;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    final status = effectiveStatus ?? request.status;
    final statusColor = _statusColor(status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              color: statusColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            _statusIcon(status),
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatusBadge(status: status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (showCountdown)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.code,
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${request.requestedPoints} KM Points',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _CountdownPanel(
                            expiresAtUtc: request.expiresAtUtc,
                            onExpired: onExpired,
                          ),
                        ],
                      )
                    else ...[
                      Text(
                        request.code,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
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
                      if (request.merchantName != null &&
                          request.merchantName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.storefront_outlined,
                          text: 'Comercio: ${request.merchantName}',
                        ),
                      ],
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
                    ],
                    if (onCancel != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Cancelar código'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownPanel extends StatelessWidget {
  const _CountdownPanel({
    required this.expiresAtUtc,
    this.onExpired,
  });

  final DateTime expiresAtUtc;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    return _CountdownTimer(
      expiresAtUtc: expiresAtUtc,
      onExpired: onExpired,
    );
  }
}

class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({
    required this.expiresAtUtc,
    this.onExpired,
  });

  final DateTime expiresAtUtc;
  final VoidCallback? onExpired;

  @override
  State<_CountdownTimer> createState() =>
      _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Timer? _timer;
  late Duration _remaining;
  bool _expirationNotified = false;

  @override
  void initState() {
    super.initState();
    _remaining = _calculateRemaining();

    if (_remaining == Duration.zero) {
      _notifyExpiration();
    } else {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted) return;

          final remaining = _calculateRemaining();

          setState(() {
            _remaining = remaining;
          });

          if (remaining == Duration.zero) {
            _timer?.cancel();
            _notifyExpiration();
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant _CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAtUtc != widget.expiresAtUtc) {
      _timer?.cancel();
      _expirationNotified = false;
      _remaining = _calculateRemaining();

      if (_remaining == Duration.zero) {
        _notifyExpiration();
      } else {
        _timer = Timer.periodic(
          const Duration(seconds: 1),
          (_) {
            if (!mounted) return;

            final remaining = _calculateRemaining();

            setState(() {
              _remaining = remaining;
            });

            if (remaining == Duration.zero) {
              _timer?.cancel();
              _notifyExpiration();
            }
          },
        );
      }
    }
  }

  void _notifyExpiration() {
    if (_expirationNotified) {
      return;
    }

    _expirationNotified = true;

    final callback = widget.onExpired;
    if (callback == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        callback();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _calculateRemaining() {
    final difference = widget.expiresAtUtc.toUtc().difference(
          DateTime.now().toUtc(),
        );

    if (difference.isNegative || difference == Duration.zero) {
      return Duration.zero;
    }

    return difference;
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = _remaining.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final expired = totalSeconds <= 0;
    final color = expired ? Colors.red : Colors.orange;

    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                expired ? 'Vencido' : 'Tiempo restante',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          if (!expired)
            const Text(
              'min : seg',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _statusIcon(status),
              color: color,
              size: 14,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _statusLabel(status),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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

class _CreateRedemptionSheet extends StatefulWidget {
  const _CreateRedemptionSheet({
    required this.balance,
  });

  final int balance;

  @override
  State<_CreateRedemptionSheet> createState() =>
      _CreateRedemptionSheetState();
}

class _CreateRedemptionSheetState extends State<_CreateRedemptionSheet> {
  final TextEditingController _controller =
      TextEditingController();

  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final points = int.tryParse(_controller.text.trim());

    if (points == null || points <= 0) {
      setState(() {
        _errorText = 'Ingresa una cantidad válida de puntos.';
      });
      return;
    }

    if (points > widget.balance) {
      setState(() {
        _errorText =
            'No puedes solicitar más puntos que tu saldo actual.';
      });
      return;
    }

    Navigator.pop(context, points);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(20),
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
              'Saldo actual: ${widget.balance} KM Points',
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
                prefixIcon: const Icon(Icons.stars_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Generar código'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatedCodeSheet extends StatelessWidget {
  const _CreatedCodeSheet({
    required this.result,
  });

  final CreateRedemptionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
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
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 88,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Muestra este código al comercio',
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
            const SizedBox(height: 14),
            _CountdownTimer(
              expiresAtUtc: result.expiresAtUtc,
            ),
            const SizedBox(height: 14),
            const Text(
              'El comercio usará este código para solicitar el canje exacto. Después deberás confirmarlo o cancelarlo.',
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

class _EmptyActiveRedemptions extends StatelessWidget {
  const _EmptyActiveRedemptions();

  @override
  Widget build(BuildContext context) {
    return const _EmptySectionCard(
      icon: Icons.qr_code_2_rounded,
      title: 'No hay códigos activos',
      message:
          'Cuando generes un nuevo código de canje, aparecerá aquí.',
    );
  }
}

class _EmptyHistoryRedemptions extends StatelessWidget {
  const _EmptyHistoryRedemptions();

  @override
  Widget build(BuildContext context) {
    return const _EmptySectionCard(
      icon: Icons.history_rounded,
      title: 'Todavía no hay historial',
      message:
          'Los canjes finalizados aparecerán en esta sección.',
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 46,
            color: Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
          const Text(
            'No pudimos cargar tus canjes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
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

bool _isClosedRedemptionStatus(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'expired':
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return true;
    default:
      return false;
  }
}

String _effectiveStatus(
  RedemptionRequestItem request,
  DateTime now,
) {
  if (request.status.toLowerCase() == 'pending' &&
      !request.expiresAtUtc.toLocal().isAfter(now)) {
    return 'Expired';
  }

  return request.status;
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
    case 'rejected':
      return Colors.blueGrey;
    case 'merchantproposed':
    case 'pendingathleteconfirmation':
    case 'awaitingathleteconfirmation':
      return Colors.orange;
    default:
      return AppColors.primary;
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Icons.schedule_rounded;
    case 'completed':
      return Icons.check_circle_outline_rounded;
    case 'expired':
      return Icons.timer_off_outlined;
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return Icons.cancel_outlined;
    case 'merchantproposed':
    case 'pendingathleteconfirmation':
    case 'awaitingathleteconfirmation':
      return Icons.schedule_rounded;
    default:
      return Icons.qr_code_2_rounded;
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
    case 'rejected':
      return 'Cancelado';
    case 'merchantproposed':
    case 'pendingathleteconfirmation':
    case 'awaitingathleteconfirmation':
      return 'Pendiente de tu confirmación';
    default:
      return status.isEmpty ? 'Sin estado' : status;
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
