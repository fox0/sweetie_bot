#!/bin/bash

log() {
    echo
    echo
    echo
    echo
    echo '#########################################################################################'
    echo "$3 (exit code: $1)"
    echo '#########################################################################################'
    cat "$2"
}

export USER=dev
source devel/setup.bash

# Launch ROS Core
roslaunch sweetie_bot_deploy load_param.launch 2>&1 > ros_core.log &
ROS_CORE=$!
sleep 40

# Create virtual display
export DISPLAY=:99
/usr/bin/Xvfb $DISPLAY -screen 0 1920x1080x24 &
VIRT_DISPLAY=$!

# Launch actual application
roslaunch sweetie_bot_deploy flexbe_control.launch run_flexbe:=true 2>&1 > app.log &
APP=$!

# Wait until full init and capture screenshot
sleep 60
scrot screenshot.png

kill -SIGINT $APP
wait $APP
EXIT_APP=$?

kill -SIGINT $ROS_CORE
wait $ROS_CORE
EXIT_CORE=$?

kill -SIGINT $VIRT_DISPLAY
wait $VIRT_DISPLAY
EXIT_VIRT_DISPLAY=$?

log $EXIT_CORE ros_core.log "roslaunch sweetie_bot_deploy load_param.launch"
log $EXIT_APP app.log "roslaunch sweetie_bot_deploy flexbe_control.launch run_flexbe:=true"

exit $(( $EXIT_APP + $EXIT_CORE + $EXIT_VIRT_DISPLAY ))