%% 储存交叉前父代
PROTOx_jdt=x_jdt;
%% x_jdt变异
[~,py]=size(x_jdt);
for i=1:pop_size
    if rand < mutate_rate
        mutate_pos = round(rand*py);
        if mutate_pos == 0
            continue;
        end
        if x_jdt(i,mutate_pos)==0
            x_jdt(i,mutate_pos)=randi([1,length(D0)]);
            tempchange_pos1=find( x_jdt(i,:) == x_jdt(i,mutate_pos));
            change_pos1=setdiff(tempchange_pos1,mutate_pos);
            x_jdt(i,change_pos1(randi([length(change_pos1)])))=0;
        else
            tempmutnum=x_jdt(i,mutate_pos);
            tempchange_pos2=find( x_jdt(i,:) == 0);
            change_pos2=tempchange_pos2(randi([length(tempchange_pos2)]));
            x_jdt(i,mutate_pos)=0;
            x_jdt(i,change_pos2)=tempmutnum;
        end
    end
end
assign;
%% v_jd变异
for i=1:pop_size
    if rand < mutate_rate
        mutate_pos = round(rand*J_max);
        if mutate_pos == 0
            continue;
        end
        v_jd(i,mutate_pos) = randi([16,24])*5;
    end
end
%% 检验变异后是否违反约束，若违反则此次变异不发生
fitness_value_temp=constraints(x_jdt,y_ijdc,TT);
for i=1:pop_size
    if isnan(fitness_value_temp(1,i))
        x_jdt(i,:)=PROTOx_jdt(i,:);
    end
end
assign;
pop=[x_jdt,y_ijdc,v_jd];
fitness(pop,TT);
