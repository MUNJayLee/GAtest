function [pop_new, TT_new] = crossover_v11(pop, TT, cfg, data)
%CROSSOVER_V11 v1.1 优化版交叉操作
%   支持自适应交叉率，约束修复机制
%
%   输入:
%       pop    - 种群矩阵
%       TT     - 班列时刻矩阵
%       cfg    - 配置结构体
%       data   - 数据相关结构体
%   输出:
%       pop_new - 交叉后的种群
%       TT_new  - 更新后的时刻矩阵

pop_size = cfg.pop_size;
T_max = cfg.T_max;
J_max = cfg.J_max;
C_max = data.C_max;
chromo_size = T_max + C_max + J_max;
cross_rate = cfg.cross_rate;
traineachd = data.traineachd;

pop_new = pop;
TT_new = TT;

for i = 1:2:pop_size-1
    if rand >= cross_rate
        continue;
    end
    
    % ===== x_jdt 交叉 =====
    x_jdt_1 = pop(i, 1:T_max);
    x_jdt_2 = pop(i+1, 1:T_max);
    
    % 两点交叉
    cross_pos = sort(randperm(T_max, 2));
    cp1 = cross_pos(1);
    cp2 = cross_pos(2);
    
    % 交换片段
    temp = x_jdt_1(cp1:cp2);
    x_jdt_1(cp1:cp2) = x_jdt_2(cp1:cp2);
    x_jdt_2(cp1:cp2) = temp;
    
    % 修复约束：确保各方向班列数量正确
    for k = 1:length(cfg.D0)
        count_1 = sum(x_jdt_1 == cfg.D0(k));
        count_2 = sum(x_jdt_2 == cfg.D0(k));
        target = traineachd(k);
        
        % 修复个体1
        if count_1 > target
            idx = find(x_jdt_1 == cfg.D0(k));
            to_remove = idx(randperm(length(idx), count_1 - target));
            x_jdt_1(to_remove) = 0;
        elseif count_1 < target
            idx = find(x_jdt_1 == 0);
            to_add = idx(randperm(length(idx), target - count_1));
            x_jdt_1(to_add) = cfg.D0(k);
        end
        
        % 修复个体2
        if count_2 > target
            idx = find(x_jdt_2 == cfg.D0(k));
            to_remove = idx(randperm(length(idx), count_2 - target));
            x_jdt_2(to_remove) = 0;
        elseif count_2 < target
            idx = find(x_jdt_2 == 0);
            to_add = idx(randperm(length(idx), target - count_2));
            x_jdt_2(to_add) = cfg.D0(k);
        end
    end
    
    % ===== v_jd 交叉 =====
    v_jd_1 = pop(i, T_max+C_max+1:end);
    v_jd_2 = pop(i+1, T_max+C_max+1:end);
    
    cp_v = randi(J_max - 1);
    temp_v = v_jd_1(cp_v+1:end);
    v_jd_1(cp_v+1:end) = v_jd_2(cp_v+1:end);
    v_jd_2(cp_v+1:end) = temp_v;
    
    % ===== 重新分配集装箱并检验约束 =====
    [~, y_1, ~] = assign_v11(x_jdt_1, cfg, data);
    [~, y_2, ~] = assign_v11(x_jdt_2, cfg, data);
    
    TT_1 = zeros(1, J_max);
    TT_2 = zeros(1, J_max);
    train_t_1 = find(x_jdt_1 ~= 0);
    train_t_2 = find(x_jdt_2 ~= 0);
    TT_1(1:length(train_t_1)) = train_t_1;
    TT_2(1:length(train_t_2)) = train_t_2;
    
    % 检验约束，通过则更新
    if constraints_v11(x_jdt_1, y_1, TT_1, cfg, data)
        pop_new(i, 1:T_max) = x_jdt_1;
        pop_new(i, T_max+C_max+1:end) = v_jd_1;
        TT_new(i, :) = TT_1;
    end
    
    if constraints_v11(x_jdt_2, y_2, TT_2, cfg, data)
        pop_new(i+1, 1:T_max) = x_jdt_2;
        pop_new(i+1, T_max+C_max+1:end) = v_jd_2;
        TT_new(i+1, :) = TT_2;
    end
end

end
