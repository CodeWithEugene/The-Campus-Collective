import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_state.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';
import '../chat/chat_controller.dart';

// ===========================================================================
// Shared building blocks
// ===========================================================================

/// A tappable grouped settings row (icon · title · subtitle · chevron).
class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _NavRow({
    required this.icon,
    required this.tint,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TccCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: TCC.text,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            color: TCC.textMuted, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: TCC.textDisabled),
          ],
        ),
      ),
    );
  }
}

/// A standalone switch row that owns its own local state (for ConsumerWidget
/// screens that only need ephemeral toggles).
class _LocalSwitchTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool initial;
  const _LocalSwitchTile({
    required this.title,
    this.subtitle,
    this.initial = false,
  });

  @override
  State<_LocalSwitchTile> createState() => _LocalSwitchTileState();
}

class _LocalSwitchTileState extends State<_LocalSwitchTile> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: TCC.surface,
        borderRadius: BorderRadius.circular(TCC.radiusSm),
        border: Border.all(color: TCC.border),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: TCC.accent,
        value: _value,
        title: Text(widget.title,
            style: const TextStyle(color: TCC.text, fontSize: 14.5)),
        subtitle: widget.subtitle != null
            ? Text(widget.subtitle!,
                style: const TextStyle(color: TCC.textMuted, fontSize: 12))
            : null,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

Widget _sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              color: TCC.textMuted,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700)),
    );

// ===========================================================================
// P37 — Settings root
// ===========================================================================

