clear all;
clc
rng(120);
n=50; m=150;
spark = 13;
% A=sqrt(0.5)*(randn(n,m)+1i*randn(n,m));
A = randn(n,m);
A(:,m) = mean(A(:,1:spark-1),2);

%% Normalizing the columns of A
A  = A./vecnorm(A);
G  = abs(A'*A);
G((m+1)*(0:1:m-1)+1) = zeros(m,1);

mu = max(G(:));
sparkest1 = ceil(1 + 1/mu);
disp(['Lower bound on spark via mutual coherence : ' num2str(sparkest1)]);

Gsorted = sort(G,2,'descend');
Gcumsum = cumsum(Gsorted,2);
% [] = 
max_Gcumsum = max(Gcumsum);
figure
plot(max_Gcumsum);
hold on
plot(mu*(1:1:150));

sparkest2 = find(max_Gcumsum>1,1)+1;
disp(['Lower bound on spark via mutual coherence : ' num2str(sparkest2)]);

%% Upper bound on spark
options = optimoptions('linprog','Algorithm','dual-simplex','Display','iter');
x = zeros(m,m);
beff = [zeros(n,1);1;0];
lb   = zeros(2*m,1);
ub   = 100*ones(2*m,1);
Aext = [A -A ;zeros(1,2*m);zeros(1,2*m)];
nnz_x= zeros(m,1);
for k = 1:1:m
    Aeff = Aext;
    Aeff(n+1,k)=1;
    Aeff(n+2,m+k)=1;
    x_extended = linprog(ones(2*m,1),[],[],Aeff,beff,lb,ub,options);
    x_extended = x_extended.*(x_extended > 1e-7);
    x(:,k) =  x_extended(1:m)-x_extended(m+1:2*m);
    nnz_x(k)  =  nnz(x(:,k));
end

sparkest3 = nnz_x(find((nnz_x==min(nnz_x)),1));
disp(['Upper bound on spark via mutual coherence : ' num2str(sparkest3)]);