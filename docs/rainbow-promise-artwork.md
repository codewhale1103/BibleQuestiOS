# Rainbow Promise artwork and learning notes

A rainbow-weaving game for the final Noah stop. Children choose seven colors in order and trace glowing arcs, or tap five guiding stars per band. Three discoveries explore the covenant in Genesis 9. The seven colors are a learning device for one covenant, not seven separate biblical promises. A gradual lighting change, musical glints, rippling reflections, light particles and a soaring dove animate the completion.

## Educational sources

The story questions and explanations paraphrase [Genesis 9:8–17, KJV](https://www.biblegateway.com/passage/?search=Genesis+9%3A8-17&version=KJV). They distinguish the promise about a flood destroying all life from a claim that rain or local flooding would never happen.

The optional science sheet explains sunlight, raindrop refraction/reflection and the continuous spectrum, using [NASA’s Rainbow at Sunset explanation](https://science.nasa.gov/image-article/apod-2010-august-7-rainbow-at-sunset/) and [NASA’s visible-light overview](https://science.nasa.gov/ems/09_visiblelight/). It uses seven familiar color names, placing red on the outer edge and violet on the inner edge of the primary bow. The landscape and dove are artistic illustrations, not scientific diagrams or reconstructions.

## Generated artwork

Both assets were generated with the built-in image generation tool and saved inside the project. The interactive rainbow, stars, trails and effects are code-native SwiftUI Canvas.

### RainbowPromiseValley

Saved: `BibleQuest/Assets.xcassets/RainbowPromiseValley.imageset/art.png`

Original: `/Users/shtu/.codex/generated_images/01a13b22-d649-7451-bfb5-582fd71df518/exec-2ceb7566-42b0-4180-a865-03a001d57666.png`

Transparent: false

References: None

Prompt:

Use case: stylized-concept. Asset type: full-bleed portrait environment for an exquisite educational Noah's Ark rainbow-weaving iOS game. A breathtaking renewed world after the rain, peaceful ancient mountainous valley with rich olive groves, soft snow-dusted distant Ararat-inspired peaks, a small warm walnut Noah-style ark resting safely on a grassy hillside in the LOWER LEFT, a few very small pairs of friendly animals walking into fresh meadow nearby, and a serene clear turquoise pool in the bottom foreground with tiny wildflowers and naturally scattered wet stones. Camera looks across the valley from a gently elevated meadow. Composition critical: portrait 1024x1536; top SIXTY-FIVE PERCENT is spacious beautiful EMPTY luminous pearl-blue and muted teal sky with a few graceful soft silver clouds along EXTREME LEFT and RIGHT edges only; all hills, ark, animals and meadow kept in LOWER THIRTY-FIVE PERCENT. Large completely open central sky is for the game to draw its own interactive rainbow. Wonderful cinematic feature-animation environment art, highly refined rich 3D natural materials, exquisite sunlight streaming softly from upper left after a storm, fresh rain-washed greens, honey gold, warm cream, blue lavender distant haze, tranquil hopeful mood. No large foreground character, no text, no UI, no logos, NO RAINBOW or colored arcs, no stars or floating fantasy objects, no borders.

### RainbowPromiseDove

Saved: `BibleQuest/Assets.xcassets/RainbowPromiseDove.imageset/art.png`

Original: `/Users/shtu/.codex/generated_images/01a13b22-d649-7451-bfb5-582fd71df518/exec-eafe569c-237f-4779-96c4-aa6f63b5e59d.png`

Transparent: true

References: None

Prompt:

Use case: stylized-concept. Asset type: one transparent hero dove for a premium Noah's Ark educational game finale. One graceful beautiful white dove in three-quarter side view flying toward RIGHT, wings elegantly extended upward and slightly back, full both wings and tail visible, carrying a tiny fresh green olive twig in its small beak. Gentle intelligent natural dark eyes, softly detailed white and cream feathers, delicate peach feet tucked back, charming but anatomically believable proportions, refined high-end animated-feature 3D rendering with warm gold sunlight edge highlights and subtle cool teal fill. Elegant soaring silhouette that reads clearly at small sizes, serene hopeful expression. Landscape3:2 canvas, whole bird and olive twig centered with 10percent clean padding around ALL edges. Genuinely transparent background everywhere outside the bird and twig, clean alpha edge. No scenery, no sky, no cloud, NO glow or aura, no shadow outside silhouette, no letters, no border.

## Audio and integration

Ten original synthesized WAV files under `BibleQuest/Noah Games/Audio/Rainbow/` provide seven color tones, a bloom chord, a resolving arpeggio and a seamless valley pad. No commercial recordings were used. Silent mode and the sound toggle are respected.

`RainbowPromiseRound` owns ordered weaving, mistakes, scoring, discoveries, pause and replay. `RainbowPromiseController` synchronizes rendering, touch interpolation, sound and haptics with a weak-target display link. `RainbowPromiseGame` uses native navigation from the final Noah chapter. On earned completion, the map records `Adventures/Noah/RainbowPromise` and `HeroAlbumUnlocked/Noah` in one Firebase update; isolated previews do not call this integration.

Completion is also recorded locally per user before the network update. A pending flag allows a failed online save to be retried from the map without replaying the round.

## Validation

- Seven model tests passed: full completion, drawing/tap parity, invalid and out-of-order input, gentle retries without score farming, pause preservation, replay reset, and rainbow geometry.
- Simulator playthrough completed all seven ribbons and three discoveries, including an incorrect answer followed by a successful retry. Direct dragging and accessible star buttons both advanced the weave. Pause, learning-sheet presentation, completion, and replay were checked visually; portrait and landscape layouts were reviewed.
- Isolated gameplay QA used a nil completion callback and did not write adventure completion or album unlocks to Firebase. Online save integration is implemented, but was not exercised against a live account during QA.
- The normal app entry was restored and the final Noah chapter's play button was verified to launch the game. Native full-screen presentation and an explicit map-owned exit callback keep return navigation inside Noah's voyage; intro and paused exits were verified in the final build.
- Final simulator and signed generic iOS builds passed. The device app passed strict recursive code-signing verification.

