x = 1:1:generation_size+1;
y = (1./each_best_fitness)./(3897223.288);
% 5.7813e+06
plot(x,y)
% axis([0 500 3.6*10^6 5.4*10^6])
% axis([0 500   ])
xlabel('迭代次数')
ylabel('最优目标')