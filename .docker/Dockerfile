# syntax=docker/dockerfile:1
# Build from parent directory with: docker build -t staubli_jpo_demo:0.1.0 -f .docker/Dockerfile .

FROM staubli_driver_ros2:jazzy

# Create workspace
WORKDIR /ws

# Copy source code
COPY . /ws/src/demo_staubli_med_2025

# Install dependencies
RUN apt-get update && \
    rosdep install --from-paths src --ignore-src -r -y

# Build packages
RUN . /opt/ros/jazzy/setup.sh \
    && colcon build \
    --cmake-args -DCMAKE_BUILD_TYPE=Release

# Ensure the ROS 2 workspace is sourced in every new shell
RUN echo "source /ws/install/setup.bash" >> /root/.bashrc

COPY .docker/entrypoint.sh /root/

RUN chmod +x /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]

# Set the default command to keep the container running
CMD ["/bin/bash", "-c", "tail -f /dev/null"]