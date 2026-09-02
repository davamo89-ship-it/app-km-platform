import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/merchants/merchant_latest_redemption.dart';
import '../../models/merchants/merchant_profile.dart';
import '../../models/merchants/merchant_redemption_proposal_result.dart';
import '../../models/merchants/merchant_redemption_validation.dart';
import '../../services/api/authenticated_api_client.dart';
import '../../services/auth/auth_api_service.dart';
import '../../services/auth/auth_token_store.dart';
import '../../services/merchants/merchant_backend_api_service.dart';
import 'merchant_redemptions_history_screen.dart';

class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});

  @override
  State<MerchantScreen> createState() =>
      _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  final MerchantBackendApiService _merchantApi =
      MerchantBackendApiService();
  final AuthApiService _authApiService = AuthApiService();
  final AuthTokenStore _authTokenStore = AuthTokenStore();

  final TextEditingController _codeController =
      TextEditingController();

  MerchantProfile? _merchant;
  MerchantRedemptionValidation? _validation;
  MerchantRedemptionProposalResult? _proposalResult;
  MerchantLatestRedemption? _latestRedemption;
  bool _showLatestRedemption = true;

  bool _isLoadingProfile = true;
  bool _hasLoadedProfileOnce = false;
  bool _isValidating = false;
  bool _isProposing = false;
  String? _profileError;
  String? _redemptionError;

  @override
  void initState() {
    super.initState();
    _loadMerchant();
    _loadLatestRedemption(showErrors: false);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _merchantApi.dispose();
    _authApiService.dispose();
    super.dispose();
  }

  Future<void> _loadMerchant() async {
    final isInitialLoad = !_hasLoadedProfileOnce;

    if (mounted) {
      setState(() {
        if (isInitialLoad) {
          _isLoadingProfile = true;
        }
        _profileError = null;
      });
    }

    try {
      final merchant =
          await _merchantApi.getCurrentMerchant();

      if (!mounted) return;

      setState(() {
        _merchant = merchant;
        _isLoadingProfile = false;
        _hasLoadedProfileOnce = true;
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) return;

      final message = _friendlyError(error);

      if (isInitialLoad) {
        setState(() {
          _isLoadingProfile = false;
          _profileError = message;
        });
        return;
      }

      setState(() {
        _isLoadingProfile = false;
      });

      _showMessage(
        '$message '
        'Se mantiene el último perfil disponible.',
        isError: true,
      );
    }
  }


  Future<void> _loadLatestRedemption({
    bool showErrors = true,
  }) async {
    try {
      final latest =
          await _merchantApi.getLatestRedemption();

      if (!mounted) return;

      setState(() {
        _latestRedemption = latest;
      });
    } catch (error) {
      if (!mounted || !showErrors) return;

      _showMessage(
        _friendlyError(error),
        isError: true,
      );
    }
  }

  Future<void> _showLatestCanje() async {
    await _loadLatestRedemption();

    if (!mounted) return;

    setState(() {
      _showLatestRedemption = true;
    });

    if (_latestRedemption == null) {
      _showMessage(
        'Este comercio todavía no tiene canjes recientes.',
      );
    }
  }

  void _markLatestAsReviewed() {
    setState(() {
      _showLatestRedemption = false;
    });

    _showMessage(
      'Canje marcado como revisado. '
      'El registro no fue eliminado.',
    );
  }

  Future<void> _refreshScreen() async {
    await _loadMerchant();
    await _loadLatestRedemption(showErrors: false);

    final code = _codeController.text.trim();

    if (code.isEmpty || _validation == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isValidating = true;
      _redemptionError = null;
    });

    try {
      final validation =
          await _merchantApi.validateRedemption(
        code: code,
      );

      if (!mounted) return;

      final normalizedStatus =
          validation.status.trim().toLowerCase();

      if (_isClosedRedemptionStatus(normalizedStatus)) {
        final message =
            _closedRedemptionMessage(normalizedStatus);

        setState(() {
          _isValidating = false;
          _codeController.clear();
          _validation = null;
          _proposalResult = null;
          _redemptionError = null;
        });

        _showMessage(message);
        return;
      }

      setState(() {
        _validation = validation;
        _isValidating = false;
      });
    } on MerchantBackendApiException catch (error) {
      if (!mounted) return;

      final shouldClearCurrentCanje =
          error.statusCode == 400 ||
          error.statusCode == 404 ||
          error.statusCode == 409;

      setState(() {
        _isValidating = false;

        if (shouldClearCurrentCanje) {
          _codeController.clear();
          _validation = null;
          _proposalResult = null;
          _redemptionError = null;
        } else {
          _redemptionError = error.message;
        }
      });

      if (shouldClearCurrentCanje) {
        await _loadLatestRedemption(
          showErrors: false,
        );

        if (!mounted) return;

        setState(() {
          _showLatestRedemption = true;
        });

        _showMessage(
          _friendlyError(error),
        );
      } else {
        _showMessage(
          error.message,
          isError: true,
        );
      }
    } catch (error) {
      if (!mounted) return;

      final message = _friendlyError(error);

      setState(() {
        _isValidating = false;
        _redemptionError = message;
      });

      _showMessage(
        message,
        isError: true,
      );
    }
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _redemptionError =
            'Ingrese el código de canje del atleta.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _redemptionError = null;
      _validation = null;
      _proposalResult = null;
    });

    try {
      final validation =
          await _merchantApi.validateRedemption(
        code: code,
      );

      if (!mounted) return;

      setState(() {
        _validation = validation;
        _isValidating = false;
      });
    } catch (error) {
      if (!mounted) return;

      final message = _friendlyError(error);

      setState(() {
        _isValidating = false;
        _redemptionError = message;
      });

      _showMessage(
        message,
        isError: true,
      );
    }
  }

  Future<void> _proposePoints() async {
    final validation = _validation;
    if (validation == null) return;

    setState(() {
      _isProposing = true;
      _redemptionError = null;
    });

    try {
      final result =
          await _merchantApi.proposeRedemption(
        code: validation.code,
        proposedPoints: validation.requestedPoints,
      );

      if (!mounted) return;

      setState(() {
        _proposalResult = result;
        _isProposing = false;
      });

      await _loadLatestRedemption(
        showErrors: false,
      );

      if (!mounted) return;

      setState(() {
        _showLatestRedemption = true;
      });

      _showMessage(
        'Canje enviado al atleta para confirmación.',
      );
    } catch (error) {
      if (!mounted) return;

      final message = _friendlyError(error);

      setState(() {
        _isProposing = false;
        _redemptionError = message;
      });

      _showMessage(
        message,
        isError: true,
      );
    }
  }

  void _resetRedemption() {
    setState(() {
      _codeController.clear();
      _validation = null;
      _proposalResult = null;
      _redemptionError = null;
    });
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Desea cerrar la sesión de este comercio?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  final refreshToken =
                      await _authTokenStore.getRefreshToken();

                  if (refreshToken != null &&
                      refreshToken.isNotEmpty) {
                    await _authApiService.logout(
                      refreshToken: refreshToken,
                    );
                  }
                } catch (_) {
                  // Aunque falle el cierre remoto,
                  // siempre eliminamos la sesión local.
                }

                await _authTokenStore.clearSession();

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.wifi_off_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(
            seconds: isError ? 5 : 3,
          ),
        ),
      );
  }

  String _friendlyError(Object error) {
    if (error is MerchantBackendApiException) {
      switch (error.code) {
        case 'Authentication.InvalidUser':
          return 'La sesión del comercio no es válida. '
              'Inicie sesión nuevamente.';
        case 'Merchants.Profile.NotFound':
          return 'No se encontró el perfil del comercio.';
        case 'Merchants.Profile.NotActive':
          return 'Este comercio no se encuentra activo.';
        case 'Merchants.Redemption.InvalidCode':
          return 'Ingrese un código de canje válido.';
        case 'Merchants.Redemption.NotFound':
          return 'No se encontró un canje con ese código.';
        case 'Merchants.Redemption.Expired':
          return 'El código de canje ya venció.';
        case 'Merchants.Redemption.NotPending':
          return 'Este canje ya fue confirmado o cancelado '
              'por el atleta.';
        case 'Merchants.Redemption.InvalidPoints':
          return 'La cantidad de puntos del canje no es válida.';
        case 'Merchants.Redemption.InsufficientBalance':
          return 'El atleta no tiene suficientes puntos '
              'disponibles.';
      }

      return 'No fue posible procesar el canje. '
          'Intente nuevamente.';
    }

    if (error is AuthenticatedApiException) {
      return 'No fue posible validar la sesión. '
          'Revise su conexión e intente nuevamente.';
    }

    return 'No fue posible comunicarse con el servicio. '
        'Intente nuevamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Comercio'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                _isLoadingProfile ? null : _refreshScreen,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Historial de canjes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      const MerchantRedemptionsHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshScreen,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28,
            ),
            children: [
              _MerchantHeader(
                merchant: _merchant,
                isLoading: _isLoadingProfile,
                errorMessage: _profileError,
                onRetry: _loadMerchant,
              ),
              const SizedBox(height: 18),
              if (_latestRedemption != null &&
                  _showLatestRedemption) ...[
                _LatestRedemptionCard(
                  redemption: _latestRedemption!,
                  onReviewed: _markLatestAsReviewed,
                ),
                const SizedBox(height: 18),
              ] else ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _showLatestCanje,
                    icon: const Icon(
                      Icons.history_rounded,
                    ),
                    label: const Text(
                      'Ver último canje',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const Text(
                'Validar canje',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Ingrese el código que muestra el atleta. '
                'Primero App KM valida la solicitud y después '
                'usted puede canjear los puntos solicitados.',
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _CodeInputCard(
                controller: _codeController,
                isLoading: _isValidating,
                onValidate: _validateCode,
                onChanged: (_) {
                  if (_redemptionError != null ||
                      _validation != null ||
                      _proposalResult != null) {
                    setState(() {
                      _redemptionError = null;
                      _validation = null;
                      _proposalResult = null;
                    });
                  }
                },
              ),
              if (_redemptionError != null) ...[
                const SizedBox(height: 12),
                _ErrorCard(
                  message: _redemptionError!,
                ),
              ],
              if (_validation != null) ...[
                const SizedBox(height: 18),
                _ValidatedRedemptionCard(
                  validation: _validation!,
                  isProposing: _isProposing,
                  proposalResult: _proposalResult,
                  onPropose: _proposePoints,
                  onReset: _resetRedemption,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MerchantHeader extends StatelessWidget {
  const _MerchantHeader({
    required this.merchant,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final MerchantProfile? merchant;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 138,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: Colors.black38,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final profile = merchant;

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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comercio',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.businessName ?? 'Comercio',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _statusLabel(profile?.status ?? ''),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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

class _CodeInputCard extends StatelessWidget {
  const _CodeInputCard({
    required this.controller,
    required this.isLoading,
    required this.onValidate,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onValidate;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            autocorrect: false,
            onChanged: onChanged,
            onSubmitted: (_) {
              if (!isLoading) {
                onValidate();
              }
            },
            decoration: InputDecoration(
              labelText: 'Código de canje',
              hintText: 'Ej. 482731',
              prefixIcon:
                  const Icon(Icons.qr_code_2_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onValidate,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.verified_outlined,
                    ),
              label: Text(
                isLoading
                    ? 'Validando...'
                    : 'Validar código',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidatedRedemptionCard
    extends StatelessWidget {
  const _ValidatedRedemptionCard({
    required this.validation,
    required this.isProposing,
    required this.proposalResult,
    required this.onPropose,
    required this.onReset,
  });

  final MerchantRedemptionValidation validation;
  final bool isProposing;
  final MerchantRedemptionProposalResult? proposalResult;
  final VoidCallback onPropose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final proposal = proposalResult;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              AppColors.primary.withValues(alpha: 0.22),
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
                  color: Colors.green
                      .withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Código válido',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _InfoRow(
            label: 'Código',
            value: validation.code,
          ),
          const Divider(height: 25),
          _InfoRow(
            label: 'Puntos solicitados',
            value:
                '${validation.requestedPoints} KM Points',
          ),
          const Divider(height: 25),
          _InfoRow(
            label: 'Estado',
            value: _statusLabel(validation.status),
          ),
          const Divider(height: 25),
          _InfoRow(
            label: 'Vence',
            value:
                _formatDateTime(validation.expiresAtUtc),
          ),
          const SizedBox(height: 19),
          if (proposal == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El atleta solicitó '
                      '${validation.requestedPoints} KM Points. '
                      'El comercio no puede modificar esta cantidad.',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (proposal == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    isProposing ? null : onPropose,
                icon: isProposing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.redeem_rounded,
                      ),
                label: Text(
                  isProposing
                      ? 'Enviando...'
                      : 'Canjear puntos',
                ),
              ),
            )
          else
            _ProposalSentCard(
              proposal: proposal,
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed:
                  isProposing ? null : onReset,
              child: const Text(
                'Validar otro código',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalSentCard extends StatelessWidget {
  const _ProposalSentCard({
    required this.proposal,
  });

  final MerchantRedemptionProposalResult proposal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Esperando al atleta',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Canje solicitado por '
            '${proposal.proposedPoints} KM Points.',
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Los puntos todavía no se descuentan. '
            'El atleta debe confirmar o cancelar.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textDark,
                height: 1.35,
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
  final month =
      local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute =
      local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}


class _LatestRedemptionCard extends StatelessWidget {
  const _LatestRedemptionCard({
    required this.redemption,
    required this.onReviewed,
  });

  final MerchantLatestRedemption redemption;
  final VoidCallback onReviewed;

  @override
  Widget build(BuildContext context) {
    final status =
        redemption.status.trim().toLowerCase();

    final isCompleted = status == 'completed';
    final isCancelled =
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected';
    final isPending =
        status == 'awaitingathleteconfirmation' ||
        status == 'pendingathleteconfirmation' ||
        status == 'merchantproposed';

    final Color accentColor = isCompleted
        ? Colors.green.shade700
        : isCancelled
            ? Colors.red.shade700
            : Colors.orange.shade800;

    final IconData statusIcon = isCompleted
        ? Icons.verified_rounded
        : isCancelled
            ? Icons.cancel_rounded
            : Icons.hourglass_top_rounded;

    final String statusText = isCompleted
        ? 'CANJE CONFIRMADO'
        : isCancelled
            ? 'CANJE CANCELADO'
            : isPending
                ? 'PENDIENTE DE CONFIRMACIÓN'
                : _statusLabel(redemption.status).toUpperCase();

    final DateTime eventDate =
        (redemption.completedAtUtc ??
                redemption.merchantProposedAtUtc ??
                redemption.createdAtUtc)
            .toLocal();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: accentColor,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Último canje',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            redemption.athleteDisplayName,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Atleta',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${redemption.points} KM Points',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: accentColor,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isCancelled) ...[
            const SizedBox(height: 10),
            const Text(
              'No se descontaron puntos al atleta.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 15),
          _LatestCanjeDetail(
            label: 'Código',
            value: redemption.code,
          ),
          const SizedBox(height: 7),
          _LatestCanjeDetail(
            label: 'Fecha',
            value: _formatMerchantDate(eventDate),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReviewed,
              icon: const Icon(
                Icons.done_all_rounded,
              ),
              label: const Text(
                'Marcar como revisado',
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Esta acción solo oculta la tarjeta. '
            'El registro del canje permanece guardado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black45,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestCanjeDetail extends StatelessWidget {
  const _LatestCanjeDetail({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatMerchantDate(DateTime value) {
  final day =
      value.day.toString().padLeft(2, '0');
  final month =
      value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  final hour12 =
      value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute =
      value.minute.toString().padLeft(2, '0');
  final period =
      value.hour < 12 ? 'a. m.' : 'p. m.';

  return '$day/$month/$year • '
      '$hour12:$minute $period';
}

bool _isClosedRedemptionStatus(String value) {
  switch (value) {
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

String _closedRedemptionMessage(String value) {
  switch (value) {
    case 'completed':
      return 'El atleta confirmó el canje. '
          'El canje fue completado.';
    case 'expired':
      return 'El código de canje venció.';
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return 'El atleta canceló el canje.';
    default:
      return 'El canje ya no está pendiente.';
  }
}

String _statusLabel(String value) {
  switch (value.toLowerCase()) {
    case 'active':
      return 'Activo';
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
    case 'awaitingathleteconfirmation':
      return 'Esperando confirmación del atleta';
    case 'rejected':
      return 'Cancelado';
    default:
      return value.isEmpty ? 'Sin estado' : value;
  }
}
