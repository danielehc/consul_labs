#!/usr/bin/env bash

echo "Running the build script"

COMMIT=${TRAVIS_COMMIT_MESSAGE}

if [[ $COMMIT ]]; then

	echo "Commit message is: ${COMMIT}"

else

	echo "Commit message isnot set"

fi

#~ echo "Finding build folder"


exit 0
