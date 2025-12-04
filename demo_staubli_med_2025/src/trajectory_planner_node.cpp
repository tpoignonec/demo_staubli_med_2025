// Copyright 2025 ICube Laboratory
// BSD 3-Clause License
// Author: Thibault Poignonec <tpoignonec@unistra.fr>

#include <memory>
#include <string>
#include <vector>
#include <cmath>
#include <thread>
#include <chrono>

#include "rclcpp/rclcpp.hpp"
#include "geometry_msgs/msg/pose_stamped.hpp"
#include "tf2_geometry_msgs/tf2_geometry_msgs.hpp"
#include "moveit/move_group_interface/move_group_interface.hpp"
#include "moveit/planning_scene_interface/planning_scene_interface.hpp"

class TrajectoryPlannerNode : public rclcpp::Node
{
public:
  TrajectoryPlannerNode()
  : Node("trajectory_planner_node")
  {
    // Declare parameters
    this->declare_parameter("planning_group", "arm");
    this->declare_parameter("base_frame", "base_link");
    this->declare_parameter("end_effector_link", "needle_tip_link");
    this->declare_parameter("start_pose_max_velocity_scaling", 0.1);
    this->declare_parameter("square_size", 0.2);
    this->declare_parameter("loop_forever", false);

    // Get parameters
    planning_group_ = this->get_parameter("planning_group").as_string();
    base_frame_ = this->get_parameter("base_frame").as_string();
    end_effector_link_ = this->get_parameter("end_effector_link").as_string();
    start_velocity_scaling_ = this->get_parameter("start_pose_max_velocity_scaling").as_double();
    square_size_ = this->get_parameter("square_size").as_double();
    loop_forever_ = this->get_parameter("loop_forever").as_bool();

    RCLCPP_INFO(this->get_logger(), "Planning group: %s", planning_group_.c_str());
    RCLCPP_INFO(this->get_logger(), "Base frame: %s", base_frame_.c_str());
    RCLCPP_INFO(this->get_logger(), "End effector: %s", end_effector_link_.c_str());

    // Create publisher for target pose visualization
    target_pose_pub_ = this->create_publisher<geometry_msgs::msg::PoseStamped>(
      "target_pose", 10);
  }

  void initialize_move_group()
  {
    // Initialize MoveGroupInterface
    RCLCPP_INFO(this->get_logger(), "Initializing MoveGroupInterface...");

    move_group_ = std::make_shared<moveit::planning_interface::MoveGroupInterface>(
      shared_from_this(), planning_group_);

    move_group_->setPoseReferenceFrame(base_frame_);
    move_group_->setEndEffectorLink(end_effector_link_);

    RCLCPP_INFO(this->get_logger(), "MoveGroupInterface initialized successfully");

    // Define reset articular pose
    double to_rad = M_PI / 180.0;
    std::vector<double> joint_reset_positions = \
      {0.0, -16 * to_rad, 100 * to_rad, 0.0, -20 * to_rad, 85 * to_rad};

    // Define starting cartesian pose
    // xyz = 0.61, -0.02, 0.805
    // rpy = 180, 0, 90 degrees (pi, 0, pi/2 radians)
    start_pose_.header.frame_id = base_frame_;
    start_pose_.pose.position.x = 0.61;
    start_pose_.pose.position.y = -0.02;
    start_pose_.pose.position.z = 0.805;

    // Convert RPY to quaternion
    tf2::Quaternion q;
    q.setRPY(0.0, M_PI/2.0, 0.0);  // 180°, 0°, 90°
    start_pose_.pose.orientation = tf2::toMsg(q);

    RCLCPP_INFO(this->get_logger(), "Start pose defined: x=%.3f, y=%.3f, z=%.3f",
                start_pose_.pose.position.x,
                start_pose_.pose.position.y,
                start_pose_.pose.position.z);

    // Give MoveIt some time to initialize
    std::this_thread::sleep_for(std::chrono::seconds(5));
  }

