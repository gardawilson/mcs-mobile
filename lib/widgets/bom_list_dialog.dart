import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/scan_processor_view_model.dart';
import '../models/bom_part_model.dart';

class BomListDialog extends StatefulWidget {
  final String message;
  final List<BomPart> parts;
  final String noSO;
  final String assetCode;
  final String assetName;

  const BomListDialog({
    Key? key,
    required this.message,
    required this.parts,
    required this.noSO,
    required this.assetCode,
    required this.assetName,
  }) : super(key: key);

  @override
  State<BomListDialog> createState() => _BomListDialogState();
}

class _BomListDialogState extends State<BomListDialog> {
  bool _isSubmitting = false;
  String _submitMessage = '';
  late List<bool> _checkedParts;

  @override
  void initState() {
    super.initState();
    _checkedParts = List.filled(widget.parts.length, false);
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _submitMessage = '';
    });

    final checklist = <Map<String, dynamic>>[];
    for (int i = 0; i < _checkedParts.length; i++) {
      final part = widget.parts[i];
      if (part.level != 'relationship') {
        checklist.add({
          'IdBOM': part.id,
          'IsExist': _checkedParts[i],
        });
      }
    }


    final viewModel = Provider.of<ScanProcessorViewModel>(context, listen: false);
    final result = await viewModel.submitAssetWithParts(
      noSO: widget.noSO,
      assetCode: widget.assetCode,
      assetName: widget.assetName,
      checklist: checklist,
    );

    setState(() {
      _isSubmitting = false;
      _submitMessage = result.message;
    });

    if (result.success) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.message),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(widget.parts.length, (index) {
              final part = widget.parts[index];

              if (part.level == 'relationship') {
                // Tampilkan sebagai header
                return ListTile(
                  title: Text(
                    part.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                );
              } else {
                // Tampilkan sebagai item dengan checkbox
                return CheckboxListTile(
                  title: Text(part.name),
                  value: _checkedParts[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _checkedParts[index] = value ?? false;
                    });
                  },
                );
              }
            }),

            if (_submitMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _submitMessage,
                  style: TextStyle(
                    color: _submitMessage.toLowerCase().contains('berhasil')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7a1b0c),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
