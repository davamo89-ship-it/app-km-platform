import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/points/upcoming_point_expiration.dart';
import '../../models/redemptions/pending_redemption_confirmation.dart';
import '../../services/points/points_backend_api_service.dart';
import '../../services/redemptions/pending_redemptions_backend_api_service.dart';
import '../redemptions/pending_redemption_decision_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final PointsBackendApiService _pointsApi =
      PointsBackendApiService();

  final PendingRedemptionsBackendApiService
      _pendingRedemptionsApi =
      PendingRedemptionsBackendApiService();

  List<PendingRedemptionConfirmation>
      _pendingRedemptions = const [];

  List<UpcomingPointExpiration> _expirations = const [];

  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pointsApi.dispose();
    _pendingRedemptionsApi.dispose();
    super.dispose();
  }

  Future<void> _load({
    bool showSuccessMessage = false,
  }) async {
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
      final pendingFuture =
          _pendingRedemptionsApi
              .getPendingConfirmations();

      final expirationsFuture =
          _pointsApi.getExpirations();

      final pending = await pendingFuture;
      final expirations = await expirationsFuture;

      pending.sort(
        (a, b) => b.merchantProposedAtUtc
            .compareTo(a.merchantProposedAtUtc),
      );

      final upcomingExpirations = expirations
          .where(
            (item) =>
                item.daysRemaining >= 0 &&
                item.daysRemaining <= 30 &&
                item.remainingPoints > 0,
          )
          .toList()
        ..sort(
          (a, b) =>
              a.expiresAtUtc.compareTo(b.expiresAtUtc),
        );

      if (!mounted) return;

      setState(() {
        _pendingRedemptions = pending;
        _expirations = upcomingExpirations;
        _isLoading = false;
        _hasLoadedOnce = true;
        _errorMessage = null;
      });

      if (showSuccessMessage) {
        _showMessage('Notificaciones actualizadas.');
      }
    } catch (error) {
      if (!mounted) return;

      final message = _friendlyError(error);

      if (isInitialLoad) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        '$message Se mantienen los últimos datos disponibles.',
        isError: true,
      );
    }
  }

  Future<void> _openPendingRedemption(
    PendingRedemptionConfirmation pending,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            PendingRedemptionDecisionScreen(
          pending: pending,
        ),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await _load();
    }

    if (!mounted) return;

    final hasNotifications =
        _pendingRedemptions.isNotEmpty ||
        _expirations.isNotEmpty;

    if (!hasNotifications && _errorMessage == null) {
      Navigator.of(context).pop();
    }
  }

  String _friendlyError(Object error) {
    if (error
        is PendingRedemptionsBackendApiException) {
      return error.message;
    }

    if (error is PointsBackendApiException) {
      return error.message;
    }

    return 'No fue posible consultar las notificaciones.';
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: Duration(
            seconds: isError ? 5 : 3,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading
                ? null
                : () => _load(
                      showSuccessMessage: true,
                    ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(
          showSuccessMessage: true,
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 140),
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

    final notificationCount =
        _pendingRedemptions.length +
        _expirations.length;

    if (notificationCount == 0) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          70,
          20,
          24,
        ),
        children: const [
          _EmptyNotifications(),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        32,
      ),
      children: [
        _NotificationsIntro(
          count: notificationCount,
        ),
        if (_pendingRedemptions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Canjes por confirmar',
            subtitle:
                _pendingRedemptions.length == 1
                    ? 'Tiene 1 canje que requiere su decisión.'
                    : 'Tiene ${_pendingRedemptions.length} canjes que requieren su decisión.',
          ),
          const SizedBox(height: 12),
          ..._pendingRedemptions.map(
            (pending) => Padding(
              padding:
                  const EdgeInsets.only(bottom: 12),
              child:
                  _PendingRedemptionNotification(
                pending: pending,
                onPressed: () =>
                    _openPendingRedemption(
                  pending,
                ),
              ),
            ),
          ),
        ],
        if (_expirations.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Puntos próximos a vencer',
            subtitle:
                'Estos avisos se calculan con la información actual del servidor.',
          ),
          const SizedBox(height: 12),
          ..._expirations.map(
            (expiration) => Padding(
              padding:
                  const EdgeInsets.only(bottom: 12),
              child:
                  _PointExpirationNotification(
                expiration: expiration,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NotificationsIntro extends StatelessWidget {
  const _NotificationsIntro({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1
                      ? 'Tiene 1 aviso importante'
                      : 'Tiene $count avisos importantes',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Se muestran situaciones actuales que requieren atención.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.35,
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

class _PendingRedemptionNotification
    extends StatelessWidget {
  const _PendingRedemptionNotification({
    required this.pending,
    required this.onPressed,
  });

  final PendingRedemptionConfirmation pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _NotificationCard(
      icon: Icons.storefront_outlined,
      title: 'Canje pendiente de confirmación',
      message:
          '${pending.merchantName} solicita canjear '
          '${pending.proposedPoints} KM Points.',
      footer:
          'Código ${pending.code} · Vence ${_formatDateTime(pending.expiresAtUtc)}',
      emphasized: true,
      actionText: 'Revisar canje',
      onPressed: onPressed,
    );
  }
}

class _PointExpirationNotification
    extends StatelessWidget {
  const _PointExpirationNotification({
    required this.expiration,
  });

  final UpcomingPointExpiration expiration;

  @override
  Widget build(BuildContext context) {
    final days = expiration.daysRemaining;

    final timeText = days == 0
        ? 'vencen hoy'
        : days == 1
            ? 'vencen en 1 día'
            : 'vencen en $days días';

    return _NotificationCard(
      icon: Icons.schedule_rounded,
      title: 'Puntos próximos a vencer',
      message:
          '${expiration.remainingPoints} KM Points $timeText.',
      footer:
          'Fecha de vencimiento: ${_formatDate(expiration.expiresAtUtc)}',
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.footer,
    this.emphasized = false,
    this.actionText,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String footer;
  final bool emphasized;
  final String? actionText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? AppColors.primary
        : Colors.orange;

    final content = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(
            alpha: emphasized ? 0.28 : 0.20,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
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
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  footer,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                  ),
                ),
                if (actionText != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        actionText!,
                        style: const TextStyle(
                          color:
                              AppColors.primary,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(22),
        child: content,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 19,
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

class _EmptyNotifications
    extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: Colors.black26,
            size: 54,
          ),
          SizedBox(height: 14),
          Text(
            'No tiene notificaciones pendientes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Cuando exista un canje por confirmar o puntos próximos a vencer, aparecerán aquí.',
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
        borderRadius:
            BorderRadius.circular(22),
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
            'No pudimos cargar las notificaciones',
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

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day =
      local.day.toString().padLeft(2, '0');
  final month =
      local.month.toString().padLeft(2, '0');

  return '$day/$month/${local.year}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day =
      local.day.toString().padLeft(2, '0');
  final month =
      local.month.toString().padLeft(2, '0');
  final hour =
      local.hour.toString().padLeft(2, '0');
  final minute =
      local.minute.toString().padLeft(2, '0');

  return '$day/$month/${local.year} $hour:$minute';
}
