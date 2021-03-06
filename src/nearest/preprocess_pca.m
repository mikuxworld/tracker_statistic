delta_time=12;
detect_set_washed=pca_trace_filter(trackerW,detect_set,delta_time);
feature_vector=[];
feature_v1_norm=[];
feature_acc1_norm=[];
feature_acc1_on_v1_past=[];
feature_acc1_on_v1_past_norm=[];
feature_v1_ang=[];
for outer_index=1:size(detect_set_washed)
    pair=detect_set_washed(outer_index,:);
    
    time_nearest=pair(1);
    index1=pair(2);    
    states1=trackerW(index1).states(1:3,:);
    timer1=trackerW(index1).start:trackerW(index1).end;   
    if delta_time~=0
        start_time1=max(timer1(1),time_nearest-delta_time);
        end_time1=min(timer1(end),time_nearest+delta_time);
        states1=states1(1:3,find(timer1==start_time1):find(timer1==end_time1));
        timer1=timer1(find(timer1==start_time1):find(timer1==end_time1));    
    end
    velocity1=states1(1:3,2:end)-states1(1:3,1:end-1);
    acc1=velocity1(1:3,2:end)-velocity1(1:3,1:end-1);
    
    v1_norm=[];
    acc1_norm=[];
    acc1_on_v1_past=[];
    v1_ang=[];
    acc1_ang=[];
    acc1_on_v1_past_norm=[];
    
    r1=[];
    av1=[];
    for i=1:size(acc1,2)
        v1=velocity1(1:3,i);
        v1_past=velocity1(1:3,i);%与加速度有关的用当前帧v
        a1=acc1(1:3,i);       
        %=====计算速度和加速度大小======
        v1_norm=[v1_norm, norm(velocity1(1:3,i))];
        acc1_norm=[acc1_norm, norm(acc1(1:3,i))];       
        %======切向加速度====
        acc1_on_v1_past=[acc1_on_v1_past, dot(a1,v1_past)/norm(v1_past)];
        %======法向加速度================
        acc1_on_v1_past_norm=[acc1_on_v1_past_norm, sqrt(norm(a1)^2-acc1_on_v1_past(end)^2)];
        %===========计算运动曲率半径===============
        r1=[r1 norm(v1)^2/acc1_on_v1_past_norm(end)];     
    end      
    for i=2:size(acc1,2)
        %==========简记变量初始化=========
        v1=velocity1(1:3,i);
        v1_past=velocity1(1:3,i-1);
        a1=acc1(1:3,i);
        a1_1=acc1(1:3,i-1);
        
        %======计算速度相对上一帧速度的变化角度==========
        v1_ang=[v1_ang acosd(dot(v1,v1_past)/norm(v1)/norm(v1_past))];  
        %======计算加速度相对上一帧加速度的变化角度==========
        acc1_ang=[acc1_ang acosd(dot(a1,a1_1)/norm(a1)/norm(a1_1))];
    end
    feature_v1_norm=[feature_v1_norm; v1_norm];
    feature_acc1_norm=[feature_acc1_norm; acc1_norm];
    feature_acc1_on_v1_past=[feature_acc1_on_v1_past; acc1_on_v1_past];
    feature_acc1_on_v1_past_norm=[feature_acc1_on_v1_past_norm; acc1_on_v1_past_norm];
    feature_v1_ang=[feature_v1_ang; v1_ang];
    %feature_vector=[feature_vector; v1_norm];

end
feature_vector=feature_v1_norm;
portion=0.95;

[pc,score,latent,tsquare,explained] =pca(feature_vector);
percentage_list=cumsum(latent)./sum(latent);
dimesion=find(percentage_list>portion);
tran=pc(:,1:dimesion(1));
feature_vector= bsxfun(@minus,feature_vector,mean(feature_vector,1));
feature_vector= feature_vector*tran;
median_vector=median(feature_vector,1);

figure(4);
hold on;
for i=1:size(feature_vector)
    
    plot3(feature_vector(i,1),feature_vector(i,2),feature_vector(i,3),'r+');
end
xlabel('pv1');
ylabel('pv2');
zlabel('pv3');
plot3(median_vector(1),median_vector(2),median_vector(3),'bh');



%-----------select cluster-------------
diff_vec=feature_vector-repmat(median_vector,size(feature_vector,1),1);
dist_vec=[];
for i=1:size(diff_vec)
    dist_vec=[dist_vec norm(diff_vec(i,:))];
end
dist_median=median(dist_vec);
selected_item=find(dist_vec<dist_median*2);
%selected_item=intersect(selected_item,find(feature_vector(:,1)-feature_vector(:,2)>0));
%selected_item=intersect(selected_item,find(feature_vector(:,2)-feature_vector(:,3)<0));
%selected_item=intersect(selected_item,find(feature_vector(:,3)-feature_vector(:,4)>0));
%selected_item=intersect(selected_item,find(feature_vector(:,4)-feature_vector(:,5)<0));
 %------------------draw ----------------------

%----------------using pca result, revise detect_set-----------
feature_vector=feature_vector(selected_item,:);
detect_set_washed=detect_set_washed(selected_item,:);
feature_v1_norm=feature_v1_norm(selected_item,:);
feature_acc1_norm=feature_acc1_norm(selected_item,:);
feature_acc1_on_v1_past=feature_acc1_on_v1_past(selected_item,:);
feature_acc1_on_v1_past_norm=feature_acc1_on_v1_past_norm(selected_item,:);
%feature_v1_ang=feature_v1_ang(selected_item,:);


figure(1);

hold on;
for i=1:size(feature_vector)
    
    plot(feature_vector(i,:),'b');
end
plot(mean(feature_vector),'r+');
plot(median(feature_vector),'r*');
plot(std(feature_vector)+mean(feature_vector),'r')
plot(-std(feature_vector)+mean(feature_vector),'r')
grid on;

figure(2);

hold on;
for i=1:size(feature_vector)
    
    plot3(feature_vector(i,1),feature_vector(i,2),feature_vector(i,3),'r+');
end
plot3(median_vector(1),median_vector(2),median_vector(3),'bh');

figure(3);
feature_vector=feature_v1_norm;
hold on;
for i=1:size(feature_vector)
    plot(feature_vector(i,:),'b');
%     for j=1:size(feature_vector,2)
%         plot(j,feature_vector(i,j),'k');
%     end
end
plot(mean(feature_vector),'r+');
plot(median(feature_vector),'r*');
plot(std(feature_vector)+mean(feature_vector),'r')
plot(-std(feature_vector)+mean(feature_vector),'r')



