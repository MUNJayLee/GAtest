%% 储存交叉前父代
PROTOx_jdt=x_jdt;

%% 对x_jdt交叉
[~,endpos]=size(x_jdt);
for i=1:2:pop_size
    if(rand < cross_rate)
        temp0=randperm(length(x_jdt));
        %         cross_pos_1 = round(rand * length(x_jdt));
        %         cross_pos_2=cross_pos_1+round(rand*(endpos-cross_pos_1));
        temp0=sort(temp0(1:2));
        cross_pos_1=temp0(1);
        cross_pos_2=temp0(2);
        if cross_pos_1 == 0 || cross_pos_1 == 1 || cross_pos_2 > endpos
            continue;
        end
        for j=cross_pos_1:cross_pos_2
            temp = x_jdt(i,j);
            x_jdt(i,j) = x_jdt(i+1,j);
            x_jdt(i+1,j) = temp;
            %                                 end
            crosstraineach_1=[length(find(x_jdt(i,:)==1)),length(find(x_jdt(i,:)==2)),length(find(x_jdt(i,:)==3)),length(find(x_jdt(i,:)==4))];
            crosstraineach_2=[length(find(x_jdt(i+1,:)==1)),length(find(x_jdt(i+1,:)==2)),length(find(x_jdt(i+1,:)==3)),length(find(x_jdt(i+1,:)==4))];
            diftraineach_1=traineachd-crosstraineach_1;
            diftraineach_2=traineachd-crosstraineach_2;
            for k=1:length(D0)
                if diftraineach_1(1,k)>0
                    %上加
                    ADD_index=find(x_jdt(i,:)==0);
                    random_num=ADD_index(randperm(numel(ADD_index),diftraineach_1(1,k)));
                    index0=sort(random_num);
                    x_jdt(i,index0)=k;
                elseif diftraineach_1(1,k)<0
                    %上减
                    DEL_index=find(x_jdt(i,:)==k);
                    random_num=DEL_index(randperm(numel(DEL_index),abs(diftraineach_1(1,k))));
                    index0=sort(random_num);
                    x_jdt(i,index0)=0;
                end
            end
            for k=1:length(D0)
                if diftraineach_2(1,k)>0
                    %下加
                    ADD_index=find(x_jdt(i+1,:)==0);
                    random_num=ADD_index(randperm(numel(ADD_index),diftraineach_2(1,k)));
                    index0=sort(random_num);
                    x_jdt(i+1,index0)=k;
                elseif diftraineach_2(1,k)<0
                    %下减
                    DEL_index=find(x_jdt(i+1,:)==k);
                    random_num=DEL_index(randperm(numel(DEL_index),abs(diftraineach_2(1,k))));
                    index0=sort(random_num);
                    x_jdt(i+1,index0)=0;
                end
            end
        end
    end
end
% aa=length(find(x_jdt(i,:)~=0));
% if aa~=sum(D0)
%     x_jdt(i,:)=PROTOx_jdt(i,:);
% end
% bb=length(find(x_jdt(i+1,:)~=0));
% if bb~=sum(D0)
%     x_jdt(i+1,:)=PROTOx_jdt(i+1,:);
% end


assign;

%% 对v_jd交叉
[~,endpos]=size(v_jd);
for i=1:2:pop_size
    if(rand < cross_rate)
        cross_pos = round(rand * length(v_jd));%cross_pos是交叉点位
        if or (cross_pos == 0, cross_pos == 1)
            continue;
        end
        for j=cross_pos:endpos
            temp = v_jd(i,j);
            v_jd(i,j) = v_jd(i+1,j);
            v_jd(i+1,j) = temp;
        end
    end
end

%% 检验交叉后是否违反约束，若违反则此次交叉不发生
fitness_value_temp=constraints(x_jdt,y_ijdc,TT);
for i=1:pop_size
    if isnan(fitness_value_temp(1,i))
        x_jdt(i,:)=PROTOx_jdt(i,:);%还原x_jdt
    end
end
%重新计算 y_ijdc TT 以及适应度
assign;
pop=[x_jdt,y_ijdc,v_jd];
fitness(pop,TT); %计算适应度 v_jd 发生了变化

clear i j endpos rand cross_pos cross_pos_1 cross_pos_2 PROTOx_jdt