  bool run_demo()
  {
    RCLCPP_INFO(this->get_logger(),
      "\n============================================================"
      "\nStarting Robot Motion Demo"
      "\n============================================================\n");

    // Task 1: Move to start pose slowly
    if (!move_to_start_pose_slowly()) {
      RCLCPP_ERROR(this->get_logger(), "Demo failed at Task 1");
      return false;
    }
    std::this_thread::sleep_for(std::chrono::seconds(1));

    // Task 2: Execute Cartesian rotations
    if (!execute_cartesian_rotations()) {
      RCLCPP_ERROR(this->get_logger(), "Demo failed at Task 2");
      return false;
    }
    std::this_thread::sleep_for(std::chrono::seconds(1));

    // Task 3: Execute square trajectory
    if (!execute_square_trajectory()) {
      RCLCPP_ERROR(this->get_logger(), "Demo failed at Task 3");
      return false;
    }

    RCLCPP_INFO(this->get_logger(),
      "\n============================================================"
      "\nDemo completed successfully!"
      "\n============================================================\n");

    return true;
  }

private:
  bool move_to_start_pose_slowly()
  {
    RCLCPP_INFO(this->get_logger(),
      "============================================================"
      "\nTASK 1: Moving to start pose slowly"
      "\n============================================================\n");

    // Publish target pose for visualization in RViz
    start_pose_.header.stamp = this->now();
    target_pose_pub_->publish(start_pose_);

    RCLCPP_INFO(this->get_logger(), "Target start pose: x=%.3f, y=%.3f, z=%.3f",
                start_pose_.pose.position.x,
                start_pose_.pose.position.y,
                start_pose_.pose.position.z);

    // Use OMPL for joint interpolation (joint space planning)
    move_group_->setPlanningPipelineId("ompl");

    // Set the goal pose
    move_group_->setPoseTarget(start_pose_);

    // Set planning parameters for slow motion
    move_group_->setMaxVelocityScalingFactor(start_velocity_scaling_);
    move_group_->setMaxAccelerationScalingFactor(start_velocity_scaling_);

    RCLCPP_INFO(this->get_logger(), "Planning with OMPL (joint space) and velocity scaling: %.2f",
                start_velocity_scaling_);

    // Plan
    moveit::planning_interface::MoveGroupInterface::Plan plan;
    bool success = (move_group_->plan(plan) == moveit::core::MoveItErrorCode::SUCCESS);

    if (!success) {
      RCLCPP_ERROR(this->get_logger(), "Planning failed for start pose");
      return false;
    }

    RCLCPP_INFO(this->get_logger(), "Planning successful! Executing trajectory...");

    // Execute
    success = (move_group_->execute(plan) == moveit::core::MoveItErrorCode::SUCCESS);

    if (success) {
      RCLCPP_INFO(this->get_logger(), "Successfully moved to start pose");
    } else {
      RCLCPP_ERROR(this->get_logger(), "Execution failed for start pose");
    }

    return success;
  }

  bool execute_linear_move_to_pose(
    const geometry_msgs::msg::PoseStamped& target_pose,
    double velocity_scaling = 0.1)
  {
    if (velocity_scaling <= 0.0 || velocity_scaling > 1.0) {
      RCLCPP_WARN(this->get_logger(),
                  "Invalid velocity scaling factor %.2f, using default 0.1",
                  velocity_scaling);
      velocity_scaling = 0.1;
    }
    // Set planner to Pilz
    move_group_->setPlanningPipelineId("pilz_industrial_motion_planner");
    move_group_->setPlannerId("LIN");
    // Use OMPL with Cartesian path planning
    // move_group_->setPlanningPipelineId("ompl");

    // Set max velocity and acceleration for Cartesian motions
    move_group_->setMaxVelocityScalingFactor(velocity_scaling);
    move_group_->setMaxAccelerationScalingFactor(velocity_scaling);

    // Publish target pose for visualization
    auto pose_msg = target_pose;
    pose_msg.header.stamp = this->now();
    target_pose_pub_->publish(pose_msg);

    // Use computeCartesianPath for Cartesian planning
    std::vector<geometry_msgs::msg::Pose> waypoints;
    waypoints.push_back(target_pose.pose);

    moveit_msgs::msg::RobotTrajectory trajectory;
    const double eef_step = 0.01;  // 1cm resolution for Cartesian path
    double fraction = move_group_->computeCartesianPath(
      waypoints, eef_step, trajectory);

    if (fraction < 0.99) {
      RCLCPP_ERROR(this->get_logger(),
                   "Cartesian path only %.2f%% achieved, aborting",
                   fraction * 100.0);
      return false;
    }

    RCLCPP_INFO(this->get_logger(), "Cartesian path achieved: %.2f%%", fraction * 100.0);

    // Execute the Cartesian trajectory
    moveit::planning_interface::MoveGroupInterface::Plan plan;
    plan.trajectory = trajectory;
    bool success = (move_group_->execute(plan) == moveit::core::MoveItErrorCode::SUCCESS);

    if (!success) {
      RCLCPP_ERROR(this->get_logger(), "Execution failed for Cartesian motion");
      return false;
    }

    return true;
  }

