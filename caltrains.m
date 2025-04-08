function caltrains()
global  J_max D0
global  trainnum C_max coneachd C_IDT C_TJ traineachd

rateachd=coneachd./C_max;
TEMPtraineachd=floor(J_max.*coneachd./C_max);
TEMPtraineachd_2=J_max.*coneachd./C_max-fix(J_max.*coneachd./C_max);
RESJ=J_max-sum(TEMPtraineachd);
[~,POSJD]=sort(TEMPtraineachd_2);
POSJD_2=POSJD(end-RESJ+1:end);
traineachd=TEMPtraineachd;
for i=1:RESJ
    traineachd(1,POSJD_2(1,i))=traineachd(1,POSJD_2(1,i))+1;
end

for i=1:length(D0)
    for j=1:traineachd(1,i)
        TEMPtrainnum(j,i)=D0(1,i);
    end
end

trainnum=TEMPtrainnum(:);
trainnum(trainnum==0)=[];%Èú?¶ÅËæìÂá∫
end
%clear i j rateachd RESJ TEMPtraineachd TEMPtraineachd_2 TEMPtrainnum POSJD POSJD_2