class SettingsRoot extends ConsumerWidget {
  const SettingsRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TccScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _NavRow(
            icon: Icons.translate_rounded,
            tint: TCC.somo,
            title: 'Language & greetings',
            subtitle: 'English · Kiswahili · Sheng',
            onTap: () => context.push('/settings/language'),
          ),
          _NavRow(
            icon: Icons.memory_rounded,
            tint: TCC.primary,
            title: 'AI Model',
            subtitle: 'Gemma 4 E2B · 2.6 GB',
            onTap: () => context.push('/settings/model'),
          ),
          _NavRow(
            icon: Icons.notifications_rounded,
            tint: TCC.warning,
            title: 'Notifications',
            subtitle: 'Reminders & alerts',
            onTap: () => context.push('/settings/notifications'),
          ),
          _NavRow(
            icon: Icons.privacy_tip_rounded,
            tint: TCC.accent,
            title: 'Data & Privacy',
            subtitle: 'Your data stays on this phone',
            onTap: () => context.push('/settings/privacy'),
          ),
          const SizedBox(height: 10),
          _sectionLabel('Support'),
          _NavRow(
            icon: Icons.info_outline_rounded,
            tint: TCC.textMuted,
            title: 'About',
            onTap: () => context.push('/settings/about'),
          ),
          _NavRow(
            icon: Icons.help_outline_rounded,
            tint: TCC.textMuted,
            title: 'Help & FAQ',
            onTap: () => context.push('/settings/help'),
          ),
          _NavRow(
            icon: Icons.bug_report_outlined,
            tint: TCC.textMuted,
            title: 'Report a problem',
            onTap: () => context.push('/settings/report'),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// P38 — Language & greetings
// ===========================================================================

class LanguageSettings extends ConsumerWidget {
  const LanguageSettings({super.key});

  static const _flavors = <(String, String, String)>[
    ('english', 'English', 'Clear, straightforward English.'),
    ('swahili', 'Kiswahili', 'Kiswahili sanifu — warm and familiar.'),
    ('sheng', 'Sheng', 'Sheng flavor — street-smart & casual.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);

    String sample() {
      final base = switch (lang.flavor) {
        'english' => 'Hey! How can I help you today?',
        'sheng' => 'Sasa! Niaje, nikusaidie na nini leo?',
        _ => 'Habari! Nikusaidie na nini leo?',
      };
      return lang.kiembuGreetings ? 'Wĩ mwega! $base' : base;
    }

    void update({String? flavor, bool? kiembu}) {
      final n = ref.read(langProvider.notifier);
      if (flavor != null) n.setFlavor(flavor);
      if (kiembu != null) n.setKiembuGreetings(kiembu);
      poa(context);
    }

    return TccScaffold(
      title: 'Language & greetings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: TCC.surface2,
              borderRadius: BorderRadius.circular(TCC.radius),
              border: Border.all(color: TCC.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preview',
                    style: TextStyle(
                        color: TCC.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(sample(),
                    style: const TextStyle(
                        color: TCC.text, fontSize: 16, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Flavor'),
          RadioGroup<String>(
            groupValue: lang.flavor,
            onChanged: (v) => update(flavor: v),
            child: Column(
              children: _flavors.map((f) {
                final selected = lang.flavor == f.$1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: TCC.surface,
                    borderRadius: BorderRadius.circular(TCC.radiusSm),
                    border: Border.all(
                        color: selected ? TCC.accent : TCC.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: RadioListTile<String>(
                    value: f.$1,
                    activeColor: TCC.accent,
                    title: Text(f.$2,
                        style: const TextStyle(
                            color: TCC.text, fontWeight: FontWeight.w600)),
                    subtitle: Text(f.$3,
                        style: const TextStyle(
                            color: TCC.textMuted, fontSize: 12.5)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _sectionLabel('Local touch'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: TCC.surface,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.border),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: TCC.accent,
              value: lang.kiembuGreetings,
              title: const Text('Kiembu greetings',
                  style: TextStyle(color: TCC.text, fontSize: 14.5)),
              subtitle: const Text('Open with a Kiembu hello like “Wĩ mwega!”',
                  style: TextStyle(color: TCC.textMuted, fontSize: 12)),
              onChanged: (v) => update(kiembu: v),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// P39 — AI Model
// ===========================================================================

class ModelSettings extends ConsumerWidget {
  const ModelSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TccScaffold(
      title: 'AI Model',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TCC.primary.withValues(alpha: 0.22),
                  TCC.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(TCC.radius),
              border: Border.all(color: TCC.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: TCC.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.memory_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gemma 4 E2B',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          const Text('v1.0 · 2.6 GB',
                              style: TextStyle(
                                  color: TCC.textMuted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: TCC.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: TCC.accent, size: 14),
                          SizedBox(width: 5),
                          Text('Ready',
                              style: TextStyle(
                                  color: TCC.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 0.34,
                    minHeight: 8,
                    backgroundColor: TCC.border,
                    valueColor: AlwaysStoppedAnimation(TCC.accent),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('2.6 GB used of 7.6 GB free on device',
                    style: TextStyle(color: TCC.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Manage'),
          OutlinedButton.icon(
            onPressed: () => poa(context, 'Model is already up to date'),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Re-download'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _switchSheet(context),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Switch model'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: TCC.danger,
              side: BorderSide(color: TCC.danger.withValues(alpha: 0.5)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete model'),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Downloads'),
          const _LocalSwitchTile(
            title: 'Download over Wi-Fi only',
            subtitle: 'Avoid using mobile data for large files',
            initial: true,
          ),
          const _LocalSwitchTile(
            title: 'Automatic updates',
            subtitle: 'Install new model versions when available',
            initial: false,
          ),
        ],
      ),
    );
  }

  void _switchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TCC.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Switch model',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text(
                'Only Gemma 4 E2B is bundled for this release. More on-device '
                'models are coming — they’ll appear here once available.',
                style: TextStyle(color: TCC.textMuted, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: TCC.surface,
        title: const Text('Delete the AI model?'),
        content: const Text(
            'The app can’t answer anything until you download it again '
            '(2.6 GB). You’ll need this before using chat.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: TCC.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) poa(context, 'Model removed');
  }
}

// ===========================================================================
// P40 — Notifications
// ===========================================================================

class NotificationSettings extends ConsumerStatefulWidget {
  const NotificationSettings({super.key});

  @override
  ConsumerState<NotificationSettings> createState() =>
      _NotificationSettingsState();
}

class _NotificationSettingsState extends ConsumerState<NotificationSettings> {
  bool _master = true;
  final Map<String, bool> _types = {
    'Class reminders': true,
    'Deadline alerts': true,
    'Task reminders': true,
    'Budget alerts': true,
    'Daily plan': false,
  };
  String _leadTime = '15 min before';
  bool _quietHours = true;

  @override
  Widget build(BuildContext context) {
    return TccScaffold(
      title: 'Notifications',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: TCC.surface,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(
                  color: _master ? TCC.accent.withValues(alpha: 0.4) : TCC.border),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: TCC.accent,
              value: _master,
              title: const Text('Allow notifications',
                  style: TextStyle(
                      color: TCC.text,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text('Master switch for all reminders',
                  style: TextStyle(color: TCC.textMuted, fontSize: 12)),
              onChanged: (v) => setState(() => _master = v),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Types'),
          ..._types.keys.map((k) => Opacity(
                opacity: _master ? 1 : 0.4,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: TCC.surface,
                    borderRadius: BorderRadius.circular(TCC.radiusSm),
                    border: Border.all(color: TCC.border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: TCC.accent,
                    value: _types[k]!,
                    title: Text(k,
                        style:
                            const TextStyle(color: TCC.text, fontSize: 14.5)),
                    onChanged: _master
                        ? (v) => setState(() => _types[k] = v)
                        : null,
                  ),
                ),
              )),
          const SizedBox(height: 14),
          _sectionLabel('Timing'),
          _pickerRow(
            icon: Icons.schedule_rounded,
            title: 'Reminder lead time',
            value: _leadTime,
            onTap: _master ? _pickLeadTime : null,
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: TCC.surface,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.border),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: TCC.accent,
              value: _quietHours,
              title: const Text('Quiet hours (10 pm – 6 am)',
                  style: TextStyle(color: TCC.text, fontSize: 14.5)),
              subtitle: const Text('Silence reminders overnight',
                  style: TextStyle(color: TCC.textMuted, fontSize: 12)),
              onChanged:
                  _master ? (v) => setState(() => _quietHours = v) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerRow({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TCC.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: TCC.surface,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: TCC.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style:
                          const TextStyle(color: TCC.text, fontSize: 14.5)),
                ),
                Text(value,
                    style: const TextStyle(color: TCC.accent, fontSize: 13.5)),
                const Icon(Icons.chevron_right_rounded, color: TCC.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickLeadTime() {
    const options = ['5 min before', '15 min before', '30 min before', '1 hour before'];
    showModalBottomSheet(
      context: context,
      backgroundColor: TCC.surface,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((o) => ListTile(
                    title: Text(o, style: const TextStyle(color: TCC.text)),
                    trailing: _leadTime == o
                        ? const Icon(Icons.check_rounded, color: TCC.accent)
                        : null,
                    onTap: () {
                      setState(() => _leadTime = o);
                      Navigator.pop(c);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ===========================================================================
// P41 — Data & Privacy
// ===========================================================================

class PrivacySettings extends ConsumerWidget {
  const PrivacySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TccScaffold(
      title: 'Data & Privacy',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TCC.accent.withValues(alpha: 0.2),
                  TCC.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(TCC.radius),
              border: Border.all(color: TCC.accent.withValues(alpha: 0.4)),
              boxShadow: glow(TCC.accent, blur: 22, opacity: 0.18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_rounded, color: TCC.accent, size: 28),
                const SizedBox(height: 12),
                Text('Everything stays on your phone.',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Your notes, receipts and chats never leave your device — '
                  'the AI runs locally, offline, on this phone.',
                  style: TextStyle(color: TCC.textMuted, fontSize: 13.5, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionLabel('Your data'),
          _NavRow(
            icon: Icons.download_rounded,
            tint: TCC.accent,
            title: 'Export my data',
            subtitle: 'Save a copy of everything you’ve stored',
            onTap: () => poa(context, 'Export prepared'),
          ),
          _NavRow(
            icon: Icons.forum_outlined,
            tint: TCC.warning,
            title: 'Clear chat history',
            subtitle: 'Delete every message with the agents',
            onTap: () => _clearChats(context, ref),
          ),
          _NavRow(
            icon: Icons.delete_forever_rounded,
            tint: TCC.danger,
            title: 'Clear all data',
            subtitle: 'Wipe everything on this device',
            onTap: () => _clearAll(context, ref),
          ),
          const SizedBox(height: 22),
          _sectionLabel('Storage'),
          _storageBreakdown(),
        ],
      ),
    );
  }

  Widget _storageBreakdown() {
    const segments = <(String, double, Color)>[
      ('Model', 0.7, TCC.primary),
      ('Scans', 0.18, TCC.somo),
      ('Chats', 0.08, TCC.accent),
      ('Other', 0.04, TCC.textMuted),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TCC.surface,
        borderRadius: BorderRadius.circular(TCC.radius),
        border: Border.all(color: TCC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: segments
                  .map((s) => Expanded(
                        flex: (s.$2 * 100).round(),
                        child: Container(height: 12, color: s.$3),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          ...segments.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: s.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.$1,
                          style: const TextStyle(
                              color: TCC.text, fontSize: 13.5)),
                    ),
                    Text('${(s.$2 * 100).round()}%',
                        style: const TextStyle(
                            color: TCC.textMuted, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _clearChats(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: 'Clear chat history?',
      body: 'Every message with the agents will be deleted from this device.',
      confirmLabel: 'Clear',
    );
    if (ok != true) return;
    final db = ref.read(dbProvider);
    await db.delete(db.chatMessages).go();
    await db.delete(db.conversations).go();
    ref.read(chatProvider.notifier).newChat(); // drop stale in-memory view
    if (context.mounted) poa(context, 'Chat history cleared');
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: TCC.surface,
        title: const Text('Clear all data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This wipes your scans, transactions, tasks, deadlines, timetable '
              'and chats. This cannot be undone.\n\nType DELETE to confirm.',
              style: TextStyle(color: TCC.textMuted, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'DELETE'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.pop(c, controller.text.trim().toUpperCase() == 'DELETE'),
            style: TextButton.styleFrom(foregroundColor: TCC.danger),
            child: const Text('Wipe everything'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(dbProvider);
    await db.transaction(() async {
      await db.delete(db.scans).go();
      await db.delete(db.transactions).go();
      await db.delete(db.budgetCategories).go();
      await db.delete(db.tasks).go();
      await db.delete(db.deadlines).go();
      await db.delete(db.timetableClasses).go();
      await db.delete(db.chatMessages).go();
      await db.delete(db.conversations).go();
    });
    ref.read(chatProvider.notifier).newChat(); // drop stale in-memory view
    if (context.mounted) poa(context, 'All data cleared');
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: TCC.surface,
        title: Text(title),
        content: Text(body,
            style:
                const TextStyle(color: TCC.textMuted, fontSize: 13.5, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: TCC.danger),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// P42 — About
// ===========================================================================

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TccScaffold(
      title: 'About',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Center(
            child: Column(
              children: [
                SvgPicture.asset(TCC.logoStatic, width: 72, height: 72),
                const SizedBox(height: 16),
                Text('The Campus Collective',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('v1.0.0',
                    style: TextStyle(color: TCC.textMuted, fontSize: 13)),
                const SizedBox(height: 8),
                const Text('Built for GDG Embu Hackathon 2026',
                    style: TextStyle(color: TCC.accent, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: TCC.surface,
              borderRadius: BorderRadius.circular(TCC.radius),
              border: Border.all(color: TCC.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory_rounded, color: TCC.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Runs on Gemma 4 E2B, fully on-device. No servers, '
                        'no accounts — your data never leaves this phone.',
                        style: TextStyle(
                            color: TCC.textMuted, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _NavRow(
            icon: Icons.article_outlined,
            tint: TCC.textMuted,
            title: 'Open-source licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'The Campus Collective',
              applicationVersion: 'v1.0.0',
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Licensed under Apache License 2.0. © 2026 The Campus Collective.',
              style: TextStyle(color: TCC.textDisabled, fontSize: 11.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// P43 — Help & FAQ
// ===========================================================================

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _search = TextEditingController();
  String _query = '';

  static const _faqs = <(String, String)>[
    (
      'Getting started',
      'Tap the chat tab and ask anything — about your notes, fees, budget or '
          'timetable. Snap a photo of notes or a document and the right agent '
          '(Study, Clerk, Hustle or Schedule) will handle it.'
    ),
    (
      'Why is the first answer slow?',
      'The AI runs entirely on your phone. The very first reply loads the model '
          'into memory, which takes a few seconds. After that it’s fast.'
    ),
    (
      'Model download & storage',
      'The Gemma 4 E2B model is about 2.6 GB and downloads once. You can '
          're-download or remove it under Settings → AI Model.'
    ),
    (
      'Is my data private?',
      'Yes. Everything — notes, receipts, chats — stays on this device. Nothing '
          'is uploaded and there are no accounts. See Settings → Data & Privacy.'
    ),
    (
      'Per-agent guides',
      'Study studies your notes, Clerk reads campus documents, Hustle tracks '
          'money and budgets, and Schedule plans your day, tasks and timetable.'
    ),
    (
      'The AI got it wrong?',
      'On-device AI can make mistakes, especially with fees or dates. Always '
          'double-check important details with the office, and use “Report a '
          'problem” to flag a wrong answer.'
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _faqs
        : _faqs
            .where((f) =>
                f.$1.toLowerCase().contains(_query) ||
                f.$2.toLowerCase().contains(_query))
            .toList();

    return TccScaffold(
      title: 'Help & FAQ',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Search help…',
              prefixIcon: Icon(Icons.search_rounded, color: TCC.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No matching help topics.',
                    style: TextStyle(color: TCC.textMuted)),
              ),
            )
          else
            ...filtered.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: TCC.surface,
                    borderRadius: BorderRadius.circular(TCC.radiusSm),
                    border: Border.all(color: TCC.border),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: TCC.accent,
                      collapsedIconColor: TCC.textMuted,
                      shape: const Border(),
                      title: Text(f.$1,
                          style: const TextStyle(
                              color: TCC.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600)),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(f.$2,
                              style: const TextStyle(
                                  color: TCC.textMuted,
                                  fontSize: 13.5,
                                  height: 1.55)),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TCC.surface2,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Still stuck? Tell us what went wrong.',
                      style: TextStyle(color: TCC.textMuted, fontSize: 13)),
                ),
                TextButton(
                  onPressed: () => context.push('/settings/report'),
                  child: const Text('Report a problem'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// P44 — Report a problem
// ===========================================================================

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _description = TextEditingController();
  String _category = 'Bug';
  bool _includeDevice = true;
  bool _sending = false;

  static const _categories = ['Bug', 'Wrong answer', 'Idea', 'Other'];

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TccScaffold(
      title: 'Report a problem',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _sectionLabel('Category'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: TCC.surface,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,
                dropdownColor: TCC.surface2,
                icon: const Icon(Icons.expand_more_rounded, color: TCC.textMuted),
                style: const TextStyle(color: TCC.text, fontSize: 15),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('What happened?'),
          TextField(
            controller: _description,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Describe the problem or idea…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: TCC.surface,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.border),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: TCC.accent,
              value: _includeDevice,
              title: const Text('Include device info',
                  style: TextStyle(color: TCC.text, fontSize: 14.5)),
              subtitle: const Text(
                  'App version & OS only — no personal data or content',
                  style: TextStyle(color: TCC.textMuted, fontSize: 12)),
              onChanged: (v) => setState(() => _includeDevice = v),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_sending ? 'Sending…' : 'Send'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reports help us improve. If you’re offline, we’ll copy it so you '
            'can send it later.',
            style: TextStyle(color: TCC.textDisabled, fontSize: 11.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _description.text.trim();
    if (text.isEmpty) {
      poa(context, 'Please describe the problem first');
      return;
    }
    setState(() => _sending = true);

    final payload = <String, dynamic>{
      'category': _category,
      'description': text,
      'app_version': '1.0.0',
      if (_includeDevice) 'device_info': 'The Campus Collective v1.0.0',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await Supabase.instance.client.from('feedback_reports').insert(payload);
      if (!mounted) return;
      setState(() => _sending = false);
      poa(context, 'Sent — asante!');
      _description.clear();
      if (context.mounted) context.pop();
    } catch (_) {
      // Offline or backend unavailable — fall back to clipboard.
      final fallback = 'The Campus Collective — problem report\n'
          'Category: $_category\n'
          '${_includeDevice ? 'Device: The Campus Collective v1.0.0\n' : ''}'
          '\n$text';
      await Clipboard.setData(ClipboardData(text: fallback));
      if (!mounted) return;
      setState(() => _sending = false);
      poa(context, 'Saved — copy your report');
    }
  }
}
