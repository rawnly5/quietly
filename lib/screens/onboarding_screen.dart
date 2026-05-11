import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers.dart';
import '../l10n/app_localizations.dart';
import '../services/permission_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (int i) => setState(() => _page = i),
                children: <Widget>[
                  _Slide(title: t.onbTitle1, icon: Icons.headphones_outlined),
                  _BeforeAfterSlide(title: t.onbTitle2),
                  _PermissionsSlide(title: t.onbTitle3, onDone: _finish),
                ],
              ),
            ),
            _Dots(count: 3, current: _page),
            const SizedBox(height: 16),
            if (_page < 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FilledButton(
                  onPressed: () => _pc.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                  child: Text(t.continueBtn),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final PermissionResult r = await ref.read(permissionServiceProvider).request();
    if (!mounted) return;
    if (r.allGranted) {
      final SharedPreferences prefs = ref.read(sharedPrefsProvider);
      await prefs.setBool('onboarding_done', true);
      if (mounted) context.go('/home');
    }
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 120, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 40),
            Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _BeforeAfterSlide extends StatelessWidget {
  const _BeforeAfterSlide({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 40),
          Row(
            children: <Widget>[
              Expanded(child: _AudioCard(label: t.before, isAfter: false)),
              const SizedBox(width: 12),
              Expanded(child: _AudioCard(label: t.after, isAfter: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioCard extends StatelessWidget {
  const _AudioCard({required this.label, required this.isAfter});
  final String label;
  final bool isAfter;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Icon(
                isAfter ? Icons.graphic_eq : Icons.surround_sound,
                size: 48,
                color: isAfter ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(label),
              const SizedBox(height: 12),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
              ),
            ],
          ),
        ),
      );
}

class _PermissionsSlide extends StatelessWidget {
  const _PermissionsSlide({required this.title, required this.onDone});
  final String title;
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _PermTile(icon: Icons.mic_none, title: t.permMic, sub: t.permMicWhy),
          const SizedBox(height: 12),
          _PermTile(icon: Icons.notifications_none, title: t.permNotif, sub: t.permNotifWhy),
          const SizedBox(height: 32),
          FilledButton(onPressed: onDone, child: Text(t.grant)),
        ],
      ),
    );
  }
}

class _PermTile extends StatelessWidget {
  const _PermTile({required this.icon, required this.title, required this.sub});
  final IconData icon;
  final String title, sub;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: Text(sub),
        ),
      );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count, current;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(count, (int i) {
          final bool active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: active ? 24 : 8,
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
}
