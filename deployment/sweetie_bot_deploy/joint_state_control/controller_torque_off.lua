--
-- TORQUE OFF controller
--
-- Setup TorqueMainSwitch controller
--
-- Intended to be run via config script.
--
require "motion"

controller = controller or {}

-- load controller
ros:import("sweetie_bot_controller_joint_space")
depl:loadComponent("controller/torque_off", "sweetie_bot::motion::controller::TorqueMainSwitch")
controller.torque_off = depl:getPeer("controller/torque_off")
-- register controller
resource_control.register_controller(controller.torque_off)
-- timer
depl:connect(timer.controller.port, "controller/torque_off.sync", rtt.Variable("ConnPolicy"))
-- data flow: controller -> agregator_ref
depl:connect("controller/torque_off.out_joints_ref", "agregator_ref.in_joints", rtt.Variable("ConnPolicy"))
-- data flow: agregator_real -> controller
depl:connect("agregator_real.out_joints_sorted", "controller/torque_off.in_joints_actual", rtt.Variable("ConnPolicy"))
-- connect to RobotModel
depl:connectServices("controller/torque_off", "agregator_ref")
-- present herkulex subsystem
depl:addPeer("controller/torque_off", herkulex.array:getName())
depl:addPeer("controller/torque_off", herkulex.sched:getName())
-- get ROS configuration
rttlib_extra.get_peer_rosparams(controller.torque_off)
-- advertise ROS operation
controller.torque_off:loadService("rosservice")
controller.torque_off:provides("rosservice"):connect("rosSetOperational", config.node_fullname .. "/controller/torque_off/set_torque_off", "std_srvs/SetBool")

-- prepare to start
assert(controller.torque_off:configure())
