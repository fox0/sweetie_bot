#!/usr/bin/env python
# -*- coding: utf-8 -*-

import string
import rospy, roslib, rospkg, os, sys, random
from sound_play.libsoundplay import SoundClient

from sweetie_bot_text_msgs.msg import TextCommand

soundhandle = SoundClient()
sounds = {}
playback_command = None

def commandCallback(cmd):
    global soundhandle, sounds;
    # check command type
    if cmd.type == 'voice/play_wav':
        # play specified sound file
        if cmd.command in sounds:
            filename = sounds[cmd.command]
            rospy.loginfo('Playing sound: {0} ({1}).'.format(cmd.command, filename))
            # playback selection
            if not playback_command:
                # use sound client
                snd = soundhandle.waveSound(filename)
                snd.play()
            else:
                # use system command
                os.system(playback_command + " " + filename)
        else:
            rospy.logerr('Unknown play_wav sound: ' + cmd.command)
    elif cmd.type == 'voice/say':
        # use voice synthesis
        snd = soundhandle.voiceSound(cmd.command)
        snd.play()


def file_dict(directory, ext):
    ''' Return list of files with given extension.

        Paramters:
            directory (string) --- directory name,
            ext (string) --- file extension,

        Return: list of strings.
    '''
    files = {} 
    try:
        for f in os.listdir(directory):
            basename, extension = os.path.splitext(f)
            if extension.endswith(ext):
                files[basename] = os.path.join(directory, f)
    except OSError as e:
        rospy.logerr('Unable to list `%s` directory.' % directory)
        return []
    return files


def main():
    global soundhandle, sounds, playback_command
    rospy.init_node('voice', anonymous = True)
    rospy.Subscriber('control', TextCommand, commandCallback)

    # Playback configuration
    playback_command = rospy.get_param('~playback_command', None) 

    # Get language settings
    lang_prefixes = string.split(rospy.get_param('lang', 'ru,en'), ',')
   
    # Get sounds location
    sounds_path = rospy.get_param('sounds_path', '')
    if not sounds_path: 
        rospack = rospkg.RosPack()
        sounds_path = os.path.join(rospack.get_path('sweetie_bot_voice'), 'sounds')
   
    # List sound files.
    paths = [ os.path.join(sounds_path, prefix) for prefix in lang_prefixes ]
    sounds = {}
    for p in reversed(paths):
        sounds.update(file_dict(p, 'wav'))
        sounds.update(file_dict(p, 'ogg'))

    rospy.loginfo('Registered sounds:\n' + repr(sounds))

    rospy.sleep(1)
    soundhandle.stopAll()

    rospy.spin()
