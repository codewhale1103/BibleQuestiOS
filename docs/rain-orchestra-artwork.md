# The Rain Orchestra — 40 Days & Nights

Playable from Noah’s voyage, chapter 5. Five water-routing chapters followed by a free-play music workshop. Completion is saved locally and to `Users/<uid>/Adventures/Noah/FortyDaysAndNights`. It does not unlock the final Noah album reward.

## Artwork

Generated with the **built-in image_gen tool**, in illustration-story mode. The exact prompt and original generated path are in [rain-orchestra-prompts.json](rain-orchestra-prompts.json).

Final project assets: `BibleQuest/Assets.xcassets/{RainOrchestraWorkshop,RainMusicBowl,RainMusicDrum,RainWaterwheel}.imageset/art.png`. Each has its own exact prompt and source path in the prompt manifest.

The detailed bowl, drum and waterwheel props are generated transparent sprites. Channels, brass sockets, splashes, the copper rain gate, tipping bucket, water fills, note ripples, conservative water network, and wheel rotation are native SwiftUI/Canvas artwork and animation. Existing `FloodStorm`, `FloodExterior`, `ParadeMonkey`, `ParadeSheep`, and `ParadeElephant` artwork is reused from Noah’s adventure. No new external stock art is used.

## Audio

ElevenLabs **Anna – Children’s Book Narrator**, Eleven Multilingual v2. Eleven offline AAC clips, exact texts/settings/durations in [rain-orchestra-narration.json](rain-orchestra-narration.json). Generated via the signed-in official website, not an API key. **These Free-plan recordings are for local preview only; regenerate under a paid commercial plan before commercial release.** No subscription was purchased or account settings changed.

Full musical upgrade: see [rain-orchestra-music.md](rain-orchestra-music.md) for the new original theme, public-domain Jesus Loves Me arrangement, CC0 instrument credits, reproducible score and audio paths.

Six original synthesized PCM WAVs: three softly resonating C-major instrument notes, a wooden placement sound, gate creak, and completion chime. The existing original `flood-rain.wav` is reused quietly as ambience. All sounds play offline and stop on pause/exit. Sound is optional.

## Play and learning

1. One channel completes a route to a tipping-bucket drum.
2. Split a stream to both outer bowls in the same pour.
3. Route separate pours to the low, high, middle bowls in order; a replayable visual/audio melody supports matching.
4. Power a wheel and drum together to animate a tiny animal parade.
5. Split and merge streams to play all three instruments together.

Drag tools to pegs, tap to turn, swap placed pieces, or return them to the shelf. Tap-to-place and equivalent VoiceOver actions support children who prefer not to drag. A clue repairs one connection at a time; pouring remains a child action. No penalties or time limits. Pause freezes water and story time. Reduced Motion preserves route feedback while removing ambient rain, rocking and parade motion.

Forty story days are condensed across five chapters. The ending explicitly explains that forty days and nights refers to the rain, and Noah’s whole stay in the ark lasted much longer. The imaginary rain orchestra is not presented as a biblical event. Story references: Genesis 7:12; 8:1–5. No dove or rainbow events are advanced.

## Validation — 2026-10-16

- Fifteen focused Swift Testing checks passed: ten water-game checks and five existing voyage-route checks (including four layout widths).
- All eleven narration clips and six new WAVs decoded and prepared with native AVAudioPlayer from the built app.
- Simulator play-through completed all five chapters using dragging, tap-to-place, rotations and the physical rain gate. Reviewed the ending, free play, pause/resume and landscape. The full completion run used an isolated nil-callback preview, so it did not mark the signed-in account complete.
- Final generated props and rounded Read to me button reviewed in the normal app. Opened from chapter five, exited back to the same berth and reopened. Simulator left on the welcome screen. Normal RootView restored.
- Final simulator and signed generic iOS Debug builds succeeded; strict codesign verification passed. `git diff --check` passed.
