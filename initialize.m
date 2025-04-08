function [pop,TT]=initialize()
global T_max J_max Tmaintenance maintenance   
global  pop_size trainnum C_max C_IDT protoC_TI protoC_SUMI 
valid_pop=[];
flag=0;
fitness_value=[];
TT_valiad=[];
while flag<pop_size%大于pop_size时终止，可能会超出pop_size范围
    
    %% x_jdt变量初始化
    for n=1:pop_size
        EXtrainnum=[trainnum',zeros(1,T_max-length(trainnum)-Tmaintenance)];
        TEMPtrainnum_1=randperm(T_max-Tmaintenance);%生成随机序号
        TEMPtrainnum_2=EXtrainnum(TEMPtrainnum_1);%使EXA按序号方式排序
        TEMPx_jdt0=TEMPtrainnum_2;
        for i=1:Tmaintenance
            TEMPx_jdt0=insert(TEMPx_jdt0,maintenance(:,i),0);
        end
        x_jdt(n,:)=TEMPx_jdt0;
    end
    
    %% 计算y_ijdc
    assign;
    
    %% v_jd变量初始化
    for i=1:pop_size
        for j=1:J_max
            v_jd(i,j) = randi([16,24])*5;
        end
    end
    pop=[x_jdt,y_ijdc,v_jd];
%     x_jdt=pop(1:pop_size,1:T_max);
%     y_ijdc=pop(1:pop_size,T_max+1:T_max+C_max);
%     v_jd=pop(1:pop_size,T_max+C_max+1:T_max+C_max+J_max);
    
    %% 检验是否违反约束
    fitness_value_temp=constraints(x_jdt,y_ijdc,TT);
    for i=1:pop_size
        if ~isnan(fitness_value_temp(1,i))
            temppop(1,:)=pop(i,:);
            valid_pop=[valid_pop;temppop];
            fitness_value=[fitness_value fitness_value_temp(1,i)];
            TT_valiad=[TT_valiad;TT(i,:)];
        end
    end
    [flag,~]=size(valid_pop);
%     clear i j n TEMPtrainnum_1 TEMPtrainnum_2 TEMPx_jdt EXtrainnum
    
end

%% 选取pop
pop=valid_pop(1:pop_size,:);
% x_jdt=pop(1:pop_size,1:T_max);
% y_ijdc=pop(1:pop_size,T_max+1:T_max+C_max);
% v_jd=pop(1:pop_size,T_max+C_max+1:T_max+C_max+J_max);
TT=TT_valiad;
%fitness_value = zeros(1,pop_size);
end