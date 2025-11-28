#!/bin/bash

MODE="copy"
LIB_ROOT="/tmp/tmp.ybKMqOcwcr"
DIR_SPEC="$GENRE/$ALBUM_ARTIST/$DATE - $album/$TRACK $TITLE"

COVER_NAMES=("cover" "front" "art")
COVER_EXTS=("jpg" "jpeg" "png")
COVER_DEST_NAME="cover"

cpmv () {
  local mode="$1"
  local src="$2"
  local dest="$3"

  echo "in cpmv func 2"
  if [ $mode = "copy" ]; then
    cp -f "$src" "$dest"
  elif [ $mode = "move"]; then
    mv "$src" "$dest"
  else
    return 1
  fi
}
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

get_cover_file () {

  local dir=$1
  local coverfile=""

  find_match_arr=()

  for i in "${COVER_NAMES[@]}"; do
    for j in "${COVER_EXTS[@]}"; do
      find_match_arr+=( -iname "${i}.${j}" -o )
    done
  done

  unset 'find_match_arr[${#find_match_arr[@]}-1]'  

  mapfile -t matches < <(find "$dir" -maxdepth 1 -type f \( "${find_match_arr[@]}" \) )

  if (( ${#matches[@]} == 0 )); then
    # No matching cover at images found
    return -1
  elif (( ${#matches[@]} > 1 )); then
    # Multiple matching images found
    return 1
  fi

  # If exactly one match 
  coverfile="${matches[0]}"
  echo "$(basename "$coverfile")"

}

embed_coverfile () {
  source_image=$1
  dest_file=$2

  # Ensure id3v2 and metaflac are installed
  if [[ "$dest_file" == *.mp3 ]]; then
    if [[ $source_image =~ \.jpe?g$ ]]; then
      id3v2 --APIC "$source_image" "$dest_file"
    else
      echo "unsupported image format"
      exit 1
    fi

  elif [[ "$dest_file" == *.flac ]]; then
    metaflac --remove --block-type=PICTURE "$dest_file"
    metaflac --import-picture-from="$source_image" "$dest_file"
    echo "  Succesfully embedded image into $dest_file"
  else
    echo "unable to edit tags on $dest_file, unsupported format"
    exit 1
  fi
  

}

sort_dir() {
  local dir="$1"
  echo "importing directory $dir"

  echo "root dir: $LIB_ROOT"
### testing for present cover art
  cover=$(get_cover_file "$dir")
  echo " returned: $cover"
  

### Embedding cover art and sorting audio files
  #find "$dir" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.flac" \) | while read -r file; do
  #  get_tags "$file"
  #  TRACK=$(printf "%02d\n" "${TRACK%%_*}")
  #  ext="${file##*.}"

  #  album_dir="$GENRE/$ALBUM_ARTIST/$ALBUM"
  #  filename="$TRACK $TITLE.$ext"

  #  full_path="$LIB_ROOT/$album_dir/$filename"

  #  echo "  importing file: $file"
  #  echo "  $full_path"
  #done
  while read -r file; do
    get_tags "$file"

    TRACK=$(printf "%02d\n" "${TRACK%%_*}")
    ext="${file##*.}"

    album_dir="$LIB_ROOT/$GENRE/$ALBUM_ARTIST/$ALBUM"
    filename="$TRACK $TITLE.$ext"

    full_path="$album_dir/$filename"

    echo "  importing file: $file"

    if [[ ! -d "$album_dir" ]]; then
      mkdir -p "$album_dir"
    fi
  
    cpmv "$MODE" "$file" "$full_path"
    embed_coverfile "$dir/$cover" "$full_path"

    echo "  $full_path"
  done < <(find "$dir" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.flac" \))


### Procesing cover art once audio files are sorted

  cover_ext="${cover##*.}"
  cpmv $MODE "$dir/$cover" "$album_dir/$COVER_DEST_NAME.$cover_ext"
  
### Processing any additional files into an "addtl_files" subdirectory

  #unset TITLE ARTIST ALBUM TRACK DISC DATE GENRE ALBUM_ARTIST COMPILATION

}
export -f sanitize get_tags sort_file sort_dir

sort_dir "$1"
