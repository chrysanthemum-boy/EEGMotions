from flask import Flask, request, jsonify
import robot_interface as bot
import math
import sys
import threading
import time
import signal
import os

app = Flask(__name__)

# 全局变量
current_command = "freeze"
previous_command = None
robot = None
controller = None

def cleanup(signum, frame):
    print("\nCleaning up...")
    if robot is not None:
        print("Stopping robot...")
        robot.stop()
    # 查找并关闭占用5000端口的进程
    try:
        os.system("fuser -k 5000/tcp")  # Flask使用TCP端口
        print("Port 5000 cleaned up")
    except:
        print("Failed to clean up port 5000")
    sys.exit(0)

# 注册信号处理函数
signal.signal(signal.SIGINT, cleanup)  # Ctrl+C
signal.signal(signal.SIGTSTP, cleanup)  # Ctrl+Z

class RobotController:
    def __init__(self):
        self.cmd = bot.HighCmdSimple()
        self.reset_cmd()
        self.local_time = 0.0
        self.local_init_time = 0.0
        self.local_duration = 0.0
        self.is_dancing = False  # 添加舞蹈状态标志

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
        global current_command
        if not self.is_dancing:  # 如果不在跳舞状态
            self.is_dancing = True  # 设置跳舞状态
            self.local_init_time = 0  # 重置时间
            current_command = "dance"  # 确保命令是dance
        
        self.reset_cmd()
        
        # 初始化时间
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
        elif 1000 < time_ms < 2000:
            self.cmd.mode = 6  # Position stand up
            print("Standing up (mode 6)")
            
        # 2000-3000ms: Turn left (mode 1)
        elif 2000 < time_ms < 3000:
            self.cmd.mode = 1  # Force stand
            my_euler = [0, 0, 0]
            my_euler[2] = -0.2
            self.cmd.euler = my_euler
            print("Turning left (mode 1)")
            
        # 3000-4000ms: Reset position (mode 1)
        elif 3000 < time_ms < 4000:
            self.cmd.mode = 1  # Force stand
            my_euler = [0, 0, 0]  # Reset all angles to zero
            self.cmd.euler = my_euler
            print("Resetting position (mode 1)")
            
        # 4000-5000ms: Turn right (mode 1)
        elif 4000 < time_ms < 5000:
            self.cmd.mode = 1  # Force stand
            my_euler = [0, 0, 0]
            my_euler[2] = 0.2
            self.cmd.euler = my_euler
            print("Turning right (mode 1)")
            
        # 5000-6000ms: Reset position (mode 1)
        elif 5000 < time_ms < 6000:
            self.cmd.mode = 1  # Force stand
            my_euler = [0, 0, 0]  # Reset all angles to zero
            self.cmd.euler = my_euler
            print("Resetting position (mode 1)")
            
        # 6000-7000ms: Walk forward (mode 2)
        elif 6000 < time_ms < 7000:
            self.cmd.mode = 2  # Target velocity walking
            my_velocity = [0.3, 0]  # Forward velocity
            self.cmd.velocity = my_velocity
            print("Walking forward (mode 2)")
            
        # 7000-8000ms: Walk backward (mode 2)
        elif 7000 < time_ms < 8000:
            self.cmd.mode = 2  # Target velocity walking
            my_velocity = [-0.3, 0]  # Backward velocity
            self.cmd.velocity = my_velocity
            print("Walking backward (mode 2)")
            
        # 8000-9000ms: Stop moving (mode 0)
        elif 8000 < time_ms < 9000:
            self.cmd.mode = 0  # Idle, default stand
            print("Stopping movement (mode 0)")
            
        # 9000-10000ms: Sit down (mode 5)
        elif 9000 < time_ms < 10000:
            self.cmd.mode = 5  # Position stand down
            print("Sitting down (mode 5)")
            
        # After 10000ms: Stop running
        elif time_ms >= 10000:
            self.cmd.running_controller = False
            self.is_dancing = False  # 重置跳舞状态
            current_command = "freeze"  # 重置为freeze状态
            print("Dance completed, resetting to freeze mode")

    def call_freeze(self):
        if not self.is_dancing:  # 只有在不在跳舞状态时才执行freeze
            self.reset_cmd()
            return "📥 Command Received: FREEZE (Idle Mode)"
        return "Dance in progress, command ignored"

    def call_stop(self):
        if not self.is_dancing:  # 只有在不在跳舞状态时才执行stop
            self.cmd.running_controller = False
            return "📥 Command Received: STOP"
        return "Dance in progress, command ignored"

    def get_cmd(self):
        return self.cmd

def controlLogicCommandDriven(state, init_state, time):
    global current_command, previous_command
    time_sec = time / 1000

    print(f"Control loop - Current command: {current_command}")  # 调试信息
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

def init_robot():
    global robot, controller
    max_retries = 3
    retry_delay = 2  # 秒
    
    for attempt in range(max_retries):
        try:
            if robot is None:
                print(f"Attempting to connect to robot (attempt {attempt + 1}/{max_retries})...")
                robot = bot.HIGO1_("192.168.123.161")
                controller = RobotController()
                robot.set_controller(controlLogicCommandDriven)
                print("Robot connected successfully!")
                robot.run()
                return True
        except Exception as e:
            print(f"Error connecting to robot (attempt {attempt + 1}/{max_retries}): {str(e)}")
            if attempt < max_retries - 1:
                print(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                print("Failed to connect to robot after maximum retries")
                return False
    return False

def run_robot():
    if not init_robot():
        print("Robot initialization failed. Please check the connection and try again.")
        return

def run_flask():
    print("Starting Flask server...")
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)

@app.route('/command', methods=['POST'])
def set_command():
    global current_command
    print("Received command request")  # 调试信息
    try:
        data = request.json
        print(f"Received data: {data}")  # 调试信息
        if data and 'command' in data:
            new_command = data['command']
            if controller.is_dancing and new_command != "dance":  # 如果在跳舞且新命令不是dance
                return jsonify({
                    "status": "warning",
                    "message": "Dance in progress, command ignored",
                    "current_command": current_command
                })
            print(f"Setting command to: {new_command}")  # 调试信息
            current_command = new_command
            return jsonify({
                "status": "success", 
                "message": f"Command set to {current_command}",
                "current_command": current_command
            })
        return jsonify({
            "status": "error", 
            "message": "No command provided",
            "received_data": data
        }), 400
    except Exception as e:
        print(f"Error processing command: {str(e)}")  # 调试信息
        return jsonify({
            "status": "error",
            "message": f"Error processing command: {str(e)}"
        }), 500

@app.route('/status', methods=['GET'])
def get_status():
    status = {
        "status": "success",
        "current_command": current_command,
        "robot_connected": robot is not None,
        "controller_initialized": controller is not None
    }
    print(f"Status request - Current state: {status}")  # 调试信息
    return jsonify(status)

if __name__ == '__main__':
    print("Starting robot control system...")
    print("Make sure the robot is powered on and connected to the network.")
    print("Robot IP: 192.168.123.161")
    print("Press Ctrl+Z to stop the program and clean up ports")
    
    # 启动Flask服务器线程
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True
    flask_thread.start()
    
    # 等待一段时间确保Flask服务器启动
    time.sleep(2)
    
    # 在主线程中运行机器人控制
    run_robot() 