import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/audio_mode.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key, required this.current, required this.onChanged});
  final AudioMode current;
  final ValueChanged<AudioMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return SegmentedButton<AudioMode>(
      segments: <ButtonSegment<AudioMode>>[
        ButtonSegment<AudioMode>(value: AudioMode.anc, label: Text(t.modeAnc), icon: const Icon(Icons.shield)),
        ButtonSegment<AudioMode>(value: AudioMode.powerSaver, label: Text(t.modePower), icon: const Icon(Icons.battery_saver)),
        ButtonSegment<AudioMode>(value: AudioMode.transparency, label: Text(t.modeTransparency), icon: const Icon(Icons.visibility)),
      ],
      selected: <AudioMode>{current},
      onSelectionChanged: (Set<AudioMode> s) => onChanged(s.first),
    );
  }
}
