# Roaring Beast facial artwork

Current implementation: see “Reference-matched sculpted characters” below. Earlier texture prompts are retained as artwork provenance.


## Reference-matched sculpted characters

The current David follows `BibleQuest/Assets.xcassets/davidFullBody.imageset/davidFullBody.png`: large green eyes, youthful cheeks, warm smile, voluminous swept chestnut hair, cream linen, wine wrap, rope belt and leather accessories. The face texture is mapped to a higher-resolution head with deeper nose, cheek and eye relief. Hair uses volumetric tapered locks with longitudinal fur UVs. This is a procedural 3D interpretation of the illustration, not an exact artist-authored rigged replica.

The lion uses the existing detailed face artwork on a deep muzzle sculpt, a modeled nose and whiskers, and a continuous grooved mane with flowing fur detail and silhouette wisps. It no longer uses concentric rows of petal-shaped mane meshes. Lighting uses less ambient fill and bloom to retain shape and surface detail.

Both assets below were generated with the built-in `image_gen` tool and are bundled locally:

- David face: `BibleQuest/Assets.xcassets/RoaringDavidFace.imageset/face.png`
- Long mane fur: `BibleQuest/Assets.xcassets/RoaringMane.imageset/mane.png`

Final David prompt:

```text
Use case: identity-preserve. Reference image is the exact character identity and rendering style required, especially his face. Produce a production facial albedo texture for this SAME David, not a redesign, not photorealism. Square front-projected face texture, entire canvas filled edge-to-edge with his warm peach skin, no head outline, no hair, no ears, no neck, no clothing. Beautiful polished hand-painted animated feature-film detail. MATCH the supplied reference's large emerald green eyes, very dark chestnut curved expressive eyebrows, charming youthful rounded cheeks, tiny rounded nose, subtle happy open smile with narrow ivory upper teeth, pink lower lip, lively kind expression. Perfect straight front view, both eye centers x33% and67%, y43%, eye width19% image, eye height22%; eyebrow arches y29%; small nose center x50%,y57%; mouth center x50%,y70%, width28%, corners y67%, lower lip y75%, chin y85%. Preserve exact reference character appeal, youthful face proportions and subtle warm shading; no skin pores, no freckles, no adult realism. Uniform skin along all edges. Neutral diffuse light, no harsh cast shadows, no strong highlights. No text, no background objects, no UV grid.
```

Final mane prompt:

```text
Use case: stylized-concept. Production albedo texture for a curved 3D lion mane mesh. Seamless tileable square, entire image filled with rich dark chestnut and warm copper lion mane fur. Long gently wavy thin tapered hair locks flowing vertically from top to bottom, hundreds of finely defined strands grouped into softly layered natural fur, subtle organic tonal variation, groomed full thick fur with refined animated-feature-game quality. Flat orthographic diffuse material only, neutral evenly lit with no directional shadows, no highlight gradients, no animals, no face, no objects, no background, no borders, no text. Warm brown monochrome range, medium detail with soft narrow strand highlights, luxurious natural fur, never scales or feathers or petals. Tileable at all edges.
```


## Earlier artwork provenance

The faces use painted diffuse textures on continuous sculpted SceneKit heads. The surface includes nose, cheek, eye-socket and muzzle relief. No floating eyes, cheek discs or mouth tubes are used. David's hair is a groomed crown with shallow swept locks. Character animation, controls, collisions and scoring remain in the existing runner implementation.

Generated with the built-in `image_gen` tool. The David reference is `/Users/shtu/Desktop/davidFullBody.png`. Final texture files are bundled in the app's asset catalog.

## RoaringDavidFace

Saved path: `BibleQuest/Assets.xcassets/RoaringDavidFace.imageset/face.png`

Final generation prompt:

