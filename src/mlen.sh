#!/bin/bash
#===============================================================================
#   mlen.sh     |   version 0.96    |   zlib license    |   2018-11-02
#   James Hendrie                   |   hendrie.james@gmail.com
#
#   This script will calculate the media playtime of a given file(s), directory
#   or playlist (m3u or pls).
#===============================================================================
VERSION="0.96"


##  Make sure we have the programs we need
required=('ffprobe' 'bc' 'printf')
for prog in "${required[@]}"; do
    if [[ "$(which "$prog" &> /dev/null; echo $?)" -ne 0 ]]; then
        echo "ERROR:  '$prog' required, but not found.  Aborting." 1>&2
        exit 1
    fi
done



##  Make sure we have at least one argument
if [[ $# -lt 1 ]]; then
    echo "ERROR:  Incorrect usage." 1>&2
    echo "Usage:  mlen.sh DIRECTORY" 1>&2
    echo "or" 1>&2
    echo "        mlen.sh FILE[s]" 1>&2
    exit 1
fi


##  Arrays of formats we give a shit about
##  Reduce the size of these to speed up the script
audioFormats=('mp3' 'ogg' 'oga' 'm4a' 'wav' 'wma')
videoFormats=('mp4' 'avi' 'webm' 'mpg' 'flv' 'wmv')
playlistFormats=('m3u' 'pls')


##  Print the help
function print_help {
    echo "This script calculates the total runtime of a given set of media files,"
    echo "a given directory or a given playlist.  This script DOES rely on the"
    echo "use of common media extensions (.mp3, .ogg, etc.), so if your filenames"
    echo "don't contain those, this script won't work properly."
    echo ""
    echo "Supported audio extensions:"
    echo -n "  "
    for fmt in "${audioFormats[@]}"; do
        echo -n "$fmt "
    done

    echo -e "\n\nSupported video extensions:"
    echo -n "  "
    for fmt in "${videoFormats[@]}"; do
        echo -n "$fmt "
    done

    echo -e "\n\nSupported playlist extensions:"
    echo -n "  "
    for fmt in "${playlistFormats[@]}"; do
        echo -n "$fmt "
    done

    echo -e "\n"
    echo "WARNING:  It's slow if you're going over tons of files.  Be patient."
}

##  Print version and author info
function print_version {
    echo "mlen.sh, version $VERSION"
    echo "James Hendrie <hendrie.james@gmail.com>"
}


##  Get the length of a file and echo it out
##  Args:
##  1   Filename to probe
function get_file_length {
    fLen="$(ffprobe -i "$FILE" -show_format 2>&1 | grep duration | tail -n1 | \
        cut -f2- -d'=')"

    echo "$fLen"
}


##  Prints the number of files
##  Args
##  1   Number of files (string)
function print_num_files {
    if [[ "$(echo "${numFiles} < 2" | bc)" = "1" ]]; then
        echo -ne "${numFiles} file\t\t"
    elif [[ "$(echo "${numFiles} < 10" | bc)" = 1 ]]; then
        echo -ne "${numFiles} files\t\t"
    else
        echo -ne "${numFiles} files\t"
    fi
}


##  Function to parse seconds (str) into a more human-readable format
##  Args
##  1   Seconds (string)
function parse_seconds {

    ##  The number of seconds without the fractional bit
    secs="$(echo "$1" | cut -f1 -d'.')"

    ##  The last little bit, separated from the seconds
    fraq="$(echo "$1" | cut -f2 -d'.' | head -c2)"

    ##  Number of seconds in a day minus one
    secLimit="$(echo "(60 * 60 * 24) - 1" | bc)"

    ##  If we've hit one or more days' time,
    if [[ "$(echo "${1} > ${secLimit}" | bc)" -eq 1 ]]; then
        printf '%02dd:%02dh:%02dm:%02d.%ds\n' $(($secs/86400)) \
            $(($secs%86400/3600)) $(($secs%3600/60)) $(($secs%60)) $fraq

    ##  If we're still under a day
    else
        printf '%02dh:%02dm:%02d.%ds\n' $(($secs/3600)) \
            $(($secs%3600/60)) $(($secs%60)) $fraq
    fi

    ##  Also just show the raw number of seconds
    #echo "(or $1 seconds)"

}

##  Get the length of all valid files in a given playlist
##  Args:
##  1   Playlist
function media_length_playlist {

    playlist="$1"
    len="0"
    numFiles="0"

    ##  Use ffprobe and bc to tally a number of seconds per line in the file
    while read FILE; do
        fLen="$(get_file_length "$FILE")"
        len="$(echo "${len} + ${fLen}" | bc)"
        numFiles="$(echo "${numFiles} + 1" | bc)"
    done <<< "$(cat "$playlist")"

    ##  Print out the number of seconds in a nicer way
    print_num_files "$numFiles"
    parse_seconds "$len"
}

##  Get the combined length of all given files
function media_length_files {

    len="0"
    numFiles="0"

    ##  Check if it's a playlist
    if [[ $# -eq 1 ]]; then

        ##  We grab the extension, and lowercase it for good measure
        ext="$(echo "$1" | cut -f2- -d'.' | tr [:upper:] [:lower:])"

        for fmt in "${playlistFormats[@]}"; do
            if [[ "$ext" = "$fmt" ]]; then
                media_length_playlist "$1"
                exit 0
            fi
        done
    fi


    ##  If it wasn't a playlist, we just run through the given files, tallying
    ##  up the total with ffprobe and bc
    for FILE in "${@}"; do
        fLen="$(get_file_length "$FILE")"
        len="$(echo "${len} + ${fLen}" | bc)"
        numFiles="$(echo "${numFiles} + 1" | bc)"
    done

    print_num_files "$numFiles"
    parse_seconds "$len"
}

##  Get the length of all valid files in a given directory
##  Args
##  1   Directory
function media_length_directory {

    ##  We'll just make a playlist, why the fuck not, let's go nuts here
    playlist="$(mktemp)"

    ##  Go through our audio formats
    for fmt in "${audioFormats[@]}"; do

        ##  Search for stuff and append it
        find "$1" -iname "*.${fmt}" | while read LINE; do
            echo "$LINE" >> "$playlist"
        done
    done
    
    ##  Go through our video formats
    for fmt in "${videoFormats[@]}"; do

        ##  Search for stuff and append it
        find "$1" -iname "*.${fmt}" | while read LINE; do
            echo "$LINE" >> "$playlist"
        done
    done

    ##  Print the length of the playlist
    media_length_playlist "$playlist"

    ##  Clean up
    rm "$playlist"
}

if [[ $# -eq 1 ]]; then

    ##  Do they want help?
    if [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]; then
        print_help
        exit 0

    ##  Do they want to send me nudes?
    elif [[ "$1" = "-V" ]] || [[ "$1" = "--version" ]]; then
        print_version
        exit 0

    ##  Is it a directory?
    elif [[ -d "$1" ]]; then
        media_length_directory "$1"

    ##  Is it just one regular-ass file?
    else
        media_length_files "$1"
    fi

##  Is it a whole bunch of files?
else
    media_length_files "${@}"
fi
