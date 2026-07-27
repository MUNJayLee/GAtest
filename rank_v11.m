function [pop, fitness_value, best_info, TT] = rank_v11(pop, fitness_value, TT, cfg)
%RANK_V11 v1.1 优化版排序与精英保留
%   改进精英保留策略，支持多种群最优个体
%
%   输入:
%       pop           - 种群矩阵
%       fitness_value - 适应度向量
%       TT            - 时刻矩阵
%       cfg           - 配置结构体
%   输出:
%       pop           - 排序后的种群
%       fitness_value - 排序后的适应度
%       best_info     - 当前最优个体信息
%       TT            - 排序后的时刻矩阵

[fitness_value, sort_idx] = sort(fitness_value, 'ascend');
pop = pop(sort_idx, :);
TT = TT(sort_idx, :);

% 精英保留
best_info.fitness = fitness_value(end);
best_info.individual = pop(end, :);
best_info.TT = TT(end, :);
best_info.generation = 0;  % 由主程序填充

end
