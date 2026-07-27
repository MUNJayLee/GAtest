function [pop, fitness_value, best_info, TT] = rank_v11(pop, fitness_value, TT, cfg)
%RANK_V11 v1.1 优化版排序与精英保留
[fitness_value, sort_idx] = sort(fitness_value, 'ascend');
pop = pop(sort_idx, :);
TT = TT(sort_idx, :);
best_info.fitness = fitness_value(end);
best_info.individual = pop(end, :);
best_info.TT = TT(end, :);
best_info.generation = 0;
end
