#!/bin/bash

# Fetch the list of tags from Docker Hub API (you might need to paginate if you have more than 100 tags)
tags=$(curl -s https://hub.docker.com/v2/repositories/dahknesh232/testapps/tags/ | jq -r '.results[].name')

# Extract the highest version for the desired prefix (e.g., dev1-)
latest_version=$(echo "$tags" | grep "^dev1-" | sort -V | tail -n1)

# Break the version into components
major=$(echo $latest_version | cut -d '-' -f 2 | cut -d '.' -f 1)
minor=$(echo $latest_version | cut -d '.' -f 2)
patch=$(echo $latest_version | cut -d '.' -f 3)

# Increment the patch version
new_patch=$((patch + 1))

# Print the new version
echo "$major.$minor.$new_patch"
