# The Dove Returns — Wings of Hope

Native SwiftUI game, created 2026-10-17. Entry: Noah's Adventure, chapter 6.

Three guided flights follow Genesis 8:8–12. The first returns with no resting place; the second follows a seven-day wait and brings a fresh olive leaf home at evening; the third follows another seven-day wait and stays away. The imagined coastline, branch and nature discoveries are described as a play setting in the in-game journal. Noah does not leave the ark during this chapter. The final Noah album unlock remains with Rainbow Promise.

## Artwork and animation

All nine assets were generated with the built-in OpenAI image_gen tool. Exact prompts, original paths and final project paths are in [dove-voyage-prompts.json](dove-voyage-prompts.json). Generated originals are preserved. No external stock illustrations or movie imagery were used.

- `BibleQuest/Assets.xcassets/DoveMorningSea.imageset/DoveMorningSea.png`: silver morning water.
- `BibleQuest/Assets.xcassets/DoveSunsetSea.imageset/DoveSunsetSea.png`: golden homeward sea.
- `BibleQuest/Assets.xcassets/DoveLivingCoast.imageset/DoveLivingCoast.png`: receding water, green coast and waterfall.
- `BibleQuest/Assets.xcassets/DoveFlightBody.imageset/DoveFlightBody.png`: pearl-white flying body, transparent cutout.
- `BibleQuest/Assets.xcassets/DoveFlightWing.imageset/DoveFlightWing.png`: detached feathered wing rigged at the shoulder.
- `BibleQuest/Assets.xcassets/DovePerched.imageset/DovePerched.png`: matching perched bird.
- `BibleQuest/Assets.xcassets/DoveWelcomeWindow.imageset/DoveWelcomeWindow.png`: Noah's palm at the ark window.
- `BibleQuest/Assets.xcassets/DoveOliveBranch.imageset/DoveOliveBranch.png`: foreground olive branch.
- `BibleQuest/Assets.xcassets/DoveOliveLeaf.imageset/DoveOliveLeaf.png`: interactive fresh leaf.

SwiftUI animates two shoulder-pivoted wings, banking, gliding, reflections, perspective ripples, cloud shadows, glints, leaf sway, a seven-day sun/moon passage, and the final resting scene. Reduce Motion keeps a steady pose and removes decorative movement. The existing NoahVoyageArk artwork is reused near home.

## Audio

- Eighteen ElevenLabs Anna — Children's Book Narrator clips. Exact script, generation settings and durations: [dove-voyage-narration.json](dove-voyage-narration.json).
- These voice clips were generated on the account's Free plan and are for local preview. Regenerate under a paid commercial plan before commercial release. [ElevenLabs publication and commercial-use guidance](https://help.elevenlabs.io/hc/en-us/articles/13313564601361-Can-I-publish-the-content-I-generate-on-the-platform).
- Original instrumental composition **Wings of Hope**, 88 BPM, flute, harp, strings, cello and glockenspiel; 35.23 seconds. Renderer: `scripts/audio/render_dove_music.py`. Render notes and note events: [dove-voyage-music.json](dove-voyage-music.json).
- Acoustic instrument samples: VSCO 2 Community Edition, CC0, pinned commit `440300901dfe9275fd84e0b7763af1f8443ae62e`. Inventory: [rain-orchestra-music-samples.json](rain-orchestra-music-samples.json). License: [VSCO-2-CE-CC0.txt](licenses/VSCO-2-CE-CC0.txt). No film soundtrack, commercial recording, or copied melody is used.
- Dove coo: **mary905**, recorded 2008-04-30, released by the recorder into the public domain. [Source and dedication](https://commons.wikimedia.org/wiki/File:Dove_cooing.ogg), permanent revision 1211894320. Original Ogg URL: `https://upload.wikimedia.org/wikipedia/commons/0/05/Dove_cooing.ogg`. MP3 transcode decoded to mono PCM, DC removed, normalized to 0.7 peak and 50 ms edge fades. Bundled as `Audio/Dove/dove-coo.wav`. Species is a Barbary dove; this is an atmospheric cue, not an identification claim about Noah's bird.
- `dove-air`, `dove-wing`, `dove-leaf`, `dove-glimmer`: original designed air, feather and leaf Foley / discovery cue. These are designed effects, not field recordings. Splitter and Foley renderer: `scripts/audio/render_dove_voice_effects.py`.

All playback is local. Music ducks while Anna speaks. Pause and app backgrounding preserve playheads; exit and replay clear playback. Master mute controls every layer.

## Play and accessibility

Finger location creates a gentle horizontal breeze and sets altitude. Release creates a short glide. Follow the breeze assists one destination at a time. There are no collisions, damage, time limits, or losing states. Three close-ups support real drags with generous drop areas and equivalent accessible action buttons. Read to me is a large rounded speaker button. Flight status and discoveries have accessibility labels/announcements. Journal text remains available without relying on sound.

Completion is local-first with Firebase retry under `Users/<uid>/Adventures/Noah/DoveReturns`. Replay and exploration do not grant the final Noah album reward.
