import math
import robot_interface as bot
import sys



# ==== EMOTION-BASED CONTROL STARTS HERE ====

# Simulated input - replace this later with EEG input
# Track the latest command (can be "walk" or "freeze")
current_command = "dance"
previous_command = None

# === Robot Command Controller Class ===
class RobotController:
    def __init__(self):
        self.cmd = bot.HighCmdSimple()
        self.reset_cmd()
        self.local_time = 0.0
        self.local_init_time = 0.0
        self.local_duration = 0.0

    def reset_cmd(self):
        self.cmd.mode = 0
        self.cmd.gait_type = 0
        self.cmd.speed_level = 0
        self.cmd.foot_raise_height = 0
        self.cmd.body_height = 0
        my_euler = [0, 0, 0]
        self.cmd.euler = my_euler
        my_velocity = [0] * 2
        self.cmd.velocity = my_velocity
        self.cmd.yaw_speed = 0.0

    def call_dance(self, time):
        self.reset_cmd()
        
        # Initialize time
        if self.local_init_time == 0:
            self.local_init_time = time
            
        self.local_duration = time - self.local_init_time
        
        # Convert to milliseconds for easier time control
        time_ms = self.local_duration * 1000
        
        # 0-1000ms: Lie down (mode 5)
        if 0 < time_ms < 1000:
            self.cmd.mode = 5  # Position stand down
            print("Lying down (mode 5)")
            
        # 1000-2000ms: Stand up (mode 6)
        if 1000 < time_ms < 2000:
            self.cmd.mode = 6  # Position stand up
            print("Standing up (mode 6)")
            
        # 2000-3000ms: Turn left (mode 1)
        if 2000 < time_ms < 3000:
            self.cmd.mode = 1  # Force stand
            my_euler = [0, 0, 0]
            my_euler[2] = -0.2
            self.cmd.euler = my_euler
            print("Turning left (mode 1)")
            
        # 3000-4000ms: Reset position (mode 1)
        if 3000 < time_ms < 4000:
            self.cmd.mode = 1  # Force stand
            my_euler = [0, 0, 0]  # Reset all angles to zero
            self.cmd.euler = my_euler
            print("Resetting position (mode 1)")
            
        # 4000-5000ms: Turn right (mode 1)
        if 4000 < time_ms < 5000:
            self.cmd.mode = 1  # Force stand
            my_euler = [0, 0, 0]
            my_euler[2] = 0.2
            self.cmd.euler = my_euler
            print("Turning right (mode 1)")
            
        # 5000-6000ms: Reset position (mode 1)
        if 5000 < time_ms < 6000:
            self.cmd.mode = 1  # Force stand
            my_euler = [0, 0, 0]  # Reset all angles to zero
            self.cmd.euler = my_euler
            print("Resetting position (mode 1)")
            
        # 6000-7000ms: Walk forward (mode 2)
        if 6000 < time_ms < 7000:
            self.cmd.mode = 2  # Target velocity walking
            my_velocity = [0.3, 0]  # Forward velocity
            self.cmd.velocity = my_velocity
            print("Walking forward (mode 2)")
            
        # 7000-8000ms: Walk backward (mode 2)
        if 7000 < time_ms < 8000:
            self.cmd.mode = 2  # Target velocity walking
            my_velocity = [-0.3, 0]  # Backward velocity
            self.cmd.velocity = my_velocity
            print("Walking backward (mode 2)")
            
        # 8000-9000ms: Stop moving (mode 0)
        if 8000 < time_ms < 9000:
            self.cmd.mode = 0  # Idle, default stand
            print("Stopping movement (mode 0)")
            
        # 9000-10000ms: Sit down (mode 5)
        if 9000 < time_ms < 10000:
            self.cmd.mode = 5  # Position stand down
            print("Sitting down (mode 5)")
            
        # After 10000ms: Stop running
        if time_ms >= 10000:
            self.cmd.running_controller = False
            print("Program will stop after 10 seconds")

    def call_freeze(self):
        self.reset_cmd()
        return "📥 Command Received: FREEZE (Idle Mode)"
        # print("📥 Command Received: FREEZE (Idle Mode)")

    def call_stop(self):
        self.reset_cmd()
        self.cmd.running_controller=False

    def get_cmd(self):
        return self.cmd


# Create the controller once
controller = RobotController()


#=== Control Logic Function ===
def controlLogicCommandDriven(state, init_state, time):
    global current_command, previous_command
    time_sec = time / 1000

    if current_command == "dance":
        controller.call_dance(time_sec)
    elif current_command == "freeze":
        controller.call_freeze()
    elif current_command == "stop":
        controller.call_stop()

    if current_command != previous_command:
        print(f"🔄 Executing Command: {current_command.upper()}")
        previous_command = current_command

    return controller.get_cmd()



# ==== MAIN ENTRY POINT ====
def main():
    robot = bot.HIGO1_("192.168.123.161")
    robot.set_controller(controlLogicCommandDriven)
    robot.run()
    
if __name__ == "__main__":
    print("Communication level is set to HIGH-level.")
    print("WARNING: Make sure the robot is on the ground.")
    input("Press Enter to continue...")
    main()
    

 