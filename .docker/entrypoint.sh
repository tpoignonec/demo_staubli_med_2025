#!/bin/bash

# Set ROS distribution
# This variable defines the ROS 2 distribution being used (e.g., "jazzy", "rolling", etc.)
ROS_DISTRO="jazzy"

# Creates required temp directory for GUI applications - needed by Linux desktop standards
# Set up XDG runtime directory
export XDG_RUNTIME_DIR=/tmp/runtime-$USER
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Source ROS setup file
source /opt/ros/$ROS_DISTRO/setup.bash

# Source the local workspace setup
source /ws/install/setup.bash

# Source the .bashrc file to ensure all environment variables are up to date
source /root/.bashrc

# Change to the ROS 2 workspace directory
cd /ws/

# Any command you run after this script runs in the environment set up by the script.
exec "$@"
