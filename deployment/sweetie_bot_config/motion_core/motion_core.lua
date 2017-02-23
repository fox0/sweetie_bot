-- 
-- MOTION CORE DEPLOYMENT
--
-- Setup logger, agreagator, resource control, timer.
--
-- Intended to be run via config script.
--
ros:import("rtt_roscomm")
ros:import("rtt_sensor_msgs")

--
-- logger subsystem
--

require "logger"

local logger_conf = rttlib_extra.ros.get_param_string("logger_conf")
if not logger_conf then logger_conf = "logger.log4cpp" end

logger.init_loglevels_log4cpp(config.file(logger_conf))
-- logger.log4cpp:addRosAppender("motion", 20)

--
-- init resource_control module
--

require "resource_control"

resource_control.arbiter:configure()
assert(resource_control.arbiter:start())

--
-- load and start pose agregator
--

ros:import("rtt_roscomm")
ros:import("sweetie_bot_agregator");
ros:import("sweetie_bot_robot_model");
-- load component
depl:loadComponent("agregator_ref", "sweetie_bot::motion::Agregator")
agregator_ref = depl:getPeer("agregator_ref")
--set properties
agregator_ref:loadService("marshalling")
agregator_ref:provides("marshalling"):loadProperties(config.file("kinematic_chains.cpf"))
agregator_ref:provides("marshalling"):loadServiceProperties(config.file("kinematic_chains.cpf"), "robot_model")
agregator_ref:loadService("rosparam")
--agregator_ref:provides("rosparam"):getRelative("robot_model")
agregator_ref:provides("rosparam"):getParam("/", "robot_model")
-- publish pose to ROS
depl:stream("agregator_ref.out_joints_sorted", ros:topic("~agregator_ref/out_joints_sorted"))
-- start component
agregator_ref:configure()
assert(agregator_ref:start())

--
-- load and start timer
--
depl:loadComponent("timer", "OCL::TimerComponent")
local timer_period = tonumber(rttlib_extra.ros.get_param_string(config.node_fullname .. "/period"))
timer = depl:getPeer("timer")
-- start timers:
--    timer_10: controllers timer
--    timer_20: herkulex timer
timer:startTimer(10, timer_period)
timer:wait(0, timer_period/2)
timer:startTimer(20, timer_period)
