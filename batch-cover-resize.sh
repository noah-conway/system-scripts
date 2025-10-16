#!/bin/bash
DIR="/home/noah/Music/new"
COVER_FILE="cover"

make_dirname () {
	echo $1
	echo $2
	if [[ -d $1 ]]
	then
		dirName="${1}$2"
		i=$(( $2+1 ))
		echo "append dirname in then"
		echo ${dirName::-1}
		echo "ontp recursion"
		make_dirname ${dirName::-1} $i
	else

		echo "creating: $DIR/$dirName"
		mkdir "$DIR/$dirName"
	fi
	
}

clear_extra_images () {
  # $1 is image format
  # $2 is path
  echo "Removing extra (non-$COVER_FILE.jpg and .png) image files from $1..."
  find $1 -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.png' \) \
  ! -iname 'cover.jpg' \
  ! -iname 'cover.png' \
  -delete

  #find_result=$(find $2 -maxdepth 1 -type f -iname ".$1" ! -iname "$COVER_FILE.$1" -delete)

  #if [ $find_result -eq 0 ]; then 
  #  echo "  Successfully removed extra .$1 image files"
#    return 0
  #else if [ $find_result -eq 1 ]; then
  #  echo "  No extra .$1 image files found"
#    return 0
  #else
  #  echo "  Failed to remove extra .$1 image files"
#    return 2
  #fi
  
}



for file in *.zip; do
#	arr=( $file )
#	dirName=${arr[0]}
  dirName=$(echo $file | awk '{gsub(/-/, ""); gsub(/ /, "_"); gsub(/\.zip$/, ""); print}')
  path="$DIR/$dirName"
  mkdir $path

  echo "Unzipping $file to $path..."
  if unzip -qq "$file" -d $path; then
    echo "  Extraction successful, cleaning up..."
    rm -r "$file" 
  else
    echo "  Extraction failed\n  Exiting..."
    exit 1
  fi
  
  # Clear .jpgs except cover.jpg
  clear_extra_images $path

  if [ -f "$path/$COVER_FILE.png" ]; then
    mogrify -format jpg "$path/$COVER_FILE.png"
    echo "Converted $path/$COVER_FILE.png to .jpg"
  fi

  

  if ! mogrify -resize '700x700>' "$path/$COVER_FILE.jpg" 2>mogrify.errors.log; then
    echo "Mogrify failed. Check mogrify_errors.log"
    exit 1
  else
    echo "Successfully converted image"
  fi
#  convert "$path/$COVER_FILE.jpg" -resize 700x700\> "$COVER_FILE.jpg"

  #Resize image to 700x700
  #read width height < <(identify -format "%w %h" "$COVER_FILE.jpg")
  #if [ "$width" -gt 700 ] || ["$height" -gt 700]; then
done



