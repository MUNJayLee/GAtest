for i=1:pop_size    
    fitness_table(i) = 0;
end

for i=1:pop_size-1
    for j = i+1:pop_size
        if fitness_value(i)>fitness_value(j)
            temp = fitness_value(i);
            fitness_value(i) = fitness_value(j);
            fitness_value(j) = temp;
            for k = 1:chromo_size
                temp(k) = pop(i,k);
                pop(i,k) = pop(j,k);
                pop(j,k) = temp(k);
            end            
        end
    end
end

for i=1:pop_size
    if i==1
        fitness_table(i) = fitness_table(i) + fitness_value(i);    
    else
        fitness_table(i) = fitness_table(i-1) + fitness_value(i);
    end
end

fitness_avg(G) = fitness_table(pop_size)/pop_size;

if fitness_value(pop_size) > best_fitness
    best_fitness = fitness_value(pop_size);
    best_generation = G;
    for j=1:chromo_size
        best_individual(j) = pop(pop_size,j);
    end
end

%% 再次分解
x_jdt=pop(1:pop_size,1:T_max);
y_ijdc=pop(1:pop_size,T_max+1:T_max+C_max);
v_jd=pop(1:pop_size,T_max+C_max+1:T_max+C_max+J_max);