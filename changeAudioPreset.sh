#!/bin/bash

# This script is used to switch between different alsa configuration files
#
# autor: Florin Hillebrand

# TODO:
#	- Let the user specify which match of "Master Playback Volume" with grep -m 
#	- Let the user specify the directory containing configuration files
#	- Insert tabs before value to match original syntax



VERSION="0.5"
THIS=$(dirname $0)

printUsage () {
	echo "Usage: changeAudioPreset.sh -p PRESETNAME [OPTIONS]"
	echo "		OPTIONS		Can be a set of this options:"
	echo "			-p PRESETNAME		Name of the preset stored in audioPresets folder."
	echo "			-k			Keep line after the first match "
	echo "						with 'Master Playback Volume'"
	echo "						from the old preset."
	echo "			-i			Print informations about this script."
	echo "			-v			Print version number."
	echo -e "\nExample: changeAudioPreset desktop	For the configuration file"
	echo "						audioPresets/desktop.conf"
}

printInfo () {
	echo "This program is used to switch between different alsa configuration files."
	echo "It searchs for configuration files with the specified PRESETNAME appended"
	echo "by a '.conf' in the directory named audioPresets relatively to the location"
	echo "of this script.\n"
	echo "Author: Florin Hillebrand 2011"
}

if [ $# -lt "1" ]; then
	echo -e "Wrong usage.\n" >&2
	printUsage
	exit 1
fi

while getopts ":ivkp:" opt; do
	case $opt in
		p)
			if [ -n "$preset_name" ]; then	
				echo "Preset name already specified" >&2
				exit 1
			fi
			preset_name=$OPTARG
			preset_file="$THIS/audioPresets/$preset_name.conf"

			if [ ! -f "$preset_file" ]; then
				echo "Could not find audio preset configuration file in $preset_file." >&2
				exit 1
			fi

		;;
		k)
			keep_volume=1
		;;
		i)
			printInfo
			exit 0
		;;
		v)
			echo $VERSION
			exit 0
		;;
		\?)
			echo "Invalid option -$opt." >&2
			exit 1
		;;
	esac
done

if [ -z $preset_name ]; then
	echo -e "Preset name not specified.\n" >&2
	printUsage
	exit 1
fi

if [ -z $keep_volume ]; then
	# apply new preset
	alsactl -f $new_preset restore

else
	old_preset="/tmp/alsapreset-old.conf"
	
	# backup old preset configuration file
	alsactl -f $old_preset store

	# find line which matches "Master Playback Volume"
	label_line=`cat $old_preset | grep --no-messages --max-count=1 -n "Master Playback Volume" | cut -d: -f1`

	# check if label has been found
	if [ -z "$label_line" ]; then
		echo "'Master Playback Volume' not found in current configuration." >&2
		exit 1
	fi

	# increment by one to catch value line
	value_line=$(( label_line + 1 ))

	# store old volume line
	old_volume=`sed -n ${value_line}p $old_preset`

	# delete backup preset
	rm -f $old_preset
	
	#store new preset in separate file
	new_preset="/tmp/alsapreset-new.conf"
	cp $preset_file $new_preset

	# delete old volume value line
	sed -i -e ${value_line}d $new_preset

	# insert old volume value line
	sed -i "$value_line i${old_volume}" $new_preset

	# apply new preset
	alsactl -f $new_preset restore

	# delete temporary created preset
	#rm -f $new_preset	
fi
exit 0