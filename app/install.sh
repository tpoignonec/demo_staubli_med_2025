#!/bin/bash

echo "Installing Staubli Demo Launcher..."

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
