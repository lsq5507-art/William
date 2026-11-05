import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/space_store.dart';

/// SCR-CM-03 weak confirm before posting custom day media.
class CustomMediaConfirmScreen extends StatefulWidget {
  final Uint8List bytes;
  final String petName;

  const CustomMediaConfirmScreen({
    super.key,
    required this.bytes,
    required this.petName,
  });

  @override
  State<CustomMediaConfirmScreen> createState() =>
      _CustomMediaConfirmScreenState();
}

class _CustomMediaConfirmScreenState extends State<CustomMediaConfirmScreen> {
  bool confirmed = false;
  bool posting = false;
  final caption = TextEditingController();

  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!confirmed || posting) {
      if (!confirmed) {
        final s = S(context.read<SpaceStore>().localeZh);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.get('custom.confirm.checkbox_hint'))),
        );
      }
      return;
    }
    setState(() => posting = true);
    Navigator.of(context).pop<CustomMediaConfirmResult>(
      CustomMediaConfirmResult(
        bytes: widget.bytes,
        caption: caption.text.trim(),
        dayConfirmed: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: posting ? null : () => Navigator.of(context).pop(),
          child: Text(s.get('custom.confirm.cancel')),
        ),
        leadingWidth: 88,
        title: Text(
          s.get('custom.confirm.title'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.memory(
                  widget.bytes,
                  fit: BoxFit.cover,
                  semanticLabel: s.fmt(
                    'custom.confirm.preview_a11y',
                    {'name': widget.petName},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.fmt('custom.confirm.publish_to', {'name': widget.petName}),
              style: const TextStyle(fontSize: 14.5, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: posting
                  ? null
                  : () => setState(() => confirmed = !confirmed),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Checkbox(
                        value: confirmed,
                        onChanged: posting
                            ? null
                            : (v) => setState(() => confirmed = v ?? false),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.get('custom.confirm.checkbox'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: caption,
              enabled: !posting,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: s.get('custom.confirm.caption_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFBBBBBB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: (!confirmed || posting) ? null : _submit,
                child: posting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.get('custom.confirm.cta')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomMediaConfirmResult {
  final Uint8List bytes;
  final String caption;
  final bool dayConfirmed;

  const CustomMediaConfirmResult({
    required this.bytes,
    required this.caption,
    required this.dayConfirmed,
  });
}
