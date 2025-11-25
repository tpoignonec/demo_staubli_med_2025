# Copyright 2025 ICube Laboratory
# BSD 3-Clause License
# Author: Thibault Poignonec <tpoignonec@unistra.fr>

from pathlib import Path

from launch import LaunchDescription
from launch.actions import RegisterEventHandler
from launch.event_handlers import OnProcessExit
from launch.substitutions import PathJoinSubstitution

from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare

from moveit_configs_utils import MoveItConfigsBuilder


def generate_launch_description():
    declared_arguments = []

    moveit_config = (
        MoveItConfigsBuilder(robot_name="staubli", package_name="demo_staubli_med_2025")
        .robot_description_semantic(Path("urdf") / "staubli_med.srdf.xacro")
        .planning_scene_monitor(publish_robot_description_semantic=True)
        .to_moveit_configs()
    )

    ld = LaunchDescription()
    ld.add_entity(LaunchDescription(declared_arguments))

    move_group_node = Node(
        package="moveit_ros_move_group",
        executable="move_group",
        output="screen",
        parameters=[
            moveit_config.to_dict(),
        ],
    )

    rviz_config_file = PathJoinSubstitution(
        [FindPackageShare("demo_staubli_med_2025"), "rviz", "moveit.rviz"]
    )
    rviz_node = Node(
        package="rviz2",
        executable="rviz2",
        name="rviz2_moveit",
        output="log",
        arguments=["-d", rviz_config_file],
        parameters=[
            moveit_config.robot_description,
            moveit_config.robot_description_semantic,
            moveit_config.robot_description_kinematics,
            moveit_config.planning_pipelines,
            moveit_config.joint_limits,
        ],
    )

    # Wait for robot description and joint states topics
    wait_for_robot_ready = Node(
        package="staubli_bringup",
        executable="wait_for_robot_ready.py",
        name="wait_for_robot_ready",
        output="both",
    )

    # Launch MoveIt when robot description becomes available
    launch_moveit_when_ready = RegisterEventHandler(
        OnProcessExit(target_action=wait_for_robot_ready, on_exit=[move_group_node])
    )

    # Make sure that robot state_publisher starts before this launch file
    # See bringup package launch file
    ld.add_action(rviz_node)
    ld.add_action(wait_for_robot_ready)
    ld.add_action(launch_moveit_when_ready)

    return ld
