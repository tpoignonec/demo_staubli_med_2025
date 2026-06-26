# demo_staubli_med_2025

Minimalist demo for the Staubli driver, used during the 2025 Staubli JPO days with the TX2-60L medical robot

## Containerized app

1. Install `docker` and `docker-compose`
2. Install the demo app

```bash
curl -sSL https://raw.githubusercontent.com/tpoignonec/demo_staubli_med_2025/main/install.sh | bash
```

3. Change robot IP if needed:

```bash
nano ~/.local/share/demo_staubli_med_2025/app/.env

# Change IP address
# Save and exit
```

> [!NOTE]
> To uninstall the demo app (removes the launcher and Docker images):
>
> ```bash
> # Remove app launcher and cloned repo
> rm -f ~/.local/share/applications/staubli-demo.desktop
> rm -rf ~/.local/share/demo_staubli_med_2025
>
> # Remove docker images
> docker rmi $(docker images 'ghcr.io/icube-robotics/staubli_driver_ros2' -q) 2>/dev/null
> docker rmi $(docker images 'staubli_driver_ros2' -q) 2>/dev/null
> ```

## Manual local installation

```bash
source /opt/ros/jazzy/setup.bash

mkdir -p ~/ws_demo_staubli_jpo_2025/src
cd ~/ws_demo_staubli_jpo_2025/src

git clone https://github.com/tpoignonec/demo_staubli_med_2025.git

# Core dependencies
vcs import . < demo_staubli_med_2025/demo_staubli_med_2025.repos
rosdep install --ignore-src --from-paths . -y -r
cd ..

# Build ros2 packages
colcon build
source install/setup.bash
```
