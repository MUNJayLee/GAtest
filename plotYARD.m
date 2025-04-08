bestTEMPTTTD=[1:T_max;bestx_jdt];
DEL_index=find(bestTEMPTTTD(2,:)==0);
bestTEMPTTTD(:,DEL_index)=[];
bestTT(1,:)=bestTEMPTTTD(1,:);%获取每节列车开行的时间
TEMPprotoC_TI=protoC_TI';
TEMPprotoC_TI(:,[1])=[];
TEMPprotoC_SUMI=protoC_SUMI';
for j=1:J_max
    bestC_JD(1,j)=sum(sum(besty_ijdc(1,:)==j));
end
TEMPbestYARDCON=[sort(bestTT(1,:)),0,TEMPprotoC_TI;-bestC_JD(1,:),TEMPprotoC_SUMI];
TEMPbestYARDCON_1=sortrows(TEMPbestYARDCON',1)';
TEMPbestYARDCON_1(3,:)=cumsum(TEMPbestYARDCON_1(2,:));
TEMPbestYARDCON_2=sortrows([TEMPbestYARDCON_1(1,:),TEMPbestYARDCON_1(1,:);TEMPbestYARDCON_1(3,:),TEMPbestYARDCON_1(3,:)]',1)';
TEMPbestYARDCON_3=[[0;0],TEMPbestYARDCON_2,[T_max;0]];
bestYARDCON(1,:)=TEMPbestYARDCON_3(2,:);
TEMPbestTIMECON_1=[1:T_max;bestx_jdt(1,:)];
DEL_index=find(TEMPbestTIMECON_1(2,:)==0);
TEMPbestTIMECON_1(:,DEL_index)=[];
TEMPbestTIMECON_2=sort([TEMPbestTIMECON_1(1,:),TI']);
TEMPbestTIMECON_3=[TEMPbestTIMECON_2,T_max];
TIMEbestCON=kron(TEMPbestTIMECON_3,ones(1,2));
stairs(TIMEbestCON(1,:),bestYARDCON(1,:));
xlabel('时间')
ylabel('集装箱数量')
bestQ=trapz(TEMPbestYARDCON_3(1,:),bestYARDCON);
bestQmax=max(TEMPbestYARDCON_1(3,:));
bestmeanQ=bestQ/C_max;


