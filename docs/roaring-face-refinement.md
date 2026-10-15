# Roaring Beast facial artwork

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

