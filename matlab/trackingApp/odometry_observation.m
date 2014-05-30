function Y = odometry_observation(x,s)
  bearing = atan2(s(2) - x(2),s(1) - x(1)) - x(3);
  %wrapToPi
  num2pi = floor(bearing/(2*pi) + 0.5);
  bearing = bearing - num2pi*2*pi;
  distance = norm(s-x(1:2));
  Y = [bearing;distance];
end