```text
Use case: identity-preserve. Asset type: front-projected facial albedo texture for an actual sculpted 3D game head, square 1024x1024. Input Image 1 is the character identity reference ONLY. Reproduce precisely the charming young shepherd boy David's facial identity: very appealing green eyes, expressive relaxed dark chestnut eyebrows, warm peach skin, sweet confident asymmetric smile, soft youthful cheeks, small natural nose, high-end animated-film character artistry. Deliver a FRONT-ON, perfectly symmetrical orthographic face paint texture, straight gaze. NO hair, NO ears, NO neck, NO clothing, NO head outline, NO silhouette, NO background objects. The entire square is filled edge-to-edge with uniform warm peach skin albedo; face features painted in the middle, softly blending into the continuous skin around all edges. The image is not a portrait with a cutout background: it is a texture map of a face on a flat square skin surface. Feature layout exact: eye centers at (33%,43%) and (67%,43%), softly almond eye shapes with naturally seated lids, green irises, pupils looking directly forward and coherent tiny catchlights; eyebrow centers at y31%; small nose centered x50%, y57%; restrained friendly smile centered at x50%, y70%, width30%, corners at y67%, small upper row of ivory teeth and warm mouth interior; chin at y86%. Broad smooth forehead in top quarter. Soft blush blended into cheek skin, NO circular pink cheek discs. Restrained neutral diffuse illumination only, no directional cast shadows or glossy plastic highlights, no heavy outlines, no protruding spherical eyes, no exaggerated eye bulge, no grin stretched across face. Preserve reference's attractive eye shape, youthful face, color and warm friendly expression. No text, no UV grid, no borders.
```

## RoaringLionFace

Saved path: `BibleQuest/Assets.xcassets/RoaringLionFace.imageset/face.png`

Final generation prompt:

```text
Use case: stylized-concept. Asset type: square front-projected facial albedo texture for a sculpted three-dimensional lion head in a polished stylized adventure game. Not an illustration of a lion head on a background: an edge-to-edge flat skin and fur texture map with face features painted in the middle. Entire image filled with evenly lit short tawny golden lion fur, seamlessly the same soft golden tan at all four edges. Perfectly front-on symmetrical face, no perspective. Intelligent fierce but family-friendly noble adult male lion, high-quality animated film design. Anatomically coherent face with almond-shaped amber eyes naturally seated beneath a broad forehead, small dark round pupils, black eyelid rims extending subtly to inner tear ducts; eye centers at x32% and x68%, y40%. Nose bridge at x50% y50%. Natural black softly triangular lion nose centered at x50%,y58%, width21%; broad creamy ivory whisker pads centered at x39% and61%,y68%, gently blended into the golden cheek fur; tiny charcoal whisker follicles, clean dark mouth line centered y77%, relaxed closed mouth, cream lower chin y85%. No ears, no mane, no head outline, no silhouette, no neck, no body, no background objects, no text, no UV grid, no borders. Subtle short hair texture and softly modeled face markings, neutral flat diffuse illumination without cast shadows. No separate spherical eyeballs, no cross-eyed pupils, no sausage muzzle shapes, no human eyebrows, no smile or goofy expression.
```


## October 2026 character polish

David now uses a smaller, longer head, rounded sleeve shoulders, darker chestnut hair with fine swept locks, and a naturalistic face with smaller eyes and a restrained closed smile. The lion has four overlapping mane layers, a larger ruff, raised fine strands, and deeper nose/whisker-pad relief. Faces use less emissive fill so scene lighting can reveal their shape. Both remain articulated 3D characters; movement and collision rules are unchanged. The David rig is also used by Elah Crossing.

Replaced asset: `BibleQuest/Assets.xcassets/RoaringDavidFace.imageset/face.png`.
Generated using the built-in `image_gen` tool, editing the previous face texture.

Final generation prompt:

```text
Edit target: supplied square front-projected facial texture for David in an actual 3D adventure game. Keep EXACT feature layout / coordinates and skin filling all edges, no head silhouette, no ears, no hair, no neck, no objects. Upgrade this cheap cartoon face into a refined naturalistic hand-painted game character, young adolescent ancient Israel shepherd, warm olive-peach skin, green hazel eyes. Reduce eye SIZE substantially (about 30 percent smaller) around their existing centers at x33%,67%, y43%; almond-shaped lids, believable iris/pupil proportions, subtle catchlights, individually defined fine dark eyebrows centered y29%. Sharper natural nose at x50% y58%; calm subtle closed-lip confident smile at x50% y71% (no open grin, no visible teeth). Delicate freckles, restrained cheek color, fine natural skin detail, beautiful realistic youthful anatomy, no exaggerated animation or baby proportions, no glossy toy look. Maintain even diffuse albedo lighting, smooth matching warm skin at all edges; nose and cheeks softly shaded only, no cast shadows. Square high resolution production texture, no text.
```


Validation: iOS simulator app build passed. The actual canyon scene was visually inspected in the intro camera and in a simulated chase/jump pose. Geometry and facial features remained attached through the chase animation. Gameplay rules and collision logic are unchanged.
