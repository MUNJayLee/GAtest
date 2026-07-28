#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GAtest Python移植版 v1.1
基于遗传算法的集装箱海铁联运班列调度优化系统
原MATLAB代码原封不动移植到Python

使用方法:
    python ga_v11.py
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import integrate
import time
import warnings
warnings.filterwarnings('ignore')

# 设置matplotlib中文字体
plt.rcParams['font.sans-serif'] = ['SimHei', 'Arial Unicode MS', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False


# ============================================================
# config.py - 参数配置中心
# ============================================================
class Config:
    """遗传算法参数配置中心"""
    # 模型参数
    T_max = 168                    # 调度周期总长 (小时)
    J_max = 15                     # 班列总数
    D0 = np.array([1, 2, 3, 4])    # 方向集合
    L_d = np.array([555, 736, 402, 310])  # 各方向运输距离 (km)
    Yardcap = 160                  # 堆场容量 (TEU)
    mintranstime = 2               # 最小转运时间 (小时)
    minintervaltime = 1            # 最小发车间隔 (小时)
    maxtsegs = 10                  # 单班列最大运载箱数
    mintsegs = 5                   # 单班列最小运载箱数

    # 维修时间窗
    Tmaintenance = 14
    maintenance = np.array([7, 8, 31, 32, 55, 56, 79, 80, 103, 104, 127, 128, 151, 152])

    # 遗传算法参数
    generation_size = 50           # 最大迭代代数
    pop_size = 40                  # 种群规模
    cross_rate = 0.85              # 初始交叉概率
    mutate_rate = 0.3              # 初始变异概率
    elitism = True                 # 精英保留开关
    elite_ratio = 0.05             # 精英比例

    # 自适应参数
    adaptive_enable = True
    cross_rate_min = 0.6
    cross_rate_max = 0.95
    mutate_rate_min = 0.05
    mutate_rate_max = 0.5
    adaptive_window = 5

    # 经济成本参数
    cf1 = 18.228
    cf2 = 144.738
    cf3 = 43.716
    cv1 = 850 * 5
    cq = 1.25e8 * 5
    c_dir = 120 * 5
    c_indir = 240 * 5
    c_penalty = 100000 * 5

    # 碳排放参数
    A_jiche = 1.44
    B_jiche = 0.0099
    C_jiche = 0.000298
    A_cheliang = 0.92
    B_cheliang = 0.0048
    C_cheliang = 0.000125
    G_0 = 128
    m_jun = 17.5
    m_0 = 22.5
    gamma = 0.65
    e_dir = 5 * 7.095
    e_indir = 5 * 10.111

    # 目标权重
    w_time = 0.25 * 150000 / 365 / 24
    w_cost = 1.0
    w_carbon = 55.3 * 1.1

    # 速度参数
    v_min = 16 * 5
    v_max = 24 * 5


# ============================================================
# 数据读取 - readC_v11
# ============================================================
def readC_v11():
    """读取数据集"""
    df = pd.read_excel('数据集.xlsx', sheet_name='Sheet1')

    # 排除汇总行
    data_rows = df[df['班轮编号'] != '总计']

    protoC_I = data_rows['班轮编号'].values.astype(float)
    protoC_TI = data_rows['到港时间'].values.astype(float)
    protoC_NUMBER = data_rows[['方向1', '方向2', '方向3', '方向4']].values.astype(float)
    coneachd = protoC_NUMBER.sum(axis=0)
    protoC_SUMI = protoC_NUMBER.sum(axis=1)
    C_max = int(protoC_SUMI.sum())

    # 构建C_IDT矩阵
    TEMPC_I = []
    TEMPC_TI = []
    TEMPC_D = []
    D = np.array([1, 2, 3, 4])

    for i in range(len(protoC_I)):
        count = int(protoC_SUMI[i])
        TEMPC_I.extend([protoC_I[i]] * count)
        TEMPC_TI.extend([protoC_TI[i]] * count)
        for d in range(len(D)):
            dir_count = int(protoC_NUMBER[i, d])
            TEMPC_D.extend([D[d]] * dir_count)

    C = np.arange(1, C_max + 1)
    C_IDT = np.array([C, TEMPC_I, TEMPC_D, TEMPC_TI])

    return protoC_I, protoC_TI, protoC_NUMBER, coneachd, protoC_SUMI, C_max, C_IDT


# ============================================================
# 班列分配计算 - caltrains_v11
# ============================================================
def caltrains_v11(C_max, coneachd, J_max, D0):
    """计算各方向班列数量"""
    TEMPtraineachd = np.floor(J_max * coneachd / C_max).astype(int)
    TEMPtraineachd_2 = J_max * coneachd / C_max - np.fix(J_max * coneachd / C_max)
    RESJ = J_max - TEMPtraineachd.sum()
    POSJD = np.argsort(TEMPtraineachd_2)
    POSJD_2 = POSJD[-RESJ:]
    traineachd = TEMPtraineachd.copy()
    for i in range(RESJ):
        traineachd[POSJD_2[i]] += 1
    return traineachd


# ============================================================
# 集装箱分配 - assign_v11
# ============================================================
def assign_v11(x_jdt, cfg, data):
    """集装箱分配算法"""
    pop_size = x_jdt.shape[0] if x_jdt.ndim > 1 else 1
    if x_jdt.ndim == 1:
        x_jdt = x_jdt.reshape(1, -1)

    J_max = cfg.J_max
    C_max = data['C_max']
    mintranstime = cfg.mintranstime
    maxtsegs = cfg.maxtsegs

    y_ijdc = np.zeros((pop_size, C_max), dtype=int)
    C_TJ = np.zeros((pop_size, C_max))

    C_IDT_dir = data['C_IDT'][2, :]
    C_IDT_ti = data['C_IDT'][3, :]

    for i in range(pop_size):
        train_times = np.where(x_jdt[i, :] != 0)[0]
        train_dirs = x_jdt[i, train_times].astype(int)
        num_trains = len(train_times)

        if num_trains == 0:
            continue

        # 构建班列信息
        train_info = np.zeros((5, num_trains))
        train_info[0, :] = np.arange(1, num_trains + 1)
        train_info[1, :] = train_dirs
        train_info[2, :] = train_times
        train_info[4, :] = 0

        for j in range(C_max):
            same_dir_idx = np.where(train_info[1, :] == C_IDT_dir[j])[0]

            if len(same_dir_idx) == 0:
                y_ijdc[i, j] = 0
                C_TJ[i, j] = cfg.T_max
                continue

            time_diff = C_IDT_ti[j] - train_info[2, same_dir_idx]
            valid_idx = np.where(time_diff >= -mintranstime)[0]
            not_full_idx = np.where(train_info[4, same_dir_idx] <= 2 * maxtsegs - 1)[0]
            candidate_idx = np.intersect1d(valid_idx, not_full_idx)

            if len(candidate_idx) == 0:
                y_ijdc[i, j] = 0
                C_TJ[i, j] = cfg.T_max
            else:
                selected = same_dir_idx[candidate_idx[0]]
                y_ijdc[i, j] = int(train_info[0, selected])
                C_TJ[i, j] = train_info[2, selected]
                train_info[4, selected] += 1

    return None, y_ijdc, C_TJ


# ============================================================
# 约束检验 - constraints_v11
# ============================================================
def constraints_v11(x_jdt, y_ijdc, TT, cfg, data):
    """约束条件检验，返回布尔值"""
    T_max = cfg.T_max
    J_max = cfg.J_max

    # 约束1: 维修时间窗
    if np.any(x_jdt[cfg.maintenance - 1] != 0):
        return False

    # 约束2: 班列装载量
    C_JD = np.zeros(J_max)
    for j in range(J_max):
        C_JD[j] = np.sum(y_ijdc == j + 1)

    if np.any(C_JD > 2 * cfg.maxtsegs) or np.any((C_JD > 0) & (C_JD < 2 * cfg.mintsegs)):
        return False

    # 约束3: 堆场容量
    protoC_TI = data['protoC_TI'].copy()
    if protoC_TI.ndim > 1 and protoC_TI.shape[1] == 1:
        protoC_TI = protoC_TI.flatten()
    protoC_SUMI = data['protoC_SUMI'].copy()
    if protoC_SUMI.ndim > 1 and protoC_SUMI.shape[1] == 1:
        protoC_SUMI = protoC_SUMI.flatten()

    # 构建堆场约束检查
    TT_nonzero = TT[TT > 0]
    if len(TT_nonzero) == 0:
        return False

    yard_events = []
    for t in TT_nonzero:
        c = C_JD[TT_nonzero.tolist().index(t)] if t in TT_nonzero else 0
        yard_events.append((t, -c))

    for i in range(len(protoC_TI)):
        if i < len(protoC_SUMI):
            yard_events.append((protoC_TI[i], protoC_SUMI[i]))

    yard_events.sort(key=lambda x: x[0])
    cumsum = 0
    for _, delta in yard_events:
        cumsum += delta
        if cumsum < 0 or cumsum > cfg.Yardcap:
            return False

    # 约束4: 发车间隔
    train_times = np.where(x_jdt != 0)[0]
    if len(train_times) >= 2:
        time_diff = np.diff(train_times)
        if np.any(time_diff < cfg.minintervaltime):
            return False

    return True


# ============================================================
# 适应度计算 - fitness_v11
# ============================================================
def fitness_v11(pop, TT, cfg, data):
    """适应度函数计算"""
    pop_size = pop.shape[0]
    T_max = cfg.T_max
    J_max = cfg.J_max
    C_max = data['C_max']
    L_d = cfg.L_d
    traineachd = data['traineachd']

    x_jdt = pop[:, :T_max]
    v_jd = pop[:, T_max + C_max:T_max + C_max + J_max]

    _, y_ijdc, C_TJ = assign_v11(x_jdt, cfg, data)

    # 计算C_JD
    C_JD = np.zeros((pop_size, J_max))
    for j in range(J_max):
        C_JD[:, j] = np.sum(y_ijdc == j + 1, axis=1)
    n_JD = np.ceil(C_JD / 2)

    # EXL_d
    EXL_d = []
    for i in range(len(L_d)):
        EXL_d.extend([L_d[i]] * traineachd[i])
    EXL_d = np.array(EXL_d)

    # 时效性目标
    fit1_1 = 5 * np.sum(np.maximum(C_TJ - data['C_IDT'][3, :], 0), axis=1)
    fit1_2_1 = EXL_d / v_jd * C_JD
    fit1_2 = 5 * np.sum(fit1_2_1, axis=1)
    fit1 = fit1_1 + fit1_2

    # 经济性目标
    EXcf1 = np.tile(cfg.cf1 * EXL_d, (pop_size, 1))
    EXcf2 = cfg.cf2 * EXL_d / v_jd
    EXcf3 = cfg.cf3 * EXL_d / v_jd
    fit2_1 = np.sum(EXcf1, axis=1) + np.sum(EXcf2, axis=1) + np.sum(EXcf3, axis=1)
    fit2_2 = np.sum(cfg.cv1 * C_JD, axis=1)

    # 堆场成本
    Q = np.zeros(pop_size)
    protoC_TI = data['protoC_TI'].flatten()
    protoC_SUMI = data['protoC_SUMI'].flatten()

    for i in range(pop_size):
        TT_i = TT[i]
        TT_nonzero = TT_i[TT_i > 0]
        if len(TT_nonzero) == 0:
            Q[i] = 0
            continue

        C_JD_i = C_JD[i]
        C_JD_nonzero = C_JD_i[C_JD_i > 0]

        yard_events = []
        for k, t in enumerate(TT_nonzero):
            if k < len(C_JD_nonzero):
                yard_events.append((t, -C_JD_nonzero[k]))

        for k in range(len(protoC_TI)):
            yard_events.append((protoC_TI[k], protoC_SUMI[k]))

        yard_events.sort(key=lambda x: x[0])
        times = [0]
        values = [0]
        cumsum = 0
        for t, delta in yard_events:
            times.extend([t, t])
            values.extend([cumsum, cumsum + delta])
            cumsum += delta
        times.append(T_max)
        values.append(0)

        Q[i] = np.trapz(values, times)

    fit2_3 = cfg.cq * Q

    # 装卸作业成本
    z_ijdc = (data['C_IDT'][3, :] + cfg.mintranstime >= C_TJ).astype(float)
    SUMC_DIR = np.sum(z_ijdc, axis=1)
    SUMC_INDIR = C_max - SUMC_DIR
    fit2_4 = cfg.c_dir * SUMC_DIR + cfg.c_indir * SUMC_INDIR

    # 剩余箱惩罚
    RESC = np.sum(y_ijdc == 0, axis=1)
    fit2_5 = cfg.c_penalty * RESC

    fit2 = fit2_1 + fit2_2 + fit2_3 + fit2_4 + fit2_5

    # 低碳性目标
    f_jiche = cfg.A_jiche + v_jd * cfg.B_jiche + v_jd**2 * cfg.C_jiche
    f_cheliang = cfg.A_cheliang + v_jd * cfg.B_cheliang + v_jd**2 * cfg.C_cheliang
    F_zu = (f_jiche * cfg.G_0 + f_cheliang * (5 * C_JD * cfg.m_jun + n_JD * cfg.m_0)) * 10

    EXWL_D = np.zeros((pop_size, J_max))
    for i in range(pop_size):
        non_zero = x_jdt[i, x_jdt[i, :] != 0]
        for j in range(min(len(non_zero), J_max)):
            if int(non_zero[j]) - 1 < len(L_d):
                EXWL_D[i, j] = L_d[int(non_zero[j]) - 1]

    fit3_1 = (np.sum(EXWL_D * cfg.gamma * F_zu, axis=1) / (3.6e6)) * 0.785
    fit3_2 = (cfg.e_dir * SUMC_DIR + cfg.e_indir * SUMC_INDIR) / 1000
    fit3 = fit3_1 + fit3_2

    # 综合适应度
    fitness_value = 1.0 / (cfg.w_time * fit1 + cfg.w_cost * fit2 + cfg.w_carbon * fit3)

    obj = {
        'fit1': fit1, 'fit2': fit2, 'fit3': fit3,
        'fit1_1': fit1_1, 'fit1_2': fit1_2,
        'fit2_1': fit2_1, 'fit2_2': fit2_2, 'fit2_3': fit2_3, 'fit2_4': fit2_4, 'fit2_5': fit2_5,
        'fit3_1': fit3_1, 'fit3_2': fit3_2,
        'SUMC_DIR': SUMC_DIR, 'SUMC_INDIR': SUMC_INDIR, 'RESC': RESC,
        'C_JD': C_JD, 'n_JD': n_JD
    }

    return fitness_value, obj


# ============================================================
# 种群初始化 - initialize_v11
# ============================================================
def initialize_v11(cfg, data):
    """初始化种群"""
    T_max = cfg.T_max
    J_max = cfg.J_max
    C_max = data['C_max']
    pop_size = cfg.pop_size
    maintenance = cfg.maintenance
    Tmaintenance = cfg.Tmaintenance
    trainnum = data['trainnum']

    valid_pop = np.zeros((2 * pop_size, T_max + C_max + J_max))
    TT_valid = np.zeros((2 * pop_size, J_max))
    valid_count = 0
    max_attempts = 5 * pop_size
    attempts = 0

    while valid_count < pop_size and attempts < max_attempts:
        attempts += 1
        batch_size = min(pop_size, max_attempts - attempts + 1)
        x_jdt_batch = np.zeros((batch_size, T_max), dtype=int)

        for n in range(batch_size):
            EXtrainnum = np.concatenate([trainnum, np.zeros(T_max - len(trainnum) - Tmaintenance)])
            perm_idx = np.random.permutation(T_max - Tmaintenance)
            TEMPx_jdt0 = EXtrainnum[perm_idx].astype(int)

            for i in range(Tmaintenance):
                pos = maintenance[i] - 1
                TEMPx_jdt0 = np.insert(TEMPx_jdt0, pos, 0)

            if len(TEMPx_jdt0) > T_max:
                TEMPx_jdt0 = TEMPx_jdt0[:T_max]
            elif len(TEMPx_jdt0) < T_max:
                TEMPx_jdt0 = np.concatenate([TEMPx_jdt0, np.zeros(T_max - len(TEMPx_jdt0))])

            x_jdt_batch[n, :] = TEMPx_jdt0

        _, y_ijdc_batch, _ = assign_v11(x_jdt_batch, cfg, data)
        v_jd_batch = np.random.randint(cfg.v_min // 5, cfg.v_max // 5 + 1, (batch_size, J_max)) * 5
        pop_batch = np.hstack([x_jdt_batch, y_ijdc_batch, v_jd_batch])

        TT_batch = np.zeros((batch_size, J_max))
        for i in range(batch_size):
            train_times = np.where(x_jdt_batch[i, :] != 0)[0]
            TT_batch[i, :len(train_times)] = train_times

        for i in range(batch_size):
            if valid_count >= pop_size:
                break

            x_jdt_i = x_jdt_batch[i, :]
            y_ijdc_i = y_ijdc_batch[i, :]
            TT_i = TT_batch[i, :]

            if constraints_v11(x_jdt_i, y_ijdc_i, TT_i, cfg, data):
                valid_pop[valid_count, :] = pop_batch[i, :]
                TT_valid[valid_count, :] = TT_i
                valid_count += 1

    if valid_count < pop_size:
        print(f"警告: 仅生成 {valid_count}/{pop_size} 个有效个体")
        for i in range(valid_count, pop_size):
            valid_pop[i, :] = valid_pop[valid_count - 1, :]
            TT_valid[i, :] = TT_valid[valid_count - 1, :]

    return valid_pop[:pop_size, :], TT_valid[:pop_size, :]


# ============================================================
# 选择操作 - selection_v11 (锦标赛选择)
# ============================================================
def selection_v11(pop, fitness_value, cfg):
    """锦标赛选择"""
    pop_size = cfg.pop_size
    tournament_size = 3

    pop_new = np.zeros_like(pop)
    for i in range(pop_size):
        contestants = np.random.choice(pop_size, tournament_size, replace=False)
        winner = contestants[np.argmax(fitness_value[contestants])]
        pop_new[i, :] = pop[winner, :]

    return pop_new


# ============================================================
# 交叉操作 - crossover_v11
# ============================================================
def crossover_v11(pop, TT, cfg, data):
    """交叉操作"""
    pop_size = cfg.pop_size
    T_max = cfg.T_max
    J_max = cfg.J_max
    C_max = data['C_max']
    cross_rate = cfg.cross_rate
    traineachd = data['traineachd']

    pop_new = pop.copy()
    TT_new = TT.copy()

    for i in range(0, pop_size - 1, 2):
        if np.random.rand() >= cross_rate:
            continue

        # x_jdt交叉
        x_jdt_1 = pop[i, :T_max].copy()
        x_jdt_2 = pop[i + 1, :T_max].copy()

        cp1, cp2 = sorted(np.random.choice(T_max, 2, replace=False))
        temp = x_jdt_1[cp1:cp2 + 1].copy()
        x_jdt_1[cp1:cp2 + 1] = x_jdt_2[cp1:cp2 + 1]
        x_jdt_2[cp1:cp2 + 1] = temp

        # 修复约束
        for k in range(len(cfg.D0)):
            target = traineachd[k]
            for xj in [x_jdt_1, x_jdt_2]:
                count = np.sum(xj == cfg.D0[k])
                if count > target:
                    idx = np.where(xj == cfg.D0[k])[0]
                    to_remove = np.random.choice(idx, count - target, replace=False)
                    xj[to_remove] = 0
                elif count < target:
                    idx = np.where(xj == 0)[0]
                    needed = target - count
                    if len(idx) >= needed:
                        to_add = np.random.choice(idx, needed, replace=False)
                        xj[to_add] = cfg.D0[k]

        # v_jd交叉
        v_jd_1 = pop[i, T_max + C_max:].copy()
        v_jd_2 = pop[i + 1, T_max + C_max:].copy()
        cp_v = np.random.randint(1, J_max)
        temp_v = v_jd_1[cp_v:].copy()
        v_jd_1[cp_v:] = v_jd_2[cp_v:]
        v_jd_2[cp_v:] = temp_v

        # 检验约束
        _, y_1, _ = assign_v11(x_jdt_1, cfg, data)
        _, y_2, _ = assign_v11(x_jdt_2, cfg, data)

        TT_1 = np.zeros(J_max)
        TT_2 = np.zeros(J_max)
        train_t_1 = np.where(x_jdt_1 != 0)[0]
        train_t_2 = np.where(x_jdt_2 != 0)[0]
        TT_1[:len(train_t_1)] = train_t_1
        TT_2[:len(train_t_2)] = train_t_2

        if constraints_v11(x_jdt_1, y_1[0] if y_1.ndim > 1 else y_1, TT_1, cfg, data):
            pop_new[i, :T_max] = x_jdt_1
            pop_new[i, T_max + C_max:] = v_jd_1
            TT_new[i, :] = TT_1

        if constraints_v11(x_jdt_2, y_2[0] if y_2.ndim > 1 else y_2, TT_2, cfg, data):
            pop_new[i + 1, :T_max] = x_jdt_2
            pop_new[i + 1, T_max + C_max:] = v_jd_2
            TT_new[i + 1, :] = TT_2

    return pop_new, TT_new


# ============================================================
# 变异操作 - mutation_v11
# ============================================================
def mutation_v11(pop, TT, cfg, data):
    """变异操作"""
    pop_size = cfg.pop_size
    T_max = cfg.T_max
    J_max = cfg.J_max
    C_max = data['C_max']
    mutate_rate = cfg.mutate_rate

    pop_new = pop.copy()
    TT_new = TT.copy()

    for i in range(pop_size):
        if np.random.rand() >= mutate_rate:
            continue

        x_jdt = pop[i, :T_max].copy()
        v_jd = pop[i, T_max + C_max:].copy()
        mutated = False

        if np.random.rand() < 0.5:
            pos = np.random.randint(0, T_max)
            if x_jdt[pos] == 0:
                new_dir = cfg.D0[np.random.randint(0, len(cfg.D0))]
                same_dir = np.where(x_jdt == new_dir)[0]
                if len(same_dir) > 0:
                    x_jdt[np.random.choice(same_dir)] = 0
                    x_jdt[pos] = new_dir
                    mutated = True
            else:
                old_dir = x_jdt[pos]
                new_pos = np.where(x_jdt == 0)[0]
                if len(new_pos) > 0:
                    x_jdt[pos] = 0
                    x_jdt[np.random.choice(new_pos)] = old_dir
                    mutated = True

        if np.random.rand() < 0.5:
            pos = np.random.randint(0, J_max)
            v_jd[pos] = np.random.randint(cfg.v_min // 5, cfg.v_max // 5 + 1) * 5
            mutated = True

        if mutated:
            _, y_ijdc, _ = assign_v11(x_jdt, cfg, data)
            y_ijdc = y_ijdc[0] if y_ijdc.ndim > 1 else y_ijdc
            TT_i = np.zeros(J_max)
            train_t = np.where(x_jdt != 0)[0]
            TT_i[:len(train_t)] = train_t

            if constraints_v11(x_jdt, y_ijdc, TT_i, cfg, data):
                pop_new[i, :T_max] = x_jdt
                pop_new[i, T_max + C_max:] = v_jd
                TT_new[i, :] = TT_i

    return pop_new, TT_new


# ============================================================
# 排序 - rank_v11
# ============================================================
def rank_v11(pop, fitness_value, TT, cfg):
    """排序与精英保留"""
    sort_idx = np.argsort(fitness_value)
    fitness_value = fitness_value[sort_idx]
    pop = pop[sort_idx, :]
    TT = TT[sort_idx, :]

    best_info = {
        'fitness': fitness_value[-1],
        'individual': pop[-1, :].copy(),
        'TT': TT[-1, :].copy()
    }

    return pop, fitness_value, best_info, TT


# ============================================================
# 自适应参数 - adaptiveParams
# ============================================================
def adaptiveParams(fitness_history, cfg, G):
    """自适应调整遗传算法参数"""
    if not cfg.adaptive_enable or G < cfg.adaptive_window:
        return cfg.cross_rate, cfg.mutate_rate

    window = min(cfg.adaptive_window, G)
    recent = fitness_history[max(0, G - window):G]

    if len(recent) >= 2:
        improvement_rate = abs(recent[-1] - recent[0]) / max(abs(recent[0]), 1e-10)
    else:
        improvement_rate = 1.0

    fitness_variance = np.var(recent)
    max_var = max(recent)**2 * 0.1
    normalized_var = min(fitness_variance / max(max_var, 1e-10), 1.0)

    if improvement_rate < 0.01:
        cross_adjust = 0.1
    else:
        cross_adjust = -0.02
    cross_adjust -= 0.05 * (1 - normalized_var)
    new_cross = cfg.cross_rate + cross_adjust
    new_cross = max(cfg.cross_rate_min, min(cfg.cross_rate_max, new_cross))

    if improvement_rate < 0.005:
        mutate_adjust = 0.15
    elif improvement_rate < 0.02:
        mutate_adjust = 0.08
    else:
        mutate_adjust = -0.03
    mutate_adjust -= 0.1 * normalized_var
    new_mutate = cfg.mutate_rate + mutate_adjust
    new_mutate = max(cfg.mutate_rate_min, min(cfg.mutate_rate_max, new_mutate))

    return new_cross, new_mutate


# ============================================================
# 堆场堆存动态曲线（总箱量 + 各方向箱量） - _plot_yard_curve
# ============================================================
def _plot_yard_curve(bestx_jdt, besty_ijdc, bestC_JD, cfg, data):
    """绘制最优解下堆场中各方向集装箱及总箱量随时间变化的曲线"""
    T_max = cfg.T_max
    C_max = data['C_max']
    D0 = cfg.D0
    num_dirs = len(D0)

    C_IDT_dir = data['C_IDT'][2, :]  # 每个集装箱的方向
    C_IDT_ti = data['C_IDT'][3, :]   # 每个集装箱的到港时间
    protoC_TI = data['protoC_TI'].flatten()

    # ---- 收集所有事件 (时间, 方向, 增减量) ----
    # 班轮到港 -> 堆场增加（按方向统计每艘班轮的集装箱数）
    arrival_events = []
    unique_arrivals = np.unique(protoC_TI)
    for arr_time in unique_arrivals:
        for d in D0:
            count_d = np.sum((C_IDT_dir == d) & (np.isclose(C_IDT_ti, arr_time)))
            if count_d > 0:
                arrival_events.append((int(arr_time), int(d), count_d))

    # 班列发车 -> 堆场减少（按方向统计每列班列运走的各方向箱量）
    train_times = np.where(bestx_jdt != 0)[0]  # 发车时刻索引(0-based，也是时间)
    train_dirs = bestx_jdt[train_times].astype(int)  # 每列班列的方向

    departure_events = []
    # 找到实际使用的班列编号
    used_trains = set(besty_ijdc[besty_ijdc > 0])
    for j_idx in range(1, int(max(used_trains)) + 1):
        # 该班列的集装箱
        containers_on_train_j = np.where(besty_ijdc == j_idx)[0]
        if len(containers_on_train_j) == 0:
            continue
        # 该班列的出发时间
        if j_idx - 1 < len(train_times):
            dep_time = int(train_times[j_idx - 1])
            dep_dir = int(train_dirs[j_idx - 1])
        else:
            continue
        # 按方向统计
        for d in D0:
            count_d = np.sum(C_IDT_dir[containers_on_train_j] == d)
            if count_d > 0:
                departure_events.append((dep_time, int(d), count_d))

    # ---- 构建各方向的时间序列 ----
    dir_colors = ['#e74c3c', '#3498db', '#2ecc71', '#f39c12']
    dir_labels = [f'方向{d}' for d in D0]

    # 合并所有事件并排序
    all_events = []
    for t, d, delta in arrival_events:
        all_events.append((t, d, delta, 'arrival'))
    for t, d, delta in departure_events:
        all_events.append((t, d, delta, 'departure'))

    # 对每个方向分别构建堆场箱量曲线
    time_points = sorted(set(
        [e[0] for e in all_events] + [0, T_max]
    ))

    # 先计算每个方向在每个时间点的箱量
    dir_stock = {d: np.zeros(len(time_points)) for d in D0}
    dir_cumsum = {d: 0 for d in D0}

    for idx_t, t in enumerate(time_points):
        for evt_t, evt_d, delta, evt_type in all_events:
            if evt_t == t:
                if evt_type == 'arrival':
                    dir_cumsum[evt_d] += delta
                else:
                    dir_cumsum[evt_d] -= delta
        # 在这个时间点记录各方向箱量
        for d in D0:
            dir_stock[d][idx_t] = dir_cumsum[d]

    total_stock = sum(dir_stock[d] for d in D0)

    # ---- 绘图 ----
    fig, axes = plt.subplots(2, 1, figsize=(14, 10), gridspec_kw={'height_ratios': [3, 2]})
    fig.suptitle('最优解 - 堆场堆存动态曲线', fontsize=14, fontweight='bold')

    # 上图：总箱量
    ax1 = axes[0]
    ax1.fill_between(time_points, total_stock, alpha=0.3, color='#2c3e50')
    ax1.plot(time_points, total_stock, color='#2c3e50', linewidth=2, label='总箱量')
    ax1.axhline(y=cfg.Yardcap, color='red', linestyle='--', linewidth=1, label=f'堆场容量 ({cfg.Yardcap})')
    ax1.set_xlabel('时间 (小时)', fontsize=11)
    ax1.set_ylabel('集装箱数量 (TEU)', fontsize=11)
    ax1.set_title('堆场总箱量变化', fontsize=12)
    ax1.legend(loc='upper right', fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_xlim(0, T_max)
    ax1.set_ylim(bottom=0)

    # 下图：各方向箱量
    ax2 = axes[1]
    for i, d in enumerate(D0):
        ax2.plot(time_points, dir_stock[d], color=dir_colors[i], linewidth=1.5, label=dir_labels[i])
        ax2.fill_between(time_points, dir_stock[d], alpha=0.1, color=dir_colors[i])
    ax2.set_xlabel('时间 (小时)', fontsize=11)
    ax2.set_ylabel('集装箱数量 (TEU)', fontsize=11)
    ax2.set_title('各方向箱量变化', fontsize=12)
    ax2.legend(loc='upper right', fontsize=10)
    ax2.grid(True, alpha=0.3)
    ax2.set_xlim(0, T_max)
    ax2.set_ylim(bottom=0)

    plt.tight_layout()
    plt.savefig('yard_curve.png', dpi=150)
    plt.close()


# ============================================================
# 结果输出 - result_v11
# ============================================================
def result_v11(best_individual, best_TT, cfg, data):
    """结果输出"""
    T_max = cfg.T_max
    J_max = cfg.J_max
    C_max = data['C_max']
    L_d = cfg.L_d

    bestx_jdt = best_individual[:T_max]
    bestv_jd = best_individual[T_max + C_max:]

    _, besty_ijdc, C_TJ_best = assign_v11(bestx_jdt, cfg, data)
    besty_ijdc = besty_ijdc[0] if besty_ijdc.ndim > 1 else besty_ijdc

    bestC_JD = np.zeros(J_max)
    for j in range(J_max):
        bestC_JD[j] = np.sum(besty_ijdc == j + 1)

    z_ijdc = (data['C_IDT'][3, :] + cfg.mintranstime >= C_TJ_best[0] if C_TJ_best.ndim > 1 else C_TJ_best).astype(float)
    if C_TJ_best.ndim > 1:
        z_ijdc = (data['C_IDT'][3, :] + cfg.mintranstime >= C_TJ_best[0]).astype(float)
    direct_rate = np.sum(z_ijdc) / C_max

    trans_times = C_TJ_best[0] - data['C_IDT'][3, :] if C_TJ_best.ndim > 1 else C_TJ_best - data['C_IDT'][3, :]
    trans_times = trans_times[trans_times > 0]
    avg_trans = np.mean(trans_times) if len(trans_times) > 0 else 0

    RESC = np.sum(besty_ijdc == 0)

    print("\n" + "=" * 50)
    print("    GAtest v1.1 Python版 - 优化结果")
    print("=" * 50)
    print(f"直取比例:      {direct_rate * 100:.2f}%")
    print(f"平均转运时间:  {avg_trans:.2f} 小时")
    print(f"剩余箱量:      {RESC}")
    print("-" * 50)

    EXL_d = []
    for i in range(len(L_d)):
        EXL_d.extend([L_d[i]] * data['traineachd'][i])
    EXL_d = np.array(EXL_d)

    fit1_1 = 5 * np.sum(np.maximum(C_TJ_best[0] - data['C_IDT'][3, :], 0)) if C_TJ_best.ndim > 1 else 5 * np.sum(np.maximum(C_TJ_best - data['C_IDT'][3, :], 0))
    fit1_2 = 5 * np.sum(EXL_d / bestv_jd[:len(EXL_d)] * bestC_JD[:len(EXL_d)])
    fit1 = fit1_1 + fit1_2

    EXcf1 = cfg.cf1 * EXL_d
    EXcf2 = cfg.cf2 * EXL_d / bestv_jd[:len(EXL_d)]
    EXcf3 = cfg.cf3 * EXL_d / bestv_jd[:len(EXL_d)]
    fit2_1 = np.sum(EXcf1) + np.sum(EXcf2) + np.sum(EXcf3)
    fit2_2 = np.sum(cfg.cv1 * bestC_JD)
    fit2 = fit2_1 + fit2_2

    n_JD = np.ceil(bestC_JD / 2)
    f_jiche = cfg.A_jiche + bestv_jd * cfg.B_jiche + bestv_jd**2 * cfg.C_jiche
    f_cheliang = cfg.A_cheliang + bestv_jd * cfg.B_cheliang + bestv_jd**2 * cfg.C_cheliang
    F_zu = (f_jiche * cfg.G_0 + f_cheliang * (5 * bestC_JD * cfg.m_jun + n_JD * cfg.m_0)) * 10

    EXWL_D = np.zeros(J_max)
    non_zero = bestx_jdt[bestx_jdt != 0]
    for j in range(min(len(non_zero), J_max)):
        if int(non_zero[j]) - 1 < len(L_d):
            EXWL_D[j] = L_d[int(non_zero[j]) - 1]

    fit3_1 = np.sum(EXWL_D * cfg.gamma * F_zu) / (3.6e6) * 0.785
    fit3_2 = (cfg.e_dir * np.sum(z_ijdc) + cfg.e_indir * (C_max - np.sum(z_ijdc))) / 1000
    fit3 = fit3_1 + fit3_2

    print(f"时效性目标:    {fit1:.2f}")
    print(f"经济性目标:    {fit2:.2f}")
    print(f"低碳性目标:    {fit3:.2f}")
    print(f"综合适应度:    {1.0 / (cfg.w_time * fit1 + cfg.w_cost * fit2 + cfg.w_carbon * fit3):.6f}")
    print("=" * 50)

    # 绘制堆场曲线（总箱量 + 各方向箱量）
    _plot_yard_curve(bestx_jdt, besty_ijdc, bestC_JD, cfg, data)

    print("堆场曲线已保存: yard_curve.png")


# ============================================================
# 收敛分析可视化 - plotConvergence
# ============================================================
def plotConvergence(fitness_history, cfg, obj_history):
    """收敛分析可视化"""
    gen = np.arange(1, len(fitness_history) + 1)

    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    fig.suptitle('遗传算法收敛分析 (Python v1.1)', fontsize=14, fontweight='bold')

    # 最优适应度
    ax = axes[0, 0]
    ax.plot(gen, fitness_history, 'b-', linewidth=1.5)
    if len(fitness_history) >= 3:
        ma = np.convolve(fitness_history, np.ones(3)/3, mode='same')
        ax.plot(gen, ma, 'r--', linewidth=1)
    ax.set_xlabel('迭代代数')
    ax.set_ylabel('最优适应度')
    ax.set_title('适应度收敛曲线')
    ax.legend(['最优值', '3代移动平均'])
    ax.grid(True)

    # 改善率
    ax = axes[0, 1]
    if len(fitness_history) > 1:
        improvement = np.diff(fitness_history) / np.maximum(fitness_history[:-1], 1e-10)
        ax.bar(gen[1:], improvement, color='#3399CC')
        ax.set_xlabel('迭代代数')
        ax.set_ylabel('改善率')
        ax.set_title('每代适应度改善率')
        ax.grid(True)

    # 多样性
    ax = axes[0, 2]
    ax.text(0.5, 0.5, '多样性数据未记录', ha='center', va='center', transform=ax.transAxes)
    ax.set_title('种群多样性变化')
    ax.axis('off')

    # 三目标收敛
    for idx, (key, title, color) in enumerate([
        ('fit1', '时效性目标收敛', 'm'),
        ('fit2', '经济性目标收敛', 'c'),
        ('fit3', '低碳性目标收敛', 'k')
    ]):
        ax = axes[1, idx]
        if len(obj_history) > 0 and key in obj_history[0]:
            vals = np.array([obj_history[i][key] if i < len(obj_history) else np.nan for i in range(len(gen))])
            ax.plot(gen, vals, color=color, linewidth=1.5)
            ax.set_xlabel('迭代代数')
            ax.set_ylabel(f'{title[:-4]}值')
            ax.set_title(title)
            ax.grid(True)

    plt.tight_layout()
    plt.savefig('convergence.png', dpi=150)
    plt.close()
    print("收敛分析图已保存: convergence.png")


# ============================================================
# 主程序 - GA_v11
# ============================================================
def main():
    """主程序入口"""
    start_time = time.time()

    print("=" * 50)
    print("    GAtest v1.1 Python版 - 遗传算法优化系统")
    print("=" * 50)
    print()

    # 加载配置
    cfg = Config()
    print("[1/6] 配置加载完成")

    # 读取数据
    protoC_I, protoC_TI, protoC_NUMBER, coneachd, protoC_SUMI, C_max, C_IDT = readC_v11()
    data = {
        'protoC_TI': protoC_TI,
        'protoC_SUMI': protoC_SUMI,
        'coneachd': coneachd,
        'C_max': C_max,
        'C_IDT': C_IDT
    }
    print(f"[2/6] 数据读取完成: {C_max} 个集装箱")

    # 计算班列分配
    traineachd = caltrains_v11(C_max, coneachd, cfg.J_max, cfg.D0)
    data['traineachd'] = traineachd

    trainnum = []
    for i in range(len(cfg.D0)):
        trainnum.extend([cfg.D0[i]] * traineachd[i])
    data['trainnum'] = np.array(trainnum)

    print(f"[3/6] 班列分配计算完成: {cfg.J_max} 列班列")

    # 初始化种群
    pop, TT = initialize_v11(cfg, data)
    fitness_value, obj = fitness_v11(pop, TT, cfg, data)
    obj_history = [obj]

    Gbest = np.max(fitness_value)
    best_idx = np.argmax(fitness_value)
    best_individual = pop[best_idx, :].copy()
    best_TT = TT[best_idx, :].copy()
    fitness_history = [Gbest]
    cross_history = [cfg.cross_rate]
    mutate_history = [cfg.mutate_rate]

    print(f"[4/6] 种群初始化完成: 最优适应度 = {Gbest:.6f}")

    # 主循环
    print("[5/6] 开始遗传算法迭代...")
    for G in range(1, cfg.generation_size + 1):
        if cfg.adaptive_enable and G > 1:
            cfg.cross_rate, cfg.mutate_rate = adaptiveParams(fitness_history, cfg, G)
        cross_history.append(cfg.cross_rate)
        mutate_history.append(cfg.mutate_rate)

        pop, fitness_value, _, TT = rank_v11(pop, fitness_value, TT, cfg)

        elite_count = max(1, int(cfg.pop_size * cfg.elite_ratio))
        elite_pop = pop[-elite_count:, :].copy()
        elite_TT = TT[-elite_count:, :].copy()

        pop = selection_v11(pop, fitness_value, cfg)
        pop, TT = crossover_v11(pop, TT, cfg, data)
        pop, TT = mutation_v11(pop, TT, cfg, data)

        fitness_value, obj = fitness_v11(pop, TT, cfg, data)
        obj_history.append(obj)

        worst_idx = np.argsort(fitness_value)[:elite_count]
        pop[worst_idx, :] = elite_pop
        TT[worst_idx, :] = elite_TT

        fitness_replace, _ = fitness_v11(elite_pop, elite_TT, cfg, data)
        fitness_value[worst_idx] = fitness_replace

        current_best = np.max(fitness_value)
        if current_best > Gbest:
            Gbest = current_best
            best_individual = pop[np.argmax(fitness_value), :].copy()
            best_TT = TT[np.argmax(fitness_value), :].copy()
            print(f"  Gen {G:3d} | New Best: {Gbest:.6f} | CR: {cfg.cross_rate:.2f} | MR: {cfg.mutate_rate:.2f}")
        elif G % 10 == 0:
            print(f"  Gen {G:3d} | Best: {Gbest:.6f} | CR: {cfg.cross_rate:.2f} | MR: {cfg.mutate_rate:.2f}")

        fitness_history.append(Gbest)

    print("[6/6] 迭代完成!")
    print()

    # 输出结果
    result_v11(best_individual, best_TT, cfg, data)
    plotConvergence(np.array(fitness_history), cfg, obj_history)

    # 自适应参数变化
    fig, axes = plt.subplots(1, 2, figsize=(10, 4))
    gen_range = np.arange(1, len(cross_history) + 1)
    axes[0].plot(gen_range, cross_history, 'b-', linewidth=1.5)
    axes[0].set_xlabel('代数')
    axes[0].set_ylabel('交叉率')
    axes[0].set_title('自适应交叉率')
    axes[0].grid(True)

    axes[1].plot(gen_range, mutate_history, 'r-', linewidth=1.5)
    axes[1].set_xlabel('代数')
    axes[1].set_ylabel('变异率')
    axes[1].set_title('自适应变异率')
    axes[1].grid(True)

    plt.tight_layout()
    plt.savefig('adaptive_params.png', dpi=150)
    plt.close()
    print("自适应参数图已保存: adaptive_params.png")

    elapsed = time.time() - start_time
    print(f"\n总运行时间: {elapsed:.2f} 秒 ({elapsed/60:.2f} 分钟)")


if __name__ == '__main__':
    main()
