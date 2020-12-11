#!/bin/bash

set -eu

output_dir="../priv/static/img/pics"
resolutions=(
    480
    1024
    1920
)
ignore=(
    homepage_background.png
)

file_extension () {
    filename=$(basename -- "$file")
    echo "${filename##*.}"
}

file_name () {
    filename=$(basename -- "$file")
    echo "${filename%.*}"
}

convert_image () {
    name=$(file_name)
    extension=$(file_extension)
    res="$1w"
    output="$output_dir/$name-$res.$extension"
    convert -geometry "$resolution"x $file $output
}

produce_webp () {
    name=$(file_name)
    output="$output_dir/$name.webp"
    cwebp $file -quiet -o $output
}

progress() {
    local w=80 p=$1;  shift
    # create a string of spaces, then change them to dots
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /.};
    # print those dots on a fixed-width space plus the percentage etc. 
    printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*"; 
}


echo "Generating responsive versions of the pictures…"

if ! command -v convert &> /dev/null
then
    echo "$(tput setaf 1)ERROR: The convert command could not be found. You need to install ImageMagick.$(tput sgr 0)"
    exit 1
fi

nb_files=$( shopt -s nullglob ; set -- $output_dir/* ; echo $#)

tasks=$((${#resolutions[@]}*$nb_files))
i=1
for file in $output_dir/*
do
    if [[ -f $file ]]; then
        for resolution in "${resolutions[@]}"; do
            convert_image $resolution
            progress $(($i*100/$tasks)) still working...
            i=$((i+1))
        done
    fi
done
echo -e "\nDone!"

echo "Generating optimized versions of the pictures…"

if ! command -v cwebp &> /dev/null
then
    echo "$(tput setaf 1)ERROR: The cwebp command could not be found. You need to install webp.$(tput sgr 0)"
    exit 1
fi

nb_files=$( shopt -s nullglob ; set -- $output_dir/* ; echo $#)
i=1
for file in $output_dir/*
do
    if [[ -f $file ]]; then
        produce_webp
        progress $(($i*100/$nb_files)) still working...
        i=$((i+1))
    fi
done
echo -e "\nDone!"