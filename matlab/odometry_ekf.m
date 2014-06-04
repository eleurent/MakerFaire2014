% MakerFaire Paris 2014
% Martin de Gourcuff, Alexandre Lefort, Edouard Leurent
function M_out = odometry_ekf(EncoderLeft,EncoderRight,startPos,theta0,WheelRadius,AxleLength,EncRes,Targets,DistanceCameraTargets,BearingCameraTargets,N_delay)
persistent P M A Q R bruit_odometrie bruit_bearing bruit_distance f_param EncoderLeftPrev EncoderRightPrev M_history P_history encoders_history i_now

%% Init
if isempty(P)
  bruit_odometrie = 2*pi/EncRes;
  bruit_bearing = 0.05;
  bruit_distance = 0.05;
  M = [startPos'; theta0*pi/180];
  P = diag([0.0001 0.0001 0.0001]);
  Q = diag((bruit_odometrie*[(WheelRadius/100)/2;(WheelRadius/100)/2;(WheelRadius/100)/(AxleLength/100)]).^2);
  M_history = zeros(3,1,N_delay);
  P_history = zeros(3,3,N_delay);
  encoders_history = zeros(2,N_delay);
  EncoderLeftPrev=0;
  EncoderRightPrev=0;
  for i=1:N_delay
      M_history(:,i) = M;
      P_history(:,:,i) = P;
  end
  i_now = 1;
end

% Start by storing encoders values
encoders_history(:,i_now) = [EncoderLeft-EncoderLeftPrev;EncoderRight-EncoderRightPrev];
EncoderLeftPrev = double(EncoderLeft);
EncoderRightPrev = double(EncoderRight);

%% EKF Update
didUpdate = false;
% Go back N steps in time to be in sync with measure
i_old = mod(i_now-1+1,N_delay)+1; % +1=-(N-1) [N]
M_old = M_history(:,i_old);
for i=1:length(DistanceCameraTargets)
    if(DistanceCameraTargets(i) ~= 0 && BearingCameraTargets(i)~=0)        
        % Identify seen target
        PositionTargetObs = M_old(1:2)+double(DistanceCameraTargets(i))*[cos(M_old(3)+double(BearingCameraTargets(i))*pi/180); sin(M_old(3)+double(BearingCameraTargets(i))*pi/180)];
        minDist = inf;
        for j = 1:length(Targets)
            dist = norm(PositionTargetObs-Targets(j,:)');
            if dist < minDist
                targetFound = j;
                minDist = double(dist);
            end
        end
        PositionTargetTrue = Targets(targetFound,:)';
        
        if norm(PositionTargetTrue - PositionTargetObs) < 30
            % Set current state to old state
            if ~didUpdate
                i_now = i_old;
                M = M_old;
                P =  P_history(:,:,i_now);
                didUpdate = true;
            end

            % Perform update step
            H = odometry_observation_jacobian(M,PositionTargetTrue);
            MU = odometry_observation(M,PositionTargetTrue);
            Z = [double(BearingCameraTargets(i))*pi/180;double(DistanceCameraTargets(i))];

            % Dynamic measurement noise : std(uniform noise*x) = (max-min)/sqrt(12)*x
            R = diag([bruit_bearing*2/sqrt(12)*abs(MU(1)), bruit_distance*2/sqrt(12)*abs(MU(2))].^2);
            S = H*P*H' + R;
            K = P*H'/S;
            M = double(M + K*(Z-MU));
            P = double(P - K*S*K');
        end
    end
end

%% EKF predict
if didUpdate
    nPredictions = N_delay;
else
    nPredictions = 1;
end
for i = 1:nPredictions
    f_param = [double(encoders_history(1,i_now))*2*pi/EncRes;double(encoders_history(2,i_now))*2*pi/EncRes;WheelRadius;AxleLength];
    A = double(odometry_jacobian(M, f_param));
    M = double(odometry_transition(M,f_param));
    P = double(A*P*A' + Q);
    
    % Write new state in history
    i_now = mod(i_now-1+1,N_delay)+1; % +1
    M_history(:,i_now) = M;
    P_history(:,:,i_now) = P;
end

M_out = M;