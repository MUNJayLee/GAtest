global mintranstime maxtsegs mintsegs C_TJ traineachd C_JD

y_ijdc=zeros(pop_size,C_max);

%根据已经生成的班列矩阵进行分配
%原则是优先直取，如果集装箱与装卸线上停留的班列去向相同，则直接装车直至达到最大运载数，再考虑堆场箱
TT=[];
TD=[];
DEL_index=[];
for i=1:pop_size
    TEMPTTTD=1:T_max;
    DEL_index=find(x_jdt(i,:)~=0);
    TT(i,:)=TEMPTTTD(DEL_index);%获取每节列车开行的时间
    TD(i,:)=TEMPTTTD(x_jdt(i,DEL_index));%获取每节列车开行的方向
end

TEMPassign=[C_IDT(3,:);C_IDT(4,:)];%保留C_IDT第3、4行，分别表示集装箱的目的方向和到达时间
C_TJ=[];%集装箱随班列发出的时间
for i =1:pop_size
    TEMPtrain=[1:J_max;TD(i,:);TT(i,:)];%形成临时班列信息矩阵，依次是编号、方向、时间
    TEMPtrain(5,:)=0;%班列的装载量
    for j=1:C_max
        TEMP_inedx=find(TEMPassign(1,j)==TEMPtrain(2,:));%寻找同方向班列
        %计算班列开行时间与集装箱卸船时间的差值，
        %若为<0，则集装箱在班列到达时间之前抵达,可进行装卸
        %若为>=0,则集装箱在班列到达时间之后抵达，不可装卸
        TEMPtrain(4,:)=TEMPassign(2,j)-TEMPtrain(3,:);
        % 限定转运时间约束，即集装箱从班轮上卸下，到班列上至少需要多少时间，小于这个时间则无法上车
        DEL_index_1=find(TEMPtrain(4,:)>=-mintranstime);
        DEL_index_2=find(TEMPtrain(5,:)>2*maxtsegs-1);
        DEL_index=union(DEL_index_1,DEL_index_2);
        ASSIGN_index=setdiff(TEMP_inedx,DEL_index);
        if isempty(ASSIGN_index)==1
            y_ijdc(i,j)=0;
            C_TJ(i,j)=168;
        elseif isempty(ASSIGN_index)==0
            y_ijdc(i,j)=TEMPtrain(1,ASSIGN_index(1,1));
            C_TJ(i,j)=TEMPtrain(3,ASSIGN_index(1,1));
            TEMPtrain(5,ASSIGN_index(1,1))=TEMPtrain(5,ASSIGN_index(1,1))+1;
        end
    end
end

clear i j TEMPTT TEMPassign;

