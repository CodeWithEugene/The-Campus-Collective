import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_state.dart';
import '../theme/tokens.dart';

/// Shared premium UI kit used across every suite (project.md §16).

/// Standard page scaffold: pure-black, static logo in the top bar.
class TccScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showLogo;
  final bool showBack;
  final PreferredSizeWidget? bottom;

  const TccScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showLogo = true,
    this.showBack = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TCC.bg,
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        leadingWidth: showLogo ? 56 : null,
        leading: showLogo && !showBack
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SvgPicture.asset(TCC.logoStatic, width: 26, height: 26),
              )
            : null,
        title: title != null
            ? Text(title!)
            : (showLogo && showBack
                  ? SvgPicture.asset(TCC.logoStatic, width: 24, height: 24)
                  : null),
        actions: actions,
        bottom: bottom,
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Elevated bordered surface card.
class TccCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? color;
  final List<BoxShadow>? shadow;

  const TccCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.onTap,
    this.color,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TCC.radius),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? TCC.surface,
            borderRadius: BorderRadius.circular(TCC.radius),
            border: Border.all(color: borderColor ?? TCC.border),
            boxShadow: shadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small agent identity avatar (colored dot with initial).
class AgentAvatar extends StatelessWidget {
  final String agent;
  final double size;
  const AgentAvatar(this.agent, {super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final c = TCC.agentColor(agent);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Text(
        agent.isEmpty ? '?' : agent[0].toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.42),
      ),
    );
  }
}

/// A pill chip used for quick actions and filters.
class TccChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color? tint;
  final VoidCallback? onTap;
  const TccChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = tint ?? TCC.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.withValues(alpha: 0.16) : TCC.surface2,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selected ? c : TCC.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? c : TCC.textMuted),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? c : TCC.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen empty / illustration state.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TCC.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: TCC.border),
              ),
              child: Icon(icon, size: 34, color: TCC.textMuted),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Amber "verify with the office" banner (project.md P54).
class LowConfidenceBanner extends ConsumerStatefulWidget {
  final VoidCallback? onFindContacts;
  const LowConfidenceBanner({super.key, this.onFindContacts});

  @override
  ConsumerState<LowConfidenceBanner> createState() => _LowConfidenceBannerState();
}

