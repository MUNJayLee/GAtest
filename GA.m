clc
clear
close all

global T_max J_max D0 L_d Tmaintenance maintenance mintranstime minintervaltime maxtsegs
global mintsegs Yardcap trainnum C_max C_IDT protoC_TI protoC_SUMI coneachd each_best_fitness
global fitness_value C_TJ traineachd v_jd G Gbest
%% ��ʼ����
readC;
%C_IDT
%��һ���Ǽ�װ����
%�ڶ����Ǽ�װ�����Եİ��ֱ��
%�������Ǽ�װ�䷽��
%�������Ǽ�װ�䵽��ʱ��

%% ģ�Ͳ���
T_max=168;
J_max=15;
D0=[1,2,3,4];%���򼯺�
L_d=[555,736,402,310];%�������򳤶�
Tmaintenance=14;%����ά��ʱ�䴰�ܳ�����Ҫ�ֶ�����ʱ�䴰
maintenance=[7,8,31,32,55,56,79,80,103,104,127,128,151,152];%ָ��ά��ʱ�䴰
mintranstime=2;
minintervaltime=1;
maxtsegs=10;
mintsegs=5;
Yardcap=160;
caltrains;%�����������з�����

%% �Ŵ��㷨����
global pop_size
generation_size=10;%����������
pop_size=20;%��Ⱥ��ģ
cross_rate = 0.9;%�������
mutate_rate = 0.5;%�������
chromo_size = T_max+C_max+J_max;%Ⱦɫ�峤��
elitism = true;%ѡ��Ӣ����
fitness_avg = zeros(1,generation_size);
fitness_value = [];
best_fitness = 0;
best_generation = 0;
each_best_fitness=zeros(1,generation_size);
each_best_individual=[];

%% ������ʼ��
[pop,TT]=initialize();
fitness(pop,TT);
Gbest=max(fitness_value);
Gbest_index=find(max(fitness_value));
each_best_fitness(1)=Gbest;
each_best_individual(1,:)=pop(Gbest_index,:);

%% ������

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