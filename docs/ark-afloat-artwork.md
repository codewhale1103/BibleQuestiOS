# Ark Afloat · Flood Begins

A native SwiftUI/Canvas adventure at Noah's fourth stop. Children explore three rooms, physically prepare supplies and shelter, watch the rising-water launch, then care for the ark's passengers. No timer, health bar, or failure state.

## Visual assets

Six new environment assets were created with the built-in image-generation tool. Exact prompts, source paths, and project paths are in [ark-afloat-prompts.json](ark-afloat-prompts.json).

- `BibleQuest/Assets.xcassets/FloodStorm.imageset/art.png`
- `BibleQuest/Assets.xcassets/FloodCargoRoom.imageset/art.png`
- `BibleQuest/Assets.xcassets/FloodAnimalRoom.imageset/art.png`
- `BibleQuest/Assets.xcassets/FloodLanternRoom.imageset/art.png`
- `BibleQuest/Assets.xcassets/FloodCutaway.imageset/art.png`
- `BibleQuest/Assets.xcassets/FloodExterior.imageset/art.png`

Original alpha is preserved. The exterior is an image-generation edit of the cutaway, preserving the boat silhouette, position, camera, and materials while enclosing the two decks. No raster editing scripts were used. Noah, sheep, elephant, monkey, tiger, and shore artwork is reused from the existing app.

The dynamic sea, foam, foreground rain, touch ripples, window droplets, wiped glass, rope, basket weave, bronze oil lamp, apples, cloth folds, and kindness particles are native Canvas/SwiftUI elements. The game uses layered dimensional artwork rather than a realtime 3D mesh engine.

## Interaction

Preparation: drag the supply basket into its cradle, pull its rope snug, slide both shutters shut, then carry the lamp to the hook. Rooms can be explored in any order. A physical delivery must land near its destination; invalid drops return the prop. Rope and shutter progress remain when a child re-grips.

The launch raises the rendered waterline and lifts the hull over 12 seconds. A draggable wooden viewing handle switches between the interior and exterior. Care: three unique rolling apples must be delivered, another rope tightened, a blanket delivered, the lamb comforted by stroking its wool, and the shutters closed. All nine actions are required before the closing story. The final callback fires once after the finale.

Rain responds with ripples; window condensation can be wiped. Audio perspective changes when looking outside. Large controls, repeatable visual/spoken hints, and equivalent VoiceOver actions support different learners. Pause freezes cinematic and task time, and stops audio. Backgrounding, leaving, and layout changes pause safely. Reduced Motion removes ambient rocking, drifting rain, and rolling apple movement while retaining essential story transitions.

## Sound

Sixteen offline Anna – Children's Book Narrator recordings were generated in the signed-in ElevenLabs workspace using its recommended Multilingual v2 model. [ark-afloat-narration.json](ark-afloat-narration.json) records the exact text, settings, file names, and durations. The long recording was split at deliberate pauses, safely trimmed, faded at the file edges, and encoded to AAC at 128 kbps. The short pause at 42.06–43.10 s separates the lantern and ready lines.

**Release dependency:** the workspace is on ElevenLabs Free. The voice files are local previews and must be regenerated under a commercially licensed paid plan before commercial release. [Provider licensing rules](https://help.elevenlabs.io/hc/en-us/articles/13313564601361-Can-I-publish-the-content-I-generate-on-the-platform). No subscription was purchased or API credential created.

Eight original designed WAVs provide rain, sea, wood clunks, rope creaks, water plops, kindness tones, a layered harmonic lift, and a finale. Everything is bundled in `BibleQuest/Noah Games/Audio/Flood/`; no network connection is required for play.

## Story and progress

The framing follows Genesis 7:10–24, ending with the first voyage. The cargo activities, rooms, lamp, and animal-care tasks are imaginative play. The long wait, dove, and rainbow remain later chapters.

Flood Begins launches full-screen from Noah's map and returns to the same berth. Completion is cached per signed-in user, saved to `Users/<uid>/Adventures/Noah/FloodBegins`, and retried if online saving fails. It does not unlock Noah's final album reward.

## Validation

All nine focused round tests passed. Coverage includes invalid inputs and wrong drops, partial rope pulls and both shutters, preparation gating, unique apple deliveries, blanket-before-stroking care, all nine actions before one ending, arbitrary room order, pause freezing cinematic time, replay, and rain play not advancing the story.

Simulator review reached the complete nine-action ending in an isolated preview with no completion callback. Direct touch checks verified basket placement, rope pulling, both sliding shutters, hanging the lamp, and the first-float sequence. The care activities reached completion, with the lamb’s blanket, comfort indicator, and final cozy room state reviewed. Replay, pause/resume, and landscape layout were inspected. Fast swipes apply their final position, and stroking is interpolated to stay consistent with touch sampling. Cancelled gestures clear their temporary state. Replay clears old hints, celebration particles, and sound.

All sixteen narration clips and eight designed WAVs passed native AVAudioPlayer decoding/preparation from the built app bundle. Signed generic-iOS Debug build and final simulator build/test succeeded; strict codesign verification passed. Normal RootView() is restored. The normal app was opened through Adventures → Noah → Play Flood Begins; exiting returns to chapter four and reopening starts a fresh introduction. The final simulator is left on the normal Ark Afloat introduction, ready to play. No online completion writes were performed during QA. Final source/asset checks pass git diff --check.
