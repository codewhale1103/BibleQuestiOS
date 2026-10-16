# Song of Courage artwork

A playable musical finale for the seventh David stop. Inspired by David playing the harp (1 Samuel 16:23); the camp celebration is a game interpretation, not a depiction of a specific recorded event. Existing Firebase `Victory` and Hero Album keys are preserved.

The built-in image generation tool produced these project assets. Native SwiftUI Canvas adds the strings, ribbons, vibrating highlights, jewels, particles, illuminated camp and finale. No image generation is needed at runtime.

## VictoryTwilightCamp

Saved: `BibleQuest/Assets.xcassets/VictoryTwilightCamp.imageset/art.png`

Original: `/Users/shtu/.codex/generated_images/01a13b22-d649-7451-bfb5-582fd71df518/exec-71b24c0c-f779-4621-b135-4e8ecaed0546.png`

Transparent: false

Reference: None

Prompt:

Use case: stylized-concept. Asset type: full bleed portrait environment painting for a premium biblical musical game finale. Primary request: a breathtaking ancient Israelite camp in the Valley of Elah at peaceful blue hour after sunset, joyful and safe, cinematic animated feature production art with exquisitely tactile natural materials. Composition: portrait 1024x1536, upper half rich luminous indigo and teal sky with wispy lavender clouds, first tiny stars, soft amber sunset at distant layered hills. Middle third graceful olive tree on the far LEFT edge, several cream linen tents and maroon banners in a semicircle across distant slopes, tiny warm oil lamps with restrained amber points at tent entrances. Lower half open beautifully textured dark sandy earth and small grass patches, EMPTY central foreground so a large playable harp can be overlaid by the app. Clear spacious depth with very small distant silhouettes celebrating only far back near tents, no main character. Palette deep ink blue, petrol teal, dusty lavender, antique honey gold, warm cream. Gorgeously lit cinematic high-end 3D animated-film background with painterly sophistication, elegant and atmospheric, not flat cartoon. No large foreground props or people, NO instruments, NO UI, NO text, no letters, no logos, no floating lanterns, no confetti.

## VictoryDavidHarp

Saved: `BibleQuest/Assets.xcassets/VictoryDavidHarp.imageset/art.png`

Original: `/Users/shtu/.codex/generated_images/01a13b22-d649-7451-bfb5-582fd71df518/exec-b216839c-e6c7-4bac-9f62-0278a2faf884.png`

Transparent: true

Reference: /Users/shtu/Desktop/All Projects/BibleQuestiOS/BibleQuest/Assets.xcassets/davidFullBody.imageset/davidFullBody.png

Prompt:

Use case: identity-preserve. Asset type: transparent character illustration for a premium biblical musical game. Image1 is an exact identity and outfit reference for David. Preserve his appealing young face, fluffy swept chestnut hair, naturally seated expressive large green eyes, peach skin, cream linen tunic, diagonal maroon cloak, braided rope belt, leather bracers and strapped sandals. Change pose: David sits comfortably on a small natural limestone rock, full body in three quarter view toward RIGHT, smiling gently and looking at the small exquisitely carved ancient wooden lyre held in his lap, fingers naturally plucking its strings. Charming and refined anatomy, natural musician hands, NO sling or weapon, no armor, no crown. Premium animated-feature 3D illustration, finely detailed cloth weave, soft hair highlights, moonlit cool fill and warm amber lantern rim lighting, cheerful serene expression, beautifully rendered rich materials. Portrait 2:3 composition, entire hair, lyre, rock, sandals visible filling 90percent canvas, clean padding around full silhouette. Genuinely transparent background outside David, instrument and rock. No ground or floor or shadows outside silhouette, no halo or speckles, no scenery, NO text or border.

## VictoryLyreFrame

Saved: `BibleQuest/Assets.xcassets/VictoryLyreFrame.imageset/art.png`

Original: `/Users/shtu/.codex/generated_images/01a13b22-d649-7451-bfb5-582fd71df518/exec-1d046957-9c2f-4582-acbe-883568b76537.png`

Transparent: true

Reference: None

Prompt:

Use case: stylized-concept. Asset type: transparent interactive instrument frame for an iOS music game. Primary request: one exquisite ancient Hebrew wooden lyre frame with NO STRINGS, perfectly straight FRONT-ON orthographic view, upright and symmetrical. Portrait 2:3 silhouette. Two graceful curving upright arms carved from rich warm walnut wood, flaring elegantly outward at top like gentle horns, connected near their tops by a straight horizontal polished bronze crossbar; broad gently curved wooden resonator soundbox across the bottom 20percent with small ornamental rosette carving. Large clean completely EMPTY transparent open rectangular space inside frame, from crossbar at 17percent height to top of soundbox at 80percent height, because game will add three luminous interactive strings. Outer arms slender and refined, occupy only outer 15percent width. Gorgeous inset antique brass filigree of olive leaves following wooden arms, cream mother-of-pearl small geometric accents, fine tactile walnut grain, restrained carved details. NOT a triangular harp, must be upright open U-shaped ancient lyre with horizontal crossbar. Full frame centered, entire edges inside canvas with 6percent padding. Premium high-end 3D animated-feature game asset, warm golden highlights and subtle teal blue cool rim, incredibly sophisticated materials, pleasing readable silhouette. Genuine transparent background including center open area. NO STRINGS, NO HANDS, no person, no ground, no floor, no shadow outside silhouette, NO glow, NO lettering, no border.

## Audio and mechanics

Original synthesized plucked-string notes, a seamless night pad, count-in and resolving arpeggio are saved under `BibleQuest/David Games/Audio/Victory/`. No external recordings were used. The song has 36 notes in three passages, including six sustained ribbons. Catch at least 20 notes to complete it. Gentle timing widens the catch window without changing the tune. VoiceOver activation sustains caught ribbons automatically. Sound respects silent mode, Reduced Motion suppresses string displacement and moving particles, and interruption or rotation pauses the song. Resume counts in before restoring the same musical moment.


## Validation

Seven gameplay tests pass. The perfect-song test runs at 30, 60 and 240 steps per second and verifies all 36 notes, six ribbons, the exact score and one completion event. Other tests cover wrong strings, repeated taps, hold release, practice/replay, pause during a ribbon, interrupted resume countdown, invalid time and the 20-note completion threshold.

Native simulator touch play caught 36/36 notes, illuminated 12/12 lights and earned a three-star victory. The practice path and pause screen were also inspected, along with portrait gameplay and the landscape introduction. The final iPhone device build succeeds and its code signature passes strict verification. Normal app startup is restored. Trophy persistence uses the existing atomic Firebase update; a failed save can be retried from the map without replaying the song. No live account progress was modified during the isolated game preview.
