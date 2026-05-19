#!/bin/sh

EXIT_CODE=0
BKMK_FILE="${BOOKMARKS_FILE:-"$HOME/.bookmarks.csv"}"
PICKERCMD="fzf"
BROWSERCMD="${BROWSER:-"firefox"}"

add_bookmark () {
  local URL="$1"
  local TITLE="$(curl -sL "$URL" | grep -oP '(?<=<title>).*?(?=</title>)' | tr -d ",")"
  local BKMK_LINE="$TITLE,$URL,$(date +%s)"
  local msg="Added $URL to bookmarks file"

  if [ ! -f "$BKMK_FILE" ]; then
    mkdir -p "$(dirname $BKMK_FILE)"
    touch "$BKMK_FILE"
  fi

  grep -q "$URL" "$BKMK_FILE" && 
  msg="$URL already exists in bookmarks file";EXIT_CODE=1 ||
  echo "$BKMK_LINE" >> "$BKMK_FILE"

  notify-send "$msg"
}


while getopts ":a:p:b:" opt; do
  case "$opt" in
    a)
      add_bookmark "$OPTARG"
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



