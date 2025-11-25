#!/usr/bin/env python3
# Copyright 2025 ICube Laboratory
# BSD 3-Clause License
# Author: Thibault Poignonec <tpoignonec@unistra.fr>

"""Launch file for the trajectory planner demo node."""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration

from launch_ros.actions import Node


def generate_launch_description():
    """Generate launch description for trajectory planner."""
    # Declare launch arguments
    declared_arguments = []

    declared_arguments.append(
        DeclareLaunchArgument(
            "loop_forever",
            default_value="false",
            description="Whether to loop the trajectory planner forever.",
            choices=["true", "false"],
        )
    )

    # Create trajectory planner node
    trajectory_planner_node = Node(
        package="demo_staubli_med_2025",
        executable="trajectory_planner_cpp",
        name="trajectory_planner",
        output="screen",
        parameters=[
            {"loop_forever": LaunchConfiguration("loop_forever")},
        ],
    )

    return LaunchDescription(declared_arguments + [trajectory_planner_node])
