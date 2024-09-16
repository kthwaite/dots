# trim video using ffmpeg
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
