# mergid

A Fish function that merges an audio track from one video file onto another.

Takes a base video file and a merge video file that share the same video content but have different audio languages, and adds the merge file's audio track to the base file. No re-encoding — streams are copied directly.

## Install

With [Fisher](https://github.com/jorgebucaran/fisher):

```
fisher install laermannjan/mergid
```

## Dependencies

- [ffmpeg](https://ffmpeg.org/) (includes ffprobe)
- [python3](https://www.python.org/) (for auto-sync, standard library only)

## Usage

```
mergid [OPTIONS] BASE MERGE
```

### Options

| Flag | Description |
|---|---|
| `-b`, `--lang-base` | Language code for base file's audio |
| `-m`, `--lang-merge` | Language code for merge file's audio |
| `-d`, `--delay` | Delay merge audio by N seconds (e.g. `1.5` or `-0.5`) |
| `-S`, `--no-sync` | Disable auto audio sync detection |
| `-o`, `--output` | Output filename (default: base file with language suffix stripped) |
| `-h`, `--help` | Show help |

### Examples

```fish
# Auto-detect languages from filename suffixes
mergid video.de.mp4 video.en.mp4

# Specify languages manually
mergid -b de -m en german.mp4 english.mp4

# Custom output filename
mergid -o merged.mp4 video.de.mp4 video.en.mp4

# Manual delay (merge audio starts 1.5s later)
mergid -d 1.5 video.de.mp4 video.en.mp4

# Disable auto-sync
mergid --no-sync video.de.mp4 video.en.mp4
```

### Merging more than two languages

Chain calls to merge additional languages onto a previous result:

```fish
mergid -o merged.mp4 video.de.mp4 video.en.mp4
mergid merged.mp4 video.fr.mp4
```

### Audio sync

By default, mergid auto-detects the audio offset between the base and merge files by cross-correlating the first 10 seconds of audio. This works well when both files share a common intro (e.g. a jingle). The detected offset is printed so you can verify it.

Use `--no-sync` to disable auto-sync, or `--delay` to set the offset manually (which also disables auto-sync).

### Language detection

mergid detects the language of each file from a suffix before the extension:

```
Talk - S2026E01 - Speaker - Title.de.mp4  → de
Talk - S2026E01 - Speaker - Title.en.mp4  → en
```

Common suffixes are normalized to ISO 639-1 codes automatically (e.g. `eng` → `en`, `deu` → `de`, `fra` → `fr`).

For the base file, existing audio stream metadata is checked first (useful when merging onto a previous result). If no metadata is found, the filename suffix is used. Use `-b`/`-m` flags to override.

### Track naming and playback

Each audio track is tagged with a human-readable title (e.g. "Deutsch", "English") and the first track is marked as the default. This ensures correct playback in QuickTime and other players that don't handle multi-track audio well.

## Companion

Pairs well with [savid](https://github.com/laermannjan/savid) — download the same episode twice with different language suffixes, then merge them.

## License

[MIT](LICENSE)
