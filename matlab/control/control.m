%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Node: control
%
% Purpose:  
% The purpose of the control node is to regulate the quadcopter to desired
% setpoints of [altitude, heading, forward speed, crab speed]. We refer to
% this as a 'ahsCmd' which is generated by a behavior in the autonomy node.
% The control node determines the appropriate 'stickCmd' [yaw, pitch, roll,
% thrust] to send to the virtual_transmitter.
%
% Input:
%   - ROS topic: /stateEstimate (generated by estimation)
%   - ROS topic: /ahsCmd (generated by autonomy)
%   
% Output:
%   - ROS topic: /stickCmd (used by virtual_transmitter)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prepare workspace
clear; close all; clc; format compact;
addpath('../')
params = loadParams();
rosinit;

global controlParams
controlParams = params.ctrl;
fprintf('Control Node Launching...\n');

% declare global variables
global altitudeError;
altitudeError.lastVal = 0;
altitudeError.lastSum = 0;
altitudeError.lastTime = 0;

global ahsCmdMsg;
ahsCmdMsg = rosmessage('terpcopter_msgs/ahsCmd');
ahsCmdMsg.AltitudeMeters = 0;
ahsCmdMsg.HeadingRad = 0;
ahsCmdMsg.ForwardSpeedMps = 0;
ahsCmdMsg.CrabSpeedMps = 0;

global stateEstimateMsg;
% initialize  stateEstimate --pending--

% initialize ROS
if(~robotics.ros.internal.Global.isNodeActive)
    rosinit;
end

controlNode = robotics.ros.Node('/control');
stickCmdPublisher = robotics.ros.Publisher(controlNode,'stickCmd','terpcopter_msgs/stickCmd');
stickCmdMsg = rosmessage('terpcopter_msgs/stickCmd');
stickCmdMsg.Thrust = 0;
stickCmdMsg.Yaw = 0;

stateEstimateSubscriber = robotics.ros.Subscriber(controlNode,'stateEstimate','terpcopter_msgs/stateEstimate',{@stateEstimateCallback});
ahsCmdSubscriber = robotics.ros.Subscriber(controlNode,'ahsCmd','terpcopter_msgs/ahsCmd',{@ahsCmdCallback});
pidSettingSubscriber = robotics.ros.Subscriber(controlNode,'pidSetting','terpcopter_msgs/ffpidSetting',{@ffpidSettingCallback});

altitudeError.lastTime = stateEstimateMsg.Time;
altitudeError.lastVal = ahsCmdMsg.AltitudeMeters;
altitudeError.lastSum = 0;
u_t = controlParams.altitudeGains.ffterm;
disp('initialize loop');

r = robotics.Rate(10);
reset(r);

while(1)
    

    % unpack statestimate
    t = stateEstimateMsg.Time;
    z = stateEstimateMsg.Range;
    fprintf('Current Quad Alttiude is : %3.3f m\n', z );

    % get setpoint
    z_d = ahsCmdMsg.AltitudeMeters;
    % DEBUG
    %z_d =1;
    % update errors
    altError = z - z_d;


    % compute controls
    [u_t, altitudeError] = FF_PID(controlParams.altitudeGains, altitudeError, t, altError);
    disp('pid loop');
    disp(controlParams.altitudeGains)


    % publish
    stickCmdMsg = rosmessage('terpcopter_msgs/stickCmd');
    stickCmdMsg.Thrust = u_t;%max(min(1,u_t),-1);
    stickCmdMsg.Yaw = 0*pi/180;
    send(stickCmdPublisher, stickCmdMsg);
    fprintf('Published Stick Cmd., Thrust : %3.3f, Altitude : %3.3f, Altitude_SP : %3.3f, Error : %3.3f \n', stickCmdMsg.Thrust , stateEstimateMsg.Up, z_d, ( z - z_d ) );

    time = r.TotalElapsedTime;
	fprintf('Iteration: %d - Time Elapsed: %f\n',i,time)
	waitfor(r);
 end

