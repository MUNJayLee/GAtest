function [fitness_value, obj] = fitness_v11(pop, TT, cfg, data)
%FITNESS_V11 v1.1 优化版适应度函数
%   使用参数结构体替代全局变量，向量化计算替代循环
%
%   输入:
%       pop    - 种群矩阵 (pop_size x chromo_size)
%       TT     - 班列时刻矩阵
%       cfg    - 配置结构体
%       data   - 数据相关结构体
%   输出:
%       fitness_value - 适应度向量 (pop_size x 1)
%       obj           - 各目标值结构体

pop_size = size(pop, 1);
T_max = cfg.T_max;
J_max = cfg.J_max;
C_max = data.C_max;
L_d = cfg.L_d;
traineachd = data.traineachd;

%% 解码染色体
x_jdt = pop(:, 1:T_max);
v_jd = pop(:, T_max + C_max + 1:T_max + C_max + J_max);

%% 计算 y_ijdc (集装箱分配)
[~, y_ijdc, C_TJ] = assign_v11(x_jdt, cfg, data);

%% 向量化计算 C_JD (各班列集装箱数量)
C_JD = zeros(pop_size, J_max);
for j = 1:J_max
    C_JD(:, j) = sum(y_ijdc == j, 2);
end
n_JD = ceil(C_JD / 2);

%% 预计算 EXL_d (各班列距离)
EXL_d = utils('expand_L_d', L_d, traineachd);

%% ========== 时效性目标 ==========
% PART1: 等待时间
fit1_1 = 5 * sum(max(C_TJ - data.C_IDT(4, :), 0), 2);

% PART2: 在途时间
fit1_2_1 = EXL_d ./ v_jd .* C_JD;
fit1_2 = 5 * sum(fit1_2_1, 2);

fit1 = fit1_1 + fit1_2;

%% ========== 经济性目标 ==========
% PART1: 固定成本
EXcf1 = repmat(cfg.cf1 * EXL_d, pop_size, 1);
EXcf2 = cfg.cf2 * EXL_d ./ v_jd;
EXcf3 = cfg.cf3 * EXL_d ./ v_jd;
fit2_1 = sum(EXcf1, 2) + sum(EXcf2, 2) + sum(EXcf3, 2);

% PART2: 可变成本
fit2_2 = sum(cfg.cv1 * C_JD, 2);

% PART3: 堆场成本
Q = zeros(pop_size, 1);
protoC_TI = data.protoC_TI';
protoC_TI(:, 1) = [];
protoC_SUMI = data.protoC_SUMI';

for i = 1:pop_size
    TEMPYARDCON = [sort(TT(i, :)), 0, protoC_TI; -C_JD(i, :), protoC_SUMI];
    TEMPYARDCON_1 = sortrows(TEMPYARDCON', 1)';
    TEMPYARDCON_1(3, :) = cumsum(TEMPYARDCON_1(2, :));
    TEMPYARDCON_2 = sortrows([TEMPYARDCON_1(1, :), TEMPYARDCON_1(1, :); TEMPYARDCON_1(3, :), TEMPYARDCON_1(3, :)]', 1)';
    TEMPYARDCON_3 = [[0; 0], TEMPYARDCON_2, [T_max; 0]];
    Q(i) = trapz(TEMPYARDCON_3(1, :), TEMPYARDCON_3(2, :));
end
fit2_3 = cfg.cq * Q;

% PART4: 装卸作业成本
z_ijdc = double(data.C_IDT(4, :) + cfg.mintranstime >= C_TJ);
SUMC_DIR = sum(z_ijdc, 2);
SUMC_INDIR = C_max - SUMC_DIR;
fit2_4 = cfg.c_dir * SUMC_DIR + cfg.c_indir * SUMC_INDIR;

% PART5: 剩余箱惩罚
RESC = sum(y_ijdc == 0, 2);
fit2_5 = cfg.c_penalty * RESC;

fit2 = fit2_1 + fit2_2 + fit2_3 + fit2_4 + fit2_5;

%% ========== 低碳性目标 ==========
% PART1: 班列碳排放
f_jiche = cfg.A_jiche + v_jd .* cfg.B_jiche + v_jd.^2 .* cfg.C_jiche;
f_cheliang = cfg.A_cheliang + v_jd .* cfg.B_cheliang + v_jd.^2 .* cfg.C_cheliang;
F_zu = (f_jiche .* cfg.G_0 + f_cheliang .* (5 * C_JD .* cfg.m_jun + n_JD .* cfg.m_0)) * 10;

% 生成距离矩阵
EXWL_D = zeros(pop_size, J_max);
for i = 1:pop_size
    non_zero = x_jdt(i, x_jdt(i, :) ~= 0);
    for j = 1:min(length(non_zero), J_max)
        EXWL_D(i, j) = L_d(non_zero(j));
    end
end

fit3_1 = (sum(EXWL_D .* cfg.gamma .* F_zu, 2) ./ (3.6e6)) * 0.785;

% PART2: 装卸作业碳排放
fit3_2 = (cfg.e_dir * SUMC_DIR + cfg.e_indir * SUMC_INDIR) / 1000;

fit3 = fit3_1 + fit3_2;

%% ========== 综合适应度 ==========
fitness_value = 1 ./ (cfg.w_time * fit1 + cfg.w_cost * fit2 + cfg.w_carbon * fit3);

%% 返回各目标值供分析
obj.fit1 = fit1;
obj.fit2 = fit2;
obj.fit3 = fit3;
obj.fit1_1 = fit1_1;
obj.fit1_2 = fit1_2;
obj.fit2_1 = fit2_1;
obj.fit2_2 = fit2_2;
obj.fit2_3 = fit2_3;
obj.fit2_4 = fit2_4;
obj.fit2_5 = fit2_5;
obj.fit3_1 = fit3_1;
obj.fit3_2 = fit3_2;
obj.SUMC_DIR = SUMC_DIR;
obj.SUMC_INDIR = SUMC_INDIR;
obj.RESC = RESC;
obj.C_JD = C_JD;
obj.n_JD = n_JD;

end
