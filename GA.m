clc
clear
close all

global T_max J_max D0 L_d Tmaintenance maintenance mintranstime minintervaltime maxtsegs
global mintsegs Yardcap trainnum C_max C_IDT protoC_TI protoC_SUMI coneachd each_best_fitness
global fitness_value C_TJ traineachd v_jd G Gbest
%% 初始表处理
readC;
%C_IDT
%第一行是集装箱编号
%第二行是集装箱来自的班轮编号
%第三行是集装箱方向
%第四行是集装箱到达时间

%% 模型参数
T_max=168;
J_max=15;
D0=[1,2,3,4];%方向集合
L_d=[555,736,402,310];%各个方向长度
Tmaintenance=14;%定义维修时间窗总长，需要手动定义时间窗
maintenance=[7,8,31,32,55,56,79,80,103,104,127,128,151,152];%指定维修时间窗
mintranstime=2;
minintervaltime=1;
maxtsegs=10;
mintsegs=5;
Yardcap=160;
caltrains;%计算各方向班列分配数

%% 遗传算法参数
global pop_size
generation_size=10;%最大迭代代数
pop_size=20;%种群规模
cross_rate = 0.9;%交叉概率
mutate_rate = 0.5;%变异概率
chromo_size = T_max+C_max+J_max;%染色体长度
elitism = true;%选择精英操作
fitness_avg = zeros(1,generation_size);
fitness_value = [];
best_fitness = 0;
best_generation = 0;
each_best_fitness=zeros(1,generation_size);
each_best_individual=[];

%% 变量初始化
[pop,TT]=initialize();
fitness(pop,TT);
Gbest=max(fitness_value);
Gbest_index=find(max(fitness_value));
each_best_fitness(1)=Gbest;
each_best_individual(1,:)=pop(Gbest_index,:);

%% 主函数

for G=1:generation_size
    G
    rank;
    selection;
    crossover;
    mutation;
    if Gbest<max(fitness_value)
        each_best_fitness(1+G)=max(fitness_value);
        Gbest_index=find(max(fitness_value));
        each_best_individual(1+G,:)=pop(Gbest_index,:);
        Gbest=max(fitness_value);
    else
        each_best_fitness(1+G)=Gbest;
        each_best_individual(1+G,:)=each_best_individual(G,:);
    end
%     REP_index=find(min(fitness_value));
%     if ~isempty(REP_index)
%         pop(REP_index,:)=best_individual;
%     end
end


result;
% save('150000')