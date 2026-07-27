function [new_cross, new_mutate] = adaptiveParams(fitness_history, cfg, G)
%ADAPTIVEPARAMS 自适应调整遗传算法参数
%   根据适应度收敛情况动态调整交叉率和变异率
%   v1.1 新增核心功能
if ~cfg.adaptive_enable || G < cfg.adaptive_window
    new_cross = cfg.cross_rate;
    new_mutate = cfg.mutate_rate;
    return;
end
window = min(cfg.adaptive_window, G);
recent = fitness_history(max(1, G-window+1):G);
if length(recent) >= 2
    improvement_rate = abs(recent(end) - recent(1)) / max(abs(recent(1)), 1e-10);
else
    improvement_rate = 1.0;
end
fitness_variance = var(recent);
max_var = max(recent)^2 * 0.1;
normalized_var = min(fitness_variance / max(max_var, 1e-10), 1.0);
if improvement_rate < 0.01
    cross_adjust = 0.1;
else
    cross_adjust = -0.02;
end
cross_adjust = cross_adjust - 0.05 * (1 - normalized_var);
new_cross = cfg.cross_rate + cross_adjust;
new_cross = max(cfg.cross_rate_min, min(cfg.cross_rate_max, new_cross));
if improvement_rate < 0.005
    mutate_adjust = 0.15;
elseif improvement_rate < 0.02
    mutate_adjust = 0.08;
else
    mutate_adjust = -0.03;
end
mutate_adjust = mutate_adjust - 0.1 * normalized_var;
new_mutate = cfg.mutate_rate + mutate_adjust;
new_mutate = max(cfg.mutate_rate_min, min(cfg.mutate_rate_max, new_mutate));
end
