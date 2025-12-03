cmake_minimum_required(VERSION 3.8)
project(demo_staubli_med_2025)

# Default to C++17
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(ament_cmake_python REQUIRED)
find_package(rclpy REQUIRED)
find_package(rclcpp REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(moveit_ros_planning_interface REQUIRED)

# C++ executable
add_executable(trajectory_planner_cpp src/trajectory_planner_node.cpp)
ament_target_dependencies(trajectory_planner_cpp
  rclcpp
  geometry_msgs
  tf2_geometry_msgs
  moveit_ros_planning_interface
)

install(TARGETS
  trajectory_planner_cpp
  DESTINATION lib/${PROJECT_NAME}
)

# Install Python modules
ament_python_install_package(${PROJECT_NAME})

# Install Python executables
# install(PROGRAMS
#   demo_staubli_med_2025/trajectory_planner.py
#   DESTINATION lib/${PROJECT_NAME}
#   RENAME trajectory_planner
# )

# Install launch / config files
install(DIRECTORY config launch meshes urdf rviz
  DESTINATION share/${PROJECT_NAME}
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
