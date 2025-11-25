# Copyright 2025 ICube Laboratory
# BSD 3-Clause License
# Author: Thibault Poignonec <tpoignonec@unistra.fr>

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution

from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    """Launch demo with robot control and MoveIt."""
    # Launch arguments
    declared_arguments = []

    declared_arguments.append(
        DeclareLaunchArgument(
            "use_mock_hardware",
            default_value="true",
            description="Use mock hardware for robot control.",
            choices=["true", "false"],
        )
    )

    declared_arguments.append(
        DeclareLaunchArgument(
            "robot_ip",
            default_value="192.168.0.254",
            description="IP address of the robot.",
        )
    )

    # Launch robot control
    launch_robot_control = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            PathJoinSubstitution(
                [FindPackageShare("demo_staubli_med_2025"), "launch", "robot_driver.launch.py"]
            )
        ),
        launch_arguments={
            "use_mock_hardware": LaunchConfiguration("use_mock_hardware"),
            "robot_ip": LaunchConfiguration("robot_ip"),
            "gui": "false",  # Disable RViz in robot control
        }.items(),
    )

    # Launch MoveIt
    launch_moveit = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            PathJoinSubstitution(
                [FindPackageShare("demo_staubli_med_2025"), "launch", "moveit.launch.py"]
            )
        ),
        launch_arguments={
            "gui": 'false',
        }.items(),
    )

    launch_trajectory_planner = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            PathJoinSubstitution(
                [FindPackageShare("demo_staubli_med_2025"), "launch", "trajectory_planner.launch.py"]
            )
        ),
        launch_arguments={
            "loop_forever": 'true',
        }.items(),
    )

    rviz_config_file = PathJoinSubstitution(
        [FindPackageShare("demo_staubli_med_2025"), "rviz", "moveit_auto.rviz"]
    )
    rviz_node = Node(
        package="rviz2",
        executable="rviz2",
        name="rviz2_moveit",
        output="log",
        arguments=["-d", rviz_config_file],
    )

    return LaunchDescription(
        declared_arguments
        + [
            launch_robot_control,
            launch_moveit,
            launch_trajectory_planner,
            rviz_node,
        ]
    )
