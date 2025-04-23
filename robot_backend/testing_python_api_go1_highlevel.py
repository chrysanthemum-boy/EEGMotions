# test for low level control a1
# IMPORTANT!!!
# stl object are imported as unique entity so you cannot change the single memory but you can reassing the
# entire stl object in one step
# it would be possible to import an stl object as a standalone class using the opaque statement but than you cannnot use list anymore in python
# for more details on that look at https://github.com/pybind/pybind11/issues/1134

# if you have an error with the pybind the error reporting is quite brutal.
# it is enough to assign the wrog thing to an obejct wrapped from cpp or not returning any value from the callback is enough to trigger
# are

# to use gamepad you have to install the input library (you should use anaconda if you want to use the pycharm project)

import math
import robot_interface as bot
import sys
import gamepad_reader as pad


class padCmd:
    def __init__(self):
        vx = 0
        vy = 0
        wz = 0


class padCallback:
    def __init__(self):

        real_max = 255
        real_min = 0
        sign = ['minus', 'minus', 'plus']
        correction = pad.Correction(real_max, real_min, sign)
        try:
            self.gamepad = pad.Gamepad(dead_zone=0.004, vel_scale_x=1., vel_scale_y=1., vel_scale_rot=1.,
                                       correction=correction)
        except:
            sys.exit("no controller connected to the computer. attach one")

    def GetGamePadCmd(self):
        ret = padCmd()
        ret.vx = self.gamepad.vx
        ret.vy = self.gamepad.vy
        ret.wz = self.gamepad.wz
        return ret


#globalgamepad = padCallback()




def controlLogic(state, init_state, time):
    time_sec = time / 1000  # converting second to milliseconds
    print("time in milliseconds=", time)

    cmd = bot.HighCmdSimple()
    cmd.mode = 0
    cmd.gait_type = 0
    cmd.speed_level = 0
    cmd.foot_raise_height = 0
    cmd.body_height = 0
    myeuler = [0] * 3
    cmd.euler = myeuler
    myvelocity = [0] * 2
    cmd.velocity = myvelocity
    cmd.yaw_speed = 0.0

    if 0 < time < 1000:
        cmd.mode = 1
        myeuler[0] = -0.3
        cmd.euler = myeuler
        print("step 1")
    if 1000 < time < 2000:
        cmd.mode = 1
        myeuler[0] = 0.3
        cmd.euler = myeuler
        print("step 2")
    if 2000 < time < 3000:
        cmd.mode = 1
        myeuler[1] = -0.2
        cmd.euler = myeuler
        print("step 3")
    if 3000 < time < 4000:
        cmd.mode = 1
        myeuler[1] = 0.2
        cmd.euler = myeuler
        print("step 4")
    if 4000 < time < 5000:
        cmd.mode = 1
        myeuler[2] = -0.2
        cmd.euler = myeuler
        print("step 5")
    if 5000 < time < 6000:
        cmd.mode = 1
        myeuler[2] = 0.2
        cmd.euler = myeuler
        print("step 6")
    if 6000 < time < 7000:
        cmd.mode = 1
        cmd.body_height = -0.2
        print("step 7")
    if 7000 < time < 8000:
        cmd.mode = 1
        cmd.body_height = 0.1
        print("step 8")
    if 8000 < time < 9000:
        cmd.mode = 1
        cmd.body_height = 0.0
        print("step 9")
    if 9000 < time < 11000:
        cmd.mode = 5
        print("step 10")
    if 11000 < time < 13000:
        cmd.mode = 6
        print("step 11")
    if 13000 < time < 14000:
        cmd.mode = 0
        print("step 12")
        
    if 14000 < time < 18000:
        #cmd.mode = 2
        #cmd.gait_type = 2
        #myvelocity[0] = 0.4
        #cmd.velocity = myvelocity  # -1  ~ +1
        #cmd.yaw_speed = 2
        #cmd.foot_raise_height = 0.1
        print("step 13")
    if 18000 < time < 20000:
        cmd.mode = 0
        myvelocity[0] = 0
        cmd.velocity = myvelocity
        print("step 14")
    if 20000 < time < 24000:
        #cmd.mode = 2
        #cmd.gait_type = 1
        #myvelocity[0] = 0.2  # -1  ~ +1
        #cmd.velocity = myvelocity
        #cmd.body_height = 0.1
        print("step 15")
    if time > 24000:
        cmd.mode = 1
        cmd.running_controller = False
        print("step closing controller")

    return cmd

memory_example = True


if __name__ == "__main__":
    print("Communication level is set to HIGH-level.")
    print("WARNING: Make sure the robot is on the ground.")
    print("Press Enter to continue...")
    input()

    object_methods = [method_name for method_name in dir(bot)
                      if callable(getattr(bot, method_name))]

    robot = bot.HIGO1_("192.168.123.161")
    
    # example without memory
    robot.set_controller(controlLogic)
        # robot.test_control_wrap()

    # executing control callback
    robot.run()
    # stop gamepad thread
    #
    # globalgamepad.gamepad.stop()
