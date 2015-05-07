#!/bin/bash

WORKSPACE="$PWD"
GIT_COMMIT="$BUILD_NUMBER"

NET=
OUTPUT_FILE=
VOLUME=
SHOULD_OUTPUT=0
INTERACTIVE=

#if [ "$PHPCI_BUILD" = "" ]; then
#       PHPCI_BUILD="$BUILD_NUMBER"             
#       PHPCI_BUILD_PATH="$PWD"
#fi

while getopts "u:sd:b:" OPTION
do
     case $OPTION in
         u)
             export USER="$OPTARG"
             ;;
         s)
             NET="--net container:selenium-$GIT_COMMIT"
             ;;
#         o)
#            SHOULD_OUTPUT=1
#             ;;
         d)
                WORKSPACE="$OPTARG"
             ;;
         b)
                GIT_COMMIT="$OPTARG"
             ;;
#         f)
#             OUTPUT_FILE="$OPTARG"
#             ;;
     esac
done

# Shift all processed options away
shift $((OPTIND-1))

LOG_DIR=$(basename $0)

#if [ "$SHOULD_OUTPUT" -eq 1 ];
#then
#        tmpfile="/tmp/docker-run-output.tmp"
#       
#       tmpdir=$(mktemp -d)
#       trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP
#        hosttmp="$tmpdir/pipe"
#       mkfifo "$hosttmp"       
# 
#        VOLUME="-v $hosttmp:$tmpfile"
#fi

if [ -t 1 ];
then
        INTERACTIVE=' -it'
fi

command="docker run $INTERACTIVE --rm --privileged $VOLUME -v $WORKSPACE/build/$LOG_DIR:/project/build/logs -v $WORKSPACE/build/$LOG_DIR:/project/app/logs $NET build-$GIT_COMMIT --"

#if [ "$tmpfile" != "" ];
#then
#        command="$command logsave $tmpfile $@"
#       $command > /dev/null 2>&1 &
#
#       cat $hosttmp
#else
        command="$command $@"
        echo "*** Running command: $command";
        $command
#fi
