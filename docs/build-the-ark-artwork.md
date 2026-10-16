# Build the Ark — Hunt, build, create

The former God's Call workshop now belongs to the second Noah stop, Build the Ark. The first stop opens its story sheet. Existing earned workshop completion is preserved under the new Build the Ark progress key; legacy keys are read for migration and no longer receive game completion writes.

Children sweep foliage off five hidden beams in a sunlit grove, then drag each beam into a timber basket. A clue button highlights the next hiding place. Three draggable decks snap into their matching shadows on the real SceneKit model. The final paint studio offers five colors and an illustrated brush: drag it onto the hull, then sweep real brushstrokes over its surface. Switching colors layers paint rather than replacing a flat section; inside and outside retain separate painted textures. Both sides need 75% coverage before the reveal is offered, and children may continue decorating before choosing it.

## Learning and source

[Genesis 6:14–22, KJV](https://www.biblegateway.com/passage/?search=Genesis+6%3A14-22&version=KJV) provides the wood, three decks, and protective pitch themes. Spoken guidance is narrator paraphrase. The miniature, timber hunt and colorful paint palette are imaginative play. Parent notes explicitly distinguish decorative colors from the biblical protective pitch and explain the open cutaway as a teaching aid.

## Generated artwork

Created with the built-in image generation tool. Both final assets are saved in the project. The ark, wood grain, ghost decks, brass details, pitch patches, interaction targets and particles are native code, not baked into the scenery.

### NoahCallWorkshop

Saved: `BibleQuest/Assets.xcassets/NoahCallWorkshop.imageset/art.png`

Original: `/Users/shtu/.codex/generated_images/01a13b22-d649-7451-bfb5-582fd71df518/exec-cfb0f534-38df-46f4-8dc3-e07a1b1f9d37.png`

Transparent: false

References: None

Final prompt:

Use case: stylized-concept. Asset type: full-bleed environment art for an exquisite children's Noah's Ark iOS game, God's Call. Primary request: a breathtaking sunlit ancient carpenter's workshop open to a lush peaceful valley BEFORE the flood. Portrait 1024x1536, rich animated-feature 3D environment rendering, warm honey wood, sage foliage, teal distant mountains, tiny soft peach wildflowers, luminous morning dust. Composition: a beautiful broad EMPTY walnut worktable fills the LOWER HALF, its uncluttered tabletop in perspective visible from a slightly elevated camera. The top half is spacious soft out-of-focus blue-green valley and olive trees through the open workshop; slender timber posts frame only extreme left and right edges, a few neatly stored period hand tools far to left. Keep CENTER 70 percent of tabletop completely empty for an interactive 3D miniature ark rendered by the game. No people, NO ARK, no boats, no large foreground objects, no rainbow, no UI, no text, no letters, no modern tools, no logos, no borders. Exquisite tactile carved wood edge details and soft atmospheric sunlight, cozy inviting and safe for children ages 4 to 10. No dark storm mood.

### NoahCallGuide

Saved: `BibleQuest/Assets.xcassets/NoahCallGuide.imageset/art.png`

Original: `/Users/shtu/.codex/generated_images/01a13b22-d649-7451-bfb5-582fd71df518/exec-8d7a2c73-8c23-4a9c-9425-168d2ee4f03a.png`

Transparent: true

References: None

Final prompt:

Use case: stylized-concept. Asset type: one transparent Noah character cutout for an exquisitely designed children's Noah's Ark game. A warmly appealing wise elderly Noah, full body, three-quarter view facing slightly LEFT toward a little model on a table, one open hand extended invitingly and the other holding a small rolled parchment at his waist. Beautiful kind NATURAL proportioned face, lively warm brown eyes, thick softly wavy silver-white beard and swept silver hair, friendly relaxed smile, olive skin, thoughtful brows. Simple cream linen ankle-length robe, muted teal draped shoulder mantle with leather belt, brown leather sandals. High-end animated-feature 3D character rendering, exquisite cloth weave, detailed well-groomed beard strands, rounded elegant anatomy, warm sunlight edge highlights with soft cool fill. Head moderately stylized and charming, not enormous, not caricature. Entire body including sandals and hands visible, 10 percent clear padding around silhouette. Portrait 2:3 composition, genuinely transparent background outside Noah. No scenery, no table, no ark, no UI, no text, no halo or divine depiction, no letters, no border. No extra fingers.


### ArkTimberGrove

Generated with the built-in image generation tool for this refinement.

Saved: `BibleQuest/Assets.xcassets/ArkTimberGrove.imageset/art.png`

Original: `/Users/shtu/.codex/generated_images/01a13b22-d649-7451-bfb5-582fd71df518/exec-78c31d13-f5b1-4948-92f2-776e165ea196.png`

Transparent: false. References: none.

Final prompt:

Use case: stylized-concept. Asset type: background for a premium children's Noah's Ark hidden-timber hunt. Beautiful top-down gently angled forest-floor environment in a sunlit ancient olive-and-cedar grove BEFORE the flood. Portrait 1024x1536. Rich stylized animated-feature 3D rendering, exquisite tactile moss, warm ochre soil, pine needles, fresh clover, tiny buttercup flowers, scattered flat smooth pebbles, a cut tree stump ONLY at extreme upper left, a partial wicker basket ONLY at extreme lower right edge, lush fern fronds and olive foliage framing extreme corners. Composition: broad continuous earthy ground with dappled warm morning light and soft leaf shadows, usable empty soil patches across central EIGHTY percent so the game can place its own interactive leaves and wood. Strong ground-plane clarity, no horizon, no sky. Colors sage, forest green, golden ochre, muted honey, soft teal shadows. Inviting miniature storybook world for children ages4to10, highly polished. NO timber beams, NO logs in center, no people, no animals, no boats, no UI, no text, no lettering, no borders, no fantasy glowing objects. Ground details must remain legible at phone size.

## Audio and implementation

Six original synthesized WAVs under `BibleQuest/Noah Games/Audio/Call/` are reused for wood, brush, fit, discovery, finale and ambience. Native AVSpeechSynthesizer provides replayable spoken guidance and captions. Sound and silent mode are respected; VoiceOver announcements replace competing narration.

`ArkWorkshopRound` validates uncovering before delivery, valid basket drops, deck matching, selected paint color and brush, UV coverage, both-side completion, explicit reveal, pause and replay. `ArkWorkshopScene` projects deck slots and ray-tests brush samples against the 3D painting surfaces. It draws bristled strokes into independent UV textures, preserving all previous colors. The controller interpolates fast input between screen samples. Native gestures move leaves, beams, decks and the on-screen brush; VoiceOver custom actions provide collection and painting alternatives.

Reduced Motion suppresses drifting particles and long transitions. Rotation and backgrounding pause the round, preserving the model and its paint. Replay clears both textures and every interaction state.

Completion is recorded locally per user (`.buildComplete` and `.buildPending`) before saving `Users/<uid>/Adventures/Noah/BuildTheArk = true`. Legacy workshop completion in `.callComplete` / `GodsCall` migrates to the new key without erasing historical data. Noah's final Hero Album reward still belongs to Rainbow Promise.
