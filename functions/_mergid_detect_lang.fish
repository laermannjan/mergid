function _mergid_detect_lang --description "Detect language from filename suffix"
    set -l basename (path change-extension '' -- $argv[1])
    set -l ext (path extension -- $basename | string trim --chars '.')
    if test -n "$ext"
        set -l normalized (_mergid_normalize_lang "$ext")
        if test -n "$normalized"
            echo $normalized
        else
            echo und
        end
    else
        echo und
    end
end
