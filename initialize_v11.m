function [pop, TT] = initialize_v11(cfg, data)
%INITIALIZE_V11 v1.1 优化版种群初始化
%   使用参数结构体，预分配内存，提高初始化效率
%
%   输入:
%       cfg  - 配置结构体
%       data - 数据相关结构体
%   输出:
%       pop  - 初始化后的种群
%       TT   - 班列时刻矩阵

T_max = cfg.T_max;
J_max = cfg.J_max;
C_max = data.C_max;
pop_size = cfg.pop_size;
maintenance = cfg.maintenance;
Tmaintenance = cfg.Tmaintenance;
trainnum = data.trainnum;

% 预分配内存
valid_pop = zeros(2 * pop_size, T_max + C_max + J_max);
TT_valid = zeros(2 * pop_size, J_max);
fitness_valid = zeros(1, 2 * pop_size);
valid_count = 0;
max_attempts = 5 * pop_size;  % 最大尝试次数，防止无限循环
attempts = 0;

while valid_count < pop_size && attempts < max_attempts
    attempts = attempts + 1;
    
    % 批量生成候选个体
    batch_size = min(pop_size, max_attempts - attempts + 1);
    x_jdt_batch = zeros(batch_size, T_max);
    
    for n = 1:batch_size
        % 生成班列方向序列
        EXtrainnum = [trainnum', zeros(1, T_max - length(trainnum) - Tmaintenance)];
        perm_idx = randperm(T_max - Tmaintenance);
        TEMPx_jdt0 = EXtrainnum(perm_idx);
        
        % 插入维修时间窗
        for i = 1:Tmaintenance
            TEMPx_jdt0 = insert(TEMPx_jdt0, maintenance(i), 0);
        end
        x_jdt_batch(n, :) = TEMPx_jdt0;
    end
    
    % 批量分配集装箱
    [~, y_ijdc_batch, ~] = assign_v11(x_jdt_batch, cfg, data);
    
    % 生成速度
    v_jd_batch = randi([cfg.v_min / 5, cfg.v_max / 5], batch_size, J_max) * 5;
    
    % 组装种群
    pop_batch = [x_jdt_batch, y_ijdc_batch, v_jd_batch];
    
    % 批量计算TT
    TT_batch = zeros(batch_size, J_max);
    for i = 1:batch_size
        train_times = find(x_jdt_batch(i, :) ~= 0);
        TT_batch(i, 1:length(train_times)) = train_times;
    end
    
    % 检验约束
    for i = 1:batch_size
        if valid_count >= pop_size
            break;
        end
        
        % 提取当前个体
        x_jdt_i = x_jdt_batch(i, :);
        y_ijdc_i = y_ijdc_batch(i, :);
        TT_i = TT_batch(i, :);
        
        % 调用约束检验
        if constraints_v11(x_jdt_i, y_ijdc_i, TT_i, cfg, data)
            valid_count = valid_count + 1;
            valid_pop(valid_count, :) = pop_batch(i, :);
            TT_valid(valid_count, :) = TT_i;
        end
    end
end

if valid_count < pop_size
    warning('initialize_v11: 仅生成 %d/%d 个有效个体，将用最后一个有效个体填充。', valid_count, pop_size);
    % 用最后一个有效个体填充
    for i = valid_count + 1:pop_size
        valid_pop(i, :) = valid_pop(valid_count, :);
        TT_valid(i, :) = TT_valid(valid_count, :);
    end
end

pop = valid_pop(1:pop_size, :);
TT = TT_valid(1:pop_size, :);

end
