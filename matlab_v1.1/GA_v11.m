function GA_v11()
%GA_V11 v1.1 优化版遗传算法主程序
%   基于参数结构体的全新架构，支持自适应参数和增强可视化
%   使用方法: GA_v11()
clc; clear; close all;
tic;
fprintf('========================================\n');
fprintf('    GAtest v1.1 - 遗传算法优化系统\n');
fprintf('========================================\n\n');
%% 加载配置
cfg = config();
fprintf('[1/6] 配置加载完成\n');
%% 读取数据
[protoC_I, protoC_TI, protoC_NUMBER, coneachd, protoC_SUMI, C_max, C_IDT] = readC_v11();
data.protoC_TI = protoC_TI;
data.protoC_SUMI = protoC_SUMI;
data.coneachd = coneachd;
data.C_max = C_max;
data.C_IDT = C_IDT;
fprintf('[2/6] 数据读取完成: %d 个集装箱\n', C_max);
%% 计算班列分配
traineachd = caltrains_v11(C_max, coneachd, cfg.J_max, cfg.D0);
data.traineachd = traineachd;
trainnum = [];
for i = 1:length(cfg.D0)
    trainnum = [trainnum, repmat(cfg.D0(i), 1, traineachd(i))];
end
data.trainnum = trainnum;
fprintf('[3/6] 班列分配计算完成: %d 列班列\n', cfg.J_max);
%% 初始化种群
[pop, TT] = initialize_v11(cfg, data);
[fitness_value, obj] = fitness_v11(pop, TT, cfg, data);
obj_history = obj;
[Gbest, best_idx] = max(fitness_value);
best_individual = pop(best_idx, :);
best_TT = TT(best_idx, :);
fitness_history = Gbest;
cross_history = cfg.cross_rate;
mutate_history = cfg.mutate_rate;
fprintf('[4/6] 种群初始化完成: 最优适应度 = %.6f\n', Gbest);
%% 主循环
fprintf('[5/6] 开始遗传算法迭代...\n');
for G = 1:cfg.generation_size
    if cfg.adaptive_enable && G > 1
        [cfg.cross_rate, cfg.mutate_rate] = adaptiveParams(fitness_history, cfg, G);
    end
    cross_history(G) = cfg.cross_rate;
    mutate_history(G) = cfg.mutate_rate;
    
    [pop, fitness_value, ~, TT] = rank_v11(pop, fitness_value, TT, cfg);
    
    elite_count = max(1, floor(cfg.pop_size * cfg.elite_ratio));
    elite_pop = pop(end-elite_count+1:end, :);
    elite_TT = TT(end-elite_count+1:end, :);
    
    pop = selection_v11(pop, fitness_value, cfg);
    [pop, TT] = crossover_v11(pop, TT, cfg, data);
    [pop, TT] = mutation_v11(pop, TT, cfg, data);
    
    [fitness_value, obj] = fitness_v11(pop, TT, cfg, data);
    obj_history(G) = obj;
    
    [~, worst_idx] = sort(fitness_value, 'ascend');
    pop(worst_idx(1:elite_count), :) = elite_pop;
    TT(worst_idx(1:elite_count), :) = elite_TT;
    
    [fitness_replace, ~] = fitness_v11(elite_pop, elite_TT, cfg, data);
    fitness_value(worst_idx(1:elite_count)) = fitness_replace;
    
    [current_best, current_idx] = max(fitness_value);
    if current_best > Gbest
        Gbest = current_best;
        best_individual = pop(current_idx, :);
        best_TT = TT(current_idx, :);
        fprintf('  Gen %3d | New Best: %.6f | CR: %.2f | MR: %.2f\n', G, Gbest, cfg.cross_rate, cfg.mutate_rate);
    elseif mod(G, 10) == 0
        fprintf('  Gen %3d | Best: %.6f | CR: %.2f | MR: %.2f\n', G, Gbest, cfg.cross_rate, cfg.mutate_rate);
    end
    
    fitness_history(G) = Gbest;
end
fprintf('[6/6] 迭代完成!\n');
fprintf('\n');
result_v11(best_individual, best_TT, cfg, data);
plotConvergence(fitness_history, cfg, obj_history);
figure('Name', '自适应参数', 'Position', [200 200 600 300]);
subplot(1,2,1);
plot(1:cfg.generation_size, cross_history, 'b-', 'LineWidth', 1.5);
xlabel('代数'); ylabel('交叉率'); title('自适应交叉率'); grid on;
subplot(1,2,2);
plot(1:cfg.generation_size, mutate_history, 'r-', 'LineWidth', 1.5);
xlabel('代数'); ylabel('变异率'); title('自适应变异率'); grid on;
elapsed = toc;
fprintf('\n总运行时间: %.2f 秒\n', elapsed);
end

function [protoC_I, protoC_TI, protoC_NUMBER, coneachd, protoC_SUMI, C_max, C_IDT] = readC_v11()
    protoC_I = xlsread('数据集.xlsx', 1, 'A2:A29');
    protoC_TI = xlsread('数据集.xlsx', 1, 'G2:G29');
    protoC_NUMBER = xlsread('数据集.xlsx', 1, 'B2:E29');
    coneachd = xlsread('数据集.xlsx', 1, 'B30:E30');
    protoC_SUMI = sum(protoC_NUMBER, 2);
    C_max = sum(protoC_SUMI);
    TEMPC_I = []; TEMPC_TI = []; TEMPC_D = [];
    D = [1;2;3;4];
    for i = 1:length(protoC_I)
        TEMPC_I = [TEMPC_I, repmat(protoC_I(i), 1, protoC_SUMI(i))];
        TEMPC_TI = [TEMPC_TI, repmat(protoC_TI(i), 1, protoC_SUMI(i))];
        for d = 1:length(D)
            TEMPC_D = [TEMPC_D, repmat(D(d), 1, protoC_NUMBER(i,d))];
        end
    end
    C = 1:C_max;
    C_IDT = [C; TEMPC_I; TEMPC_D; TEMPC_TI];
end

function traineachd = caltrains_v11(C_max, coneachd, J_max, D0)
    TEMPtraineachd = floor(J_max .* coneachd ./ C_max);
    TEMPtraineachd_2 = J_max .* coneachd ./ C_max - fix(J_max .* coneachd ./ C_max);
    RESJ = J_max - sum(TEMPtraineachd);
    [~, POSJD] = sort(TEMPtraineachd_2);
    POSJD_2 = POSJD(end-RESJ+1:end);
    traineachd = TEMPtraineachd;
    for i = 1:RESJ
        traineachd(POSJD_2(i)) = traineachd(POSJD_2(i)) + 1;
    end
end
