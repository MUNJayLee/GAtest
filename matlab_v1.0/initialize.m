function [pop,TT]=initialize()
global T_max J_max Tmaintenance maintenance   
global  pop_size trainnum C_max C_IDT protoC_TI protoC_SUMI 
valid_pop=[];
flag=0;
fitness_value=[];
TT_valiad=[];
while flag<pop_size
    for n=1:pop_size
        EXtrainnum=[trainnum',zeros(1,T_max-length(trainnum)-Tmaintenance)];
        TEMPtrainnum_1=randperm(T_max-Tmaintenance);
        TEMPtrainnum_2=EXtrainnum(TEMPtrainnum_1);
        TEMPx_jdt0=TEMPtrainnum_2;
        for i=1:Tmaintenance
            TEMPx_jdt0=insert(TEMPx_jdt0,maintenance(:,i),0);
        end
        x_jdt(n,:)=TEMPx_jdt0;
    end
    assign;
    for i=1:pop_size
        for j=1:J_max
            v_jd(i,j) = randi([16,24])*5;
        end
    end
    pop=[x_jdt,y_ijdc,v_jd];
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
end
pop=valid_pop(1:pop_size,:);
TT=TT_valiad;
end
