function fitness_value_temp=constraints(x_jdt,y_ijdc,TT)
global T_max J_max C_max  maintenance  minintervaltime maxtsegs
global mintsegs Yardcap pop_size  protoC_TI protoC_SUMI
M=NaN;
fitness_value_temp=zeros(1,pop_size);
%% 时间窗约束
for i=1:pop_size
    for j=1:length(maintenance)
        if x_jdt(i,maintenance(j))~=0
            fitness_value_temp(:,i)=M;
        end
    end
end

% %% 通行能力限制
% for i=1:pop_size
%     tdayeach1=length(find(TT(i,:)<24));
%     tdayeach2=length(find(TT(i,:)>=24 & TT(i,:)<48));
%     tdayeach3=length(find(TT(i,:)>=48 & TT(i,:)<72));
%     tdayeach4=length(find(TT(i,:)>=72 & TT(i,:)<96));
%     tdayeach5=length(find(TT(i,:)>=96 & TT(i,:)<120));
%     tdayeach6=length(find(TT(i,:)>=120 & TT(i,:)<144));
%     tdayeach7=length(find(TT(i,:)>=144 & TT(i,:)<168));
%     tdayeach(i,:)=[tdayeach1,tdayeach2,tdayeach3,tdayeach4,tdayeach5,tdayeach6,tdayeach7];
%     for j=1:7
%         if tdayeach(i,j)>3
%             fitness_value_temp(:,i)=M;
%         end
%     end
% end

%% 开行条件约束
C_JD=[];
for i=1:pop_size
    for j=1:J_max
        C_JD(i,j)=sum(sum(y_ijdc(i,:)==j));
    end
end
n_JD=ceil(C_JD./2);
for i =1:pop_size
    for j=1:J_max
        if C_JD(i,j)>2*maxtsegs || C_JD(i,j)<2*mintsegs
            fitness_value_temp(:,i)=M;
        end
    end
end
% 
% %% 余量约束
% RESC=C_max-sum(C_JD,2);
% for i=1:pop_size
%     if RESC>50
%         fitness_value_temp(:,i)=M;
%     end
% end

%% 堆场堆存能力约束（YARDCON）
    TEMPprotoC_TI=protoC_TI';%船舶到港时间
    TEMPprotoC_TI(:,[1])=[];
    TEMPprotoC_SUMI=protoC_SUMI';%船舶运载箱数
for i =1:pop_size
%     TEMPprotoC_TI=protoC_TI';%船舶到港时间
%     TEMPprotoC_TI(:,[1])=[];
%     TEMPprotoC_SUMI=protoC_SUMI';%船舶运载箱数
    TEMPYARDCON=[sort(TT(i,:)),0,TEMPprotoC_TI;-C_JD(i,:),TEMPprotoC_SUMI];%班列时刻，船的时刻，负的班列运载箱数，正的船的运载箱数
    TEMPYARDCON_1=sortrows(TEMPYARDCON',1)';
    TEMPYARDCON_1(3,:)=cumsum(TEMPYARDCON_1(2,:));%累加
    [~,py]=size(TEMPYARDCON_1);
    for j=1:py
        if TEMPYARDCON_1(3,j)<0 || TEMPYARDCON_1(3,j)>Yardcap
            fitness_value_temp(:,i)=M;
        end
    end
%     YARDCON(i,:)=TEMPYARDCON_1(3,:);
end
% 
% [~,py]=size(YARDCON);
% for i=1:pop_size
%     for j=1:py
%         if YARDCON(i,j)<0 || YARDCON(i,j)>Yardcap %任意一时刻的累加箱量大于容量或小于0都违背约束
%             fitness_value_temp(:,i)=M;
%         end
%     end
% end

%% 装车作业能力约束
TEMPx_jdt=zeros(pop_size,T_max);
for i=1:pop_size
    for j=1:T_max
        if x_jdt(i,j)~=0
            TEMPx_jdt(i,j)=1;
        end
    end
end
for i=1:pop_size
    TEMPx_jdt_2=[1:T_max;TEMPx_jdt(i,:)];
    DEL_index=find(TEMPx_jdt_2(2,:)==0);
    TEMPx_jdt_2(:,DEL_index)=[];
    for j=1:J_max-1
        if TEMPx_jdt_2(1,j+1)-TEMPx_jdt_2(1,j)<minintervaltime
            fitness_value_temp(:,i)=M;
        end
    end
end
end