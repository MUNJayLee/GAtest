each_best_x_jdt=each_best_individual(1:generation_size,1:T_max);
each_best_y_ijdc=zeros(pop_size,C_max);
each_best_TT=[];
each_best_TD=[];
each_best_DEL_index=[];
for i=1:generation_size
    TEMPTTTD=1:T_max;
    each_best_DEL_index=find(each_best_x_jdt(i,:)~=0);
    each_best_TT(i,:)=TEMPTTTD(each_best_DEL_index);
    each_best_TD(i,:)=TEMPTTTD(each_best_x_jdt(i,each_best_DEL_index));
end
TEMPassign=[C_IDT(3,:);C_IDT(4,:)];
each_best_C_TJ=[];
for i =1:generation_size
    TEMPtrain=[1:J_max;each_best_TD(i,:);each_best_TT(i,:)];
    TEMPtrain(5,:)=0;
    for j=1:C_max
        TEMP_inedx=find(TEMPassign(1,j)==TEMPtrain(2,:));
        TEMPtrain(4,:)=TEMPassign(2,j)-TEMPtrain(3,:);
        DEL_index_1=find(TEMPtrain(4,:)>=-mintranstime);
        DEL_index_2=find(TEMPtrain(5,:)>2*maxtsegs-1);
        each_best_DEL_index=union(DEL_index_1,DEL_index_2);
        ASSIGN_index=setdiff(TEMP_inedx,each_best_DEL_index);
        if isempty(ASSIGN_index)==1
            each_best_y_ijdc(i,j)=0;
            each_best_C_TJ(i,j)=0;
        elseif isempty(ASSIGN_index)==0
            each_best_y_ijdc(i,j)=TEMPtrain(1,ASSIGN_index(1,1));
            each_best_C_TJ(i,j)=TEMPtrain(3,ASSIGN_index(1,1));
            TEMPtrain(5,ASSIGN_index(1,1))=TEMPtrain(5,ASSIGN_index(1,1))+1;
        end
    end
end
clear i j TEMPTT TEMPassign;
each_best_v_jd=each_best_individual(1:generation_size,T_max+C_max+1:T_max+C_max+J_max);
each_best_C_JD=[];
for i=1:generation_size
    for j=1:J_max
        each_best_C_JD(i,j)=sum(sum(each_best_y_ijdc(i,:)==j));
    end
end
for i=1:generation_size
    each_best_fit1_1(i,:)=5*sum(each_best_C_TJ(i,:)-C_IDT(4,:));
end
for i=1:length(L_d)
    for j=1:traineachd(1,i)
        TEMPL_d(j,i)=L_d(1,i);
    end
end
EXL_d=TEMPL_d(:);
EXL_d(EXL_d==0)=[];
EXL_d=EXL_d';
for i=1:generation_size
    for j=1:J_max
        each_best_fit1_2_1(i,j)=EXL_d(1,j)/each_best_v_jd(i,j)*each_best_C_JD(i,j);
    end
end
each_best_fit1_2=5*sum(each_best_fit1_2_1,2);
each_best_fit1=each_best_fit1_1+each_best_fit1_2;
cf1=18.228;
cf2=144.738;
cf3=43.716;
for i=1:generation_size
    EXcf1(i,:)=cf1.*EXL_d;
end
for i=1:generation_size
    for j=1:J_max
        EXcf2(i,j)=cf2.*EXL_d(1,j)./each_best_v_jd(i,j);
    end
end
for i=1:generation_size
    for j=1:J_max
        EXcf3(i,j)=cf3.*EXL_d(1,j)./each_best_v_jd(i,j);
    end
