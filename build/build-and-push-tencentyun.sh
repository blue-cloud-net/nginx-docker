#!/bin/bash
set -eux;

# Define the private repository
repository="ccr.ccs.tencentyun.com/huansky/nginx";

# Parse command line arguments
build_type="stable"  # default to stable
while [[ $# -gt 0 ]]; do
    case $1 in
        --nightly)
            build_type="nightly"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Determine the directory and tag suffix based on build type
if [ "$build_type" = "nightly" ]; then
    dockerfile_dir="nightly"
    echo "Building nightly version..."
else
    dockerfile_dir="mainline"
    echo "Building stable version..."
fi

# Find all Dockerfiles in the directory
dockerfiles=$(find "$dockerfile_dir" -type f -name "Dockerfile*");

# Loop through each Dockerfile, build and push the image
for dockerfile in $dockerfiles; do
    # Extract the version from the Dockerfile's directory name
    version=$(basename "$(dirname "$dockerfile")");
    
    echo "Building and pushing tengine:$version...";

    # Build the Docker image for the specified platforms
    # Use --platform to specify the target platforms
    # --platform "linux/amd64,linux/arm64" \
    # Use --push to push the image directly to the repository
    docker buildx build \
        --cache-from "type=registry,ref=$repository:$version-buildcache" \
        --cache-to "type=registry,ref=$repository:$version-buildcache,mode=max" \
        --platform "linux/amd64" \
        -f "$dockerfile" \
        -t "$repository:$version" \
        -t "$repository:$version-$(date +%Y%m%d%H%M%S)" \
        --push \
        .;

    echo "Successfully pushed tengine:$version to $repository";
done
