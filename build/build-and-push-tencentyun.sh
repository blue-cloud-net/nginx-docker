#!/bin/bash
set -eux;

# Define the private repository
repository="ccr.ccs.tencentyun.com/huansky/nginx";

# Find all Dockerfiles in the mainline directory
dockerfiles=$(find mainline -type f -name "Dockerfile*");

# Loop through each Dockerfile, build and push the image
for dockerfile in $dockerfiles; do
    # Extract the version from the Dockerfile's directory name
    version=$(basename "$(dirname "$dockerfile")");
    
    echo "Building and pushing tengine:$version...";

    # Build the Docker image for the specified platforms
    # Use --platform to specify the target platforms
    # Use --push to push the image directly to the repository
    docker buildx build \
        --cache-from "type=registry,ref=$repository:buildcache" \
        --cache-to "type=registry,ref=$repository:buildcache,mode=max" \
        --platform "linux/amd64,linux/arm64" \
        -f "$dockerfile" \
        -t "$repository:$version" \
        -t "$repository:$version-$(date +%Y%m%d%H%M%S)" \
        --push \
        .;

    echo "Successfully pushed tengine:$version to $repository";
done