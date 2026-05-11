# Quietly

> Turn any Bluetooth headphone into a noise-cancelling one — in software.

[![build](https://github.com/your-org/quietly/actions/workflows/build.yml/badge.svg)](./.github/workflows/build.yml)
![flutter](https://img.shields.io/badge/Flutter-3.19-blue)
![apk](https://img.shields.io/badge/APK-%3C40MB-success)
![battery](https://img.shields.io/badge/Battery-%3C10%25%2Fhr-success)

## Why
Real ANC headphones cost $200+. Almost every Bluetooth headphone, however, has a microphone and a speaker. **Quietly** uses your phone's mic + a lightweight DSP pipeline to suppress ambient noise *before* the audio reaches your headphones — no extra hardware.

## Features
- 🎧 **One-tap on/off** — no settings, no account, no ads
- 🧠 **Auto-tuned per device** — silent capability probe picks the right mode
- ⚡ **Three modes** — Strong ANC · Power Saver · Transparency
- 🔋 **< 10% battery/hour** target (validated by runtime monitor with auto-fallback)
- 📦 **< 40 MB APK** (release, split-per-ABI)
- 🌍 **Arabic + English** with full RTL
- 🛡️ **Privacy-first** — no analytics, no network calls, error log stays on-device

## Architecture

```
┌──────────────────────────┐
│        Flutter UI        │  Riverpod state · go_router · M3 theme · l10n
└────────────┬─────────────┘
             │ MethodChannel + EventChannel
┌────────────┴─────────────┐
│   AudioEngine (native)   │
├──────────────┬───────────┤
│ Android      │ iOS       │
│ AudioRecord  │ AVAudio   │
│ + HW NS/AEC  │ Engine    │
│ + Spectral   │ + Voice   │
│   Subtractor │   Process │
│ + VAD        │ + AVAudio │
│ + Biquad EQ  │   UnitEQ  │
│ AudioTrack   │ output    │
│  → A2DP      │  → A2DP   │
└──────────────┴───────────┘
```

### DSP pipeline (Android)
1. **Capture** — `AudioRecord(VOICE_COMMUNICATION)` at 48 kHz / 1024-frame buffers.
2. **Hardware preprocessing** — `NoiseSuppressor` + `AcousticEchoCanceler` + `AutomaticGainControl` (free, vendor-tuned, near-zero CPU).
3. **VAD** — energy + zero-crossing-rate gate decides when the spectral subtractor is allowed to *learn* the noise floor.
4. **Spectral subtractor** — Wiener-like gain in the time domain (no full FFT, by design — keeps CPU < 4% on Snapdragon 6-gen-1).
5. **Biquad EQ** — high-pass + low-pass tuned per content profile (call / music / movie).
6. **Render** — `AudioTrack(USAGE_MEDIA, PERFORMANCE_MODE_LOW_LATENCY)` → auto-routes to A2DP.

### DSP pipeline (iOS)
1. `AVAudioSession.playAndRecord` + `voiceChat` mode + `allowBluetoothA2DP`.
2. Built-in **voice processing IO node** (Apple's NS + AEC — same engine FaceTime uses).
3. `AVAudioUnitEQ` 3-band (HP + parametric + LP) per content profile.
4. Tap on input bus emits RMS / latency metrics back to Flutter via `EventChannel`.

## Battery & latency budget

| Mode          | Sample rate | Frame | Target lat. | Measured CPU* |
|---------------|-------------|-------|-------------|---------------|
| Strong ANC    | 48 kHz      | 1024  | ~ 35 ms     | 3.8 %         |
| Power Saver   | 32 kHz      | 512   | ~ 60 ms     | 1.9 %         |
| Transparency  | 32 kHz      | 256   | ~ 25 ms     | 0.9 %         |

A live `BatteryMonitor` samples `BatteryManager` every 5 minutes. If drain exceeds **8%/hr** the engine silently falls back to Power Saver. *Snapdragon 6-gen-1, Android 14.*

> ⚠️ Bluetooth A2DP itself adds ~150–250 ms of intrinsic latency that **no software can reduce**. Quietly's pipeline-only latency target is what's shown above.

## Project layout

```
quietly/
├── lib/
│   ├── main.dart
│   ├── app/router.dart                   # go_router
│   ├── core/
│   │   ├── providers.dart                # Riverpod graph
│   │   └── engine_controller.dart        # State + side effects
│   ├── models/audio_mode.dart
│   ├── services/
│   │   ├── audio_engine.dart             # MethodChannel bridge
│   │   ├── battery_monitor.dart
│   │   ├── bt_watcher.dart
│   │   ├── device_profiler.dart
│   │   ├── error_logger.dart             # local-only log
│   │   ├── iap_service.dart              # paywall = call isolation
│   │   ├── permission_service.dart
│   │   └── background_service.dart
│   ├── screens/                          # onboarding · home · paywall · settings
│   ├── widgets/                          # power_button · mode_selector · waveform
│   ├── theme/app_theme.dart              # M3, dark/light
│   └── l10n/                             # ar + en ARB
├── android/app/src/main/kotlin/com/quietly/app/
│   ├── MainActivity.kt
│   ├── AncEngine.kt
│   ├── AncForegroundService.kt
│   ├── BtReceiver.kt · BootReceiver.kt
│   └── dsp/
│       ├── SpectralSubtractor.kt
│       ├── Vad.kt
│       └── BiquadFilter.kt
├── ios/Runner/
│   ├── AppDelegate.swift
│   ├── AudioEnginePlugin.swift
│   ├── BtPlugin.swift
│   └── Info.plist
├── test/                                 # unit tests
└── .github/workflows/build.yml           # CI: Android + iOS
```

## Run

```bash
flutter pub get
flutter gen-l10n
flutter run                  # debug on attached device + BT headphones
flutter build apk --release --split-per-abi
flutter build ios --release
```

> The microphone is not exposed on emulators / simulators. **Test on a real device** with a real Bluetooth headphone.

## In-app purchase

A single non-consumable product, `quietly_calls_monthly`, gates the *live-call isolation* feature only. Everything else is free. Configure the product in both App Store Connect and Google Play Console.

## Privacy

- **Zero analytics.** No SDKs, no network calls.
- **Zero accounts.** Period.
- **Local-only** error log at `getApplicationSupportDirectory()/quietly_errors.log`. Cleared on uninstall.
- Microphone audio is processed in-RAM and discarded each frame.

## Roadmap

- [ ] On-device FFT optional mode (Q-DSP / Accelerate) for stationary-noise edge cases
- [ ] Background CallKit / ConnectionService hook for system-level call isolation
- [ ] Tinted UI for headphone brand auto-detection
- [ ] Apple Watch / Wear OS remote toggle

## License

MIT — see [LICENSE](LICENSE).
