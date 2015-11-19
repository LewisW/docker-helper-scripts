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
BOOTOPTS="--skip-runit"

while getopts "u:sSd:b:c" OPTION
do
     case $OPTION in
          # Force runit (for the cron and syslogs)
         c)
               BOOTOPTS=""
             ;;
          # Set the user
         u)
               export USER="$OPTARG"
             ;;
          # Boot Selenium
         s)
              echo "*** Starting Selenium";
              selenium=`docker run --privileged -P -d lewisw/selenium-stable`
              NET="--net container:$selenium"
             ;;
          # Boot Sauce Connect
         S)
              echo "*** Starting Sauce Connect";
              selenium=`docker run -d lewisw/docker-sauce-connect $SAUCE_USERNAME $SAUCE_ACCESS_KEY`
              NET="--net container:$selenium"
             ;;
          # Use a different directory
         d)
                WORKSPACE="$OPTARG"
             ;;
          # Branch name
         b)
                GIT_COMMIT="$OPTARG"
             ;;
     esac
done

# No selenium? Skip startup files
#if [ "$selenium" == "" ];
#then
#     BOOTOPTS="$BOOTOPTS --skip-startup-files"
#fi

# Shift all processed options away
shift $((OPTIND-1))

if [ -t 1 ];
then
        INTERACTIVE=' -it'
fi

mkdir -p $WORKSPACE/logs/build
mkdir -p $WORKSPACE/logs/app

command="docker run $INTERACTIVE --rm \
--privileged $VOLUME \
-v $WORKSPACE/logs/build:/project/build/logs \
-v $WORKSPACE/logs/app/:/project/app/logs \
$NET $GIT_COMMIT $BOOTOPTS -- $@"

echo "*** Running command: $command";
$command
