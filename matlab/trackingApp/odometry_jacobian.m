function G = odometry_jacobian(X, f_params)
el = f_params(1);
er = f_params(2);
rayonRoue = f_params(3);
distanceRoues = f_params(4);

dTheta = (er-el)*rayonRoue/distanceRoues;
dL = (er+el)*rayonRoue/2;

if dTheta ~= 0
    G = [[1 0 dL/dTheta*(cos(X(3)+dTheta) - cos(X(3)))];
         [0 1 dL/dTheta*(sin(X(3)+dTheta) - sin(X(3)))];
         [0 0 1]];
else
    G = [[1 0 -dL*sin(X(3))];
         [0 1 dL*cos(X(3))];
         [0 0 1]];
end
end