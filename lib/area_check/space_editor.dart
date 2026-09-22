import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'area_check_model.dart';
import 'check_ui.dart';

class SpaceEditor extends StatefulWidget {
  const SpaceEditor({super.key, required this.space, required this.site});
  final AreaSpace space;
  final bool site;
  @override
  State<SpaceEditor> createState() => _SpaceEditorState();
}

class _SpaceEditorState extends State<SpaceEditor> {
  final form = GlobalKey<FormState>();
  late AreaSpace s = widget.space;
  bool confirmed = false;
  String? error;
  int unitRevision = 0;
  Widget number(
    String label,
    double value,
    void Function(double) update, {
    bool integer = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey('${s.unit}:$label'),
      initialValue: '$value',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        final n = double.tryParse(v ?? '');
        return n == null ||
                !n.isFinite ||
                n < 0 ||
                (integer && (n < 1 || n != n.roundToDouble()))
            ? 'Enter a valid ${integer ? 'positive whole number' : 'non-negative number'}.'
            : null;
      },
      onChanged: (v) {
        final n = double.tryParse(v);
        if (n != null && n.isFinite) {
          setState(() {
            update(n);
            confirmed = false;
          });
        }
      },
    ),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    title: const Row(
      children: [
        CheckIcon(Icons.straighten_rounded, size: 40),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Space measurements',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'One space at a time. Measure, add details, and save.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: CheckPalette.muted,
                  ),
                ),
              ),
              TextFormField(
                initialValue: s.name,
                decoration: const InputDecoration(labelText: 'Space name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name.' : null,
                onChanged: (v) => s.name = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SpaceCategory>(
                initialValue: s.category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Area category'),
                items: SpaceCategory.values
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => s.category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MeasureUnit>(
                key: ValueKey(unitRevision),
                initialValue: s.unit,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Measurement unit',
                ),
                items: MeasureUnit.values
                    .map(
                      (v) => DropdownMenuItem(value: v, child: Text(v.label)),
                    )
                    .toList(),
                onChanged: (v) async {
                  if (v == s.unit) return;
                  final accepted = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Change input unit?'),
                      content: const Text(
                        'Enter dimensions again in the new unit. The current dimensions in this editor will be cleared.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Change unit'),
                        ),
                      ],
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      unitRevision++;
                      if (accepted == true) {
                        s.unit = v!;
                        s.length = 0;
                        s.width = 0;
                        s.lengthInches = 0;
                        s.widthInches = 0;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              number(
                s.unit.isArea
                    ? 'Area (${s.unit == MeasureUnit.squareFeet ? 'sq ft' : 'sq m'})'
                    : 'Length (${s.unit == MeasureUnit.feetInches ? 'feet' : s.unit.label})',
                s.length,
                (v) => s.length = v,
              ),
              if (s.unit == MeasureUnit.feetInches)
                number(
                  'Length inches (0–11)',
                  s.lengthInches,
                  (v) => s.lengthInches = v,
                ),
              if (!s.unit.isArea)
                number(
                  '${s.category == SpaceCategory.internalWall ? 'Thickness' : 'Width'} (${s.unit == MeasureUnit.feetInches ? 'feet' : s.unit.label})',
                  s.width,
                  (v) => s.width = v,
                ),
              if (s.unit == MeasureUnit.feetInches)
                number(
                  '${s.category == SpaceCategory.internalWall ? 'Thickness' : 'Width'} inches (0–11)',
                  s.widthInches,
                  (v) => s.widthInches = v,
                ),
              number(
                'Quantity',
                s.quantity.toDouble(),
                (v) => s.quantity = v.toInt(),
                integer: true,
              ),
              TextFormField(
                initialValue: s.notes,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                onChanged: (v) => s.notes = v,
              ),
              const SizedBox(height: 12),
              CheckSurface(
                color: const Color(0xFFEFF5FF),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SPACE AREA',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: CheckPalette.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${s.area.toStringAsFixed(2)} sq ft',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.source,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CheckPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (s.photo != null)
                Image.memory(
                  base64Decode(s.photo!),
                  height: 120,
                  semanticLabel: 'Site photograph',
                ),
              if (widget.site)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final photo = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1200,
                        imageQuality: 65,
                      );
                      if (photo != null) {
                        final bytes = await photo.readAsBytes();
                        if (bytes.length > 5 * 1024 * 1024) {
                          if (mounted) {
                            setState(
                              () => error = 'Choose a photo smaller than 5 MB.',
                            );
                          }
                          return;
                        }
                        if (mounted) {
                          setState(() => s.photo = base64Encode(bytes));
                        }
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => error =
                              'Could not open photos. Try again or continue without a photo.',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    s.photo == null
                        ? 'Attach optional photo'
                        : 'Replace attached photo',
                  ),
                ),
              if (s.area > 10000)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: confirmed,
                  onChanged: (v) => setState(() => confirmed = v!),
                  title: const Text(
                    'This unusually large measurement is correct.',
                  ),
                ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          if (s.error != null) {
            setState(() => error = s.error);
            return;
          }
          if (s.area > 10000 && !confirmed) {
            setState(() => error = 'Confirm the unusually large area.');
            return;
          }
          Navigator.pop(context, s);
        },
        child: const Text('Save space'),
      ),
    ],
  );
}
