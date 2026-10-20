# The Rain Orchestra — musical upgrade

Two offline instrumental recordings are made specifically for BibleQuest:

- **After the Rain** — original 12-bar melody in C major, 112 BPM, approximately 29 seconds. Flute lead, dancing harp and plucked string accompaniment, cello bass, glockenspiel, marimba, soft strings, shaker and tambourine. The composition and arrangement are newly written for this game. No David film melody, lyrics, performance, recording or artist voice is used.
- **Jesus Loves Me** — William B. Bradbury’s original 1862 public-domain refrain, transposed to C major with a newly created orchestral accompaniment, 104 BPM, approximately 21 seconds. Instrumental only. No existing commercial recording or modern arranger’s backing track is used.

Final app audio:

- `BibleQuest/Noah Games/Audio/RainOrchestra/Music/rain-song-after-the-rain.m4a`
- `BibleQuest/Noah Games/Audio/RainOrchestra/Music/rain-song-jesus-loves-me.m4a`

The song picker is available on the welcome screen, during play and on the completion screen. A visible Play/Pause control and progress line let children hear a whole song immediately. Playback begins with the game and can be paused independently. Narration automatically lowers the music; the three-note pattern demonstration lowers it further. Scene pause preserves music and speech positions; replay resets playback and exit stops all audio. Completed inventions let the selected melody continue without an automatic spoken interruption. Master mute applies to music, narration and effects.

## Instrument recording source and permission

All instrument source samples are from **VS Chamber Orchestra: Community Edition**, recorded by **Sam Gossner & Simon Dalzell**, sample cutting by **Elan Hickler / Soundemote**. The creator’s repository releases the library under **CC0 1.0 Universal**, including commercial reuse. Only newly rendered composite music recordings are shipped; the source library is not bundled with the app.

- Creator repository: https://github.com/sgossner/VSCO-2-CE
- Exact source commit: `440300901dfe9275fd84e0b7763af1f8443ae62e`
- License: https://github.com/sgossner/VSCO-2-CE/blob/440300901dfe9275fd84e0b7763af1f8443ae62e/LICENSE
- Preserved license: [VSCO-2-CE-CC0.txt](licenses/VSCO-2-CE-CC0.txt)
- Exact sample paths and pinned source: [rain-orchestra-music-samples.json](rain-orchestra-music-samples.json)

## Public-domain hymn sources

Hymnary identifies both Anna B. Warner’s original text and Bradbury’s tune as public domain: https://hymnary.org/hymn/HHNO1911/133 . Only the original melody is used; this recording contains no lyrics.

Melody notation was cross-checked against the Open Hymnal Project melody as transcribed by OpenPsalm: https://openpsalm.com/songs/7 and https://github.com/squinky86/OP-songs/blob/main/7/song.toml . Credit for this notation reference: OpenPsalm (2026), CC BY 4.0, https://creativecommons.org/licenses/by/4.0/ . Changes for BibleQuest: refrain only, key changed from E-flat to C, different tempo, newly composed accompaniment and instrumentation. The source’s alto, tenor, bass and recorded performances are not used.

Musical compositions and sound recordings have separate rights; the U.S. Copyright Office explains the distinction at https://www.copyright.gov/circs/circ56a.pdf . These are fresh renders, not downloads of a singer’s or studio’s hymn recording.

## Reproducible score and render

Renderer: [render_rain_music.py](../scripts/audio/render_rain_music.py). Requires Python 3.12 with numpy, scipy and soundfile, plus macOS `afconvert`. The script downloads only the pinned CC0 samples into a cache, renders natural instrument recordings with a new score, adds stereo room ambience and exports stereo AAC at 256 kb/s. It records exact note events, durations, tempo and signal levels in [rain-orchestra-music-render.json](rain-orchestra-music-render.json).

The new music has no ElevenLabs or other generated-audio subscription dependency. Existing Anna narration remains subject to the separate preview license documented in `rain-orchestra-narration.json`.
