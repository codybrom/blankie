#!/bin/bash

# Convert audio files to high-quality m4a (AAC) format
# Usage: ./convert-audio.sh [input_format] [bitrate] [directory]
# Example: ./convert-audio.sh wav 192k
# Example: ./convert-audio.sh mp3 256k /path/to/audio/files
# Example: ./convert-audio.sh * 192k .
# Default: converts all audio formats to m4a at 192k in current directory

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed"
    echo "Install it using: brew install ffmpeg"
    exit 1
fi

# Default values
INPUT_FORMAT="${1:-*}"  # Default: all supported formats
BITRATE="${2:-192k}"  # Default: 192k
WORK_DIR="${3:-.}"  # Default: current directory

# If no directory specified and we're in the Blankie project, use the sounds directory
if [ "$3" = "" ] && [ -d "Blankie/Resources/Sounds" ]; then
    WORK_DIR="Blankie/Resources/Sounds"
elif [ "$3" = "" ] && [ -d "../Blankie/Resources/Sounds" ]; then
    WORK_DIR="../Blankie/Resources/Sounds"
elif [ "$3" = "" ] && [ -d "./Blankie/Resources/Sounds" ]; then
    WORK_DIR="./Blankie/Resources/Sounds"
fi

# Supported input formats
SUPPORTED_FORMATS="wav mp3 aac aiff flac ogg"

echo "Audio to M4A Converter"
echo "====================="
echo "Input format: $INPUT_FORMAT"
echo "Output format: m4a (AAC)"
echo "Bitrate: $BITRATE"
echo "Directory: $(realpath "$WORK_DIR")"
echo

cd "$WORK_DIR" || { echo "Error: Cannot access directory $WORK_DIR"; exit 1; }

# Function to determine audio quality priority (higher number = better quality)
get_format_priority() {
    case "$1" in
        "wav"|"aiff"|"flac") echo 4 ;;  # Lossless formats
        "m4a"|"aac") echo 3 ;;          # High-quality lossy
        "ogg") echo 2 ;;                # Medium-quality lossy  
        "mp3") echo 1 ;;                # Lower-quality lossy
        *) echo 0 ;;                    # Unknown
    esac
}

# Function to convert a single file to m4a
convert_file() {
    local input_file="$1"
    local base_name="${input_file%.*}"
    local input_ext="${input_file##*.}"
    local output_file="${base_name}.m4a"
    
    # Skip if already m4a
    if [ "$input_ext" = "m4a" ]; then
        echo "⏭️  Skipping $input_file (already in m4a format)"
        return
    fi
    
    # Smart handling of existing output files
    if [ -f "$output_file" ]; then
        # Get priority of current input vs existing output's likely source
        input_priority=$(get_format_priority "$input_ext")
        
        # Check if there are other source files that could have created the existing m4a
        existing_sources=""
        for ext in wav aiff flac mp3 ogg aac; do
            if [ -f "${base_name}.${ext}" ] && [ "${base_name}.${ext}" != "$input_file" ]; then
                existing_sources="$existing_sources $ext"
            fi
        done
        
        if [ -n "$existing_sources" ]; then
            # Find the highest priority among existing sources
            max_existing_priority=0
            for ext in $existing_sources; do
                priority=$(get_format_priority "$ext")
                if [ $priority -gt $max_existing_priority ]; then
                    max_existing_priority=$priority
                fi
            done
            
            if [ $input_priority -gt $max_existing_priority ]; then
                echo "🔄 Upgrading $output_file (better source: $input_ext vs existing sources)"
            elif [ $input_priority -eq $max_existing_priority ]; then
                echo "⚠️  $output_file exists with same quality source, overwriting anyway"
            else
                echo "⬇️  $output_file exists with better source, but converting anyway"
            fi
        else
            echo "🔄 Overwriting existing $output_file"
        fi
    fi
    
    echo "Converting $input_file to m4a..."
    
    # Convert to m4a with AAC codec
    ffmpeg -i "$input_file" -c:a aac -b:a "$BITRATE" -ar 44100 -ac 2 "$output_file" -hide_banner -loglevel error
    
    if [ $? -eq 0 ]; then
        # Get file sizes
        input_size=$(ls -lh "$input_file" | awk '{print $5}')
        output_size=$(ls -lh "$output_file" | awk '{print $5}')
        
        echo "✅ Converted successfully"
        echo "   Original: $input_size → Output: $output_size"
        
        # Calculate size ratio
        input_bytes=$(stat -f%z "$input_file" 2>/dev/null || stat -c%s "$input_file" 2>/dev/null)
        output_bytes=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
        if [ -n "$input_bytes" ] && [ -n "$output_bytes" ]; then
            if [ "$input_bytes" -gt "$output_bytes" ]; then
                ratio=$(echo "scale=1; $input_bytes / $output_bytes" | bc)
                echo "   Compression ratio: ${ratio}:1"
            else
                ratio=$(echo "scale=1; $output_bytes / $input_bytes" | bc)
                echo "   Size increase: ${ratio}x"
            fi
        fi
        
        # Analyze the output file
        echo -n "   Output info: "
        ffprobe -v quiet -show_streams -select_streams a:0 "$output_file" | grep -E "(codec_name|bit_rate|sample_rate|channels)" | tr '\n' ' ' | sed 's/codec_name=/codec:/g' | sed 's/bit_rate=/bitrate:/g' | sed 's/sample_rate=/sr:/g' | sed 's/channels=/ch:/g'
        echo
    else
        echo "❌ Failed to convert $input_file"
    fi
    echo
}

# Convert files based on input format
if [ "$INPUT_FORMAT" = "*" ]; then
    # Convert all supported formats to m4a
    echo "Converting all supported audio formats to m4a..."
    echo
    
    for format in $SUPPORTED_FORMATS; do
        for file in *."$format"; do
            if [ -f "$file" ]; then
                convert_file "$file"
            fi
        done
    done
else
    # Convert specific format to m4a
    echo "Converting $INPUT_FORMAT files to m4a..."
    echo
    
    found_files=false
    for file in *."$INPUT_FORMAT"; do
        if [ -f "$file" ]; then
            convert_file "$file"
            found_files=true
        fi
    done
    
    if [ "$found_files" = false ]; then
        echo "No $INPUT_FORMAT files found in $(pwd)"
    fi
fi

echo "Conversion complete!"
echo
echo "Tips:"
echo "- To remove source files after verifying conversions:"
echo "    rm *.$INPUT_FORMAT"
echo "- To replace existing files with converted versions:"
echo "    for f in *-converted.m4a; do mv \"\$f\" \"\${f%-converted.m4a}.m4a\"; done"