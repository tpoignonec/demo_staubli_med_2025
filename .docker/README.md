# Build docker image

1) Install and setup docker & docker-compose

- Follow instructions at https://docs.docker.com/engine/install/ubuntu/ to install docker
- Don't forget the post-installation steps (see [here](https://docs.docker.com/engine/install/linux-postinstall/))

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
