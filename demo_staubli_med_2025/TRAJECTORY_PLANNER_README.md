# Trajectory Planner Node

A Python node for executing robot motion using MoveIt's move_group interface.

## Features

1. **Move to Start Pose Slowly**: Moves the robot to a predefined start pose with configurable slow velocity
2. **Cartesian Rotations**: Executes rotations in Cartesian space using the Pilz LIN planner
3. **Square Trajectory**: Executes a square trajectory in the XY plane using the Pilz planner

## Dependencies

- ROS 2 Jazzy
- MoveIt 2
- Pilz Industrial Motion Planner

## Usage

### Launch the Complete Demo

To run the full demo sequence (all three tasks):

```bash
# First, make sure the robot driver and MoveIt are running
ros2 launch demo_staubli_med_2025 robot_driver.launch.py
ros2 launch demo_staubli_med_2025 moveit.launch.py

# Then, in a new terminal, launch the trajectory planner
ros2 launch demo_staubli_med_2025 trajectory_planner.launch.py
```

### Launch with Custom Parameters

You can customize the behavior using launch arguments:

```bash
ros2 launch demo_staubli_med_2025 trajectory_planner.launch.py \
    planning_group:=arm \
    base_frame:=base_link \
    end_effector_link:=needle_tip_link \
    start_pose_max_velocity_scaling:=0.05 \
    square_size:=0.15
```

### Run as a Standalone Node

You can also run the node directly without a launch file:

```bash
ros2 run demo_staubli_med_2025 trajectory_planner
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `planning_group` | string | `arm` | The name of the MoveIt planning group |
| `base_frame` | string | `base_link` | The base reference frame |
| `end_effector_link` | string | `needle_tip_link` | The end effector link name |
| `start_pose_max_velocity_scaling` | double | `0.1` | Velocity scaling factor (0.0-1.0) for the start pose motion |
| `square_size` | double | `0.1` | Size of the square trajectory in meters |

## Demo Sequence

The demo executes the following tasks in order:

### Task 1: Move to Start Pose
- Moves to a predefined Cartesian pose: (x=0.4, y=0.0, z=0.3)
- Uses very slow velocity (default 10% of maximum)
- Uses the default motion planner (OMPL)

### Task 2: Cartesian Rotations
- Performs a series of rotations around the Z-axis
- Rotation sequence: 0° → 45° → 90° → 45° → 0°
- Uses Pilz LIN planner for Cartesian space motion
- Velocity scaling: 30%

### Task 3: Square Trajectory
- Executes a square path in the XY plane
- Square size is configurable (default: 0.1m × 0.1m)
- Uses Pilz LIN planner for linear Cartesian motion
- Velocity scaling: 20%
- Returns to the starting corner after completing the square

## Customization

### Modify Start Pose

Edit the `move_to_start_pose_slowly()` method in `trajectory_planner.py`:

```python
start_pose.pose.position.x = 0.4  # Change these values
start_pose.pose.position.y = 0.0
start_pose.pose.position.z = 0.3
```

### Adjust Rotation Angles

Edit the `execute_cartesian_rotations()` method:

```python
rotation_angles = [0.0, math.pi/4, math.pi/2, math.pi/4, 0.0]
```

### Change Velocity Scaling

Modify the velocity scaling factors in each method or pass as parameters.

## Pilz Planner Configuration

The Pilz Industrial Motion Planner is configured in:
```
config/pilz_cartesian_limits.yaml
```

Adjust these limits based on your robot's capabilities:
- `max_trans_vel`: Maximum translational velocity (m/s)
- `max_trans_acc`: Maximum translational acceleration (m/s²)
- `max_trans_dec`: Maximum translational deceleration (m/s²)
- `max_rot_vel`: Maximum rotational velocity (rad/s)

## Troubleshooting

### Planning Failures

If planning fails, check:
1. The robot is not in a singularity
2. The target poses are within the workspace
3. There are no collision obstacles
4. Joint limits are not violated

### Execution Failures

If execution fails:
1. Ensure the robot driver is running and connected
2. Check that MoveIt move_group is active
3. Verify the controller is in the correct state
4. Check for collision warnings in the logs

## Safety Notes

⚠️ **Important Safety Considerations:**

1. Always test in simulation first
2. Keep emergency stop accessible
3. Start with very slow velocities
4. Verify workspace limits before running
5. Ensure the area around the robot is clear
6. The default start pose may need adjustment for your specific robot setup

## License

BSD 3-Clause License
Copyright 2025 ICube Laboratory
