import 'package:flutter/material.dart';

import '../data/purchase_repository.dart';
import '../models/purchase.dart';
import '../utils/dates.dart';
import '../utils/money.dart';

/// A form in a dialog for logging a new purchase or editing one.
/// It closes with true when the purchase was saved.
class PurchaseDialog extends StatefulWidget {
  final PurchaseRepository purchaseRepository;
  final int mealId;

  /// The purchase to edit. Null when logging a new purchase.
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

    // Keep the time of day and only change the date.
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
    if (!_formKey.currentState!.validate()) return;

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
      setState(() => _errorMessage = 'Could not save. Try again.');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.purchase != null;

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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save' : 'Log purchase'),
        ),
      ],
    );
  }
}
