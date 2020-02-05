%% ANALYSIS ON TRANSFORMED DATA!!!
data_matrix = DAFEA;
Nenc = length(data_matrix(:,1))
u_l = 5
u_u = 12
clf;plot(min(data_matrix'),'.'); hold on; plot(ones(1,Nenc)*u_l); plot(ones(1,Nenc)*u_u)
ylim([-1,40])
%% transformation analysis
p=4
delta = 1
transinv = @(x)1./(delta + x).^p;
transex = @(x)exp(-0.4*(x - 2));
transneg = @(x) -x;
trans = @(x) transex(x);
Nenc = length(data_matrix(:,1));
clf

u_min_max = sort(trans([u_l,u_u]));
u_l_trans = u_min_max(1); 
u_u_trans = u_min_max(2);

trans_data = trans(data_matrix);
clf; plot(max(trans_data'),'.'); hold on
plot(ones(1,Nenc)*u_l_trans); plot(ones(1,Nenc)*u_u_trans);ylim([trans(30),trans(0)])
%% find good initial value
trans_data = trans_data(:);
exceed = trans_data(find(trans_data > u_l_trans));
negL = @(par,exceed_data,u) -sum( log(gppdf(exceed_data,par(2),par(1),u)) );
init = fminsearch(@(par) negL(par, exceed, u_l_trans), [3 0.5])
%%
shake_guess = 0.1;                   % variance of noise that gets added to initial guess when stuck
Nenc = length(data_matrix(:,1));         % number of encounters
compute_ci = 0;                    % set equal to one if confidence intervals for xi are desired
Nbs = 200;                         % number of bootstrapped samples to compute standard error
trans_data = trans(data_matrix);   
p_EA = (sum(enc_type==-1)+sum(enc_type==-2) + sum(enc_type==2))/N; % probability for encounter to be interactive
m = 10;                                                    % number of thresholds used for estimation
U = sort(trans(linspace(u_l, u_u,m)));                                 % vector containing thresholds
ci_xi_u = zeros(2,m);                                      % collects 95% ci's for xi
param_save = zeros(2,m);
p_nea = zeros(1,m);                                        % collects estimated collision probability for each threshold
ue_save = zeros(1,m)*nan;                               % collects estimated upper endpoint
max_data = max(max(trans_data));

logit = 0;                                               % set to plot logarithm of p_nea
for k=1:m
    k
    data = trans_data(:);
    data = data(find(data>U(k)));
    negL = @(par) -sum( log(gppdf(data,par(2),par(1),U(k))) );
    param = fminsearch(negL,init);
    init_temp = init;
    while param == init_temp                                                    % in case initial guess is bad
        init = [max(0.1, init(1) + normrnd(0,shake_guess^2)), init(2) + normrnd(0,shake_guess^2)];
        param = fminsearch(negL,init);
    end
    param_save(:,k) = param;
    p_u = sum(sum((trans_data)>U(k)))/( length(data_matrix(1,:))*length(data_matrix(:,1)) );
    p_nea(k) = p_u*(1 - gpcdf(trans(0), param(2), param(1),U(k)) );%(max(0,1 + param(2)*(trans(0) - U(k))/param(1)) )^(-1/param(2)); % * p_EA
    ue = U(k) - param(1)/param(2);
    if param(2)<0; ue_save(k) = ue; end

%%%%%%%%%%%%%%%%%%%%%%%%%% bootstrapping %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if compute_ci == 1
        for j=1:Nbs
            resampling = randsample(Nenc,Nenc,true);              % indeces used to bootstrap
            trans_DAFEA_bs = trans_data(resampling,:);            % bootstrapped sample
            data = trans_DAFEA_bs(:);
            data = data(find(data>U(k)));                         % get exceedences
            negL = @(par) -sum( log(gppdf(data,par(2), par(1), U(k))) ); % negative log likelihood function
            param_bs = fminsearch(negL,param);                           % estimate parameters
            if param_bs == param                                         % in case of stuck
            stuck = 1;
                for t = 1:200
                    t
                    init_temp = [max(0.1,param(1) + normrnd(0.01, 2.0^2) ),param(2) + normrnd(0, 2.0^2)];
                    if negL(init_temp) ~= Inf
                       param_bs = fminsearch(negL,init_temp);
                       if param_bs ~= init_temp
                           break
                       end
                    end

                    if t==200                          % give up if after 100 iterations no results have been obtained
                        param_bs = [NaN,NaN];
                        SAMPLE = DAFEA_bs;
                        PARAM = param;
                        u_corrupt = u;
                    end
                end
            end
            xi_sample(j) = param_bs(2);
        end
        xi_sample(find(xi_sample == NaN)) = [];
        xi_mean = mean(xi_sample);
        se_xi = sqrt(sum((xi_sample - xi_mean).^2)/length(xi_sample));
        ci_xi = param(2) + [-1 1]   *1.96*se_xi; ci_xi = sort(ci_xi);
        ci_xi_u(:,k) = ci_xi';
    end
    init = param;

end

clf;
subplot(221)
plot(U,param_save(1,:))

title('sigma_{est}')

subplot(222)
plot(U, param_save(2,:))
title('xi_{est}')
hold on
if compute_ci == 1
    plot(U,ci_xi_u)
end

subplot(223)
if min(param_save(2,:))<0
    plot(U,ue_save(find(param_save(2,:)<0))); hold on
    plot(U,ones(1,m)*max_data)
    plot(U,ones(1,m)*trans(0))
    title('upper endpoint estimates')
end
subplot(224)
if logit==1; plot(U,log10(p_nea)); title('log(p_{est})')
else; plot(U,p_nea); title('p_{est}'); end

































%%%%%%%%%%%%%% code from the olden days %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %% exponential tranformation
% NN = length(DAFEA(:,1));
% delta = -0.01;
% u_l_trans = exp(-s*(u_u)).^p
% u_u_trans = 1/(delta + u_l).^p
% s = .6;
% trans_data = exp(-s*(DAFEA + delta));
% clf; plot(mean(trans_data'),'.'); hold on; plot(ones(1,NN)*0.03); plot(ones(1,NN)*0.2); hold off
% %% Estimating using
% compute_ci = 1;                                            % set equal to one if confidence intervals for xi are desired
% Nbs = 100;                                                 % number of bootstrapped samples to compute standard error
% delta= -0.01
% s = 0.4;
% compute_ci = 1;
% trans_data = exp(-s*(DAFEA + delta));
% p_EA = (sum(enc_type==-1)+sum(enc_type==-2) + sum(enc_type==2))/N;
% m=10;
% ci_xi_u = zeros(2,m);                                      % collects 95% ci's for xi
% init = [2 .8];         % initial parameter guess
% U = linspace(.01 , .2, m);
% ue_save = zeros(1,m);
% parameters = zeros(2, m);
% p_nea = zeros(1, m);
% 
% for k=1:m
%     data = trans_data(:);
%     data = data(find(data>U(k)));
%     negL = @(par) -sum( log(gppdf(data, par(2), par(1), U(k))) );
%     param = fminsearch(negL,init);
%     init_temp = init;
%     while param == init_temp                                                    % in case initial guess is bad
%         init_temp = [max(0.1,init(1) + normrnd(0,1.4^2)), init(2) + normrnd(0,1.4^2)];
%         param = fminsearch(negL,init)
%     end
%     parameters(:,k) = param
%     p_u = sum(sum((trans_data)>U(k)))/( length(DAFEA(1,:))*length(DAFEA(:,1)) )
%     ue = U(k) - param(1)/param(2)
%     if param(2)<0; ue_save(k) = ue; end
%     p_nea(k) = p_u*(max(0,1 + param(2)*(exp(-delta*s) - U(k))/param(1)) )^(-1/param(2)) * p_EA
%         %%% bootstrapping %%%%
%     if compute_ci == 1
%         for j=1:Nbs
%             resampling = randsample(Nenc,Nenc,true);  % indeces used to bootstrap
%             trans_DAFEA_bs = trans_data(resampling,:);           % resample
%             data = trans_DAFEA_bs(:);
%             data = data(find(data>U(k)));       % get exceedences
%             negL = @(par) -sum( log(gppdf(data,par(2),par(1),U(k))) ); % negative log likelihood function
%             param_bs = fminsearch(negL,param);                          % estimate parameters
%             if param_bs == param                       % in case of stuck
%             stuck = 1;
%                 for t = 1:200
%                     t
%                     init_temp = [max(0.1,param(1) + normrnd(0.01, 2.0^2) ),param(2) + normrnd(0, 2.0^2)];
%                     if negL(init_temp) ~= Inf
%                        param_bs = fminsearch(negL,init_temp);
%                        if param_bs ~= init_temp
%                            break
%                        end
%                     end
%     %                 if t>195
%     %                     pause(0.5)
%     %                 end
% 
% 
%                     if t==200                          % give up if after 100 iterations no results have been obtained
%                         param_bs = [NaN,NaN];
%                         SAMPLE = DAFEA_bs;
%                         PARAM = param;
%                         u_corrupt = u;
%                     end
%                 end
%             end
%             xi_sample(j) = param_bs(2);
%         end
%         xi_sample(find(xi_sample == NaN)) = [];
%         xi_mean = mean(xi_sample);
%         se_xi = sqrt(sum((xi_sample - xi_mean).^2)/length(xi_sample));
%         ci_xi = param(2) + [-1 1]*1.96*se_xi; ci_xi = sort(ci_xi);
%         ci_xi_u(:,k) = ci_xi';
%     end
% end
% 
% clf;
% subplot(211)
% plot(U,parameters(2,:))
% hold on
% if compute_ci == 1
%     plot(U,ci_xi_u)
% end
% subplot(212)
% plot(U,p_nea)
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %% exponential tranformation (old code)
% NN = length(DAFEA(:,1));
% delta=-0.01;
% s = .4;
% trans_data = exp(-s*(DAFEA + delta));
% clf; plot(mean(trans_data'),'.'); hold on; plot(ones(1,NN)*0.03); plot(ones(1,NN)*0.1); hold off
% %%
% delta= -0.01
% s = 0.4;
% trans_data = exp(-s*(DAFEA(:) + delta));
% p_EA = (sum(enc_type==-1)+sum(enc_type==-2) + sum(enc_type==2))/N;              % probability of evasive action for one encounter
% m=5;
% init = [2 .8];                     % initial parameter guess
% U = linspace(.02 , .1, m);
% parameters = zeros(2, m);
% p_nea = zeros(1, m);
% for k=1:m
%     data = trans_data(:);
%     data = data(find(data>U(k)));
%     negL = @(par) -sum( log(gppdf(data, par(2), par(1), U(k))) );
%     param = fminsearch(negL,init);
%     init_temp = init;
%     while param == init_temp                                                    % in case initial guess is bad
%         init_temp = [max(0.1,init(1) + normrnd(0,1.4^2)), init(2) + normrnd(0,1.4^2)];
%         param = fminsearch(negL,init)
%     end
%     parameters(:,k) = param
%     p_u = sum(sum((trans_data)>U(k)))/( length(DAFEA(1,:))*length(DAFEA(:,1)) )
%     ue = U(k) - param(1)/param(2)
%     p_nea(k) = p_u*(max(0,1 + param(2)*(exp(-delta*s) - U(k))/param(1)) )^(-1/param(2)) * p_EA
% end
% 
% clf;
% subplot(211)
% plot(U,parameters(2,:))
% subplot(212)
% plot(U,p_nea)
