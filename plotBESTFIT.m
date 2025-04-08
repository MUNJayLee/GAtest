x = 1:1:generation_size+1;
y = each_best_fitness;
plot(x,y)
xlabel('迭代次数')
ylabel('最优适应度')