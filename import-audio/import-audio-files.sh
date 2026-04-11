#!/bin/bash

MODE="copy"
DEST_DIR="/home/noah/dev/import-audio/destination"
DIR_SPEC="$GENRE/$ALBUM_ARTIST/$DATE - $album/$TRACK $TITLE"

COVER_NAMES=("cover" "front" "art")
COVER_EXTS=("jpg" "jpeg" "png")
COVER_DEST_NAME="cover"

MOVE_FLAG=0


cpmv () {
  local mode="$1"
  local src="$2"
  local dest="$3"

  echo "in cpmv func: $src to $dest"
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
  echo "  source image: $1"
  if [[ "$dest_file" == *.mp3 ]]; then
    if [[ $source_image =~ \.(jpe?g|png)$ ]]; then
      tmpfile=$(mktemp --suffix=".mp3")
      mv "$dest_file" "$tmpfile"
      ffmpeg -loglevel error -i "$tmpfile" -i "$source_image" \
        -map 0:a \
        -map 1:v \
        -c copy \
        -metadata:s:v title="Album cover" \
        -metadata:s:v comment="Cover (front)" \
        -disposition:v:0 attached_pic \
        "$dest_file"

    # test if $dest file exists, if so delete temp file
      if [ -f "$dest_file" ]; then
        rm "$tmpfile"
      else
        echo "Error: ffmpeg unsuccessful for $dest_file, tmp file located in $tmpfile"
      fi

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

get_coverfile () {
  # takes filename as arg $1
  local dir=$(dirname -- "$1")
  coverfile=$(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))
}

sort_dir() {

  #error handling variables

  num_errors=0 # number of files that throw an error
  error_dirs=() # specific source directories that have errors occur during import

  local dir="$1"

  echo "importing directory '$dir' with parameters:"
  echo "LIB_ROOT: $DEST_DIR"
  echo "MODE: $MOVE_FLAG"
  echo -e "-----------------------------------------------------------------\n"

  while read -r file; do
    get_tags "$file"
    get_coverfile "$file"
    cover_ext="${coverfile##*.}"

    TRACK=$(printf "%02d\n" "${TRACK%%_*}")
    ext="${file##*.}"

    album_dir="$DEST_DIR/$GENRE/$ALBUM_ARTIST/$DATE - $ALBUM"
    filename="$TRACK $TITLE.$ext"

    full_path="$album_dir/$filename"
    processed_cover="$album_dir/$COVER_DEST_NAME.$cover_ext"

    echo -e "--> Importing file: $file..."

    mkdir -p "$album_dir"

    echo "Checking for $processed_cover"
    if [[ ! -f "$processed_cover" ]]; then
    
      if [[ -n "$coverfile" ]]; then
        echo "      No processed cover art detected."
        echo "      Processing cover art from $coverfile..."
        magick "$coverfile" -resize '600x600>' "$processed_cover"
        echo "      Cover art processing sucessful"
      else
        echo "ERROR: no cover art detected"
        exit 1
      fi

    else

      echo "      Processed cover art detected."

    fi


    ffmpeg -loglevel error -y -i "$file" -i "$processed_cover" \
        -map 0:a \
        -map 1:v \
        -c copy \
        -metadata:s:v title="Album cover" \
        -metadata:s:v comment="Cover (front)" \
        -disposition:v:0 attached_pic \
        "$full_path"  

    if [ $? -ne 0 ]; then
      echo -e "     File not imported"
    else
      if [[ -f "$full_path" ]]; then
        echo -e "     File import successful. Import path: $full_path"
        if [ $MOVE_FLAG -gt 0 ]; then
          rm "$file"
        fi
      else
        echo -e "     ERROR: file import completed, but imported file not detected"
      fi
    fi
  
    unset TITLE ARTIST ALBUM TRACK DISC DATE GENRE ALBUM_ARTIST COMPILATION

  done < <(find "$dir" -type f \( -iname "*.mp3" -o -iname "*.flac" \))

  echo -e "\nFinished import of $dir"
  echo "-----------------------------------------------------------------"
  echo "Import complete. Exiting..."

}

export -f sanitize get_tags sort_file sort_dir


while getopts ":s:d:m" opt; do
  case "$opt" in
    s) 
      SOURCE_DIR="$OPTARG" 
      ;;
    d) 
      DEST_DIR="$OPTARG" 
      ;;
    m) 
      MOVE_FLAG=1 
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

echo "$SOURCE_DIR, $dest_dir, $move_mode"

sort_dir "$SOURCE_DIR"



