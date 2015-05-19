#!/bin/bash
selenium=

WORKSPACE="$PWD"
GIT_COMMIT="$BUILD_NUMBER"

NET=
VOLUME=
INTERACTIVE=

while getopts "u:sd:b:" OPTION
do
     case $OPTION in
         u)
               export USER="$OPTARG"
             ;;
         s)
              echo "*** Starting Selenium";
              selenium=`docker run --privileged -P -d lewisw/selenium`
              NET="--net container:$selenium"
             ;;
         d)
                WORKSPACE="$OPTARG"
             ;;
         b)
                GIT_COMMIT="$OPTARG"
             ;;
     esac
done

# Shift all processed options away
shift $((OPTIND-1))

LOG_DIR=$(basename $0)

if [ -t 1 ];
then
        INTERACTIVE=' -it'
fi

command="docker run $INTERACTIVE --rm --privileged $VOLUME -v $WORKSPACE/build/$LOG_DIR:/project/build/logs -v $WORKSPACE/build/$LOG_DIR:/project/app/logs $NET build-$GIT_COMMIT -- $@"

echo "*** Running command: $command";
$command
e=$?

if [ -n "$selenium" ];
then
     docker stop $selenium
     docker rm -f $selenium
     echo "*** Stoping Selenium";
fi

exit $e
