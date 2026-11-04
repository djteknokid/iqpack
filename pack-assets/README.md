# pack-assets

Local staging folder for pack cover images. **Not included in the Xcode target or app bundle.**

Upload files here to Supabase Storage bucket `pack-images` to make them live in the app.

## Files

| File | Pack | Storage path |
|------|------|-------------|
| `edison-inventions.jpg` | Thomas Edison — The Inventions (V1) | `pack-images/edison-inventions.jpg` |
| `edison-experiments.jpg` | Thomas Edison — The Experiments (V2) | `pack-images/edison-experiments.jpg` |
| `ev1-lightbulb-filament.png` | Edison V1 Q7 — filament multiple choice | `pack-images/ev1-lightbulb-filament.png` |

## Upload command

```bash
supabase storage cp ./pack-assets/<file> ss:///pack-images/<file>
```

Or upload via the Supabase dashboard: Storage → pack-images → Upload file.
