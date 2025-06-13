# FFmpeg media manipulation utilities

# Trim video using ffmpeg
trim_video() {
    if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
        echo "Usage: trim_video <input_file> <start_time> [<end_time>]"
        echo "Example: trim_video input.mp4 00:01:00 00:02:00"
        return 1
    fi

    ext="${1##*.}"
    filename="${1%.*}"
    output="${filename}.trimmed.${ext}"

    if [ "$#" -eq 3 ]; then
        ffmpeg -i "$1" -ss "$2" -to "$3" -c copy "$output"
    else
        ffmpeg -i "$1" -ss "$2" -c copy "$output"
    fi
}

# Compress video with quality presets
compress_video() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: compress_video <input_file> [quality]"
        echo "Quality: ultrafast, fast, medium (default), slow, veryslow"
        return 1
    fi

    local input="$1"
    local quality="${2:-medium}"
    local ext="${input##*.}"
    local filename="${input%.*}"
    local output="${filename}.compressed.mp4"

    echo "Compressing with $quality preset..."
    ffmpeg -i "$input" -c:v libx264 -preset "$quality" -crf 23 -c:a aac -b:a 128k "$output"
}

# Extract audio from video
extract_audio() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: extract_audio <video_file>"
        return 1
    fi

    local input="$1"
    local filename="${input%.*}"
    local output="${filename}.mp3"

    ffmpeg -i "$input" -vn -acodec libmp3lame -ab 256k "$output"
}

# Convert video format
convert_video() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: convert_video <input_file> <output_format>"
        echo "Example: convert_video input.avi mp4"
        return 1
    fi

    local input="$1"
    local format="$2"
    local filename="${input%.*}"
    local output="${filename}.${format}"

    ffmpeg -i "$input" "$output"
}

# Create GIF from video
video_to_gif() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
        echo "Usage: video_to_gif <input_file> [fps] [scale]"
        echo "Example: video_to_gif input.mp4 10 320"
        return 1
    fi

    local input="$1"
    local fps="${2:-10}"
    local scale="${3:-320}"
    local filename="${input%.*}"
    local output="${filename}.gif"

    ffmpeg -i "$input" -vf "fps=$fps,scale=$scale:-1:flags=lanczos" -c:v gif "$output"
}

# Merge/concatenate videos
merge_videos() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: merge_videos <output_file> <input1> <input2> [input3...]"
        return 1
    fi

    local output="$1"
    shift

    # Create file list
    local tmpfile=$(mktemp)
    for file in "$@"; do
        echo "file '$file'" >> "$tmpfile"
    done

    ffmpeg -f concat -safe 0 -i "$tmpfile" -c copy "$output"
    rm "$tmpfile"
}

# Add watermark to video
add_watermark() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: add_watermark <video_file> <watermark_image>"
        return 1
    fi

    local input="$1"
    local watermark="$2"
    local filename="${input%.*}"
    local ext="${input##*.}"
    local output="${filename}.watermarked.${ext}"

    ffmpeg -i "$input" -i "$watermark" -filter_complex \
        "overlay=W-w-10:H-h-10" -codec:a copy "$output"
}

# Batch process videos in directory
batch_compress() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: batch_compress <directory>"
        return 1
    fi

    local dir="$1"
    local quality="fast"

    for video in "$dir"/*.{mp4,avi,mov,mkv}; do
        if [ -f "$video" ]; then
            echo "Processing: $video"
            compress_video "$video" "$quality"
        fi
    done
}

# Get video information
video_info() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: video_info <video_file>"
        return 1
    fi

    ffprobe -v quiet -print_format json -show_format -show_streams "$1" | jq '.'
}

# Extract frames from video
extract_frames() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: extract_frames <video_file> [fps]"
        echo "Example: extract_frames input.mp4 1  # 1 frame per second"
        return 1
    fi

    local input="$1"
    local fps="${2:-1}"
    local filename="${input%.*}"
    local output_dir="${filename}_frames"

    mkdir -p "$output_dir"
    ffmpeg -i "$input" -vf "fps=$fps" "$output_dir/frame_%04d.png"
}

# Remove audio from video
remove_audio() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: remove_audio <video_file>"
        return 1
    fi

    local input="$1"
    local filename="${input%.*}"
    local ext="${input##*.}"
    local output="${filename}.noaudio.${ext}"

    ffmpeg -i "$input" -c copy -an "$output"
}

# Speed up or slow down video
change_speed() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: change_speed <video_file> <speed_factor>"
        echo "Example: change_speed input.mp4 2.0  # 2x speed"
        echo "Example: change_speed input.mp4 0.5  # half speed"
        return 1
    fi

    local input="$1"
    local speed="$2"
    local filename="${input%.*}"
    local ext="${input##*.}"
    local output="${filename}.speed${speed}.${ext}"

    # Calculate inverse for video filter
    local video_speed=$(echo "scale=2; 1/$speed" | bc)
    
    ffmpeg -i "$input" -filter:v "setpts=${video_speed}*PTS" -filter:a "atempo=$speed" "$output"
}
