#!/bin/bash

function check_run()
{
	if [[ (! -f "mw4/common/$2") || ("mw4/common/$2" -ot "$1") ]]; then
		echo "$3"
		./$1
	fi 
}

find . -iname '*~' -delete
echo "Generating luaimg files..."
./imagedump.sh

BUILD="builds/mw4-hud-$(date +"%F").7z"
mkdir -p builds
rm -f "$BUILD"
echo "Creating archive '$BUILD'..."
unix2dos *.txt *.md
7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on "$BUILD" *.txt *.md mw4-hud.lua headers/*.lua img/*.luaimg mw4/*.lua mw4/common/*.lua &> /dev/null
dos2unix *.txt *.md
echo "All done."

