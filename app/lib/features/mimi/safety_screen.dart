import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n.dart';
import '../../data/content_service.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P36 — Safety contacts: campus & national helplines. Ships offline in the
/// APK; works with no internet. Sample campus numbers are shown greyed.
class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.l10n;
    return TccScaffold(
      title: t.safetyContacts,
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(contentServiceProvider).load('safety_contacts'),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: TCC.accent));
          }
          final data = snap.data!;
          final sections = (data['sections'] as List?) ?? const [];
          final disclaimer = data['disclaimer'] as String?;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _emergencyBanner(t),
              const SizedBox(height: 20),
              ...sections.map((s) => _section(context, t, s as Map)),
              if (disclaimer != null) ...[
                const SizedBox(height: 12),
                Text(disclaimer,
                    style: const TextStyle(
                        color: TCC.textDisabled, fontSize: 11.5, height: 1.5)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _emergencyBanner(L t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: TCC.danger.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(TCC.radius),
        border: Border.all(color: TCC.danger.withValues(alpha: 0.5)),
        boxShadow: glow(TCC.danger, blur: 20, opacity: 0.22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: TCC.danger.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_share_rounded,
                color: TCC.danger, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.inDangerCall,
                    style: const TextStyle(
                        color: TCC.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(t.worksOffline,
                    style: const TextStyle(color: TCC.textMuted, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, L t, Map section) {
    final title = section['title'] as String? ?? '';
    final note = section['note'] as String?;
    final contacts = (section['contacts'] as List?) ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(note,
                  style: const TextStyle(
                      color: TCC.warning, fontSize: 11.5, height: 1.4)),
            ),
          ...contacts.map((c) => _contactRow(context, t, c as Map)),
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context, L t, Map c) {
    final name = c['name'] as String? ?? 'Unknown';
    final phone = c['phone'] as String?;
    final alt = c['alt'] as String?;
    final disabled = phone == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TCC.surface,
        borderRadius: BorderRadius.circular(TCC.radiusSm),
        border: Border.all(color: TCC.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: disabled ? TCC.textDisabled : TCC.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  disabled
                      ? t.numberComingSoon
                      : (alt != null ? '$phone · or $alt' : phone),
                  style: TextStyle(
                      color: disabled ? TCC.textDisabled : TCC.textMuted,
                      fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (!disabled) ...[
            IconButton(
              tooltip: t.copy,
              icon: const Icon(Icons.copy_rounded, color: TCC.textMuted, size: 20),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: phone));
                if (context.mounted) poa(context, t.copied(phone));
              },
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: () => _call(phone),
              style: FilledButton.styleFrom(
                backgroundColor: TCC.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.call_rounded, size: 18),
              label: Text(t.call),
            ),
          ] else
            const Icon(Icons.lock_clock_rounded,
                color: TCC.textDisabled, size: 20),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
