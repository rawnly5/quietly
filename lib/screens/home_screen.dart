import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/engine_controller.dart';
import '../core/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/audio_mode.dart';
import '../widgets/mode_selector.dart';
import '../widgets/power_button.dart';
import '../widgets/waveform_indicator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EngineState s = ref.watch(engineControllerProvider);
    final EngineController c = ref.read(engineControllerProvider.notifier);
    final AppLocalizations t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 16),
              _StatusCard(state: s),
              const Spacer(),
              PowerButton(active: s.running, onTap: c.toggle),
              const SizedBox(height: 12),
              Text(s.running ? t.tapToStop : t.tapToStart,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              WaveformIndicator(active: s.running, noiseDb: s.noiseDb),
              const Spacer(),
              ModeSelector(
                current: s.mode,
                onChanged: (AudioMode m) {
                  if (m == AudioMode.anc && !ref.read(iapServiceProvider).isPro) {
                    context.push('/paywall');
                    return;
                  }
                  c.switchMode(m);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});
  final EngineState state;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            _Stat(label: t.latencyMs(state.latencyMs), icon: Icons.speed),
            const SizedBox(width: 16),
            _Stat(
              label: state.running ? t.isolating : '—',
              icon: state.running ? Icons.graphic_eq : Icons.power_settings_new,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
}
