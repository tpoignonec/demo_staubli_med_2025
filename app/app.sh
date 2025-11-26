#!/bin/bash

# Default values
DEFAULT_IP="192.168.0.254"
STAUBLI_AUTOMATIC_MODE=false
STAUBLI_USE_MOCK_HARDWARE=false

# Help message
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --ip IP_ADDRESS     Set the IP address (default: $DEFAULT_IP)"
    echo "  -m, --mocked            Use mocked hardware(default: false)"
    echo "  -a, --auto              Enable automatic mode (default: false)"
    echo "  -h, --help              Show this help message"
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--ip)
            IP="$2"
            shift 2
            ;;
        -a|--auto)
            STAUBLI_AUTOMATIC_MODE=true
            shift
            ;;
        -m|--mocked)
            STAUBLI_USE_MOCK_HARDWARE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Use defaults if not provided
STAUBLI_ROBOT_IP="${IP:-$DEFAULT_IP}"

# Validate IP format
if ! [[ "$STAUBLI_ROBOT_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid IP address format."
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check for Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Start the services
echo "Starting the demo with IP: $STAUBLI_ROBOT_IP, AUTO_MODE: $STAUBLI_AUTOMATIC_MODE, MOCKED: $STAUBLI_USE_MOCK_HARDWARE"

# Remove any existing containers and start new ones
docker rm -f staubli_jpo_demo

STAUBLI_ROBOT_IP="$STAUBLI_ROBOT_IP" \
STAUBLI_AUTOMATIC_MODE="$STAUBLI_AUTOMATIC_MODE" \
STAUBLI_USE_MOCK_HARDWARE="$STAUBLI_USE_MOCK_HARDWARE" \
docker compose up  --remove-orphans
