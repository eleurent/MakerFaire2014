% Copyright 2014 The MathWorks, Inc.
%% loadRobotParameters.m
% This MATLAB script populates the workspace with parameters related to the
% simulation of the Mars rover robot. It specifies plant model parameters to
% characterise the motors and motion of the Mars rover robot.

%% Robot Geometry
AxleLength = 16.2; %Distance between centre-line of driving wheels is 162mm [cm]
WheelRadius = 6.65/2; %Driving wheel diameter is 66.5mm [cm]

%% Initial Conditions for Robot Position
theta0 = 0; %Initial Robot Angle relative to positive x-axis [deg]
startPos = [50 50]; % [cm]

%% Plant Model Motor Parameters:
EncR_init = 0;          %Right encoder initialisation value [deg]
EncL_init = 0;          %Left encoder initialisation value [deg]
EncRes = 636;           %Encoder resolution 636
TauMotor = 0.1;         %Motor time constant

%% Plant motor characteristics
motorX = [-100.000000 -90.000000 -70.000000 -50.000000 -30.000000 -27.000000 27.000000 30.000000 50.000000 70.000000 90.000000 100.000000 ];
motorL = [-967.207000 -900.359000 -783.375000 -618.344000 -325.884000 -0.000000 0.000000 325.884000 618.344000 783.375000 900.359000 967.207000 ];
motorR = [-937.961000 -850.223000 -768.752000 -618.344000 -302.905000 -0.000000 0.000000 302.905000 618.344000 768.752000 850.223000 937.961000 ];

motorLinv = [-967.207000 -900.359000 -783.375000 -618.344000 -325.884000 -100.000000 100.000000 325.884000 618.344000 783.375000 900.359000 967.207000 ];
motorRinv = [-937.961000 -850.223000 -768.752000 -618.344000 -302.905000 -100.000000 100.000000 302.905000 618.344000 768.752000 850.223000 937.961000 ];


%% Camera characteristics
pcam = [24, 100]; % pcam depth of the field of view [cm]
lcam = [21, 90];  % width of the field of view [cm]

%% Simulation Parameters
Ts = 0.1;  % Step size for model

%% Default Sites Positions
if ~exist('SitesPositions','var') || all(SitesPositions(:) == 0)
    Sites;
end
