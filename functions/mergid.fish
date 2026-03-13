function mergid --description "Merge audio tracks from multiple video files into one"
    # Requires: ffmpeg

    argparse 'l/languages=' 'o/output=' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "mergid — merge audio tracks from multiple video files into one."
        echo
        echo "Takes two or more video files that share the same video content but"
        echo "have different audio languages, and combines their audio tracks into"
        echo "a single file. The video stream is copied from the first file."
        echo
        echo "Usage: mergid [OPTIONS] FILE1 FILE2 [FILE3 ...]"
        echo
        echo "Options:"
        echo "  -l, --languages   Comma-separated language codes (e.g. de,en)"
        echo "  -o, --output      Output filename (default: replaces first input file)"
        echo "  -h, --help        Show this help"
        echo
        echo "Language detection:"
        echo "  mergid tries to detect the language of each file from a suffix in"
        echo "  the filename, right before the extension. For example:"
        echo
        echo "    Talk - S2026E01 - Speaker - Title.de.mp4  → de"
        echo "    Talk - S2026E01 - Speaker - Title.en.mp4  → en"
        echo
        echo "  Recognized suffixes include common language codes and names:"
        echo "    en, eng, english → en"
        echo "    de, deu, ger, german, deutsch → de"
        echo "    fr, fra, fre, french → fr"
        echo "    es, spa, spanish → es"
        echo "    it, ita, italian → it"
        echo "    pt, por, portuguese → pt"
        echo "    ja, jpn, japanese → ja"
        echo "    zh, zho, chi, chinese → zh"
        echo "    ko, kor, korean → ko"
        echo "    ru, rus, russian → ru"
        echo "    nl, nld, dut, dutch → nl"
        echo "    pl, pol, polish → pl"
        echo
        echo "  If no suffix is detected, use --languages to assign them manually."
        echo "  The --languages flag always takes precedence over auto-detection."
        echo
        echo "Examples:"
        echo "  mergid video.de.mp4 video.en.mp4"
        echo "  mergid -l de,en video_german.mp4 video_english.mp4"
        echo "  mergid -o merged.mp4 video.de.mp4 video.en.mp4"
        return 0
    end

    # --- Validate inputs ---
    if test (count $argv) -lt 2
        echo "Error: need at least two input files." >&2
        echo "Run with --help for usage." >&2
        return 1
    end

    # --- Check ffmpeg ---
    if not command -q ffmpeg
        echo "Error: ffmpeg is required but not found." >&2
        return 1
    end

    # --- Language code normalizer ---
    function _mergid_normalize_lang
        switch (string lower -- $argv[1])
            case en eng english
                echo en
            case de deu ger german deutsch
                echo de
            case fr fra fre french
                echo fr
            case es spa spanish
                echo es
            case it ita italian
                echo it
            case pt por portuguese
                echo pt
            case ja jpn japanese
                echo ja
            case zh zho chi chinese
                echo zh
            case ko kor korean
                echo ko
            case ru rus russian
                echo ru
            case nl nld dut dutch
                echo nl
            case pl pol polish
                echo pl
            case '*'
                echo $argv[1]
        end
    end

    # --- Detect language from filename suffix ---
    # e.g. "video.en.mp4" → "en", "video.deu.mp4" → "deu"
    function _mergid_detect_lang
        set -l basename (path change-extension '' -- $argv[1])
        set -l ext (path extension -- $basename | string trim --chars '.')
        if test -n "$ext"
            _mergid_normalize_lang "$ext"
        else
            echo und
        end
    end

    # --- Resolve languages ---
    set -l files $argv
    set -l langs

    if set -q _flag_languages
        set langs (string split ',' "$_flag_languages")
        if test (count $langs) -ne (count $files)
            echo "Error: number of languages ("(count $langs)") doesn't match number of files ("(count $files)")." >&2
            return 1
        end
        # Normalize provided languages
        set -l normalized
        for lang in $langs
            set -a normalized (_mergid_normalize_lang "$lang")
        end
        set langs $normalized
    else
        for file in $files
            set -a langs (_mergid_detect_lang "$file")
        end
    end

    # --- Determine output file ---
    set -l outfile
    if set -q _flag_output
        set outfile "$_flag_output"
    else
        # Strip language suffix from first file for the output name
        set -l base (path change-extension '' -- $files[1])
        set -l inner_ext (path extension -- $base | string trim --chars '.')
        set -l normalized (_mergid_normalize_lang "$inner_ext" 2>/dev/null)
        if test -n "$inner_ext"; and test "$normalized" != "$inner_ext" -o "$normalized" = "$inner_ext"
            # Has a language suffix — strip it
            set base (path change-extension '' -- $base)
        end
        set outfile "$base.mp4"
    end

    # --- Show plan ---
    echo
    echo "Merging audio tracks:"
    for i in (seq (count $files))
        echo "  [$langs[$i]] $files[$i]"
    end
    echo "→ $outfile"
    echo

    # --- Build ffmpeg command ---
    set -l ff_args -y

    for file in $files
        set -a ff_args -i "$file"
    end

    # Map video from first file
    set -a ff_args -map 0:v

    # Map audio from each file
    for i in (seq (count $files))
        set -a ff_args -map (math $i - 1):a
    end

    # Copy streams without re-encoding
    set -a ff_args -c copy

    # Tag language metadata on each audio stream
    for i in (seq (count $files))
        set -a ff_args -metadata:s:a:(math $i - 1) language=$langs[$i]
    end

    # Use temp file to avoid overwriting input
    set -l tmpfile (path change-extension '' -- $outfile)".tmp.mp4"

    set -a ff_args "$tmpfile"

    ffmpeg $ff_args

    if test $status -ne 0
        echo "Error: ffmpeg merge failed." >&2
        rm -f "$tmpfile"
        return 1
    end

    mv "$tmpfile" "$outfile"

    echo
    echo "Done: $outfile"
end
