%% ���潻��ǰ����
PROTOx_jdt=x_jdt;

%% ��x_jdt����
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
                    %�ϼ�
                    ADD_index=find(x_jdt(i,:)==0);
                    random_num=ADD_index(randperm(numel(ADD_index),diftraineach_1(1,k)));
                    index0=sort(random_num);
                    x_jdt(i,index0)=k;
                elseif diftraineach_1(1,k)<0
                    %�ϼ�
                    DEL_index=find(x_jdt(i,:)==k);
                    random_num=DEL_index(randperm(numel(DEL_index),abs(diftraineach_1(1,k))));
                    index0=sort(random_num);
                    x_jdt(i,index0)=0;
                end
            end
            for k=1:length(D0)
                if diftraineach_2(1,k)>0
                    %�¼�
                    ADD_index=find(x_jdt(i+1,:)==0);
                    random_num=ADD_index(randperm(numel(ADD_index),diftraineach_2(1,k)));
                    index0=sort(random_num);
                    x_jdt(i+1,index0)=k;
                elseif diftraineach_2(1,k)<0
                    %�¼�
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

%% ��v_jd����
[~,endpos]=size(v_jd);
for i=1:2:pop_size
    if(rand < cross_rate)
        cross_pos = round(rand * length(v_jd));%cross_pos�ǽ����λ
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

%% ���齻����Ƿ�Υ��Լ������Υ����˴ν��治����
fitness_value_temp=constraints(x_jdt,y_ijdc,TT);
for i=1:pop_size
    if isnan(fitness_value_temp(1,i))
        x_jdt(i,:)=PROTOx_jdt(i,:);%��ԭx_jdt
    end
end
%���¼��� y_ijdc TT �Լ���Ӧ��
assign;
pop=[x_jdt,y_ijdc,v_jd];
fitness(pop,TT); %������Ӧ�� v_jd �����˱仯

clear i j endpos rand cross_pos cross_pos_1 cross_pos_2 PROTOx_jdt