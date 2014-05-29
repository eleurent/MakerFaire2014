function Y = odometry_observation(x,s)
  bearing = atan2(s(2) - x(2),s(1) - x(1)) - x(3);
  distance = norm(s-x(1:2));
  Y = [bearing;distance];
end