class _LowConfidenceBannerState extends ConsumerState<LowConfidenceBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final isEnglish = lang.flavor == 'english';

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TCC.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TCC.radiusSm),
          border: Border.all(color: TCC.warning.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: TCC.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEnglish
                        ? 'Double-check this with the office — on-device AI can make mistakes.'
                        : 'Hakikisha habari hii na ofisi — AI ya simu inaweza kukosea.',
                    style: const TextStyle(color: TCC.text, fontSize: 13, height: 1.35),
                  ),
                ),
                if (widget.onFindContacts != null)
                  TextButton(
                    onPressed: widget.onFindContacts,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isEnglish ? 'Contacts' : 'Nambari',
                      style: const TextStyle(color: TCC.warning, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(color: TCC.border, height: 16, thickness: 1),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEnglish ? '💡 Tips for better scans:' : '💡 Njia za kuboresha picha:',
                    style: const TextStyle(color: TCC.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: TCC.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tipRow(isEnglish ? 'Use a well-lit space or toggle flash' : 'Tumia mahali penye mwanga wa kutosha au washa taa'),
                    const SizedBox(height: 4),
                    _tipRow(isEnglish ? 'Hold phone parallel to the paper (no angles)' : 'Shikilia simu sambamba na karatasi (bila kuinama)'),
                    const SizedBox(height: 4),
                    _tipRow(isEnglish ? 'Avoid shadows and make sure no text is cut off' : 'Epuka vivuli na hakikisha maandishi hayajakatwa'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tipRow(String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: TCC.textMuted, fontSize: 12)),
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(color: TCC.textMuted, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    );
  }
}

/// Show a teal "Poa!" confirmation snackbar.
void poa(BuildContext context, [String message = 'Poa!']) {
  String finalMessage = message;
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    final lang = container.read(langProvider);
    switch (lang.flavor) {
      case 'english':
        finalMessage = switch (message) {
          'Poa!' => 'Success!',
          'Imeshindikana. Jaribu tena.' => 'Failed. Try again.',
          'Budget imewekwa!' => 'Budget created!',
          'Imehifadhiwa!' => 'Saved!',
          'Imefutwa.' => 'Deleted.',
          'Deadline imehifadhiwa!' => 'Deadline saved!',
          'Andika title kwanza' => 'Please enter a title first',
          'Poa! Imehifadhiwa' => 'Saved!',
          'Sent — asante!' => 'Sent — thank you!',
          'Saved — copy your report' => 'Saved — copy your report',
          'Please describe the problem first' => 'Please describe the problem first',
          'Model is already up to date' => 'Model is already up to date',
          'Model removed' => 'Model removed',
          'Export prepared' => 'Export prepared',
          'Chat history cleared' => 'Chat history cleared',
          'All data cleared' => 'All data cleared',
          'Timetable imported!' => 'Timetable imported!',
          'Class removed' => 'Class removed',
          'Poa! Class added' => 'Class added',
          'Poa! Task done' => 'Task done!',
          'Reopened' => 'Reopened',
          'Task deleted' => 'Task deleted',
          'Poa! Deadline added' => 'Deadline added!',
          _ => message,
        };
        break;
      case 'sheng':
        finalMessage = switch (message) {
          'Poa!' => 'Poa!',
          'Imeshindikana. Jaribu tena.' => 'Haijaenda. Jaribu tena.',
          'Budget imewekwa!' => 'Budget imesetiwa!',
          'Imehifadhiwa!' => 'Imesave-iwa!',
          'Imefutwa.' => 'Imefutwa.',
          'Deadline imehifadhiwa!' => 'Deadline imesave-iwa!',
          'Andika title kwanza' => 'Andika title kwanza',
          'Poa! Imehifadhiwa' => 'Poa! Imesave-iwa',
          'Sent — asante!' => 'Imetumwa — shukran!',
          'Saved — copy your report' => 'Imesave-iwa — copy report yako',
          'Please describe the problem first' => 'Andika shida kwanza',
          'Model is already up to date' => 'Model iko sawa kabisa',
          'Model removed' => 'Model imefutwa',
          'Export prepared' => 'Export iko ready',
          'Chat history cleared' => 'Chat history imefutwa',
          'All data cleared' => 'Data yote imefutwa',
          'Timetable imported!' => 'Timetable imeingizwa!',
          'Class removed' => 'Class imetolewa',
          'Poa! Class added' => 'Poa! Class imeongezwa',
          'Poa! Task done' => 'Poa! Task imeisha',
          'Reopened' => 'Imefunguliwa tena',
          'Task deleted' => 'Task imefutwa',
          'Poa! Deadline added' => 'Poa! Deadline imeongezwa',
          _ => message,
        };
        break;
      default: // Kiswahili
        finalMessage = switch (message) {
          'Poa!' => 'Vyema!',
          'Imeshindikana. Jaribu tena.' => 'Imeshindikana. Jaribu tena.',
          'Budget imewekwa!' => 'Bajeti imewekwa!',
          'Imehifadhiwa!' => 'Imehifadhiwa!',
          'Imefutwa.' => 'Imefutwa.',
          'Deadline imehifadhiwa!' => 'Muda wa mwisho umehifadhiwa!',
          'Andika title kwanza' => 'Andika kichwa kwanza',
          'Poa! Imehifadhiwa' => 'Vyema! Imehifadhiwa',
          'Sent — asante!' => 'Imetumwa — asante!',
          'Saved — copy your report' => 'Imehifadhiwa — nakili ripoti yako',
          'Please describe the problem first' => 'Tafadhali eleza tatizo kwanza',
          'Model is already up to date' => 'Mfano tayari umesasishwa',
          'Model removed' => 'Mfano umefutwa',
          'Export prepared' => 'Usafirishaji umetayarishwa',
          'Chat history cleared' => 'Historia ya mazungumzo imefutwa',
          'All data cleared' => 'Data yote imefutwa',
          'Timetable imported!' => 'Ratiba imeingizwa!',
          'Class removed' => 'Darasani limeondolewa',
          'Poa! Class added' => 'Vyema! Darasani limeongezwa',
          'Poa! Task done' => 'Vyema! Kazi imekamilika',
          'Reopened' => 'Imefunguliwa tena',
          'Task deleted' => 'Kazi imefutwa',
          'Poa! Deadline added' => 'Vyema! Muda wa mwisho umeongezwa',
          _ => message,
        };
    }
  } catch (_) {}

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: TCC.accent, size: 20),
            const SizedBox(width: 10),
            Text(finalMessage),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Section header used inside pages.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          ?trailing,
        ],
      ),
    );
  }
}
