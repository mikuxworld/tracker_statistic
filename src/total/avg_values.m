temp=[];
for tracker_index=1:size(trackerW,2)
    states=trackerW(tracker_index).states(1:3,:);
    velocity=states(:,2:end)-states(:,1:end-1);
    acc=velocity(:,2:end)-velocity(:,1:end-1);
    
    acc_norm=sum(abs(acc).^2,1).^(1/2);
    velocity_norm=sum(abs(velocity).^2,1).^(1/2);
    
    v_a_dot=sum(velocity(:,1:end-1).*acc,1);
    a_tan=v_a_dot./velocity_norm(1:end-1);
    a_tan_d=a_tan(2:end)-a_tan(1:end-1);
    a_norm=(abs(acc_norm).^2.-abs(a_tan).^2).^(1/2);
    a_norm_d=a_norm(2:end)-a_norm(1:end-1);
    temp=[temp (a_tan(velocity_norm(1:end-2)>1.5))];
 
end
figure;
temp=temp(temp<5);
temp=temp(temp>-5);


mean(temp)
exp(std(temp))
h1=histogram(temp);
title('全体切向加速度分布');
xlabel('mm/f^2');
ylabel('count');
%saveas(gca,'../../statistic/acc_tan.png');
%saveas(gca,'../../statistic/acc_tan.fig');

clear states velocity acc acc_norm velocity_norm v_a_dot a_tan a_norm;
