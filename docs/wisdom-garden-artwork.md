# Wisdom Garden artwork

Generated using the built-in `image_gen` tool. Final project asset: `BibleQuest/Assets.xcassets/WisdomGarden.imageset/garden.png`. The illustration is decorative; verses, references, activities and controls are native accessible SwiftUI content.

Final generation prompt:

```text
Use case: illustration-story. A gorgeous premium children's Bible app illustration for a 'Wisdom Garden'. Wide landscape composition, 3:2 aspect ratio. A small open book with completely blank cream pages resting on a smooth mossy stone in a lush peaceful garden, a delicate bright green sapling growing just beside the book, luminous warm golden sun behind the sapling, tiny glowing fireflies, soft coral and lavender wildflowers, rounded leafy branches framing the upper edges, a tranquil turquoise stream winding into softly painted distant hills. The open book and sapling form one clear focal point centered in the middle horizontal band so it crops beautifully as a short wide banner. Refined cinematic hand-painted storybook artistry with soft sculptural depth, subtle gouache brush texture, beautiful layered light, warm apricot and honey sky, sage and turquoise greenery, lilac and peach accents. Beautiful, calm, hopeful and full of wonder, clean readable composition, richly crafted, not flat icons, not emoji, not cheap clipart. NO text, no lettering, no words on pages, no numbers, no border, no people, no depictions of God. Full edge-to-edge opaque artwork.
```


## Validation

The iOS simulator build passed. The production Wisdom view was checked in an isolated simulator preview for topic switching, verse saves and reopening, expanded reflections, daily practice marking, persistence across relaunch, unsaving and empty collection states, larger text, and quiz entry/answer/progression. A preview-only expired-date fixture confirmed that practice resets on a new day while saved verses remain. All six original verses/references and the original three quiz implementations and question data are unchanged. Animations are gated by Reduce Motion; continuous sparkle animation also pauses outside the active scene.
