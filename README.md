# demo_staubli_med_2025

Minimalist demo for the Staubli driver, used during the 2025 Staubli JPO days with the TX2-60L medical robot

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

## Build docker image to share with Staubli

