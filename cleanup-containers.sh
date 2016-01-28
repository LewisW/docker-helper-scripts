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
        # Stop all leftover selenium containers
        docker ps -a | grep 'selenium-stable' | awk '{print $1 }' | xargs -t --no-run-if-empty docker stop $FORCE
        
        # Delete stopped containers
        docker ps -a | grep Exited | awk '{print $1 }' | xargs -t --no-run-if-empty docker rm $FORCE
        # Delete old containers
        docker ps -a | grep ':5000/build' | grep 'months\|weeks\|days ago' | awk '{print $1}' | xargs -t --no-run-if-empty docker rm $FORCE
        # Delete old images
        docker images | grep ':5000/build' | grep 'months\|weeks\|days ago' | awk '{print $3}' | xargs -t --no-run-if-empty docker rmi $FORCE
fi
