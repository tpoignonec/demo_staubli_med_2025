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

## Build docker image for JPO demo

1) Install and setup docker & docker-compose

2) Build Staubli driver base image:
```bash
git clone https://github.com/tpoignonec/staubli_driver_ros2.git

git checkout tpo/dockerization_for_demo_app

# Build staubli_driver docker image
docker build -t staubli_driver_ros2:jazzy staubli_driver_ros2
```

3) Build demo app image:
```bash
# Clone all
git clone https://github.com/tpoignonec/demo_staubli_med_2025.git

# Build demo container from staubli_driver_ros2:jazzy
docker build -t staubli_jpo_demo:0.1.0 \
    -f demo_staubli_med_2025/.docker/Dockerfile \
    demo_staubli_med_2025
```

4) Run 😀
