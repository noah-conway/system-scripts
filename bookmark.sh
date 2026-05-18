#!/bin/sh

BKMK_FILE="${BOOKMARKS_FILE:-"$HOME/bmk/.bookmarks"}"

add_bookmark () {
  local URL="$1"
  local TITLE="$(curl -sL "$URL" | grep -oP '(?<=<title>).*?(?=</title>)' | tr -d ",")"
  local BKMK_LINE="$TITLE,$URL"

  mkdir -p "$(dirname $BKMK_FILE)"
  touch "$BKMK_FILE"
  echo "$BKMK_LINE" >> "$BKMK_FILE"
}


while getopts ":a:" opt; do
  case "$opt" in
    a)
      add_bookmark "$OPTARG"
      ;;
    \?)
      echo "Error: Invalid option $OPTARG"
      # invalid arg
  esac
done

#URL=$1
#TITLE="$(curl -sL "$URL" | grep -oP '(?<=<title>).*?(?=</title>)')"
#BKMK_LINE="$TITLE,$URL"
#echo "$BKMK_LINE"



