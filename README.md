# 🔬🎵 Melodies Sound Lab

A 45-minute classroom game for one PC on a projector (up to 14 students, 2 teams).
Students are sound scientists who collect clues on a printed **code card**. At the end
the vault opens, the code is unveiled, and lines on the card earn stamps.

| Step | Section | Time | What happens |
|---|---|---|---|
| 1 | 🔬 Sound microscope | 5 min | Live sound waves from the mic: high vs low, loud vs quiet, claps = spikes |
| 2 | 🎧 Pitch on Click | 12 min | Blindfolded hearing test with headphones – SPACE on every beep. Team points. Clues 1–3 |
| 3 | 🧮 Beat maths | 7 min | "How many beats is it?" practice. Clues 4–6 |
| 4 | 🕵️ Note detectives | 6 min | Hand signs and notes on the staff. Clues 7–8 |
| 5 | 📡 Rhythm scanner | 8 min | Each team claps a rhythm, the mic scores it. Pass = ⭐ middle square |
| 6 | 🔐 Crack the code | 7 min | Vault opens, answers unveiled one by one, stamps, winning team |

Every section has an **Intro** screen and a **Play** screen.

## Teacher controls
- **T** – show/hide teacher notes (what to say, ask and watch for)
- **Practice / Clue time** switch in sections 2–4
- **Level** buttons – make it harder when the class is ready
- **Timer** (top bar) – tap to pause, long-press to reset
- **New lesson** (home screen) – new secret code + scores reset

## Before class
1. Print `print/code_cards.pdf` (14 cards, each with the squares in a different order).
2. Headphones for Pitch on Click. Unplug them before "Clue time" so everyone can hear.
3. A microphone (built-in is fine) for the microscope and rhythm scanner.

## Run it
```bash
cd ~/development/melodies
flutter pub get
flutter run -d chrome     # on the Mac (allow the microphone when Chrome asks)
flutter run -d windows    # on the Windows laptop
```
Build for the class PC (Windows): `flutter build windows`, then copy
`build/windows/x64/runner/Release/` and run `melodies.exe`.

## Hand-sign pictures
Add photos to `assets/handsigns/` (do.png, re.png, mi.png, fa.png, sol.png, la.png,
ti.png, do_high.png). Until then an emoji stand-in is shown.
