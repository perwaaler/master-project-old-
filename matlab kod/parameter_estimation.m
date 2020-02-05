%% analysis based on danger_FEA
sigma = 0.6182146 ; 
shape = 0.5167388; 
u=-1.5
negdata = -danger_FEA;
negdata = negdata(find(negdata>u));
negL = @(par) -sum( log(gppdf(negdata,par(2),par(1),u)) )
negL([sigma shape])
negloglik([sigma,shape],u,length(danger_FEA),danger_FEA')
% this is my change! hello git!
%%
clf; plot(danger_FEA,'.'); ylim([-1,3])
%% danger FEA analysis; Fitting for multiple thresholds
p_EA = (sum(enc_type==-1)+sum(enc_type==-2))/N
m=10;
U2 = linspace(-3,-0.8,m);
parameters2 = zeros(2,m);
p_nea2 = zeros(1,m);
UE2 = zeros(1,m);
ci_sigmaFEA = zeros(2,m);
ci_xiFEA = zeros(2,m);
for k=1:m
    negdata = -danger_FEA;
    negdata = negdata(find(negdata>U2(k)));
    neg_pot = negdata - U2(k);                                             % pot for negated data
    negL = @(par) -sum( log(gppdf(negdata,par(2),par(1),U2(k))) )
    param2 = fminsearch(negL,[1 -.5]);
    UE2(k,:) = U2(k) - param2(1)/param2(2)
    parameters2(:,k) = param2
    pu2 = sum(-danger_FEA>U2(k))/length(danger_FEA);
    p_nea2(k) = pu2*(max(0,1 + param2(2)*(0 - U2(k))/param2(1)) )^(-1/param2(2)) * p_EA;  % probability of pure collision
    [nlogL,acov] = gplike([param2(2),param2(1)], neg_pot);
    ci_sigmaFEA(:,k) = param2(1) + [-1;1]*1.96*sqrt(acov(2,2));
    ci_xiFEA(:,k) = param2(2) + sign(param2(2))*[-1;1]*1.96*sqrt(acov(1,1));
    F_inv = @(y,scale,shape) scale/shape*((1-y).^-shape - 1);
    NN = length(neg_pot);
    clf; plot(sort(neg_pot), F_inv( [1:NN] /(NN+1), param2(1),param2(2)) ,'.');
    hold on
    plot(sort(neg_pot), sort(neg_pot)); hold off
    pause(0)
    
end
clf
subplot(211)
plot(U2,parameters2(2,:))
hold on
plot(U2,ci_xiFEA(1,:))
plot(U2,ci_xiFEA(2,:))
hold off
title('estimate of xi')
subplot(212)
plot(U2,p_nea2)
title('prob pure collision')
%%
clf; plot((DAFEA(:)),'.'); ylim([-1,10])
%% optimization for particular threshold u
u = -3;
init = [0.3 -.5]
negdata = -DAFEA(:);
negdata = negdata(find(negdata>u));
negL = @(par) -sum( log(gppdf(negdata,par(2),par(1),u)) )
param = fminsearch(negL,init)
Nenc = length(DAFEA(:,1));
Nbs = 100;
xi_sample = zeros(2,Nbs);
xi_init = -0.5;
sigma_init = 1;

while param == init
    init = [max(0.1,init(1) + normrnd(0,1^2)), init(2) + normrnd(0,0.7^2)]
    param = fminsearch(negL,init)
end
p_u = sum(sum((DAFEA)<-u))/( length(DAFEA(1,:))*length(DAFEA(:,1)) )
ue = u - param(1)/param(2);
p_nea = p_u*(max(0,1 + param(2)*(0 - u)/param(1)) )^(-1/param(2))

for j=1:Nbs
    resampling = randsample(Nenc,Nenc,true) % indecis used to bootstrap
    DAFEA_bs = DAFEA(resampling,:);           % resample
    negdata = -DAFEA_bs(:);                   % negate data
    negdata = negdata(find(negdata>u));       % get exceedences
    negL = @(par) -sum( log(gppdf(negdata,par(2),par(1),u)) ); % negative log likelihood function
    param_bs = fminsearch(negL,init);                          % estimate parameters
    stuck = 1;
    for t = 1:100
        % initiate while loop when estimate is the same as inital guess
        %xi_init_temp = xi_init + normrnd(0,1.0^2);
        %sigma_init_temp = max(0,sigma_init + normrnd(0,1.0^2);
        init_temp = [max(0,init(1) + normrnd(0.01,3.0^2) ),init(2) + normrnd(0,3.0^2)];
        param_bs = fminsearch(negL,init_temp)
        if param_bs ~= init_temp
            break
        end
        if t==100
            param_bs = [NaN,NaN]; 
        end
    end
    xi_sample(:,j) = param_bs;
end

%% optimization for m thresholds; DAFEA
p_EA = (sum(enc_type==-1)+sum(enc_type==-2) + sum(enc_type==2))/N
m=20;
init = [2 .8]         % initial guess
U = linspace(-6,-4,m);
parameters = zeros(2,m);
Nenc = length(DAFEA(:,1));
p_nea = zeros(1,m);
xi_sample = zeros(m,50);
xi_init = -0.5;
upper_endpoint = zeros(1,m);
ci_bs = 0;
for k=1:m
    k
    negdata = -DAFEA(:);
    negdata = negdata(find(negdata>U(k)));
    negL = @(par) -sum( log(gppdf(negdata,par(2),par(1),U(k))) );
    param = fminsearch(negL,init);
    while param == init                                                    % in case initial guess is bad
        init = [max(0.1,init(1) + normrnd(0,1.4^2)), init(2) + normrnd(0,1.4^2)]
        param = fminsearch(negL,init)
    end
    parameters(:,k) = param
    p_u = sum(sum((DAFEA)<-U(k)))/( length(DAFEA(1,:))*length(DAFEA(:,1)) )
    ue = U(k) - param(1)/param(2)
    p_nea(k) = p_u*(max(0,1 + param(2)*(0 - U(k))/param(1)) )^(-1/param(2)) * p_EA;
    upper_endpoint(k) = U(k) - param(1)/param(2)
    %%%%%%%%%%%%%%%%%% bootstrapping to get ci %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ci_bs == 1
    for j=1:50
        resampling = randsample(Nenc,Nenc,true); % indecis used to bootstrap
        DAFEA_bs = DAFEA(resampling,:);           % resample
        negdata = -DAFEA_bs(:);
        negdata = negdata(find(negdata>U(k)));   % get exceedences
        negL = @(xi) -sum( log(gppdf(negdata,xi,parameters(1,k),U(k))) );
        xi_bs = fminsearch(negL,xi_init);
        while xi_bs == xi_init                                             % in case initial guess is bad
            xi_init = xi_init + normrnd(0,1.4^2);
            xi_bs = fminsearch(negL,xi_init);
        end
        xi_sample(k,j) = xi_bs;
    end
    end
        
        
        

end

clf; 
subplot(211)
plot(U,parameters(2,:))
subplot(212)
plot(U,p_nea)
%%

NLL = @(par) -sum(log(gampdf(DAFEA(1,:),par(1),par(2))))
par = fminsearch(NLL,[1,1]);
plot(linspace(10,15,100),gampdf(linspace(10,15,100),par(1),par(2)))
%hist(DAFEA(1,:))
%% analysis for dangermax_EA; estimating probability of non-clean-crash
plot(min(dangermax_EA'),'.')
%%
p_EA = (sum(enc_type==-1)+sum(enc_type==-2))/N
m = 20;
U3 = linspace(-.6,-0.2,m);
parameters3 = zeros(2,m);
p_ea3 = zeros(1,m);
data = min(dangermax_EA');
for k=1:m
    negdata = -data;
    negdata = negdata(find(negdata>U3(k)));
    negL = @(par) -sum( log(gppdf(negdata,par(2),par(1),U3(k))) )
    param3 = fminsearch(negL,[1 -.5]);
    parameters3(:,k) = param3
    pu3 = sum(-data>U3(k))/length(data);
    p_ea3(k) = pu3*(max(0,1 + param3(2)*(0 - U3(k))/param3(1)) )^(-1/param3(2)) * p_EA;
end
%%
plot(U3,parameters3(2,:))
%%
plot(U3,p_ea3)
