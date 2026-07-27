function pop_new = selection_v11(pop, fitness_value, cfg)
%SELECTION_V11 v1.1 优化版选择操作
%   锦标赛选择替代轮盘赌，避免早熟收敛
%
%   输入:
%       pop           - 种群矩阵
%       fitness_value - 适应度向量
%       cfg           - 配置结构体
%   输出:
%       pop_new       - 选择后的新种群

pop_size = cfg.pop_size;
tournament_size = 3;  % 锦标赛规模

pop_new = zeros(size(pop));

for i = 1:pop_size
    % 随机选择tournament_size个个体
    contestants = randperm(pop_size, tournament_size);
    % 选择适应度最高的
    [~, best_idx] = max(fitness_value(contestants));
    winner = contestants(best_idx);
    pop_new(i, :) = pop(winner, :);
end

end
