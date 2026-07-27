function plotConvergence(fitness_history, cfg, obj_history)
%PLOTCONVERGENCE 绘制算法收敛曲线
%   v1.1 新增：增强的可视化，包含多维度收敛分析
%
%   输入:
%       fitness_history - 每代最优适应度 (1 x generation_size)
%       cfg             - 配置结构体
%       obj_history     - 各目标历史值 (结构体数组)

figure('Name', '收敛分析', 'Position', [100 100 1200 800]);

%% 子图1: 最优适应度收敛曲线
subplot(2, 3, 1);
gen = 1:length(fitness_history);
plot(gen, fitness_history, 'b-', 'LineWidth', 1.5);
hold on;
plot(gen, movmean(fitness_history, 3), 'r--', 'LineWidth', 1);
xlabel('迭代代数');
ylabel('最优适应度');
title('适应度收敛曲线');
legend('最优值', '3代移动平均');
grid on;

%% 子图2: 适应度改善率
subplot(2, 3, 2);
if length(fitness_history) > 1
    improvement = diff(fitness_history) ./ max(fitness_history(1:end-1), eps);
    bar(gen(2:end), improvement, 'FaceColor', [0.2 0.6 0.8]);
    xlabel('迭代代数');
    ylabel('改善率');
    title('每代适应度改善率');
    grid on;
end

%% 子图3: 种群多样性（如提供）
subplot(2, 3, 3);
if isfield(obj_history, 'diversity') && ~isempty(obj_history(1).diversity)
    diversity = [obj_history.diversity];
    plot(gen, diversity, 'g-', 'LineWidth', 1.5);
    xlabel('迭代代数');
    ylabel('种群多样性');
    title('种群多样性变化');
    grid on;
else
    text(0.5, 0.5, '多样性数据未记录', 'HorizontalAlignment', 'center');
    axis off;
end

%% 子图4: 时效性目标收敛
subplot(2, 3, 4);
if isfield(obj_history, 'fit1') && ~isempty(obj_history(1).fit1)
    fit1_vals = [obj_history.fit1];
    plot(gen, fit1_vals, 'm-', 'LineWidth', 1.5);
    xlabel('迭代代数');
    ylabel('时效性目标值');
    title('时效性目标收敛');
    grid on;
end

%% 子图5: 经济性目标收敛
subplot(2, 3, 5);
if isfield(obj_history, 'fit2') && ~isempty(obj_history(1).fit2)
    fit2_vals = [obj_history.fit2];
    plot(gen, fit2_vals, 'c-', 'LineWidth', 1.5);
    xlabel('迭代代数');
    ylabel('经济性目标值');
    title('经济性目标收敛');
    grid on;
end

%% 子图6: 低碳性目标收敛
subplot(2, 3, 6);
if isfield(obj_history, 'fit3') && ~isempty(obj_history(1).fit3)
    fit3_vals = [obj_history.fit3];
    plot(gen, fit3_vals, 'k-', 'LineWidth', 1.5);
    xlabel('迭代代数');
    ylabel('低碳性目标值');
    title('低碳性目标收敛');
    grid on;
end

sgtitle('遗传算法收敛分析 (v1.1)', 'FontSize', 14, 'FontWeight', 'bold');

end
