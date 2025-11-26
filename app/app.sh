#!/bin/bash

echo "Welcome to the Staubli Demo Launcher Setup"
sleep 1

# Default values
DEFAULT_IP="192.168.0.254"
STAUBLI_AUTOMATIC_MODE=false
STAUBLI_USE_MOCK_HARDWARE=false

# Prompt for IP address using Zenity
STAUBLI_ROBOT_IP=$(zenity --entry \
  --title="Staubli Demo Setup" \
  --text="Enter the robot IP address:" \
  --entry-text="$DEFAULT_IP")

# Check if user canceled
if [ $? -ne 0 ]; then
    exit 1
fi

# Prompt for automatic mode
if zenity --question --title="Staubli Demo Setup" --text="Enable automatic mode?"; then
    STAUBLI_AUTOMATIC_MODE=true
fi

# Prompt for mocked hardware
if zenity --question --title="Staubli Demo Setup" --text="Use mocked hardware?"; then
    STAUBLI_USE_MOCK_HARDWARE=true
fi

# Validate IP format
if ! [[ "$STAUBLI_ROBOT_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    zenity --error --text="Error: Invalid IP address format."
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    zenity --error --text="Docker is not installed. Please install Docker first."
    exit 1
fi

# Check for Docker Compose
if ! command -v docker compose &> /dev/null; then
    zenity --error --text="Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Allow Docker to access X server
xhost +local:docker

# Start the services
echo "Starting the demo with IP: $STAUBLI_ROBOT_IP, AUTO_MODE: $STAUBLI_AUTOMATIC_MODE, MOCKED: $STAUBLI_USE_MOCK_HARDWARE"

# Show safety warning if not using mocked hardware
if [ "$STAUBLI_USE_MOCK_HARDWARE" = false ]; then
    zenity --warning --text="<span foreground='red' size='large'><b>WARNING!</b></span>\n\nThe robot will move in 5 seconds.\nDo not stay in robot workspace!\n\n<b>Starting the demo with:</b>\nIP: $STAUBLI_ROBOT_IP\nAutomatic Mode: $STAUBLI_AUTOMATIC_MODE\nMocked Hardware: $STAUBLI_USE_MOCK_HARDWARE" --title="Safety Warning - Starting Demo"
fi

# Remove any existing containers and start new ones

sleep 3
docker rm -f staubli_jpo_demo > /dev/null 2>&1
STAUBLI_ROBOT_IP="$STAUBLI_ROBOT_IP" \
STAUBLI_AUTOMATIC_MODE="$STAUBLI_AUTOMATIC_MODE" \
STAUBLI_USE_MOCK_HARDWARE="$STAUBLI_USE_MOCK_HARDWARE" \
docker compose up --remove-orphans
