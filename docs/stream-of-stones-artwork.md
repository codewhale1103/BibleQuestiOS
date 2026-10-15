# Stream of Stones artwork and implementation

Stream of Stones keeps the original 30-second bird-defense challenge. The game starts every attempt with five stones. Birds approach on seeded Bézier paths with a rising pace. Taps shoo birds away, consecutive taps build a score combo, and five taps charge a shepherd’s call that scatters the approaching flock. Unstopped birds visibly carry away a stone. At least one stone must remain after 30 seconds to complete the adventure. The round model is independent of rendering and has no delayed callbacks; pause and replay cannot leak bird arrivals into a new round.

The SpriteKit scene uses a water-refraction shader, articulated body/wing sprites, flight shadows, ripples, floating motes, feather particles, animated pouch inventory, and a staged opening. SwiftUI supplies accessible bird buttons, HUD, pause and end panels. Reduce Motion limits flutter and ambient effects. Bundled synthesized water, wing, bird, call and stone cues use an ambient audio session and respect the silent switch. Art was generated with the built-in `image_gen` tool.

## StreamSanctuary

Saved path: `BibleQuest/Assets.xcassets/StreamSanctuary.imageset/art.png`

Transparent background: false.

Final prompt:

```text
Use case: stylized-concept. Asset type: premium portrait background artwork for an interactive iOS game called Stream of Stones in David's biblical adventure. Beautiful high-end animated-film environment, three-quarter overhead view of a shallow ancient Judean spring in a lush little oasis, no characters. A clear luminous turquoise stream winds from upper-center distance through the middle and flows toward the lower-left foreground, visible golden sand and smooth pebbles under the water. Left and right banks frame open central play space, warm sunlit limestone ledges, rich moss, olive roots, elegant hanging willow branches near upper corners, delicate ferns, small pale wildflowers, soft amber sunlight filtering through leaves, luminous reflection and natural depth, very fine lovingly painted material detail, gorgeous atmospheric composition. At bottom center, a broad flat smooth sunlit limestone ledge at water's edge, deliberately EMPTY as a resting spot for a shepherd's pouch that will be added in-game. This ledge occupies the bottom20percent, shoreline in bottom third. Middle60percent calm readable blue-green water, do not overcrowd the playable center. Upper distance gentle limestone little cascade and olive grove softly hazy. Cohesive sophisticated warm golden cream, deep pine green, teal water palette. Tactile modern 3D adventure-game art with soft painterly finish, not vector or children's flat clipart. Portrait 1024x1536. No people, no birds, no bag, no stones pile on the central ledge, no UI, no icons, no letters, no border, no watermark. Full bleed environment, no black background.
```

## StreamBirdBody

Saved path: `BibleQuest/Assets.xcassets/StreamBirdBody.imageset/art.png`

Transparent background: true.

Final prompt:

```text
Use case: stylized-concept. Asset type: transparent game character cutout, articulated bird BODY ONLY, for a premium animated iOS adventure game. A beautiful small mischievous blue-gray jackdaw, elegant compact natural bird anatomy, dark charcoal-indigo head, intelligent warm amber eyes with small highlights, blue-slate back, soft silver-gray breast, tiny dark beak, slim little tucked feet and tapered charcoal tail. THREE-QUARTER OVERHEAD frontal view, facing DOWN toward bottom of image as though gliding toward the viewer, nose/beak at bottom end, tail feathers pointing upward. Body axis perfectly vertical, centered. High-quality richly shaded animated-film 3D game art, sculpted plumage with delicate feather details and soft golden rim light, appealing natural bird face, no goofy human expression. Important: NO WINGS at all, remove both wings entirely, wings will be separate animated geometry in the game. Body, head, tail and tucked feet only. Isolated single compact bird body on truly transparent background, full silhouette visible, no floor, no scenery, no cast shadow, no text, no border. Square canvas with ample transparent padding, centered body occupies75percent of height.
```

## StreamBirdWing

Saved path: `BibleQuest/Assets.xcassets/StreamBirdWing.imageset/art.png`

Transparent background: true.

Final prompt:

```text
Use case: stylized-concept. Asset type: one isolated LEFT WING cutout for an articulated small blue-gray jackdaw in a polished 3D animated adventure game. Single fully extended wing only, seen from above at a gentle three-quarter angle. Root/shoulder at far RIGHT at middle height, broad layered coverts toward the right, wing fans gracefully out toward the LEFT with long finely tapered charcoal-indigo primary feathers, silvery blue-slate secondary feathers and soft golden rim light along upper edge. Natural elegant bird anatomy, detailed sculpted feather overlap, tactile rich animated-film 3D render, subtle shape and lighting, not flat vector and not outlined cartoon. Horizontally oriented wing, single isolated wing on truly transparent background, entire feather silhouette visible with transparent padding all around. No body, no bird head, no second wing, no hands, no scenery, no floor, no cast shadow, no text, no border. Landscape composition, wing fills85percent of width. Root joint is at x90percent,y50percent.
```

## StreamPouch

Saved path: `BibleQuest/Assets.xcassets/StreamPouch.imageset/art.png`

Transparent background: true.

Final prompt:

```text
Use case: stylized-concept. Asset type: transparent foreground game prop for David's biblical adventure, an open shepherd's leather pouch. A beautifully crafted ancient warm cognac brown leather drawstring pouch resting upright, wide OPEN oval mouth visible viewed from a three-quarter overhead front angle, dark EMPTY inner cavity; no contents inside. Soft slouching leather walls with realistic stitched seams, elegant folded rim, braided leather cord and two small tassel ends falling down the front, tactile worn grain and warm sunlit edge highlights, detailed high-end animated-film 3D art, rich natural warm chestnut and tobacco brown palette. Single pouch centered, full silhouette with generous transparent padding. No stones inside, no contents, no hands, no person, no ground, no floor, no background, no cast shadow, no text, no symbols, no watermark. Truly transparent background. Broad enough mouth to fit five small stones added by code. Square canvas.
```

## StreamRiverStone

Saved path: `BibleQuest/Assets.xcassets/StreamRiverStone.imageset/art.png`

Transparent background: true.

Final prompt:

```text
Use case: stylized-concept. Asset type: one premium smooth river stone prop cutout for a 3D animated biblical adventure game. One beautiful oval, gently irregular flattened smooth river pebble, cool soft blue-gray slate with delicate milky mineral veins and subtly damp polished satin texture, rounded edges and soft warm sunlit rim highlights, viewed from a three-quarter overhead angle. Tactile high-end animated-film 3D rendering, restrained sophisticated detail, clean appealing silhouette readable at small size. Single isolated river stone only, centered and filling70percent of a square canvas, entire silhouette visible. Truly transparent background. No other stones, no hands, no ground, no floor, no water around it, no background, no cast shadow, no text, no outline, no border.
```

