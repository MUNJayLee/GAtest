function pop_new = selection_v11(pop, fitness_value, cfg)
%SELECTION_V11 v1.1 优化版选择操作
%   锦标赛选择替代轮盘赌，避免早熟收敛
pop_size = cfg.pop_size;
tournament_size = 3;
pop_new = zeros(size(pop));
for i = 1:pop_size
    contestants = randperm(pop_size, tournament_size);
    [~, best_idx] = max(fitness_value(contestants));
    winner = contestants(best_idx);
    pop_new(i, :) = pop(winner, :);
end
end
