#!/bin/bash

echo "Welcome to the Staubli Demo Launcher Setup"
sleep 1

# Default values
STAUBLI_AUTOMATIC_MODE=false
STAUBLI_USE_MOCK_HARDWARE=true

# Function to check if previous command was aborted
check_abort() {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

# Always resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Source .env from script directory if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Prompt for mocked hardware
if zenity --question --title="Staubli Demo Setup" --text="Use real hardware?"; then
    STAUBLI_USE_MOCK_HARDWARE=false
fi
check_abort

# Prompt for automatic mode
if zenity --question --title="Staubli Demo Setup" --text="Enable automatic mode?"; then
    STAUBLI_AUTOMATIC_MODE=true
fi
check_abort

SHOULD_CHECK_UPLOAD_VAL3_OUTPUT=false

if [ "$STAUBLI_USE_MOCK_HARDWARE" = true ]; then
    # Use default IP for mocked hardware
    STAUBLI_ROBOT_IP="$DEFAULT_IP"
else
    # Prompt for IP address using Zenity
    STAUBLI_ROBOT_IP=$(zenity --entry \
        --title="Staubli Demo Setup" \
        --text="Enter the robot IP address:" \
        --entry-text="$DEFAULT_IP")

    # Check if user canceled
    check_abort

    # Ask if the VAL3 program should be uploaded
    if zenity --question --title="Staubli Demo Setup" --text="Do you want to upload the VAL3 program to the robot?"; then
        echo "Uploading VAL3 program to the robot at IP: $STAUBLI_ROBOT_IP"
        # Call the upload script
        docker run --rm staubli_jpo_demo:${DEMO_VERSION} bash \
            -c "ros2 run staubli_robot_driver upload_val3_server.py --ros-args -p robot_ip:=${STAUBLI_ROBOT_IP}"
        SHOULD_CHECK_UPLOAD_VAL3_OUTPUT=true
    fi

    check_abort

    if [ "$SHOULD_CHECK_UPLOAD_VAL3_OUTPUT" = true ]; then
        if zenity --question --text="Please check the terminal output of the upload process to ensure the VAL3 program was uploaded successfully. Press no to abort..."; then
            echo "User confirmed VAL3 upload check."
        else
            echo "User indicated VAL3 upload issue. Exiting."
            sleep 2
            exit 1
        fi
    fi
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

if [ "$STAUBLI_USE_MOCK_HARDWARE" = false ]; then
    # If using real hardware, remind user to launch the VAL3 program
    zenity --info \
    --text="Please ensure that the VAL3 program <b>ros2_server</b> is running on the robot before proceeding.
    \nAlso, make sure the robot is ready to accept commands:
    • Power ON
    • Safety conditions met
    • Programmed automatic movement enabled" \
    --title="Reminder - Prepare Robot"

    # Show safety warning if not using mocked hardware
    zenity --warning --text="<span foreground='red' size='large'><b>WARNING!</b></span>\n\nThe robot will move in 5 seconds.\nDo not stay in robot workspace!\n\n<b>Starting the demo with:</b>\nIP: $STAUBLI_ROBOT_IP\nAutomatic Mode: $STAUBLI_AUTOMATIC_MODE\nMocked Hardware: $STAUBLI_USE_MOCK_HARDWARE" --title="Safety Warning - Starting Demo"
fi

# Remove any existing containers and start new ones
docker rm -f staubli_jpo_demo:${DEMO_VERSION} > /dev/null 2>&1

# Wait 3s before starting application container
sleep 3

STAUBLI_ROBOT_IP="$STAUBLI_ROBOT_IP" \
STAUBLI_AUTOMATIC_MODE="$STAUBLI_AUTOMATIC_MODE" \
STAUBLI_USE_MOCK_HARDWARE="$STAUBLI_USE_MOCK_HARDWARE" \
docker compose up --remove-orphans
