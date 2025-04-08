function fitness(pop,TT)
global T_max J_max D L_d Tmaintenance maintenance mintranstime minintervaltime maxtsegs
global mintsegs Yardcap trainnum C_max C_IDT protoC_TI protoC_SUMI coneachd each_best_fitness
global fitness_value pop_size C_TJ   traineachd  G
PROTOfitness_value=max(fitness_value);
x_jdt=pop(1:pop_size,1:T_max);
% y_ijdc=pop(1:pop_size,T_max+1:T_max+C_max);
assign;
v_jd=pop(1:pop_size,T_max+C_max+1:T_max+C_max+J_max);

C_JD=[];
for i=1:pop_size
    for j=1:J_max
        C_JD(i,j)=sum(sum(y_ijdc(i,:)==j));
    end
end

%% 时效性目标
%PART1
for i=1:pop_size
    fit1_1(i,:)=5*sum(C_TJ(i,:)-C_IDT(4,:));
end

%PART2
for i=1:length(L_d)
    for j=1:traineachd(1,i)
        TEMPL_d(j,i)=L_d(1,i);
    end
end
EXL_d=TEMPL_d(:);
EXL_d(EXL_d==0)=[];
EXL_d=EXL_d';
for i=1:pop_size
    for j=1:J_max
        fit1_2_1(i,j)=EXL_d(1,j)/v_jd(i,j)*C_JD(i,j);
    end
end
fit1_2=5*sum(fit1_2_1,2);
fit1=fit1_1+fit1_2;


%% 经济性目标
%PART1
cf1=18.228;%*L
cf2=144.738;%*L/v
cf3=43.716;%*L/v
for i=1:pop_size
    EXcf1(i,:)=cf1.*EXL_d;
end
for i=1:pop_size
    for j=1:J_max
        EXcf2(i,j)=cf2.*EXL_d(1,j)./v_jd(i,j);
    end
end
for i=1:pop_size
    for j=1:J_max
        EXcf3(i,j)=cf3.*EXL_d(1,j)./v_jd(i,j);
    end
end
fit2_1=sum(EXcf1,2)+sum(EXcf2,2)+sum(EXcf3,2);

%PART2
cv1=850*5;%与集装箱量有关的（找数据）
% cv2=2300;%与车底数有关的（找数据）
fit2_2_1=sum(cv1.*C_JD,2);
n_JD=ceil(1/2*C_JD);
% fit2_2_2=sum(cv2.*n_JD,2);

% m1=138;
% m2=22.5;
% m3=17.5;
% D=18.57;
% k_ran=0.66;
% fit2_2_3=sum(D/10000.*EXL_d.*k_ran.*(m1+n_JD.*m2+C_JD.*m3),2);

% fit2_2=fit2_2_1+fit2_2_2+fit2_2_3;
fit2_2=fit2_2_1;

%PART3
Q=[];
cq=1.25*10^8*5;
for i =1:pop_size
    TEMPprotoC_TI=protoC_TI';%船舶到港时间
    TEMPprotoC_TI(:,[1])=[];
    TEMPprotoC_SUMI=protoC_SUMI';%船舶运载箱数
    TEMPYARDCON=[sort(TT(i,:)),0,TEMPprotoC_TI;-C_JD(i,:),TEMPprotoC_SUMI];%班列时刻，船的时刻，负的班列运载箱数，正的船的运载箱数
    TEMPYARDCON_1=sortrows(TEMPYARDCON',1)';%按时序排列
    TEMPYARDCON_1(3,:)=cumsum(TEMPYARDCON_1(2,:));%箱数累积
    TEMPYARDCON_2=sortrows([TEMPYARDCON_1(1,:),TEMPYARDCON_1(1,:);TEMPYARDCON_1(3,:),TEMPYARDCON_1(3,:)]',1)';
    TEMPYARDCON_3=[[0;0],TEMPYARDCON_2,[T_max;0]];
    Q(i,:)=trapz(TEMPYARDCON_3(1,:),TEMPYARDCON_3(2,:));
end
fit2_3=cq.*Q;

%PART4
for i=1:pop_size
    for j=1:C_max
        if C_IDT(4,j)+mintranstime<C_TJ(i,j)
            z_ijdc(i,j)=0;
        else
            z_ijdc(i,j)=1;
        end
    end
end

SUMC_DIR=sum(z_ijdc,2);
SUMC_INDIR=C_max-SUMC_DIR;
c_dir=120*5;%直取装卸作业成本
c_indir=240*5;%非直取装卸作业成本
fit2_4=c_dir.*SUMC_DIR+c_indir.*SUMC_INDIR;

%PART5 剩余箱惩罚
for i=1:pop_size
    RESC(i,:)=length(find(y_ijdc(i,:)==0));
end
RESN=ceil(RESC./2);
fit2_5=100000*5.*RESC;%+85*5.*RESN.*mean(L_d);

fit2=fit2_1+fit2_2+fit2_3+fit2_4+fit2_5;


%% 低碳性目标
%PART1 班列碳排放
A_jiche=1.44;
B_jiche=0.0099;
C_jiche=0.000298;
A_cheliang=0.92;
B_cheliang=0.0048;
C_cheliang=0.000125;
G_0=128;
m_jun=17.5;
m_0=22.5;
gamma=0.65;%燃料消耗率
f_jiche=A_jiche+v_jd.*B_jiche+v_jd.^2.*C_jiche;
f_cheliang=A_cheliang+v_jd.*B_cheliang+v_jd.^2.*C_cheliang;
F_zu=(f_jiche.*G_0+f_cheliang.*(5*C_JD.*m_jun+n_JD.*m_0)).*10;
%生成每个班列开行的距离矩阵
for i=1:pop_size
    tempx_jdt_1(i,:)=x_jdt(i,:);
    tempx_jdt_1(tempx_jdt_1==0)=[];
    tempx_jdt_2(i,:)=tempx_jdt_1;
    clear tempx_jdt_1;
end
for i=1:pop_size
    for j=1:J_max
        for k=1:length(L_d)
            if tempx_jdt_2(i,j)==k
                EXWL_D(i,j)=L_d(1,k);
            end
        end
    end
end
% fit3_1=sum(EXWL_D.*gamma.*F_zu,2).*6.4*10^-8;
fit3_1=(sum(EXWL_D.*gamma.*F_zu,2)./(3.6*10^6)).*0.785;
% fit3_1=(sum(EXWL_D.*gamma.*F_zu,2)./(3.6*10^6)).*0.785;

%PART2 装卸作业碳排放
e_dir=5*7.095;%((4+3)*0.3025+0.5*1.4571)*2.493
e_indir=5*10.111;%((4+3+4)*0.3025+0.5*1.4571)*2.493
fit3_2=(e_dir.*SUMC_DIR+e_indir.*SUMC_INDIR)./1000;

fit3=fit3_1+fit3_2;
%% 适应度总和（考虑加权）
fitness_value=1./((0.25*150000/365/24).*fit1+fit2+55.3*1.1.*fit3);
% fitness_value=((0.25*150000/365/24).*fit1+fit2+55.3.*fit3./1000);
% fitness_value=SUMC_DIR;
% fitness_value=1./Q;
end