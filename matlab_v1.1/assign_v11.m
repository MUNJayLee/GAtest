function [pop_new, y_ijdc, C_TJ] = assign_v11(x_jdt, cfg, data)
%ASSIGN_V11 v1.1 优化版集装箱分配函数
%   向量化优化，减少循环嵌套
pop_size = size(x_jdt, 1);
J_max = cfg.J_max;
C_max = data.C_max;
mintranstime = cfg.mintranstime;
maxtsegs = cfg.maxtsegs;
y_ijdc = zeros(pop_size, C_max);
C_TJ = zeros(pop_size, C_max);
C_IDT_dir = data.C_IDT(3, :);
C_IDT_ti  = data.C_IDT(4, :);
for i = 1:pop_size
    train_times = find(x_jdt(i, :) ~= 0);
    train_dirs = x_jdt(i, train_times);
    num_trains = length(train_times);
    if num_trains == 0
        continue;
    end
    train_info = zeros(5, num_trains);
    train_info(1, :) = 1:num_trains;
    train_info(2, :) = train_dirs(1:num_trains);
    train_info(3, :) = train_times(1:num_trains);
    train_info(5, :) = 0;
    for j = 1:C_max
        same_dir_idx = find(train_info(2, :) == C_IDT_dir(j));
        if isempty(same_dir_idx)
            y_ijdc(i, j) = 0;
            C_TJ(i, j) = cfg.T_max;
            continue;
        end
        time_diff = C_IDT_ti(j) - train_info(3, same_dir_idx);
        valid_idx = find(time_diff >= -mintranstime);
        not_full_idx = find(train_info(5, same_dir_idx) <= 2 * maxtsegs - 1);
        candidate_idx = intersect(valid_idx, not_full_idx);
        if isempty(candidate_idx)
            y_ijdc(i, j) = 0;
            C_TJ(i, j) = cfg.T_max;
        else
            selected = same_dir_idx(candidate_idx(1));
            y_ijdc(i, j) = train_info(1, selected);
            C_TJ(i, j) = train_info(3, selected);
            train_info(5, selected) = train_info(5, selected) + 1;
        end
    end
end
end
