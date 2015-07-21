#!/bin/bash
selenium=

finish() {
     if [ -n "$selenium" ];
     then
          docker stop $selenium
          docker rm -f $selenium
          echo "*** Stoping Selenium";
     fi
}
trap finish EXIT

WORKSPACE="$PWD"
GIT_COMMIT="$BUILD_NUMBER"

NET=
VOLUME=
INTERACTIVE=

while getopts "u:sSd:b:" OPTION
do
     case $OPTION in
         u)
               export USER="$OPTARG"
             ;;
         s)
              echo "*** Starting Selenium";
              selenium=`docker run --privileged -P -d lewisw/selenium-stable`
              NET="--net container:$selenium"
             ;;
         S)
              echo "*** Starting Sauce Connect";
              selenium=`docker run -d lewisw/docker-sauce-connect $SAUCE_USERNAME $SAUCE_ACCESS_KEY`
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

command="docker run $INTERACTIVE --rm --privileged $VOLUME -v $WORKSPACE/build/$LOG_DIR:/project/build/logs -v $WORKSPACE/build/$LOG_DIR:/project/app/logs $NET $GIT_COMMIT -- $@"

echo "*** Running command: $command";
$command
