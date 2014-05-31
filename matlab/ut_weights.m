function [WM,WC,c] = ut_weights(n)

%
% UT parameters
%
alpha = 1;
beta = 0;
kappa = 3 - n;
	  
%
% Compute the normal weights 
%
lambda = alpha^2 * (n + kappa) - n;
	  
WM = zeros(2*n+1,1);
WC = zeros(2*n+1,1);
for j=1:2*n+1
  if j==1
    wm = lambda / (n + lambda);
    wc = lambda / (n + lambda) + (1 - alpha^2 + beta);
  else
    wm = 1 / (2 * (n + lambda));
    wc = wm;
  end
  WM(j) = wm;
  WC(j) = wc;
end

c = n + lambda;
