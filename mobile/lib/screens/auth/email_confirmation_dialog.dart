import 'package:flutter/material.dart';

/// Wait for the dialog's reverse transition before navigating the parent route.
Future<bool> showEmailConfirmationDialog({
  required BuildContext context,
  required String email,
  required Future<void> Function(String code) confirm,
}) async {
  FocusScope.of(context).unfocus();
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => EmailConfirmationDialog(email: email, confirm: confirm),
  );
  final confirmed = await navigator.push(route);
  await route.completed;
  return confirmed == true;
}

class EmailConfirmationDialog extends StatefulWidget {
  const EmailConfirmationDialog({
    super.key,
    required this.email,
    required this.confirm,
  });

  final String email;
  final Future<void> Function(String code) confirm;

  @override
  State<EmailConfirmationDialog> createState() => _EmailConfirmationDialogState();
}

class _EmailConfirmationDialogState extends State<EmailConfirmationDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Ingresa el código de confirmación.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    var confirmed = false;
    try {
      await widget.confirm(code);
      confirmed = true;
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted || !confirmed) return;
    // Rebuild PopScope before popping so the completed request can close it.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: const Text('Confirmar correo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingresa el código enviado a ${widget.email}.'),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofocus: true,
                onSubmitted: (_) => _confirm(),
                decoration: const InputDecoration(labelText: 'Código de confirmación'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _confirm,
            child: Text(_submitting ? 'Confirmando…' : 'Continuar'),
          ),
        ],
      ),
    );
  }
}
