#!/bin/bash

README="README.md"
TEMP_FILE="README.md.new"
START_MARKER="<!-- TRANSLATOR_CREDITS_START -->"
END_MARKER="<!-- TRANSLATOR_CREDITS_END -->"
CONTENT_FILE="temp/translators.md"
skip=false

# Read the content in chunks
while IFS= read -r line; do
  if [[ "$line" == *"$START_MARKER"* ]]; then
    # Found start marker - output it
    echo "$line" >> "$TEMP_FILE"
    
    # Insert the new content
    cat "$CONTENT_FILE" >> "$TEMP_FILE"
    
    # Skip lines until end marker
    skip=true
  elif [[ "$line" == *"$END_MARKER"* ]]; then
    # Found end marker - output it and stop skipping
    echo "$line" >> "$TEMP_FILE"
    skip=false
  elif [[ "$skip" != "true" ]]; then
    # Not skipping, so output the line
    echo "$line" >> "$TEMP_FILE"
  fi
done < "$README"

# Replace the original file
mv "$TEMP_FILE" "$README"
