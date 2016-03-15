#!/bin/bash
set -e

# Cleanup old images
docker images | grep ':5000/build' | grep 'months\|weeks\|days\|hours ago' | awk '{print $3}' | xargs -t --no-run-if-empty docker rmi || true

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
sudo sh -c "find -L ./ -exec touch -t 200001010000.00 '{}' \;"

echo "** Building image **"

# Build our image
docker build --rm -t $GIT_COMMIT .

echo "*** Successfully built docker image $GIT_COMMIT ***"
echo "*** Pushing to local repository ***"

(setsid docker push $GIT_COMMIT &)

mkdir -p build
touch build/docker.built
