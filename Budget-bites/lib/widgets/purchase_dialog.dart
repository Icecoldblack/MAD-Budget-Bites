import 'package:flutter/material.dart';

import '../data/purchase_repository.dart';
import '../models/purchase.dart';
import '../utils/dates.dart';
import '../utils/money.dart';

// Logs a new purchase, or edits one. Closes with true when saved.
class PurchaseDialog extends StatefulWidget {
  final PurchaseRepository purchaseRepository;
  final int mealId;

  // Null when logging a new purchase.
  final Purchase? purchase;

  const PurchaseDialog({
    super.key,
    required this.purchaseRepository,
    required this.mealId,
    this.purchase,
  });

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _purchasedAt = DateTime.now();
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final purchase = widget.purchase;
    if (purchase != null) {
      _priceController.text = formatMinor(purchase.actualPriceMinor);
      _noteController.text = purchase.note;
      _purchasedAt = purchase.purchasedAt;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchasedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    // Change the date but keep the time of day.
    setState(() {
      _purchasedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _purchasedAt.hour,
        _purchasedAt.minute,
      );
    });
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter what you paid.';
    }
    if (parseMinor(value) == null) {
      return 'Enter a price like 6.50 (zero or more, up to 2 decimals).';
    }
    return null;
  }

  Future<void> _save() async {
    // Double tap guard: a second tap can arrive before the button turns
    // off, so ignore it while a save is running.
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final purchase = Purchase(
      id: widget.purchase?.id,
      mealId: widget.mealId,
      purchasedAt: _purchasedAt,
      actualPriceMinor: parseMinor(_priceController.text)!,
      note: _noteController.text.trim(),
    );

    try {
      if (widget.purchase == null) {
        await widget.purchaseRepository.insertPurchase(purchase);
      } else {
        await widget.purchaseRepository.updatePurchase(purchase);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save. Try again.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.purchase != null;

    String buttonText = 'Log purchase';
    if (isEditing) {
      buttonText = 'Save';
    }
    if (_isSaving) {
      buttonText = 'Saving...';
    }

    return AlertDialog(
      title: Text(isEditing ? 'Edit purchase' : 'Log purchase'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price paid',
                hintText: '6.50',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validatePrice,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Date: ${formatDate(_purchasedAt)}')),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ],
            ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        // onPressed: null turns the button off.
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(buttonText),
        ),
      ],
    );
  }
}
