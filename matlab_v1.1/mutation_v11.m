function [pop_new, TT_new] = mutation_v11(pop, TT, cfg, data)
%MUTATION_V11 v1.1 优化版变异操作
pop_size = cfg.pop_size;
T_max = cfg.T_max;
J_max = cfg.J_max;
C_max = data.C_max;
mutate_rate = cfg.mutate_rate;
pop_new = pop;
TT_new = TT;
for i = 1:pop_size
    if rand >= mutate_rate
        continue;
    end
    x_jdt = pop(i, 1:T_max);
    v_jd = pop(i, T_max+C_max+1:end);
    mutated = false;
    if rand < 0.5
        pos = randi(T_max);
        if x_jdt(pos) == 0
            new_dir = cfg.D0(randi(length(cfg.D0)));
            same_dir = find(x_jdt == new_dir);
            if ~isempty(same_dir)
                x_jdt(same_dir(randi(length(same_dir)))) = 0;
                x_jdt(pos) = new_dir;
                mutated = true;
            end
        else
            old_dir = x_jdt(pos);
            new_pos = find(x_jdt == 0);
            if ~isempty(new_pos)
                x_jdt(pos) = 0;
                x_jdt(new_pos(randi(length(new_pos)))) = old_dir;
                mutated = true;
            end
        end
    end
    if rand < 0.5
        pos = randi(J_max);
        v_jd(pos) = randi([cfg.v_min/5, cfg.v_max/5]) * 5;
        mutated = true;
    end
    if mutated
        [~, y_ijdc, ~] = assign_v11(x_jdt, cfg, data);
        TT_i = zeros(1, J_max);
        train_t = find(x_jdt ~= 0);
        TT_i(1:length(train_t)) = train_t;
        if constraints_v11(x_jdt, y_ijdc, TT_i, cfg, data)
            pop_new(i, 1:T_max) = x_jdt;
            pop_new(i, T_max+C_max+1:end) = v_jd;
            TT_new(i, :) = TT_i;
        end
    end
end
end
