function Xk = odometry_transition(X, f_params)
el = f_params(1);
er = f_params(2);
rayonRoue = f_params(3);
distanceRoues = f_params(4);

dTheta = (er-el)*rayonRoue/distanceRoues;
dL = (er+el)*rayonRoue/2;

if dTheta ~= 0
Xk = X + [dL/dTheta*(sin(X(3)+dTheta) - sin(X(3)));
         -dL/dTheta*(cos(X(3)+dTheta) - cos(X(3)));
          dTheta];
else
    Xk = X + [dL*cos(X(3));dL*sin(X(3));0];
end
end