function traineachd = caltrains(C_max, coneachd, J_max, D0)
    TEMPtraineachd = floor(J_max .* coneachd ./ C_max);
    TEMPtraineachd_2 = J_max .* coneachd ./ C_max - fix(J_max .* coneachd ./ C_max);
    RESJ = J_max - sum(TEMPtraineachd);
    [~, POSJD] = sort(TEMPtraineachd_2);
    POSJD_2 = POSJD(end-RESJ+1:end);
    traineachd = TEMPtraineachd;
    for i = 1:RESJ
        traineachd(POSJD_2(i)) = traineachd(POSJD_2(i)) + 1;
    end
end
