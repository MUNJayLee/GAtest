global mintranstime maxtsegs mintsegs C_TJ traineachd C_JD

y_ijdc=zeros(pop_size,C_max);

%�����Ѿ����ɵİ��о�����з���
%ԭ��������ֱȡ�������װ����װж����ͣ���İ���ȥ����ͬ����ֱ��װ��ֱ���ﵽ������������ٿ��Ƕѳ���
TT=[];
TD=[];
DEL_index=[];
for i=1:pop_size
    TEMPTTTD=1:T_max;
    DEL_index=find(x_jdt(i,:)~=0);
    TT(i,:)=TEMPTTTD(DEL_index);%��ȡÿ���г����е�ʱ��
    TD(i,:)=TEMPTTTD(x_jdt(i,DEL_index));%��ȡÿ���г����еķ���
end

TEMPassign=[C_IDT(3,:);C_IDT(4,:)];%����C_IDT��3��4�У��ֱ��ʾ��װ���Ŀ�ķ���͵���ʱ��
C_TJ=[];%��װ������з�����ʱ��
for i =1:pop_size
    TEMPtrain=[1:J_max;TD(i,:);TT(i,:)];%�γ���ʱ������Ϣ���������Ǳ�š�����ʱ��
    TEMPtrain(5,:)=0;%���е�װ����
    for j=1:C_max
        TEMP_inedx=find(TEMPassign(1,j)==TEMPtrain(2,:));%Ѱ��ͬ�������
        %������п���ʱ���뼯װ��ж��ʱ��Ĳ�ֵ��
        %��Ϊ<0����װ���ڰ��е���ʱ��֮ǰ�ִ�,�ɽ���װж
        %��Ϊ>=0,��װ���ڰ��е���ʱ��֮��ִ����װж
        TEMPtrain(4,:)=TEMPassign(2,j)-TEMPtrain(3,:);
        % �޶�ת��ʱ��Լ��������װ��Ӱ�����ж�£���������������Ҫ����ʱ�䣬С�����ʱ�����޷��ϳ�
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

