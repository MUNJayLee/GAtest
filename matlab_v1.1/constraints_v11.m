function valid = constraints_v11(x_jdt, y_ijdc, TT, cfg, data)
%CONSTRAINTS_V11 v1.1 优化版约束检验函数
valid = true;
T_max = cfg.T_max;
J_max = cfg.J_max;
if any(x_jdt(cfg.maintenance) ~= 0)
    valid = false;
    return;
end
C_JD = zeros(1, J_max);
for j = 1:J_max
    C_JD(j) = sum(y_ijdc == j);
end
if any(C_JD > 2 * cfg.maxtsegs) || any(C_JD > 0 & C_JD < 2 * cfg.mintsegs)
    valid = false;
    return;
end
protoC_TI = data.protoC_TI';
protoC_TI(:, 1) = [];
protoC_SUMI = data.protoC_SUMI';
TEMPYARDCON = [sort(TT(TT > 0)), 0, protoC_TI; -C_JD(C_JD > 0), protoC_SUMI];
TEMPYARDCON_1 = sortrows(TEMPYARDCON', 1)';
TEMPYARDCON_1(3, :) = cumsum(TEMPYARDCON_1(2, :));
if any(TEMPYARDCON_1(3, :) < 0) || any(TEMPYARDCON_1(3, :) > cfg.Yardcap)
    valid = false;
    return;
end
train_times = find(x_jdt ~= 0);
if length(train_times) >= 2
    time_diff = diff(train_times);
    if any(time_diff < cfg.minintervaltime)
        valid = false;
        return;
    end
end
end
