#!/bin/bash

MODE="mv"
LIB_ROOT="~/media/music/library"
declare DIR_SPEC="$GENRE/$ALBUM_ARTIST/$DATE - $album/$TRACK $TITLE"

sanitize() {
    echo "$1" | sed 's/[\/:*?"<>|]/_/g'
}

get_tags() {
    local file="$1"

    while IFS='=' read -r key value; do
        # Example key: "TAG:title"

        # Remove empty lines
        [[ -z "$key" ]] && continue

        # Strip the "TAG:" prefix if present
        key="${key#TAG:}"

        # Normalize to uppercase and safe characters
        norm_key=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9_')

        # Assign variable dynamically
        s_value=$(sanitize "$value")
        eval "${norm_key}=\"${s_value}\""

    done < <(
        ffprobe -v quiet \
                -show_entries format_tags \
                -of default=nw=1:nk=0 \
                "$file"
    )
}

sort_file() {
  local file="$1"
  echo "importing directory $dir"
  unset TITLE ARTIST ALBUM TRACK DISC DATE GENRE ALBUM_ARTIST COMPILATION


  get_tags "$file"
  TRACK=$(printf "%02d\n" "${TRACK%%_*}")
  ext="${file##*.}"

  echo $ALBUM
  echo "$LIB_ROOT/$DIR_SPEC"


}

sort_dir() {
  local dir="$1"
  echo "importing directory $dir"

### testing for present cover art
### Embedding cover art and sorting audio files
  find "$dir" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.flac" \) | while read -r file; do
    get_tags "$file"
    TRACK=$(printf "%02d\n" "${TRACK%%_*}")
    ext="${file##*.}"

    album_dir="$GENRE/$ALBUM_ARTIST/$ALBUM"
    filename="$TRACK $TITLE.$ext"

    full_path="$LIB_ROOT/$album_dir/$filename"

    echo "  importing file: $file"
    echo "  $full_path"
  done

### Procesing cover art once audio files are sorted
### Processing any additional files into an "addtl_files" subdirectory

  echo "### DONE"

  echo "### EOF"

  #unset TITLE ARTIST ALBUM TRACK DISC DATE GENRE ALBUM_ARTIST COMPILATION

}
export -f sanitize get_tags sort_file sort_dir

sort_dir "$1"
