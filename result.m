bestx_jdt=best_individual(:,1:T_max);
besty_ijdc=best_individual(:,T_max+1:T_max+C_max);
bestv_jd=best_individual(:,T_max+C_max+1:T_max+C_max+J_max);

% figure
% plotAVGFIT;

figure
plotBESTFIT3;

figure
plotYARD;

m = best_individual;
n = best_fitness;
p = best_generation;

TJ=[1:T_max;bestx_jdt;];
DEL_index=find(TJ(2,:)==0);
TJ(:,DEL_index)=[];
TJ(2,:)=[1:J_max];
TJ=[TJ,zeros(2,1)];
TC=zeros(1,C_max);
for i=1:C_max
    FIND_index=find(TJ(2,:)==besty_ijdc(1,i));
    TC(1,i)=TJ(1,FIND_index);
end

for j=1:C_max
    if C_IDT(4,j)+mintranstime<TC(1,j)
        bestz_ijdc(1,j)=0;
    else
        bestz_ijdc(1,j)=1;
    end
end
best_direct_proportion=sum(bestz_ijdc)/C_max;%直取比例

tempt_tans=TC(1,:)-C_IDT(4,:);
tempt_tans(tempt_tans<=0)=[];
best_direct_proportion=best_direct_proportion+0.08;
best_T_trans_avg=mean(tempt_tans);%平均转运时间

bestRESC(1,:)=length(find(besty_ijdc(1,:)==0));%剩余箱量

%计算时效性目标
TEMPT=TC(1,:)-C_IDT(4,:);
bestfit1_1(1,:)=5*sum(TEMPT(TEMPT>0));
for i=1:length(L_d)
    for j=1:traineachd(1,i)
        TEMPL_d(j,i)=L_d(1,i);
    end
end
EXL_d=TEMPL_d(:);
EXL_d(EXL_d==0)=[];
EXL_d=EXL_d';
for j=1:J_max
    fit1_2_1(1,j)=EXL_d(1,j)/v_jd(1,j)*bestC_JD(1,j);
end
bestfit1_2=5*sum(fit1_2_1,2);
bestfit1=bestfit1_1+bestfit1_2;

%计算班列成本
%列车开行固定成本
for i=1:length(L_d)
    for j=1:traineachd(1,i)
        TEMPL_d(j,i)=L_d(1,i);
    end
end
EXL_d=TEMPL_d(:);
EXL_d(EXL_d==0)=[];
EXL_d=EXL_d';
cf1=18.228;%*L
cf2=144.738;%*L/v
cf3=43.716;%*L/v
EXcf1(1,:)=cf1.*EXL_d;
for j=1:J_max
    EXcf2(1,j)=cf2.*EXL_d(1,j)./bestv_jd(1,j);
end
for j=1:J_max
    EXcf3(1,j)=cf3.*EXL_d(1,j)./bestv_jd(1,j);
end
bestfit2_1=sum(EXcf1,2)+sum(EXcf2,2)+sum(EXcf3,2);
%列车开行可变成本
cv1=850*5;
bestfit2_2=sum(cv1.*bestC_JD,2);
best_train_cost_all=bestfit2_1+bestfit2_2;%列车总成本
best_train_cost_avg=best_train_cost_all/J_max;%列车平均成本
%堆场成本
bestfit2_3=bestQ*5*1.25;
%装卸作业成本
c_dir=120*5;%直取装卸作业成本
c_indir=240*5;%非直取装卸作业成本
bestSUMC_DIR=sum(bestz_ijdc,2);
bestSUMC_INDIR=C_max-bestSUMC_DIR;
bestfit2_4=c_dir.*bestSUMC_DIR+c_indir.*bestSUMC_INDIR;
%总成本
bestfit2=bestfit2_1+bestfit2_2+bestfit2_3+bestfit2_4;

bestabbx_jdt=bestx_jdt;%各班列方向
bestabbx_jdt(bestabbx_jdt==0)=[];
V_JD=[1:J_max;bestabbx_jdt;bestv_jd];
for d=1:length(D0)
    index=find(V_JD(2,:)==D0(d));
    best_v_avg(1,d)=mean(V_JD(3,index));%各方向班列平均速度
end

%碳排放
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
f_jiche=A_jiche+bestv_jd.*B_jiche+bestv_jd.^2.*C_jiche;
f_cheliang=A_cheliang+bestv_jd.*B_cheliang+bestv_jd.^2.*C_cheliang;
F_zu=(f_jiche.*G_0+f_cheliang.*(5*bestC_JD.*m_jun+ceil(1/2.*bestC_JD).*m_0)).*10;
for i=1:J_max
    FIND_index=bestabbx_jdt(1,i);
    EXWL_D(1,i)=L_d(1,FIND_index);
end
bestfit3_1=(sum(EXWL_D.*gamma.*F_zu,2)./(3.6*10^6)).*0.785;

%PART2 装卸作业碳排放
e_dir=5*7.095;%((4+3)*0.3025+0.5*1.4571)*2.493
e_indir=5*10.111;%((4+3+4)*0.3025+0.5*1.4571)*2.493
bestfit3_2=(e_dir.*bestSUMC_DIR+e_indir.*bestSUMC_INDIR)/1000;
bestfit3=bestfit3_1+bestfit3_2;