end
each_best_fit2_1=sum(EXcf1,2)+sum(EXcf2,2)+sum(EXcf3,2);
cv1=850*5;
each_best_fit2_2_1=sum(cv1.*each_best_C_JD,2);
each_best_n_JD=ceil(1/2*each_best_C_JD);
each_best_fit2_2=each_best_fit2_2_1;
each_best_Q=[];
cq=1.25*5;
for i =1:generation_size
    TEMPprotoC_TI=protoC_TI';
    TEMPprotoC_TI(:,[1])=[];
    TEMPprotoC_SUMI=protoC_SUMI';
    TEMPYARDCON=[sort(each_best_TT(i,:)),0,TEMPprotoC_TI;-each_best_C_JD(i,:),TEMPprotoC_SUMI];
    TEMPYARDCON_1=sortrows(TEMPYARDCON',1)';
    TEMPYARDCON_1(3,:)=cumsum(TEMPYARDCON_1(2,:));
    TEMPYARDCON_2=sortrows([TEMPYARDCON_1(1,:),TEMPYARDCON_1(1,:);TEMPYARDCON_1(3,:),TEMPYARDCON_1(3,:)]',1)';
    TEMPYARDCON_3=[[0;0],TEMPYARDCON_2,[T_max;0]];
    each_best_Q(i,:)=trapz(TEMPYARDCON_3(1,:),TEMPYARDCON_3(2,:));
end
each_best_fit2_3=cq.*each_best_Q;
for i=1:generation_size
    for j=1:C_max
        if C_IDT(4,j)+mintranstime<each_best_C_TJ(i,j)
            each_best_z_ijdc(i,j)=0;
        else
            each_best_z_ijdc(i,j)=1;
        end
    end
end
each_best_SUMC_DIR=sum(each_best_z_ijdc,2);
each_best_SUMC_INDIR=C_max-each_best_SUMC_DIR;
c_dir=120*5;
c_indir=240*5;
each_best_fit2_4=c_dir.*each_best_SUMC_DIR+c_indir.*each_best_SUMC_INDIR;
for i=1:generation_size
    each_best_RESC(i,:)=length(find(each_best_y_ijdc(i,:)==0));
end
each_best_RESN=ceil(each_best_RESC./2);
each_best_fit2_5=1000*5.*each_best_RESC;
each_best_fit2=each_best_fit2_1+each_best_fit2_2+each_best_fit2_3+each_best_fit2_4+each_best_fit2_5;
A_jiche=1.44;
B_jiche=0.0099;
C_jiche=0.000298;
A_cheliang=0.92;
B_cheliang=0.0048;
C_cheliang=0.000125;
G_0=128;
m_jun=17.5;
m_0=22.5;
gamma=0.65;
f_jiche=A_jiche+each_best_v_jd.*B_jiche+each_best_v_jd.^2.*C_jiche;
f_cheliang=A_cheliang+each_best_v_jd.*B_cheliang+each_best_v_jd.^2.*C_cheliang;
F_zu=(f_jiche.*G_0+f_cheliang.*(5*each_best_C_JD.*m_jun+each_best_RESN.*m_0)).*10;
for i=1:generation_size
    tempx_jdt_1(i,:)=each_best_x_jdt(i,:);
    tempx_jdt_1(tempx_jdt_1==0)=[];
    tempx_jdt_2(i,:)=tempx_jdt_1;
    clear tempx_jdt_1;
end
for i=1:generation_size
    for j=1:J_max
        for k=1:length(L_d)
            if tempx_jdt_2(i,j)==k
                EXWL_D(i,j)=L_d(1,k);
            end
        end
    end
end
each_best_fit3_1=(sum(EXWL_D.*gamma.*F_zu,2)./3.6*10^6).*0.785;
e_dir=5*7.095;
e_indir=5*10.111;
each_best_fit3_2=e_dir.*each_best_SUMC_DIR+e_indir.*each_best_SUMC_INDIR;
each_best_fit3=each_best_fit3_1+each_best_fit3_2./1000;
each_best_fit=(0.25*150000/365/24).*each_best_fit1+each_best_fit2+55.3.*each_best_fit3;
x = 1:1:generation_size;
y = each_best_fit;
plot(x,y)
xlabel('迭代次数')
ylabel('最优目标')
