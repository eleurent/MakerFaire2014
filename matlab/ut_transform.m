function [mu,S,C] = ut_transform(M,P,g,g_param)
    %
    % Calculate sigma points
    %
    [WM,WC,c] = ut_weights(size(M,1));
    X = ut_sigmas(M,P,c);

    %
    % Propagate through the function
    %
    
    Y1 = g(X(:,1),g_param);
    Y = zeros(size(Y1,1), 2*size(M,1)+1);
    for i=2:size(X,2)
        Y(:,i) = g(X(:,i),g_param);
    end


    mu = zeros(size(Y,1),1);
    S  = zeros(size(Y,1),size(Y,1));
    C  = zeros(size(M,1),size(Y,1));
    for i=1:size(X,2)
        mu = mu + WM(i) * Y(:,i);
    end
    for i=1:size(X,2)
        S = S + WC(i) * (Y(:,i) - mu) * (Y(:,i) - mu)';
        C = C + WC(i) * (X(1:size(M,1),i) - M) * (Y(:,i) - mu)';
    end
end
  
