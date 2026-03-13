function _mergid_probe_langs --description "Read audio stream languages from file via ffprobe"
    set -l file $argv[1]
    for line in (ffprobe -v quiet -select_streams a \
        -show_entries stream=codec_type:stream_tags=language \
        -of csv=p=0 "$file" 2>/dev/null)
        set -l lang (string split ',' -- $line)[2]
        if test -n "$lang"
            echo $lang
        else
            echo und
        end
    end
end
