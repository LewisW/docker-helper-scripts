#!/bin/bash
set -e

while getopts "b:" OPTION
do
     case $OPTION in
         b)
                GIT_COMMIT="$OPTARG"
             ;;
     esac
done

echo "** Resetting mtime **" 
# Reset the mtime to force Docker's cache to ignore checkout time
sudo sh -c "find ./ | xargs touch -t 200001010000.00"

echo "** Building image **"

# Build our image
sudo docker build --rm -t $GIT_COMMIT .

echo "*** Successfully built docker image $GIT_COMMIT ***"
echo "*** Pushing to local repository ***"

(setsid docker push $GIT_COMMIT &)

mkdir -p build
touch build/docker.built
