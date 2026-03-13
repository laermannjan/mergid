#!/usr/bin/env fish

# Simple test runner for mergid helper functions
# Run: fish tests/test_mergid.fish

set -l pass 0
set -l fail 0

function assert --argument-names description expected actual
    if test "$expected" = "$actual"
        set pass (math $pass + 1)
        echo "  ✓ $description"
    else
        set fail (math $fail + 1)
        echo "  ✗ $description"
        echo "    expected: '$expected'"
        echo "    got:      '$actual'"
    end
end

# Load the function so helpers are defined
source (status dirname)/../functions/mergid.fish

# We need to define the helpers by calling mergid --help (which defines them as side effect)
# Actually, fish defines inner functions when the outer function runs.
# Let's call mergid --help to trigger the inner function definitions.
mergid --help >/dev/null 2>&1

echo "=== _mergid_normalize_lang ==="

# Known languages — various input forms
assert "en → en"         en  (_mergid_normalize_lang en)
assert "eng → en"        en  (_mergid_normalize_lang eng)
assert "english → en"    en  (_mergid_normalize_lang english)
assert "EN → en"         en  (_mergid_normalize_lang EN)

assert "de → de"         de  (_mergid_normalize_lang de)
assert "deu → de"        de  (_mergid_normalize_lang deu)
assert "ger → de"        de  (_mergid_normalize_lang ger)
assert "german → de"     de  (_mergid_normalize_lang german)
assert "deutsch → de"    de  (_mergid_normalize_lang deutsch)

assert "fr → fr"         fr  (_mergid_normalize_lang fr)
assert "fra → fr"        fr  (_mergid_normalize_lang fra)
assert "fre → fr"        fr  (_mergid_normalize_lang fre)

assert "ja → ja"         ja  (_mergid_normalize_lang ja)
assert "jpn → ja"        ja  (_mergid_normalize_lang jpn)

# Unknown — should return empty
assert "xyz → empty"     ""  (_mergid_normalize_lang xyz)
assert "720p → empty"    ""  (_mergid_normalize_lang 720p)
assert "h264 → empty"    ""  (_mergid_normalize_lang h264)

echo
echo "=== _mergid_detect_lang ==="

# With language suffix
assert "video.en.mp4 → en"       en   (_mergid_detect_lang video.en.mp4)
assert "video.de.mp4 → de"       de   (_mergid_detect_lang video.de.mp4)
assert "video.deu.mp4 → de"      de   (_mergid_detect_lang video.deu.mp4)
assert "video.english.mp4 → en"  en   (_mergid_detect_lang video.english.mp4)

# Complex filenames with language suffix
assert "Show - S2026E01 - Title.de.mp4 → de" \
    de (_mergid_detect_lang "Show - S2026E01 - Title.de.mp4")
assert "Show - S2026E01 - Title.en.mp4 → en" \
    en (_mergid_detect_lang "Show - S2026E01 - Title.en.mp4")

# No language suffix — should return und
assert "video.mp4 → und"         und  (_mergid_detect_lang video.mp4)
assert "video.720p.mp4 → und"    und  (_mergid_detect_lang video.720p.mp4)
assert "video.h264.mp4 → und"    und  (_mergid_detect_lang video.h264.mp4)
assert "video.mp4 → und"         und  (_mergid_detect_lang video.mp4)

# No extension at all
assert "video → und"             und  (_mergid_detect_lang video)

echo
echo "=== Results ==="
echo "$pass passed, $fail failed"

if test $fail -gt 0
    exit 1
end
