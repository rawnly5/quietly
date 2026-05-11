# Developer Notes

## Why no full FFT?

A 1024-point FFT on every frame on a budget Snapdragon costs ~6–8 % CPU sustained, which alone breaks the < 10 %/hour battery budget once Bluetooth A2DP + screen are factored in. Time-domain Wiener-style suppression captures ~70 % of the perceptual benefit at ~1/4 the cost. A full-spectrum mode is on the roadmap as an *opt-in* power mode.

## Why VOICE_COMMUNICATION (Android) / voiceChat (iOS)?

Both platforms expose vendor-tuned echo cancellation + noise suppression for free on these modes. We layer our own DSP *on top* — not instead of.

## Why no auto-start on boot?

Battery-paranoid users hate apps that hijack their boot sequence. The `BootReceiver` exists so the OS doesn't kill us on first install, but it is intentionally a no-op. The user must tap the power button at least once per device boot.

## Bluetooth latency reality

A2DP codecs add intrinsic latency we cannot fix:
- SBC: ~220 ms
- AAC: ~180 ms
- aptX: ~80 ms
- aptX-LL: ~40 ms
- LDAC: 200–400 ms

Our pipeline's own latency is what the app reports. The total perceived latency to the user = our latency + codec latency. We document this in the README rather than hide it.

## Testing on real hardware

Emulators don't route audio to A2DP. To test:
1. Pair a real BT headphone with your dev device.
2. `flutter run --release` (debug builds add audio jitter).
3. Watch `adb logcat -s Quietly` for the engine's per-frame metrics.
