% MakerFaire Paris 2014
% Martin de Gourcuff, Alexandre Lefort, Edouard Leurent
function M_out = odometry_ukf(EncoderLeft,EncoderRight,startPos,theta0,WheelRadius,AxleLength,EncRes,Targets,DistanceCameraTargets,BearingCameraTargets,N_delay,slip_intensity)
persistent P M Q R bruit_odometrie bruit_bearing bruit_distance f_param EncoderLeftPrev EncoderRightPrev M_history P_history encoders_history i_now

%% Init
if isempty(P)
  bruit_odometrie = 2*pi/EncRes;
  bruit_bearing = 0.05;
  bruit_distance = 0.5*0.05;
  M = [startPos'; theta0*pi/180];
  P = diag([0.1 0.1 0.01]);
  Q = diag((bruit_odometrie*[WheelRadius/2;WheelRadius/2;WheelRadius/AxleLength]).^2);
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

%% UKF Update
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
        
        if norm(PositionTargetTrue - PositionTargetObs) < 50
            % Set current state to old state
            if ~didUpdate
                i_now = i_old;
                M = M_old;
                P =  P_history(:,:,i_now);
                didUpdate = true;
            end

            % Perform update step
            Z = [double(BearingCameraTargets(i))*pi/180;double(DistanceCameraTargets(i))];
            MU = odometry_observation(M,PositionTargetTrue);
            % Dynamic measurement noise : std(uniform noise*x) = (max-min)/sqrt(12)*x
            R = diag([bruit_bearing*2/sqrt(12)*abs(MU(1)), bruit_distance*2/sqrt(12)*abs(MU(2))].^2);
            [M,P] = ukf_update1(M,P,Z,@odometry_observation,R,PositionTargetTrue);
        end
    end
end

%% UKF predict
if didUpdate
    nPredictions = N_delay;
else
    nPredictions = 1;
end
for i = 1:nPredictions
    Ts = 0.1;
    bruit_glissement_L = double(encoders_history(1,i_now))*2*pi/EncRes -Ts*pi/180*atan(double(encoders_history(1,i_now))*360/EncRes/Ts*(pi/4*slip_intensity))/(pi/4*slip_intensity);
    bruit_glissement_R = double(encoders_history(2,i_now))*2*pi/EncRes -Ts*pi/180*atan(double(encoders_history(2,i_now))*360/EncRes/Ts*(pi/4*slip_intensity))/(pi/4*slip_intensity);
    bruit_odometrie = (abs(bruit_glissement_L) + abs(bruit_glissement_R)) + 2*pi/EncRes;
    Q = diag((bruit_odometrie*[WheelRadius/2;WheelRadius/2;WheelRadius/AxleLength]).^2);
    
    f_param = [double(encoders_history(1,i_now))*2*pi/EncRes;double(encoders_history(2,i_now))*2*pi/EncRes;WheelRadius;AxleLength];
    [M,P] = ukf_predict1(M,P,@odometry_transition,Q,f_param);
    % Write new state in history
    i_now = mod(i_now-1+1,N_delay)+1; % +1
    M_history(:,i_now) = M;
    P_history(:,:,i_now) = P;
end

M_out = M;