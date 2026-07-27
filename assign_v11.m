function [pop_new, y_ijdc, C_TJ] = assign_v11(x_jdt, cfg, data)
%ASSIGN_V11 v1.1 优化版集装箱分配函数
%   向量化优化，减少循环嵌套
%
%   输入:
%       x_jdt - 班列方向矩阵 (pop_size x T_max)
%       cfg   - 配置结构体
%       data  - 数据相关结构体
%   输出:
%       pop_new - 分配后的种群部分
%       y_ijdc  - 集装箱分配矩阵 (pop_size x C_max)
%       C_TJ    - 集装箱发出时间矩阵 (pop_size x C_max)

pop_size = size(x_jdt, 1);
J_max = cfg.J_max;
C_max = data.C_max;
mintranstime = cfg.mintranstime;
maxtsegs = cfg.maxtsegs;

y_ijdc = zeros(pop_size, C_max);
C_TJ = zeros(pop_size, C_max);

% 预提取数据
C_IDT_dir = data.C_IDT(3, :);   % 集装箱方向
C_IDT_ti  = data.C_IDT(4, :);   % 集装箱到达时间

for i = 1:pop_size
    % 获取班列信息
    train_times = find(x_jdt(i, :) ~= 0);
    train_dirs = x_jdt(i, train_times);
    num_trains = length(train_times);
    
    if num_trains == 0
        continue;
    end
    
    % 构建班列信息矩阵 [编号; 方向; 时间; 时间差; 装载量]
    train_info = zeros(5, num_trains);
    train_info(1, :) = 1:num_trains;
    train_info(2, :) = train_dirs(1:num_trains);
    train_info(3, :) = train_times(1:num_trains);
    train_info(5, :) = 0;  % 装载量
    
    for j = 1:C_max
        % 寻找同方向班列
        same_dir_idx = find(train_info(2, :) == C_IDT_dir(j));
        
        if isempty(same_dir_idx)
            y_ijdc(i, j) = 0;
            C_TJ(i, j) = cfg.T_max;
            continue;
        end
        
        % 计算时间差
        time_diff = C_IDT_ti(j) - train_info(3, same_dir_idx);
        
        % 筛选满足转运时间约束的班列
        valid_idx = find(time_diff >= -mintranstime);
        
        % 筛选未满载的班列
        not_full_idx = find(train_info(5, same_dir_idx) <= 2 * maxtsegs - 1);
        
        % 取交集
        candidate_idx = intersect(valid_idx, not_full_idx);
        
        if isempty(candidate_idx)
            y_ijdc(i, j) = 0;
            C_TJ(i, j) = cfg.T_max;
        else
            % 选择第一个满足条件的班列（最早可装载）
            selected = same_dir_idx(candidate_idx(1));
            y_ijdc(i, j) = train_info(1, selected);
            C_TJ(i, j) = train_info(3, selected);
            train_info(5, selected) = train_info(5, selected) + 1;
        end
    end
end

end
