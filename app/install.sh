#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for Docker
if ! command -v docker &> /dev/null; then
    zenity --error --text="Docker is not installed. Please install Docker first."
    exit 1
fi

echo "Building the Docker images for Staubli Demo Launcher..."

# Check for Staubli Driver ROS2 image (error if not found)
if ! docker image inspect staubli_driver_ros2:0.1.0 > /dev/null 2>&1; then
    echo "Error: Docker image 'staubli_driver_ros2:0.1.0' not found. Please build it first."
    exit 1
fi

# Build the Staubli Demo Launcher image
docker build -t staubli_jpo_demo:latest \
    -f "$SCRIPT_DIR/../.docker/Dockerfile" \
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
