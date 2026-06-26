#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source .env from script directory if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    zenity --error --text="Docker is not installed. Please install Docker first."
    exit 1
fi

echo "Building the Docker images for Staubli Demo Launcher..."

# Check for Staubli Driver ROS2 image, pull if not available
if ! docker image inspect ${STAUBLI_DRIVER_IMAGE}:${STAUBLI_DRIVER_VERSION} > /dev/null 2>&1; then
    echo "Staubli Driver ROS2 image not found. Pulling from registry..."
    if ! docker pull ${STAUBLI_DRIVER_IMAGE}:${STAUBLI_DRIVER_VERSION}; then
        echo "Error: Failed to pull Docker image '${STAUBLI_DRIVER_IMAGE}:${STAUBLI_DRIVER_VERSION}'. Please check your network connection and try again."
        exit 1
    fi
fi

# Build the Staubli Demo Launcher image
docker build -t staubli_jpo_demo:${DEMO_VERSION} \
    -f "$SCRIPT_DIR/../.docker/Dockerfile" \
    --build-arg STAUBLI_DRIVER_IMAGE="${STAUBLI_DRIVER_IMAGE}" \
    --build-arg STAUBLI_DRIVER_VERSION="${STAUBLI_DRIVER_VERSION}" \
    "$SCRIPT_DIR/.."

echo "Installing Staubli Demo Launcher..."

# Set the application directory
APP_DIR="$SCRIPT_DIR"
echo "App directory: $APP_DIR"

# Remove existing desktop entry if it exists
if [ -f ~/.local/share/applications/staubli-demo.desktop ]; then
    rm ~/.local/share/applications/staubli-demo.desktop
fi

# Create desktop entry with dynamic path replacement
sed "s|APP_DIR|$APP_DIR|g" "$APP_DIR/staubli-demo.desktop" > ~/.local/share/applications/staubli-demo.desktop

# Make sure the scripts are executable
chmod +x ~/.local/share/applications/staubli-demo.desktop
chmod +x $APP_DIR/app.sh

# OK message
echo "Installation complete. You can now launch the Staubli Demo from your application menu."
