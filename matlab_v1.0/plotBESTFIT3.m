x = 1:1:generation_size+1;
y = (1./each_best_fitness)./(3897223.288);
plot(x,y)
xlabel('迭代次数')
ylabel('最优目标')
