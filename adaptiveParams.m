function [new_cross_rate, new_mutate_rate] = adaptiveParams(fitness_history, cfg, G)
%ADAPTIVEPARAMS 自适应调整遗传算法参数
%   根据种群适应度变化趋势动态调整交叉率和变异率
%   v1.1 新增：自适应遗传算法策略
%
%   输入:
%       fitness_history - 历史适应度数组 (1 x G)
%       cfg             - 配置结构体
%       G               - 当前代数
%   输出:
%       new_cross_rate  - 调整后的交叉率
%       new_mutate_rate - 调整后的变异率

if ~cfg.adaptive_enable || G < cfg.adaptive_window
    new_cross_rate = cfg.cross_rate;
    new_mutate_rate = cfg.mutate_rate;
    return;
end

% 计算最近窗口期内的适应度变化趋势
window = min(cfg.adaptive_window, G);
recent_fitness = fitness_history(max(1, G-window+1):G);

% 计算适应度改善率
if length(recent_fitness) >= 2
    improvement_rate = abs(recent_fitness(end) - recent_fitness(1)) / max(abs(recent_fitness(1)), eps);
else
    improvement_rate = 1;
end

% 计算适应度方差（种群多样性指标）
fitness_variance = var(recent_fitness);
max_var = max(recent_fitness)^2 * 0.1;  % 参考最大方差
normalized_var = min(fitness_variance / max(max_var, eps), 1);

%% 自适应交叉率调整策略
% 当改善率较低时，提高交叉率以加速收敛
% 当种群多样性低时，降低交叉率以保持多样性
if improvement_rate < 0.01
    % 适应度停滞，增加交叉率探索新区域
    cross_adjust = 0.1;
else
    % 正常收敛，保持或略微降低交叉率
    cross_adjust = -0.02;
end

% 多样性影响：多样性低时降低交叉率
cross_adjust = cross_adjust - 0.05 * (1 - normalized_var);

new_cross_rate = cfg.cross_rate + cross_adjust;
new_cross_rate = max(cfg.cross_rate_min, min(cfg.cross_rate_max, new_cross_rate));

%% 自适应变异率调整策略
% 当改善率较低时，提高变异率以增加多样性
% 当种群多样性高时，降低变异率以稳定收敛
if improvement_rate < 0.005
    % 严重停滞，大幅增加变异率
    mutate_adjust = 0.15;
elseif improvement_rate < 0.02
    % 轻度停滞，适度增加变异率
    mutate_adjust = 0.08;
else
    % 正常收敛，降低变异率
    mutate_adjust = -0.03;
end

% 多样性影响：多样性高时降低变异率
mutate_adjust = mutate_adjust - 0.1 * normalized_var;

new_mutate_rate = cfg.mutate_rate + mutate_adjust;
new_mutate_rate = max(cfg.mutate_rate_min, min(cfg.mutate_rate_max, new_mutate_rate));

end
