function mergid --description "Merge audio tracks from two video files into one"
    # Requires: ffmpeg, ffprobe, python3 (for auto-sync)

    argparse 'b/lang-base=' 'm/lang-merge=' 'd/delay=' 'S/no-sync' \
        'o/output=' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "mergid — merge an audio track from one video file onto another."
        echo
        echo "Takes a base video file and a merge video file that share the same"
        echo "video content but have different audio languages, and adds the merge"
        echo "file's audio track to the base file. The video stream and any existing"
        echo "audio streams are kept from the base file."
        echo
        echo "Usage: mergid [OPTIONS] BASE MERGE"
        echo
        echo "Options:"
        echo "  -b, --lang-base   Language code for base file's audio"
        echo "  -m, --lang-merge  Language code for merge file's audio"
        echo "  -d, --delay       Delay merge audio by N seconds (e.g. 1.5 or -0.5)"
        echo "  -S, --no-sync     Disable auto audio sync detection"
        echo "  -o, --output      Output filename (default: replaces base file)"
        echo "  -h, --help        Show this help"
        echo
        echo "Audio sync:"
        echo "  By default, mergid auto-detects the audio offset between the base"
        echo "  and merge files by cross-correlating the first 10 seconds of audio."
        echo "  This works well when both files share a common intro jingle."
        echo "  Use --no-sync to disable. --delay overrides auto-sync."
        echo "  Requires python3."
        echo
        echo "Language detection:"
        echo "  Languages are resolved in this order:"
        echo "    Base:  --lang-base flag → ffprobe metadata → filename suffix"
        echo "    Merge: --lang-merge flag → filename suffix"
        echo
        echo "  Recognized filename suffixes: en, de, fr, es, it, pt, ja, zh, ko, ru, nl, pl"
        echo "  (and common variants like eng, deu, ger, deutsch, etc.)"
        echo
        echo "Chaining merges:"
        echo "  To merge more than two languages, chain calls:"
        echo "    mergid -o merged.mp4 video.de.mp4 video.en.mp4"
        echo "    mergid merged.mp4 video.fr.mp4"
        echo
        echo "Examples:"
        echo "  mergid video.de.mp4 video.en.mp4"
        echo "  mergid -b de -m en german.mp4 english.mp4"
        echo "  mergid -d 1.5 video.de.mp4 video.en.mp4"
        echo "  mergid --no-sync video.de.mp4 video.en.mp4"
        echo "  mergid -o merged.mp4 video.de.mp4 video.en.mp4"
        return 0
    end

    # --- Validate inputs ---
    if test (count $argv) -ne 2
        echo "Error: need exactly two input files (base and merge)." >&2
        echo "Run with --help for usage." >&2
        return 1
    end

    if not command -q ffmpeg
        echo "Error: ffmpeg is required but not found." >&2
        return 1
    end

    if not command -q ffprobe
        echo "Error: ffprobe is required but not found." >&2
        return 1
    end

    set -l base $argv[1]
    set -l merge $argv[2]

    for file in $base $merge
        if not test -f "$file"
            echo "Error: file not found: $file" >&2
            return 1
        end
    end

    # --- Resolve base languages ---
    set -l base_langs

    if set -q _flag_lang_base
        # Manual override — only for single-stream base files
        set -l probed (_mergid_probe_langs "$base")
        if test (count $probed) -gt 1
            echo "Warning: --lang-base ignored for multi-stream base file." >&2
            set base_langs $probed
        else
            set -l n (_mergid_normalize_lang "$_flag_lang_base")
            if test -n "$n"
                set base_langs $n
            else
                set base_langs (string lower -- $_flag_lang_base)
            end
        end
    else
        # Prefer filename detection over ffprobe metadata
        set -l detected (_mergid_detect_lang "$base")
        if test "$detected" != und
            set base_langs $detected
        else
            set base_langs (_mergid_probe_langs "$base")
        end
    end

    # --- Resolve merge language ---
    set -l merge_lang

    if set -q _flag_lang_merge
        set -l n (_mergid_normalize_lang "$_flag_lang_merge")
        if test -n "$n"
            set merge_lang $n
        else
            set merge_lang (string lower -- $_flag_lang_merge)
        end
    else
        set merge_lang (_mergid_detect_lang "$merge")
    end

    # --- All languages (base streams + merge stream) ---
    set -l all_langs $base_langs $merge_lang

    # --- Determine output file ---
    set -l outfile
    if set -q _flag_output
        set outfile "$_flag_output"
    else
        set -l base_path (path change-extension '' -- $base)
        set -l inner_ext (path extension -- $base_path | string trim --chars '.')
        if test -n "$inner_ext"
            set -l detected (_mergid_detect_lang "$base")
            if test "$detected" != und
                set base_path (path change-extension '' -- $base_path)
            end
        end
        set outfile "$base_path"(path extension -- $base)
    end

    # --- Guard against overwriting input ---
    for file in $base $merge
        if test (path resolve -- "$file") = (path resolve -- "$outfile")
            echo "Error: output '$outfile' would overwrite input '$file'." >&2
            echo "Use -o to specify a different output filename." >&2
            return 1
        end
    end

    # --- Determine delay ---
    set -l delay 0

    if set -q _flag_delay
        set delay $_flag_delay
    else if not set -q _flag_no_sync
        if not command -q python3
            echo "Warning: python3 not found, skipping auto-sync." >&2
        else
            echo "Detecting audio offset..."
            set -l _sync_output (_mergid_detect_sync "$base" "$merge")
            set -l _sync_status $status
            if test $_sync_status -ne 0
                echo "Warning: auto-sync failed, using no delay." >&2
            else
                set delay $_sync_output
                echo "  Detected offset: "$delay"s"
            end
        end
    end

    # --- Show plan ---
    echo
    echo "Merging audio tracks:"
    for i in (seq (count $base_langs))
        echo "  [$base_langs[$i]] $base (stream $i)"
    end
    echo "  [$merge_lang] $merge"
    if test "$delay" != 0
        echo "  Delay: "$delay"s"
    end
    echo "→ $outfile"
    echo

    # --- Build ffmpeg command ---
    set -l ff_args -y

    # Input files (with optional delay on merge)
    set -a ff_args -i "$base"
    if test "$delay" != 0
        set -a ff_args -itsoffset "$delay"
    end
    set -a ff_args -i "$merge"

    # Map video and subtitles from base, all audio from base, first audio from merge
    set -a ff_args -map 0:v -map 0:s? -map 0:a -map 1:a:0

    # Copy streams without re-encoding
    set -a ff_args -c copy

    # Set disposition: first audio is default, rest are not
    set -a ff_args -disposition:a:0 default
    for i in (seq 2 (count $all_langs))
        set -a ff_args -disposition:a:(math $i - 1) 0
    end

    # Set language and title metadata on all audio streams
    for i in (seq (count $all_langs))
        set -a ff_args -metadata:s:a:(math $i - 1) language=$all_langs[$i]
        set -a ff_args -metadata:s:a:(math $i - 1) title=(_mergid_lang_title $all_langs[$i])
    end

    # Use temp file to avoid corruption
    set -l tmpfile (path change-extension '' -- $outfile)".tmp"(path extension -- $outfile)
    set -a ff_args "$tmpfile"

    ffmpeg $ff_args

    if test $status -ne 0
        echo "Error: ffmpeg merge failed." >&2
        rm -f "$tmpfile"
        return 1
    end

    if not mv "$tmpfile" "$outfile"
        echo "Error: failed to move temp file to $outfile." >&2
        echo "Merged file may be at: $tmpfile" >&2
        return 1
    end

    echo
    echo "Done: $outfile"
end
