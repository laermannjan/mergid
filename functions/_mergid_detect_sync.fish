function _mergid_detect_sync --description "Detect audio offset between base and merge files"
    set -l base $argv[1]
    set -l merge $argv[2]

    set -l tmpdir (mktemp -d)
    set -l base_pcm "$tmpdir/base.raw"
    set -l merge_pcm "$tmpdir/merge.raw"

    # Extract first 10s as 8kHz mono 16-bit PCM
    ffmpeg -v quiet -i "$base" -t 10 -ac 1 -ar 8000 \
        -f s16le -acodec pcm_s16le "$base_pcm" 2>/dev/null
    ffmpeg -v quiet -i "$merge" -t 10 -ac 1 -ar 8000 \
        -f s16le -acodec pcm_s16le "$merge_pcm" 2>/dev/null

    if not test -f "$base_pcm" -a -f "$merge_pcm"
        rm -rf "$tmpdir"
        echo 0
        return 1
    end

    # Cross-correlate using Python to find the offset
    # Convention: positive = merge should be delayed, negative = merge should be advanced
    # Search range: ±5 seconds in 10ms steps
    set -l offset (python3 -c '
import struct, sys

def read_pcm(path):
    with open(path, "rb") as f:
        data = f.read()
    n = len(data) // 2
    return struct.unpack("<" + str(n) + "h", data)

a = read_pcm(sys.argv[1])
b = read_pcm(sys.argv[2])

best_lag = 0
best_corr = -1
max_lag = min(len(a), len(b), 40000)  # ±5s at 8kHz

for lag in range(-max_lag, max_lag + 1, 80):  # 10ms steps
    s = 0
    sa = max(lag, 0)
    sb = max(-lag, 0)
    n = min(len(a) - sa, len(b) - sb)
    for i in range(0, n, 10):
        s += a[sa + i] * b[sb + i]
    if s > best_corr:
        best_corr = s
        best_lag = lag

print(f"{best_lag / 8000:.3f}")
' "$base_pcm" "$merge_pcm" 2>/dev/null)

    rm -rf "$tmpdir"

    if test -n "$offset"
        echo $offset
    else
        echo 0
        return 1
    end
end
