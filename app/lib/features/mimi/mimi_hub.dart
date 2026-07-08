import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_state.dart';
import '../../core/l10n.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P32 — Mimi: the personal hub tab. Everything the user owns lives here,
/// framed by the app's core promise: it never leaves the phone.
class MimiHub extends ConsumerWidget {
  const MimiHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final t = ref.l10n;

    final rows = <_HubRow>[
      _HubRow(
        icon: Icons.folder_copy_rounded,
        tint: TCC.somo,
        title: t.library,
        subtitle: t.hubLibrarySub,
        onTap: () => context.push('/library'),
      ),
      _HubRow(
        icon: Icons.school_rounded,
        tint: TCC.accent,
        title: t.studySets,
        subtitle: t.hubStudySub,
        onTap: () => context.push('/library'),
      ),
      _HubRow(
        icon: Icons.shield_rounded,
        tint: TCC.danger,
        title: t.safetyContacts,
        subtitle: t.hubSafetySub,
        onTap: () => context.push('/safety'),
      ),
      _HubRow(
        icon: Icons.settings_rounded,
        tint: TCC.textMuted,
        title: t.settings,
        subtitle: t.hubSettingsSub,
        onTap: () => context.push('/settings'),
      ),
    ];

    return TccScaffold(
      showBack: false,
      title: t.tabMe,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _header(context, lang, t),
          const SizedBox(height: 24),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _rowCard(context, r),
              )),
          const SizedBox(height: 20),
          _footer(context, t),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, LangPref lang, L t) {
    final line = lang.kiembuGreetings
        ? 'Wĩ mwega — ${t.yoursAlone}'
        : t.yoursAlone;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: glow(TCC.primary, blur: 20, opacity: 0.4),
            image: const DecorationImage(
              image: AssetImage('assets/brand/profile.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.yourSpace,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                line,
                style: const TextStyle(color: TCC.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowCard(BuildContext context, _HubRow r) {
    return TccCard(
      onTap: r.onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: r.tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: r.tint.withValues(alpha: 0.4)),
            ),
            child: Icon(r.icon, color: r.tint, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: const TextStyle(
                        color: TCC.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(r.subtitle,
                    style: const TextStyle(color: TCC.textMuted, fontSize: 12.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: TCC.textDisabled),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, L t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TCC.surface2,
        borderRadius: BorderRadius.circular(TCC.radiusSm),
        border: Border.all(color: TCC.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: TCC.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${t.staysOnPhone} 🔒',
              style: const TextStyle(color: TCC.textMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubRow {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _HubRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
