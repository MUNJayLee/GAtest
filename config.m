function cfg = config()
%CONFIG 遗传算法参数配置中心
%   集中管理所有模型参数和GA超参数，便于调优和复用
%   v1.1 新增：支持参数结构体传递，减少全局变量依赖

%% 模型参数 (Model Parameters)
cfg.T_max        = 168;                    % 调度周期总长 (小时)
cfg.J_max        = 15;                     % 班列总数
cfg.D0           = [1, 2, 3, 4];           % 方向集合
cfg.L_d          = [555, 736, 402, 310];   % 各方向运输距离 (km)
cfg.Yardcap      = 160;                    % 堆场容量 (TEU)
cfg.mintranstime = 2;                      % 最小转运时间 (小时)
cfg.minintervaltime = 1;                   % 最小发车间隔 (小时)
cfg.maxtsegs     = 10;                     % 单班列最大运载箱数
cfg.mintsegs     = 5;                      % 单班列最小运载箱数

%% 维修时间窗 (Maintenance Windows)
cfg.Tmaintenance = 14;                     % 维修时间窗总长
cfg.maintenance  = [7,8,31,32,55,56,79,80,103,104,127,128,151,152];

%% 遗传算法参数 (GA Hyperparameters)
cfg.generation_size = 50;                  % 最大迭代代数 (v1.1: 从10增加到50)
cfg.pop_size        = 40;                  % 种群规模 (v1.1: 从20增加到40)
cfg.cross_rate      = 0.85;                % 初始交叉概率 (v1.1: 自适应调整)
cfg.mutate_rate     = 0.3;                 % 初始变异概率 (v1.1: 自适应调整)
cfg.elitism         = true;                % 精英保留开关
cfg.elite_ratio     = 0.05;                % v1.1 新增：精英比例

%% 自适应参数 (Adaptive Parameters) - v1.1 新增
cfg.adaptive_enable = true;                % 启用自适应参数
cfg.cross_rate_min  = 0.6;                 % 交叉概率下限
cfg.cross_rate_max  = 0.95;                % 交叉概率上限
cfg.mutate_rate_min = 0.05;                % 变异概率下限
cfg.mutate_rate_max = 0.5;                 % 变异概率上限
cfg.adaptive_window = 5;                   % 适应度停滞检测窗口

%% 经济成本参数 (Cost Parameters)
cfg.cf1 = 18.228;                          % 固定成本系数 (与距离相关)
cfg.cf2 = 144.738;                         % 固定成本系数 (与距离/速度相关)
cfg.cf3 = 43.716;                          % 固定成本系数 (与距离/速度相关)
cfg.cv1 = 850 * 5;                         % 可变成本系数 (与集装箱量相关)
cfg.cq  = 1.25e8 * 5;                      % 堆场成本系数
cfg.c_dir   = 120 * 5;                     % 直取装卸作业成本
cfg.c_indir = 240 * 5;                     % 非直取装卸作业成本
cfg.c_penalty = 100000 * 5;                % 剩余箱惩罚系数

%% 碳排放参数 (Carbon Parameters)
cfg.A_jiche   = 1.44;
cfg.B_jiche   = 0.0099;
cfg.C_jiche   = 0.000298;
cfg.A_cheliang = 0.92;
cfg.B_cheliang = 0.0048;
cfg.C_cheliang = 0.000125;
cfg.G_0       = 128;
cfg.m_jun     = 17.5;
cfg.m_0       = 22.5;
cfg.gamma     = 0.65;
cfg.e_dir     = 5 * 7.095;
cfg.e_indir   = 5 * 10.111;

%% 目标权重 (Objective Weights)
cfg.w_time   = 0.25 * 150000 / 365 / 24;   % 时效性权重
cfg.w_cost   = 1.0;                         % 经济性权重
cfg.w_carbon = 55.3 * 1.1;                  % 低碳性权重

%% 速度参数 (Speed Parameters)
cfg.v_min = 16 * 5;                        % 最小速度 (km/h)
cfg.v_max = 24 * 5;                        % 最大速度 (km/h)

end
