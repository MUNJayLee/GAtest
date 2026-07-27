for i=1:pop_size
    r = rand * fitness_table(pop_size);
    first = 1;
    last = pop_size;
    mid = round((last+first)/2);
    idx = -1;
    while (first <= last) && (idx == -1)
        if r > fitness_table(mid)
            first = mid;
        elseif r < fitness_table(mid)
            last = mid;
        else
            idx = mid;
            break;
        end
        mid = round((last+first)/2);
        if (last - first) == 1
            idx = last;
            break;
        end
    end
    for j=1:chromo_size
        pop_new(i,j)=pop(idx,j);
    end
end
if elitism
    p = pop_size-1;
else
    p = pop_size;
end
for i=1:p
    for j=1:chromo_size
        pop(i,j) = pop_new(i,j);
    end
end
x_jdt=pop(1:pop_size,1:T_max);
v_jd=pop(1:pop_size,T_max+C_max+1:T_max+C_max+J_max);