  bool execute_cartesian_rotations()
  {
    RCLCPP_INFO(this->get_logger(),
      "============================================================"
      "\nTASK 2: Executing Cartesian rotations"
      "\n============================================================\n");

    // Define rotation waypoints (in radians)
    std::vector<double> rotation_angles = {
      0.0,
      0.9 * M_PI / 2,
      0.0,
      - 0.9 * M_PI / 2,
      0.0
    };

    RCLCPP_INFO(this->get_logger(), "Planning %zu rotation waypoints", rotation_angles.size());

    // Execute each rotation
    for (size_t i = 0; i < rotation_angles.size(); ++i) {
      double angle = rotation_angles[i];
      RCLCPP_INFO(this->get_logger(), "Rotation %zu/%zu: %.1f degrees",
                  i + 1, rotation_angles.size(), angle * 180.0 / M_PI);

      // Create pose with rotation relative to start pose
      geometry_msgs::msg::PoseStamped target_pose;
      target_pose.header.frame_id = base_frame_;
      target_pose.pose.position = start_pose_.pose.position;

      // Rotation around Y-axis relative to start pose orientation
      // Combine start pose rotation with additional Y-axis rotation
      tf2::Quaternion q_start;
      tf2::fromMsg(start_pose_.pose.orientation, q_start);

      tf2::Quaternion q_rotation;
      q_rotation.setRPY(0.0, 0.0, angle);  // Pure X-axis rotation

      // Combine rotations: first apply start pose orientation, then rotate around its Z-axis
      tf2::Quaternion q_result = q_start * q_rotation;
      target_pose.pose.orientation = tf2::toMsg(q_result);

      // Execute Cartesian motion to target pose
      if (!execute_linear_move_to_pose(target_pose)) {
        RCLCPP_ERROR(this->get_logger(), "Failed to execute rotation %zu", i + 1);
        return false;
      }

      RCLCPP_INFO(this->get_logger(), "Rotation %zu completed", i + 1);
      std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }

    RCLCPP_INFO(this->get_logger(), "All rotations completed successfully");
    return true;
  }

  bool execute_square_trajectory()
  {
    RCLCPP_INFO(this->get_logger(),
      "============================================================"
      "\nTASK 3: Executing square trajectory"
      "\n============================================================\n");

    // Define square corners relative to start pose
    std::vector<std::pair<double, double>> offsets = {
      {0.0, 0.0},
      {square_size_, 0.0},
      {square_size_, -square_size_},
      {0.0, -square_size_},
      {0.0, 0.0}
    };

    std::vector<geometry_msgs::msg::PoseStamped> square_waypoints;
    for (const auto& offset : offsets) {
      geometry_msgs::msg::PoseStamped pose;
      pose.header.frame_id = base_frame_;
      pose.pose.position.x = start_pose_.pose.position.x + offset.first;
      pose.pose.position.y = start_pose_.pose.position.y + offset.second;
      pose.pose.position.z = start_pose_.pose.position.z;
      pose.pose.orientation = start_pose_.pose.orientation;
      square_waypoints.push_back(pose);
    }

    RCLCPP_INFO(this->get_logger(), "Executing square with %zu waypoints (size: %.3fm)",
                square_waypoints.size(), square_size_);

    // Execute each segment of the square
    for (size_t i = 1; i < square_waypoints.size(); ++i) {
      auto target_pose = square_waypoints[i];
      RCLCPP_INFO(this->get_logger(), "Moving to corner %zu/%zu: x=%.3f, y=%.3f",
                  i, square_waypoints.size() - 1,
                  target_pose.pose.position.x,
                  target_pose.pose.position.y);

      // Execute Cartesian motion to target pose
      if (!execute_linear_move_to_pose(target_pose)) {
        RCLCPP_ERROR(this->get_logger(), "Failed to reach corner %zu", i);
        return false;
      }

      RCLCPP_INFO(this->get_logger(), "Reached corner %zu", i);
      std::this_thread::sleep_for(std::chrono::milliseconds(300));
    }

    RCLCPP_INFO(this->get_logger(), "Square trajectory completed successfully");
    return true;
  }

  std::string planning_group_;
  std::string base_frame_;
  std::string end_effector_link_;
  double start_velocity_scaling_;
  double square_size_;
  bool loop_forever_;

  geometry_msgs::msg::PoseStamped start_pose_;
  rclcpp::Publisher<geometry_msgs::msg::PoseStamped>::SharedPtr target_pose_pub_;
  std::shared_ptr<moveit::planning_interface::MoveGroupInterface> move_group_;
};

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);

  auto node = std::make_shared<TrajectoryPlannerNode>();

  // Initialize MoveGroupInterface after node is fully constructed
  node->initialize_move_group();

  // Create a separate thread for spinning
  std::thread spin_thread([node]() {
    rclcpp::spin(node);
  });

  // Run the demo (with optional looping)
  bool success = true;
  int iteration = 1;

  do {
    if (node->get_parameter("loop_forever").as_bool()) {
      RCLCPP_INFO(node->get_logger(),
        "\n========== Starting Demo Iteration %d ==========\n",
        iteration
      );
    }

    success = node->run_demo();

    if (success) {
      RCLCPP_INFO(node->get_logger(), "Demo iteration %d completed successfully", iteration);
      if (node->get_parameter("loop_forever").as_bool()) {
        RCLCPP_INFO(node->get_logger(), "Waiting 2 seconds before next iteration...\n");
        std::this_thread::sleep_for(std::chrono::seconds(2));
        iteration++;
      }
    } else {
      RCLCPP_ERROR(node->get_logger(), "Demo failed at iteration %d", iteration);
      break;
    }
  } while (node->get_parameter("loop_forever").as_bool() && rclcpp::ok());

  rclcpp::shutdown();
  spin_thread.join();

  return success ? 0 : 1;
}
