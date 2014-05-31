function dY = odometry_observation_jacobian(x,s)
  % Loop through sensors
  for i=1:size(s,2)
    dbearing = [-(x(2)-s(2)) / ((x(1)-s(1))^2 + (x(2)-s(2))^2);...
	   (x(1)-s(1)) / ((x(1)-s(1))^2 + (x(2)-s(2))^2);...
	  -1]';
    ddistance = [(x(1)-s(1))/norm(x(1:2)-s);
                 (x(2)-s(2))/norm(x(1:2)-s);
                 0]';
    
    dY = [dbearing; ddistance]; 
  end