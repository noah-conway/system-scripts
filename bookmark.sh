#!/bin/sh

EXIT_CODE=0
BKMK_FILE="${BOOKMARKS_FILE:-"$HOME/.bookmarks.csv"}"
PICKERCMD="fzf"
BROWSERCMD="${BROWSER:-"firefox"}"

add_bookmark () {
  local msg="Added $URL to bookmarks file"
  local URL="$1"
  echo "$URL" | grep -E -q '^(https?://)?([\da-z.-]+)\.([a-z.]{2,6})([/\w .-]*)*$`' ||
    notify-send "Failure | invalid URL";exit 1
  local TITLE="$(curl -sL "$URL" | grep -oP '(?<=<title>).*?(?=</title>)' | tr -d ",")" 
  
  if [ -z "$TITLE" ]; then
    notify-send "Failure | unable to get HTML data via curl"
    EXIT_CODE=1
    return
  fi

  local BKMK_LINE="$TITLE,$URL,$(date +%s)"

  if [ ! -f "$BKMK_FILE" ]; then
    mkdir -p "$(dirname $BKMK_FILE)"
    touch "$BKMK_FILE"
  fi

  grep -q "$URL" "$BKMK_FILE" && 
  notify-send "$URL already exists in bookmarks file";exit 1 ||
  echo "$BKMK_LINE" >> "$BKMK_FILE"

  notify-send "$msg"
}


while getopts ":a:p:b:" opt; do
  case "$opt" in
    a)
      add_bookmark "$OPTARG"
      echo $EXIT_CODE
      return $EXIT_CODE
      ;;
    p) #specify picker
      PICKERCMD="$OPTARG"
      ;;
    b)
      BROWSERCMD="$OPTARG"
      ;;
    \?)
      echo "Error: Invalid option $OPTARG"
      # invalid arg
      ;;
  esac
done

URL="$(cut -d, -f1,2 "$BKMK_FILE" | $PICKERCMD | cut -d, -f2)" &&
$BROWSERCMD $URL


exit $EXIT_CODE

#URL=$1
#TITLE="$(curl -sL "$URL" | grep -oP '(?<=<title>).*?(?=</title>)')"
#BKMK_LINE="$TITLE,$URL"
#echo "$BKMK_LINE"



