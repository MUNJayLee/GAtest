%% 得到C_I，即每个集装箱按顺序来自那艘船上
[protoC_I]=xlsread('数据集.xlsx',1,'A2:A29');
[protoC_TI]=xlsread('数据集.xlsx',1,'G2:G29');%需要输出
[protoC_NUMBER]=xlsread('数据集.xlsx',1,'B2:E29');
[TI]=xlsread('数据集.xlsx',1,'G2:G29');
coneachd=xlsread('数据集.xlsx',1,'B30:E30');
[protoC_SUMI]=sum(protoC_NUMBER,2);
C_max=sum(protoC_SUMI);
for i = 1:length(protoC_I)
    for j=1:protoC_SUMI(i,1)
        TEMPC_I(i,j)=protoC_I(i,1);
    end
end
TEMPC_I_2=reshape(TEMPC_I',1,[]);
TEMPC_I_2(TEMPC_I_2==0)=[];%TEMPC_I_2(find(TEMPC_I_2==0))=[];
C_I=[zeros(1,protoC_SUMI(1,1)),TEMPC_I_2];

%% 得到C_TI，即每个集装箱随班列抵达的时间
for i = 1:length(protoC_I)
    for j=1:protoC_SUMI(i,1)
        TEMPC_TI(i,j)=protoC_TI(i,1);
    end
end
TEMPC_TI_2=reshape(TEMPC_TI',1,[]);
TEMPC_TI_2(TEMPC_TI_2==0)=[];
C_TI=[zeros(1,protoC_SUMI(1,1)),TEMPC_TI_2];

%% 得到C_D，即每个集装箱按顺序去往的方向
D=[1,2,3,4]';%方向集合
C_D=[];
for m=1:length(protoC_I)
    TEMPC_D=protoC_NUMBER(m,:)';
    for i=1:length(D)
        for j=1:TEMPC_D(i,1)
            TEMPC_D_2(i,j)=D(i,1);
        end
    end
    TEMPC_D_3=reshape(TEMPC_D_2',1,[]);
    TEMPC_D_3(TEMPC_D_3==0)=[];
    C_D=[C_D,TEMPC_D_3];
    clear TEMPC_D_2;
    clear TEMPC_D_3;
end


%% 得到C_ID矩阵
%第一行集装箱C编号，第二行集装箱来源班轮编号C_I，第三行集装箱去向编号C_D
C=[1:C_max];
C_IDT=[C;C_I;C_D;C_TI];

clear i j m TEMPC_D TEMPC_I TEMPC_I_2 TEMPC_TI TEMPC_TI_2