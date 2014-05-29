function M_out = odometry_ukf2(el,er,WheelRadius,AxleLength,EncRes,Targets,DistanceCameraTargets,BearingCameraTargets)
persistent P M A Q R bruit_odometrie bruit_bearing bruit_distance f_param

%% Init
if isempty(P)
  bruit_odometrie = 2*pi/180;
  bruit_bearing = 5*pi/180;
  bruit_distance = 10;
  M = [50; 50; 0];
  P = diag([0.001 0.001 0.001]);
  R = diag([bruit_bearing, bruit_distance].^2);
  Q = diag((bruit_odometrie*[WheelRadius/2;WheelRadius/2;WheelRadius/AxleLength]).^2);
end

%% EKF predict
f_param = [double(el)*2*pi/EncRes;double(er)*2*pi/EncRes;WheelRadius;AxleLength];
A = double(odometry_jacobian(M, f_param));
M = double(odometry_transition(M,f_param));
P = double(A*P*A' + Q);

%% EKF update
for i=1:length(DistanceCameraTargets)
    if(DistanceCameraTargets(i) ~= 0 && BearingCameraTargets(i)~=0)
        % Identify seen target
        PositionTargetObs = M(1:2)+double(DistanceCameraTargets(i))*[cos(M(3)+double(BearingCameraTargets(i))*pi/180); sin(M(3)+double(BearingCameraTargets(i))*pi/180)];
        minDist = inf;
        for j = 1:length(Targets)
            dist = norm(PositionTargetObs-Targets(j,:)');
            if dist < minDist
                targetFound = j;
                minDist = double(dist);
            end
        end
        PositionTargetTrue = Targets(targetFound,:)';
        
        if norm(PositionTargetTrue - PositionTargetObs) < 40
        % Perform update step
        H = odometry_observation_jacobian(M,PositionTargetTrue);
        MU = odometry_observation(M,PositionTargetTrue);
        Z = [double(BearingCameraTargets(i))*pi/180;double(DistanceCameraTargets(i))];
        S = H*P*H' + R;
        K = P*H'/S;
        M = double(M + K*(Z-MU));
        P = double(P - K*S*K');
        end
    end
end

M_out = M;