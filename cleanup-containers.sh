#!/bin/bash
set -e

FORCE=
ALL=

while getopts "af" opt; do
        case $opt in
          f)
            FORCE='-f'
            ;;
          a)
            ALL=true
            ;;
        esac
done

if [ "$ALL" = true ];
then
        # Delete all containers
        docker rm $FORCE $(docker ps -a -q)
        # Delete all images
        docker rmi $FORCE $(docker images -q)
else
        # Delete stopped containers
        docker ps -a | grep Exited | awk '{print $1 }' | xargs -t --no-run-if-empty docker rm $FORCE
        # Delete old containers
        docker ps -a | grep 'months\|weeks\|days ago' | awk '{print $1}' | xargs -t --no-run-if-empty docker rm $FORCE
        # Delete old images
        docker images | grep 'months\|weeks\|[0-9]\{2,\} days ago' | awk '{print $3}' | xargs -t --no-run-if-empty docker rmi $FORCE
fi
