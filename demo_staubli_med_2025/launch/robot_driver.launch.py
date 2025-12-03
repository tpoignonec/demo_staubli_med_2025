# Copyright 2025 ICube Laboratory
# BSD 3-Clause License
# Author: Thibault Poignonec <tpoignonec@unistra.fr>

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch.substitutions import (
    Command,
    FindExecutable,
    LaunchConfiguration,
    PathJoinSubstitution,
)
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare
from launch_ros.parameter_descriptions import ParameterValue


def generate_launch_description():
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

    declared_arguments.append(
        DeclareLaunchArgument(
            "gui",
            default_value="true",
            description="Launch Rviz if true.",
            choices=["true", "false"],
        )
    )

    use_mock_hardware = LaunchConfiguration("use_mock_hardware")

    # Robot description

    description_file = PathJoinSubstitution(
        [FindPackageShare("demo_staubli_med_2025"), "urdf", "staubli_med.urdf.xacro"]
    )
    robot_description_content = Command(
        [
            PathJoinSubstitution([FindExecutable(name="xacro")]),
            " ",
            description_file,
            " ",
            "use_mock_hardware:=",
            use_mock_hardware,
            " ",
            "robot_ip:=",
            LaunchConfiguration("robot_ip"),
        ]
    )
    robot_description = {
        "robot_description": ParameterValue(value=robot_description_content, value_type=str)
    }

    # Robot state publisher

    robot_state_publisher_node = Node(
        package="robot_state_publisher",
        executable="robot_state_publisher",
        parameters=[robot_description],
        output="both",
    )

    # ros2_control node
    controllers = PathJoinSubstitution(
        [
            FindPackageShare("demo_staubli_med_2025"),
            "config",
            "controllers.yaml",
        ]
    )

    control_node = Node(
        package="controller_manager",
        executable="ros2_control_node",
        parameters=[controllers, {"use_sim_time": False}],
        output="both",
    )

    # Always load and activate joint state broadcaster
    load_joint_state_broadcaster = Node(
        package="controller_manager",
        executable="spawner",
        arguments=["joint_state_broadcaster", "--controller-manager", "/controller_manager"],
    )

    load_joint_trajectory_controller = Node(
        package="controller_manager",
        executable="spawner",
        arguments=["joint_trajectory_controller", "--controller-manager", "/controller_manager"],
    )

    # Load controllers
    load_controllers = [
        load_joint_state_broadcaster,
        load_joint_trajectory_controller,
    ]

    # Rviz
    rviz_config_file = PathJoinSubstitution(
        [FindPackageShare("demo_staubli_med_2025"), "rviz", "default.rviz"]
    )
    rviz_node = Node(
        package="rviz2",
        executable="rviz2",
        name="rviz2",
        output="log",
        arguments=["-d", rviz_config_file],
        condition=IfCondition(LaunchConfiguration("gui")),
    )
    # Launch description
    nodes = [
        robot_state_publisher_node,
        control_node,
        rviz_node,
    ]

    return LaunchDescription(declared_arguments + nodes + load_controllers)
