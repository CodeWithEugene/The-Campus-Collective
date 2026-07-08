import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_state.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P23 — Sheng WhatsApp-status ad copywriter for student side hustles.
class CopywriterScreen extends ConsumerStatefulWidget {
  const CopywriterScreen({super.key});
  @override
  ConsumerState<CopywriterScreen> createState() => _CopywriterScreenState();
}

class _CopywriterScreenState extends ConsumerState<CopywriterScreen> {
  static const _tones = [
    ('Poa', 'chill', Icons.sentiment_satisfied_rounded),
    ('Hype', 'hype', Icons.local_fire_department_rounded),
    ('Formal', 'formal', Icons.business_center_rounded),
  ];

  final _product = TextEditingController();
  final _price = TextEditingController();
  final _editCtrl = TextEditingController();

  String _tone = 'chill';
  String _ad = '';
  bool _busy = false;
  bool _editing = false;

  @override
  void dispose() {
    _product.dispose();
    _price.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final lang = ref.read(langProvider);
    final what = _product.text.trim();
    if (what.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(lang.flavor == 'english' ? 'Please write what you are selling first.' : 'Andika unauza nini kwanza.')));
      return;
    }
    setState(() {
      _busy = true;
      _editing = false;
      _ad = '';
    });
    final gemma = ref.read(gemmaProvider);
    final price = _price.text.trim();
    final prompt = 'Write a short, catchy WhatsApp Status advert in Sheng for a '
        'student selling: $what${price.isEmpty ? '' : ' at KSh $price'}. '
        'Tone: $_tone. Add 2-3 emojis and a call to action to DM.';
    final buffer = StringBuffer();
    try {
      await for (final token in gemma.chat(prompt, agent: 'hustle')) {
        buffer.write(token);
        if (mounted) setState(() => _ad = buffer.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _copy() {
    final lang = ref.read(langProvider);
    Clipboard.setData(ClipboardData(text: _ad.trim()));
    poa(context, lang.flavor == 'english' ? 'Copied!' : 'Imenakiliwa!');
  }

  void _share() {
    if (_ad.trim().isEmpty) return;
    Share.share(_ad.trim());
  }

  void _toggleEdit() {
    setState(() {
      if (_editing) {
        _ad = _editCtrl.text;
      } else {
        _editCtrl.text = _ad;
      }
      _editing = !_editing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return TccScaffold(
      title: lang.flavor == 'english' ? 'Ad Copywriter' : 'Mwandishi wa Matangazo',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(lang.flavor == 'english' ? 'What are you selling?' : 'Nini unauza?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _product,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: TCC.text),
            decoration: InputDecoration(
              hintText: lang.flavor == 'english' ? 'e.g. Fresh mandazi, thrift jeans, henna designs' : 'e.g. Mandazi moto, thrift jeans, urembo wa henna',
              prefixIcon: const Icon(Icons.storefront_rounded, color: TCC.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: TCC.text),
            decoration: InputDecoration(
              labelText: lang.flavor == 'english' ? 'Price (optional)' : 'Bei (hiari)',
              prefixText: 'KSh ',
              prefixStyle: const TextStyle(color: TCC.textMuted),
              prefixIcon: const Icon(Icons.sell_rounded, color: TCC.textMuted),
            ),
          ),
          const SizedBox(height: 18),
          Text(lang.flavor == 'english' ? 'Tone' : 'Mhemko',
              style: const TextStyle(
                  color: TCC.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final t in _tones) ...[
                TccChip(
                  label: t.$2 == 'chill'
                      ? (lang.flavor == 'english' ? 'Chill' : 'Poa')
                      : t.$1,
                  icon: t.$3,
                  selected: _tone == t.$2,
                  tint: TCC.hustle,
                  onTap: () {
                    setState(() => _tone = t.$2);
                    if (_ad.isNotEmpty) _generate();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            style: FilledButton.styleFrom(
              backgroundColor: TCC.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(
              _busy
                  ? (lang.flavor == 'english' ? 'Generating...' : 'Inatengeneza…')
                  : (lang.flavor == 'english' ? 'Generate' : 'Tengeneza'),
            ),
          ),
          const SizedBox(height: 24),
          if (_ad.isNotEmpty || _busy) _preview(lang),
          if (_ad.trim().isNotEmpty && !_busy) ...[
            const SizedBox(height: 16),
            _actions(lang),
          ],
        ],
      ),
    );
  }

  Widget _preview(LangPref lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Color(0xFF25D366)),
            const SizedBox(width: 8),
            Text(
                lang.flavor == 'english'
                    ? 'WhatsApp Status preview'
                    : 'Onyesho la Status ya WhatsApp',
                style: const TextStyle(color: TCC.textMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF075E54), Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.circular(TCC.radius),
            boxShadow: glow(const Color(0xFF25D366), opacity: 0.22, blur: 30),
          ),
          child: _editing
              ? TextField(
                  controller: _editCtrl,
                  maxLines: null,
                  autofocus: true,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  _ad.trim().isEmpty ? '…' : _ad.trim(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.5,
                      fontWeight: FontWeight.w500),
                ),
        ),
      ],
    );
  }

  Widget _actions(LangPref lang) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(lang.flavor == 'english' ? 'Copy' : 'Nakili'),
            style: _ghost(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleEdit,
            icon: Icon(_editing ? Icons.check_rounded : Icons.edit_rounded,
                size: 18),
            label: Text(_editing
                ? (lang.flavor == 'english' ? 'Done' : 'Sawa')
                : (lang.flavor == 'english' ? 'Edit' : 'Hariri')),
            style: _ghost(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(lang.flavor == 'english' ? 'Share' : 'Sambaza'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _ghost() => OutlinedButton.styleFrom(
        foregroundColor: TCC.text,
        side: const BorderSide(color: TCC.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
      );
}
