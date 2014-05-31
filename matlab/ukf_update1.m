function [M,P,K,MU,S] = ukf_update1(M,P,Y,h,R,h_param)
  %
  % Do transform and make the update
  %
  [MU,S,C] = ut_transform(M,P,h,h_param);
  
  S = S + R;
  K = C / S;
  M = double(M + K * (Y - MU));
  P = double(P - K * S * K');
