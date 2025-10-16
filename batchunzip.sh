#!/bin/bash
DIR="/home/noah/Music/new"

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


for file in *.zip; do
	arr=( $file )
	dirName=${arr[0]}
	echo "file: $file"
	make_dirname $dirName 1
	echo "dir: $DIR/$dirName"
	unzip "$file" -d "$DIR/$dirName"
#	rm -r "$file"
done



