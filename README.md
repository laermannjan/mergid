# mergid

A Fish function that merges audio tracks from multiple video files into one.

Takes two or more video files that share the same video content but have different audio languages, and combines their audio tracks into a single file. No re-encoding — streams are copied directly.

## Install

With [Fisher](https://github.com/jorgebucaran/fisher):

```
fisher install laermannjan/mergid
```

## Dependencies

- [ffmpeg](https://ffmpeg.org/)

## Usage

```
mergid [OPTIONS] FILE1 FILE2 [FILE3 ...]
```

### Options

| Flag | Description |
|---|---|
| `-l`, `--languages` | Comma-separated language codes (e.g. `de,en`) |
| `-o`, `--output` | Output filename (default: first input with language suffix stripped) |
| `-h`, `--help` | Show help |

### Examples

```fish
# Auto-detect languages from filename suffixes
mergid video.de.mp4 video.en.mp4

# Specify languages manually
mergid -l de,en video_german.mp4 video_english.mp4

# Custom output filename
mergid -o merged.mp4 video.de.mp4 video.en.mp4
```

### Language detection

mergid detects the language of each file from a suffix before the extension:

```
Talk - S2026E01 - Speaker - Title.de.mp4  → de
Talk - S2026E01 - Speaker - Title.en.mp4  → en
```

Common suffixes are normalized to ISO 639-1 codes automatically (e.g. `eng` → `en`, `deu` → `de`, `fra` → `fr`). If no suffix is detected, use `--languages` to assign them manually. The `--languages` flag always takes precedence over auto-detection.

## Companion

Pairs well with [savid](https://github.com/laermannjan/savid) — download the same episode twice with different language suffixes, then merge them.

## License

[MIT](LICENSE)
