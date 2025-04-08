%% 储存交叉前父代
PROTOx_jdt=x_jdt;
% PROTOy_ijdc=y_ijdc;

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

%% y_ijdc变异
%按照x_jdt进行交换
% for i=1:pop_size
%     TEMP_trainorder=[1:T_max;PROTOx_jdt(i,:);x_jdt(i,:)];
%     DEL_index1=find(TEMP_trainorder(2,:)==0);
%     DEL_index2=find(TEMP_trainorder(3,:)==0);
%     DEL_index=intersect(DEL_index1,DEL_index2);
%     TEMP_trainorder(:,DEL_index)=[];
%     order_num=length(TEMP_trainorder);
%     TEMP_trainorder(4,:)=1:order_num;
%     zeropos_1=find(TEMP_trainorder(2,:)==0);
%     zeropos_2=find(TEMP_trainorder(3,:)==0);
%     TEMP_trainorder(5,:)=TEMP_trainorder(4,:);
%     TEMP_trainorder(5,zeropos_1:end)=inf;
%     TEMP_trainorder(5,zeropos_1+1:end)=TEMP_trainorder(4,zeropos_1+1:end)-1;
%     TEMP_trainorder(6,:)=TEMP_trainorder(4,:);
%     TEMP_trainorder(6,zeropos_2:end)=inf;
%     TEMP_trainorder(6,zeropos_2+1:end)=TEMP_trainorder(4,zeropos_2+1:end)-1;
%     TEMP_trainorder(4,:)=[];
%     for j=1:C_max
%         if y_ijdc(i,j)==0
%             muty_ijdc(i,j)=0;
%         else
%             index=y_ijdc(i,j)==TEMP_trainorder(4,:);
%             muty_ijdc(i,j)=TEMP_trainorder(5,index);
%         end
%         if muty_ijdc(i,j)==inf
%             muty_ijdc(i,j)=TEMP_trainorder(5,zeropos_1);
%         end
%     end
% end

%% 计算y_ijdc
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
pop=[x_jdt,y_ijdc,v_jd]; %还原
fitness(pop,TT);%重新计算适应度
