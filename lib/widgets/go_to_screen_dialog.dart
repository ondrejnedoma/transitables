import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

class GoToScreenDialog extends StatefulWidget {
  const GoToScreenDialog({super.key});

  /// Returns the entered screen number, or null if cancelled / dismissed.
  static Future<int?> show(BuildContext context) => showDialog<int>(
    context: context,
    builder: (_) => const GoToScreenDialog(),
  );

  @override
  State<GoToScreenDialog> createState() => _GoToScreenDialogState();
}

class _GoToScreenDialogState extends State<GoToScreenDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(int.tryParse(_controller.text));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to screen'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Screen number'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Go')),
      ],
    );
  }
}
