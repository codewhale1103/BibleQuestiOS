# Roaring Beast: canyon runner

The game uses native SceneKit rendering through Metal. David, the lion, the terrain, trees, obstacles and refuge gate are articulated or procedural 3D geometry, with no downloaded model dependencies. World-space game rules live in `RoaringRun.swift`, separate from rendering. The original 30-second, three-lane dodge-and-jump chase remains; three courage shields allow recovery from two collisions.

Terrain and foliage textures were generated with the built-in imagegen tool, then saved locally as optimized JPEGs. The original running soundtrack is retained. Jump and impact WAVs are original synthesized cues in `BibleQuest/David Games/Audio/Roaring/`.

## RoaringFoliage

Saved path: `BibleQuest/Assets.xcassets/RoaringFoliage.imageset/texture.jpg`

Final generation prompt:

```text
Use case: stylized-concept. Asset: seamless tileable opaque albedo texture for foliage on 3D olive trees in a beautiful ancient Israel canyon adventure game. Square 1024x1024. Dense overlapping tiny silvery olive-green leaves and warm moss green leaf clusters fill the ENTIRE canvas, richly detailed painterly natural foliage, no discernible single plant silhouette, no branches larger than tiny twigs. Subtle varied leaf orientations and organic dappled tones, sophisticated storybook 3D game texture, evenly lit flat diffuse material without any major shadows or directional light. No backdrop, no empty spaces, no transparent holes, no pots, no trees as whole objects, no grass, no text, no frame, no scene, no sky. Leafy material texture covers all four edges, seamless and natural, calm cohesive muted olive greens.
```

## RoaringSandstone

Saved path: `BibleQuest/Assets.xcassets/RoaringSandstone.imageset/texture.jpg`

Final generation prompt:

```text
Use case: stylized-concept. Production diffuse texture for a native 3D biblical canyon runner game. A seamless tileable square material texture of ancient sun-warmed pale golden sandstone rock, warm honey ochre and cream beige, finely textured chalky natural stone, subtle layered sedimentary bands and fine believable weathering. High-end painterly 3D adventure game finish, tactile but calm, medium detail without obvious large feature repetition. Flat evenly lit material albedo viewed perfectly straight-on, NO shadows, no directional lighting, no perspective, no scene, no horizon, no rocks as isolated objects, no text, no frame. Edge-to-edge seamless stone surface, no black cracks, no scattered objects. Square 1024x1024.
```

## RoaringTrail

Saved path: `BibleQuest/Assets.xcassets/RoaringTrail.imageset/texture.jpg`

Final generation prompt:

```text
Use case: stylized-concept. Production diffuse texture for a native 3D biblical canyon runner game. Seamless tileable square texture of an ancient golden sandy footpath in the Valley of Elah, warm muted tan earth and pale ochre dust, subtle fine pebbles and gentle uneven sandy grains. Mostly calm readable terrain, soft naturally painterly 3D game material, no large rocks, no large shapes, no grass, no roads or lane markings, no footprints, no text. Perfect flat orthographic view straight down. Even diffuse lighting, NO directional shadows, no perspective, no scene or horizon, no border, no gradients. Edge-to-edge seamless sand and tiny gravel surface, 1024x1024 square.
```



## Character refinement

David and the lion are articulated SceneKit geometry, built in `BibleQuest/David Games/RoaringCharacters.swift`. David's design follows the supplied `davidFullBody.png`: chestnut swept locks, green eyes, cream linen, wine-colored wrap and cape, twisted rope belt, leather bracers, sandals and sling. Swept tapered meshes form hair and mane; cloth rings and pleated cloth panels form the outfit. Cape, rope tassels, head and limb motion are animated independently. The lion has shoulder and haunch volumes, jointed legs, toes, claws, amber eyes, muzzle details and a curved tufted tail. Collision rules are unchanged.

The following textures were generated using the built-in `image_gen` tool and copied into the project. No character sprites or billboard replacements are used.

### RoaringLinen

Saved asset: `BibleQuest/Assets.xcassets/RoaringLinen.imageset/texture.png`

Final prompt:

> Use case: stylized-concept. Asset type: seamless tileable albedo material for a real-time 3D animated adventure game. Primary request: a close, perfectly flat square swatch of finely woven natural linen, warm ivory monochrome, subtle irregular fiber detail, small dense weave, delicate soft thread variation. Orthographic flat material scan, even neutral illumination, no directional lighting, no shadows, no folds, no objects, no borders, no text. Restrained polished animated-film surface, realistic fibers without harsh contrast. Edges must tile seamlessly. It will be multiplied by cream and burgundy fabric colors on 3D clothing. Entire square fully filled with woven linen.

### RoaringFur

Saved asset: `BibleQuest/Assets.xcassets/RoaringFur.imageset/texture.png`

Final prompt:

> Use case: stylized-concept. Asset type: seamless tileable albedo material for a real-time 3D animated adventure game character. Primary request: an extremely close flat swatch of short dense sleek lion fur, softly flowing top to bottom, uniform warm pale beige monochrome, subtle fine individual hairs and soft clumped microstructure. Entire square filled with fur only. Orthographic material scan under completely even neutral diffuse illumination. No animal, no face, no anatomy, no large clumps, no dark patches, no shadows, no lighting gradient, no objects, no borders, no text. Refined animated feature-film quality, understated smooth groom. Edges must tile seamlessly. It will be multiplied by golden tan and brown colors on actual 3D geometry.
