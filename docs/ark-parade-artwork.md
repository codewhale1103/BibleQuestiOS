# Ark Parade · Gather Animals

A native SwiftUI/Canvas woodland adventure for Noah’s third stop. Children listen to an animal, reunite its partner among three candidates, then draw a trail from the pair to the ark ramp. Eight selected pairs: lion, wolf, tiger, monkey, elephant, sheep, cow, horse. No timer or penalties.

## Artwork

Created with the built-in image-generation tool, except the licensed lion illustration. The exact final prompt set and saved asset paths are in [ark-parade-prompts.json](ark-parade-prompts.json). Generated PNG alpha is preserved. Assets are stored in the project’s asset catalog, not referenced from the generation cache. Existing `NoahCallGuide` artwork is reused for Noah; `ShepherdLimestone` and `ElahRiverReeds` are reused as textured scene props.

The new assets are `ParadeClearing`, `ParadeArk`, `ParadeElephant`, `ParadeCow`, `ParadeMonkey`, `ParadeSheep`, `ParadeHorse`, `ParadeWolf`, `ParadeTiger`, and `ParadeLion`, each at `BibleQuest/Assets.xcassets/<name>.imageset/art.png`.

Lion generation was declined by the image service. The game instead uses [cameronschmidt’s transparent lion illustration](https://pixabay.com/illustrations/ai-generated-lion-transparent-animal-9287227/) under the [Pixabay Content License](https://pixabay.com/service/license-summary/). The original transparent PNG is bundled without raster edits. Wolf and tiger were generated for this update; exact prompts are in the manifest. Duck is removed from gameplay, narration, journal, and progression.

## Recordings

Bundled WAVs: `BibleQuest/Noah Games/Audio/Parade/parade-<animal>.wav`. Converted from the source MP3s to mono PCM16 at 22,050 Hz; peak adjusted to 0.68; 12 ms attack and 90 ms tail fade. Macaque excerpt: original 5.8–8.9 s. Wolf excerpt: original 1–5 s. Lion, wolf, and tiger are normalized to peak 0.60 with 30 ms attack and 120 ms tail fades. Other calls use the full short clips. No recording requires a runtime network connection. Narration is 21 prerecorded **Anna – Children’s Book Narrator** clips from ElevenLabs, generated with the recommended Multilingual v2 model, then split at deliberate pauses, trimmed with safe margins, edge faded, and encoded to AAC at 128 kbps. No system speech synthesizer is used. The exact text, settings, file names, and durations are in [ark-parade-narration.json](ark-parade-narration.json).

**Release dependency:** The signed-in ElevenLabs workspace was on the Free plan during generation. These recordings are for local preview; regenerate them under a commercially licensed paid plan before commercial release. [Provider licensing rules](https://help.elevenlabs.io/hc/en-us/articles/13313564601361-Can-I-publish-the-content-I-generate-on-the-platform). No subscription was purchased or API credentials created.

| Animal | Recording / creator | License |
| --- | --- | --- |
| Lion | [Lion Roar](https://soundbible.com/1282-Lion-Roar.html), Mike Koenig | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) |
| Wolf | [Medium Pack of Wolves Howling](https://soundbible.com/277-Medium-Pack-Of-Wolves-Howling.html), fws.gov | Public Domain |
| Tiger | [Tiger Growling](https://soundbible.com/1485-Tiger-Growling.html), Mike Koenig | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) |
| Elephant | [Elephant voice – trumpeting](https://commons.wikimedia.org/wiki/File:Elephant_voice_-_trumpeting.ogg), தகவலுழவன் / Info-farmer | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| Cow | [Cow Moo](https://soundbible.com/1778-Cow-Moo.html), Mike Koenig | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) |
| Monkey | [Sound of stump-tailed macaque](https://commons.wikimedia.org/wiki/File:Sound-of-stump-tailed-macaque-(macaca-arctoides).ogg), Rushenb | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) |
| Sheep | [Sheep Bleating](https://soundbible.com/520-Sheep-Bleating.html), Mike Koenig | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) |
| Horse | [Horse Neigh](https://soundbible.com/1296-Horse-Neigh.html), Mike Koenig | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) |

The adapted macaque WAV is distributed under CC BY-SA 4.0, the same license as its source. App journal credits include creator, source, license, changes, and export of every licensed clip. These recording licenses apply to the audio files, not the rest of the app. Footfalls, woodland bed, match/boarding/finale cues are original synthesized sounds created for this game; they are identified separately from animal recordings.

## Interaction and accessibility

- Three varied hiding positions per hunt; different arrangements on replay.
- Visible call labels and ripples; all gameplay works muted.
- Large animal hit areas, spoken prompts/facts, no failure state.
- A child-drawn route is preserved, with local detours around the boulder.
- Footprints, animal-specific gait rhythms, pair greetings, boarding shrink, window peeks, stamp discoveries, and a final sequential animal chorus.
- VoiceOver has equivalent partner controls and a “Guide this pair to the ark” alternative to tracing.
- Pause on backgrounding, orientation changes, or journal presentation; explicit resume.
- Reduce Motion removes ambient drifting, bobbing, and celebratory rocking while keeping essential route movement.
- The parent note explains that these eight selected pairs are not the full number of animals described in Genesis 7:2–3.

## Progress

Launches from Gather Animals on Noah’s map via a full-screen presentation with explicit return to the same map. Completion is recorded locally per signed-in user and saved to `Users/<uid>/Adventures/Noah/GatherAnimals`, with retry support if online saving fails. This game does not unlock Noah’s final album reward.

## Validation

All eight focused round tests passed, including the full sixteen-animal progression and a check that boarding six pairs does not finish the game. Both the normal simulator build and signed generic-iOS Debug build succeeded. Strict code-signature verification passed. All 21 Anna narration files and all eight animal WAVs passed native AVAudioPlayer decoding/preparation from the built app bundle. Narration adds 1.52 MiB.

Simulator review completed all eight pairs and the finale in an isolated preview with no completion callback, avoiding online progress writes. Verified both lions, wolves, tigers, and monkeys remain distinct, child-drawn trails work from either member of a pair, sequential boarding, the seventh/eighth window rendering, the eight-stamp grid, updated completion counts, muted play, and pause/resume. The full-screen win panel fits all eight animal illustrations in two rows.

The journal's “Read to me” control is a full-width 58-point rounded button with a speaker icon, play arrow, large rounded type, high-contrast gold fill, and pressed feedback. Each button announces the animal's name to VoiceOver. Verified the normal app launches through Adventures → Noah → Gather Animals. Reviewed the new rounded buttons in the journal and tapped the lion’s read-aloud control. The normal simulator is left on the journal with the buttons visible. RootView() is restored and git diff --check passes.
