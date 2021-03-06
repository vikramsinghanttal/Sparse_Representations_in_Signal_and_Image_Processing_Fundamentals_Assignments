% ref : http://math.mit.edu/~liewang/OMP.pdf
% Orthogonal Matching Pursuit for Sparse Signal Recovery With Noise
%% Complexity Analysis
% Most complex operations are :
% A'*r_k       ~ O(mn) 
% inv(As'*As)  ~ O(K*K*m)
% Overall complexity of OMP is O(mnk)


clear all;
clc;
% rng(120);

%% Setting the parameters
n = 50; m =120;
threshold = 0.1;
montecarloiterations = 10000;
error_omp = zeros(15,1);
Pe_sup_omp= zeros(15,1);
error_lsomp = zeros(15,1);
Pe_sup_lsomp= zeros(15,1);
error_mp = zeros(15,1);
Pe_sup_mp= zeros(15,1);
error_wmp = zeros(15,1);
Pe_sup_wmp= zeros(15,1);
error_thr = zeros(15,1);
Pe_sup_thr= zeros(15,1);
for mci=1:montecarloiterations
    for K=1:15
        %% Generating A, x and b
        % K = randi([1,n/2]);             % No. of nonzero parameters in x
        nonz_idx = randi([1,120],K,1);  % Indices which will contain the non zero elements in x

        % A=sqrt(0.5)*(randn(n,m)+1i*randn(n,m));
        A = randn(n,m);                 % Dictionary matrix
        % A  = A./vecnorm(A);           % Not supported by R2015a
        A = A*diag(1./sqrt(diag(A'*A)));% making columns unit norm
        x = zeros(m,1);
        x(nonz_idx) = 1+rand(K,1); 
        b = A*x;
        %% Auxilliary Variables
        k   = 0;
        r_k = b;
        S_k = [];
        E_i = inf;
        z_i = 0;

    %         tic
        %% OMP Algorithm
        while(norm(r_k)>threshold && k<m)
            z   = A'*r_k;
            [M,I]= max(abs(z));
            S_k = [S_k I];
            As  = A(:,S_k);
            x_k = (As'*As)\(As'*b);
            r_k = b - As*x_k;
            k=k+1;
        end
    %         toc
            %% Results
        x_omp = zeros(m,1);
        x_omp(S_k)=x_k;
        error_omp(K) = error_omp(K)+norm(x_omp-x)/norm(x);
        Pe_sup_omp(K)=Pe_sup_omp(K)+(1-sum(x&x_omp)/max(nnz(x),nnz(x_omp)));

            %% Auxilliary Variables
        k   = 0;
        r_k = b;
        S_k = [];
        E_i = inf;
        z_i = 0;
        A_idx = 1:1:m; 
        best_idx = 0;

    %% LS-OMP Algorithm
        while(E_i > threshold && k<m)
            E_i = inf;
            for i  = 1:m-k
                As = [A(:,S_k) A(:,A_idx(i))];
                x_i= (As'*As)\(As'*b);
                norm_rk=norm(As*x_i-b);
                if E_i > norm_rk
                   E_i = norm_rk;
                   best_idx  = i;
                   x_k = x_i;
                end
            end
            k = k+1;
            S_k = [S_k A_idx(best_idx)];
            A_idx(best_idx)=[];
        end

        %% Results
        x_lsomp = zeros(m,1);
        x_lsomp(S_k)=x_k;
        error_lsomp(K) = error_lsomp(K)+norm(x_lsomp-x)/norm(x);
        Pe_sup_lsomp(K)= Pe_sup_lsomp(K) + 1-sum(x&x_lsomp)/max(nnz(x),nnz(x_lsomp));
        
        %% Auxilliary Variables
        k   = 0;
        r_k = b;
        S_k = [];
        x_k =[];
        tic
        %% Matching Pursuit Algorithm
        while(norm(r_k)>threshold && k<m)
            z   = A'*r_k;
            [M,I]= max(abs(z));
            S_k = [S_k I];
            As  = A(:,S_k);
            x_k = [x_k;A(:,I)'*r_k];
            r_k = b - As*x_k;
            k   = k+1;
        end
        %% Results
        x_mp = zeros(m,1);
        x_mp(S_k)=x_k;

        error_mp(K) = error_mp(K)+norm(x_mp-x)/norm(x);
        Pe_sup_mp(K)= Pe_sup_mp(K)+ 1-sum(x&x_mp)/max(nnz(x),nnz(x_mp));
        
        k   = 0;
        r_k = b;
        S_k = [];
        z_i = 0;
        x_k= [];
        t   = 0.5;
%         tic
        %% Weak Matching Pursuit Algorithm
        while(norm(r_k)>threshold && k<m)
            for i=1:m
                z_i   = A(:,i)'*r_k;
                if abs(z_i) > t*norm(r_k)
                    break;
                end
            end
            S_k = [S_k i];
            As  = A(:,S_k);
            x_k = [x_k;A(:,i)'*r_k];
            r_k = b - As*x_k;
            k   = k+1;
        end
%         toc
        %% Results
        x_wmp = zeros(m,1);
        x_wmp(S_k) =   x_k;
        error_wmp(K) = error_wmp(K) + norm(x_wmp-x)/norm(x);
        Pe_sup_wmp(K)= Pe_sup_wmp(K)+ 1-sum(x&x_wmp)/max(nnz(x),nnz(x_wmp));
        
        
        %% Auxilliary Variables
        k   = 0;
        r_k = b;
        S_k = [];
        E_i = inf;
        z_i = 0;
        [A_sorted,sorted_idx] = sort(abs(A'*b),'descend');

        %% OMP Algorithm
        while(norm(r_k)>threshold && k<m)
            k   = k+1;
            S_k = [S_k sorted_idx(k)];
            As  = A(:,S_k);
            x_k = As'*b;
            r_k = b - As*x_k;
        end

        %% Results
        x_thr = zeros(m,1);
        x_thr(S_k)=x_k;
        error_thr(K) = error_thr(K)+norm(x_thr-x)/norm(x);
        Pe_sup_thr(K)=Pe_sup_thr(K)+(1-sum(x&x_thr)/max(nnz(x),nnz(x_thr)));
    end
    mci
end
error_omp   = error_omp/montecarloiterations;
error_lsomp = error_lsomp/montecarloiterations;
error_mp    = error_mp/montecarloiterations;
error_wmp   = error_wmp/montecarloiterations;
error_thr   = error_thr/montecarloiterations;

Pe_sup_omp  = Pe_sup_omp/montecarloiterations;
Pe_sup_lsomp= Pe_sup_lsomp/montecarloiterations;
Pe_sup_mp   = Pe_sup_mp/montecarloiterations;
Pe_sup_wmp  = Pe_sup_wmp/montecarloiterations;
Pe_sup_thr  = Pe_sup_thr/montecarloiterations;

x_ax = (1:1:15)';
p = figure(1); clf;
set(p,'Position',[115 100 600 400]);
% set(gca,'xscale','log')
hold on
p = semilogx(x_ax,error_omp,'r');
p.LineWidth = 1.5;
p = semilogx(x_ax,error_lsomp,'g');
p.LineWidth = 1.5;
p = semilogx(x_ax,error_mp,'b');
p.LineWidth = 1.5;
p = semilogx(x_ax,error_wmp,'k');
p.LineWidth = 1.5;
p = semilogx(x_ax,error_thr,'c');
p.LineWidth = 1.5;
title(['L_2 Estimation Error vs K (Error Tolerance = ' num2str(threshold) ' )']);
ylabel('Avg. Relative L_2 error in estimates');
xlabel('Cordinality of the solution (K)');
legend('OMP','LS-OMP','MP',['WMP (t=' num2str(t) ')'],'Threshold');
grid on;

q = figure(2); clf;
set(q,'Position',[730 100 600 400]);
hold on
q = semilogx(x_ax,Pe_sup_omp,'r');
q.LineWidth = 1.5;
q = semilogx(x_ax,Pe_sup_lsomp,'g');
q.LineWidth = 1.5;
q = semilogx(x_ax,Pe_sup_mp,'b');
q.LineWidth = 1.5;
q = semilogx(x_ax,Pe_sup_wmp,'k');
q.LineWidth = 1.5;
q = semilogx(x_ax,Pe_sup_thr,'c');
q.LineWidth = 1.5;
title(['P_e Support vs K (Error Tolerance = ' num2str(threshold) ' )']);
ylabel('Probability of mismatch in support');
xlabel('Cordinality of the Solution (K)');
legend('OMP','LS-OMP','MP',['WMP (t=' num2str(t) ')'],'Threshold');
grid on;

Pe_sup = [x_ax	Pe_sup_omp	Pe_sup_lsomp	Pe_sup_mp	Pe_sup_wmp	Pe_sup_thr];
L2_err = [x_ax	error_omp	error_lsomp     error_mp    error_wmp   error_thr ];

fid = fopen('comparison_greedy_algorithms_Pe_Sup.txt','wt');
fprintf(fid, '\t\t x   \t\t Pe_supp_omp \t Pe_supp_lsomp \t Pe_supp_mp \t Pe_supp_wmp \t Pe_supp_thr\n');
fclose(fid);
fid = fopen('comparison_greedy_algorithms_L2_error.txt','wt');
fprintf(fid, '\t\t x   \t\t Error_omp  \t Error_lsomp  \t Error_mp  \t\t Error_wmp  \t Error_thr\n');
fclose(fid);
save('comparison_greedy_algorithms_L2_error.txt','Pe_sup','-ascii','-append');
save('comparison_greedy_algorithms_Pe_Sup.txt','L2_err','-ascii','-append');