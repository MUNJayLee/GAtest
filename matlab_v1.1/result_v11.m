function result_v11(best_individual, best_TT, cfg, data)
%RESULT_V11 v1.1 优化版结果输出
T_max = cfg.T_max;
J_max = cfg.J_max;
C_max = data.C_max;
L_d = cfg.L_d;
bestx_jdt = best_individual(1:T_max);
bestv_jd = best_individual(T_max + C_max + 1:end);
[~, besty_ijdc, C_TJ_best] = assign_v11(bestx_jdt, cfg, data);
bestC_JD = zeros(1, J_max);
for j = 1:J_max
    bestC_JD(j) = sum(besty_ijdc == j);
end
z_ijdc = double(data.C_IDT(4, :) + cfg.mintranstime >= C_TJ_best);
direct_rate = sum(z_ijdc) / C_max;
trans_times = C_TJ_best - data.C_IDT(4, :);
trans_times(trans_times <= 0) = [];
avg_trans = mean(trans_times);
RESC = sum(besty_ijdc == 0);
EXL_d = utils('expand_L_d', L_d, data.traineachd);
fit1_1 = 5 * sum(max(C_TJ_best - data.C_IDT(4, :), 0));
fit1_2 = 5 * sum(EXL_d ./ bestv_jd .* bestC_JD);
fit1 = fit1_1 + fit1_2;
EXcf1 = cfg.cf1 * EXL_d;
EXcf2 = cfg.cf2 * EXL_d ./ bestv_jd;
EXcf3 = cfg.cf3 * EXL_d ./ bestv_jd;
fit2_1 = sum(EXcf1) + sum(EXcf2) + sum(EXcf3);
fit2_2 = sum(cfg.cv1 * bestC_JD);
fit2 = fit2_1 + fit2_2;
n_JD = ceil(bestC_JD / 2);
f_jiche = cfg.A_jiche + bestv_jd .* cfg.B_jiche + bestv_jd.^2 .* cfg.C_jiche;
f_cheliang = cfg.A_cheliang + bestv_jd .* cfg.B_cheliang + bestv_jd.^2 .* cfg.C_cheliang;
F_zu = (f_jiche .* cfg.G_0 + f_cheliang .* (5 * bestC_JD .* cfg.m_jun + n_JD .* cfg.m_0)) * 10;
EXWL_D = zeros(1, J_max);
non_zero = bestx_jdt(bestx_jdt ~= 0);
for j = 1:min(length(non_zero), J_max)
    EXWL_D(j) = L_d(non_zero(j));
end
fit3_1 = sum(EXWL_D .* cfg.gamma .* F_zu) / (3.6e6) * 0.785;
fit3_2 = (cfg.e_dir * sum(z_ijdc) + cfg.e_indir * (C_max - sum(z_ijdc))) / 1000;
fit3 = fit3_1 + fit3_2;
fprintf('\n========== GAtest v1.1 优化结果 ==========\n');
fprintf('直取比例:      %.2f%%\n', direct_rate * 100);
fprintf('平均转运时间:  %.2f 小时\n', avg_trans);
fprintf('剩余箱量:      %d\n', RESC);
fprintf('------------------------------------------\n');
fprintf('时效性目标:    %.2f\n', fit1);
fprintf('经济性目标:    %.2f\n', fit2);
fprintf('低碳性目标:    %.2f\n', fit3);
fprintf('综合适应度:    %.6f\n', 1 / (cfg.w_time * fit1 + cfg.w_cost * fit2 + cfg.w_carbon * fit3));
fprintf('==========================================\n');
figure('Name', '最优解堆场分析', 'Position', [150 150 800 400]);
bestTEMPTTTD = [1:T_max; bestx_jdt];
DEL_index = find(bestTEMPTTTD(2, :) == 0);
bestTEMPTTTD(:, DEL_index) = [];
bestTT = bestTEMPTTTD(1, :);
protoC_TI = data.protoC_TI';
protoC_TI(:, 1) = [];
protoC_SUMI = data.protoC_SUMI';
TEMPbestYARDCON = [sort(bestTT(bestTT > 0)), 0, protoC_TI; -bestC_JD(bestC_JD > 0), protoC_SUMI];
TEMPbestYARDCON_1 = sortrows(TEMPbestYARDCON', 1)';
TEMPbestYARDCON_1(3, :) = cumsum(TEMPbestYARDCON_1(2, :));
TEMPbestYARDCON_2 = sortrows([TEMPbestYARDCON_1(1, :), TEMPbestYARDCON_1(1, :); TEMPbestYARDCON_1(3, :), TEMPbestYARDCON_1(3, :)]', 1)';
TEMPbestYARDCON_3 = [[0; 0], TEMPbestYARDCON_2, [T_max; 0]];
bestYARDCON = TEMPbestYARDCON_3(2, :);
stairs(TEMPbestYARDCON_3(1, :), bestYARDCON, 'LineWidth', 1.5);
xlabel('时间 (小时)');
ylabel('集装箱数量');
title('最优解 - 堆场堆存动态曲线');
grid on;
end
