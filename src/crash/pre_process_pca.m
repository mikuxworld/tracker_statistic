left_delta_time=12;
right_delta_time=5;
record_crash_washed=filter_pca(trackerW,record_crash,left_delta_time,right_delta_time);
feature_v_norm=[];
feature_acc_norm=[];
feature_acc_on_v_past=[];
feature_acc_on_v_past_norm=[];
feature_v_ang=[];
record_crash_washed_double=[];
for outer_index=1:size(record_crash_washed,2)
    pair=record_crash_washed(1,outer_index);
    record_crash_washed_double=[record_crash_washed_double pair pair];
    time_crash=floor(pair.time_end);
    index1=pair.id(1);
    index2=pair.id(2);
    states1=trackerW(index1).states(1:3,:);
    states2=trackerW(index2).states(1:3,:);
    timer1=trackerW(index1).start:trackerW(index1).end;   
    timer2=trackerW(index2).start:trackerW(index2).end;   
    
    %cut time(left_delta_time---crash---right_delta_time)
    if left_delta_time~=0 || right_delta_time~=0
        start_time1=max(timer1(1),time_crash-left_delta_time);
        end_time1=min(timer1(end),time_crash+right_delta_time);
        states1=states1(1:3,find(timer1==start_time1):find(timer1==end_time1));
        timer1=timer1(find(timer1==start_time1):find(timer1==end_time1));   
        
        start_time2=max(timer2(1),time_crash-left_delta_time);
        end_time2=min(timer2(end),time_crash+right_delta_time);
        states2=states2(1:3,find(timer2==start_time1):find(timer2==end_time1));
        timer2=timer2(find(timer2==start_time1):find(timer2==end_time1));  
    end
    
    velocity1=states1(1:3,2:end)-states1(1:3,1:end-1);
    acc1=velocity1(1:3,2:end)-velocity1(1:3,1:end-1);
    
    [ v1_norm,acc1_norm, acc1_on_v1_past, acc1_on_v1_past_norm, r1, v1_ang, acc1_ang] = calc_trace_attribute( states1 );
    
    [ v2_norm,acc2_norm, acc2_on_v2_past, acc2_on_v2_past_norm, r2, v2_ang, acc2_ang] = calc_trace_attribute( states2 );
    
    feature_v_norm=[feature_v_norm; v1_norm+v2_norm*1i];
    feature_acc_norm=[feature_acc_norm; acc1_norm+acc2_norm*1i];
    feature_acc_on_v_past=[feature_acc_on_v_past; acc1_on_v1_past+acc2_on_v2_past*1i];
    feature_acc_on_v_past_norm=[feature_acc_on_v_past_norm; acc1_on_v1_past_norm+acc2_on_v2_past_norm*1i];
    feature_v_ang=[feature_v_ang; v1_ang];
    
    feature_v_norm=[feature_v_norm; v2_norm+v1_norm*1i];
    feature_acc_norm=[feature_acc_norm; acc2_norm+acc1_norm*1i];
    feature_acc_on_v_past=[feature_acc_on_v_past; acc2_on_v2_past+acc1_on_v1_past*1i];
    feature_acc_on_v_past_norm=[feature_acc_on_v_past_norm; acc2_on_v2_past_norm+acc1_on_v1_past_norm*1i];
    feature_v_ang=[feature_v_ang; v1_ang];
    
    %feature_vector=[feature_vector; v1_norm];

end


feature_vector=feature_v_norm;
portion=1;

[pc,score,latent,tsquare,explained] =pca(feature_vector);
percentage_list=cumsum(latent)./sum(latent);
dimesion=find(percentage_list>=portion);
tran=pc(:,1:dimesion(1));
recons_mean=mean(feature_vector,1);
feature_vector= bsxfun(@minus,feature_vector,mean(feature_vector,1));
feature_vector= feature_vector*tran;
median_vector=median(feature_vector,1);

% recons=feature_vector*pinv(tran);
% recons=recons*0;
% %recons=recons+recons_mean;
% recons= bsxfun(@plus,recons,recons_mean);
% corrcoef(recons,feature_v_norm)

% recons_=(ones(1,1))*pinv(pc(:,4));
% %recons_= bsxfun(@plus,recons_,recons_mean);
% figure(6);
% hold on;
% recons_real=real(recons_);
% recons_imag=imag(recons_);
% plot(recons_real,'b');
% plot(recons_imag,'r');
% return;
%-----------select cluster-------------
diff_vec=feature_vector-repmat(median_vector,size(feature_vector,1),1);
dist_vec=[];
for i=1:size(diff_vec)
    dist_vec=[dist_vec norm(diff_vec(i,:))];
end
dist_median=median(dist_vec);
selected_item=find(dist_vec<dist_median);

feature_vector_real=real(feature_vector);
feature_vector_imag=imag(feature_vector);
% selected_item=intersect(selected_item,find(feature_vector_real(:,1)-feature_vector_real(:,2)>0));
% selected_item=intersect(selected_item,find(feature_vector_real(:,2)-feature_vector_real(:,3)<0));
% selected_item=intersect(selected_item,find(feature_vector_real(:,3)-feature_vector_real(:,4)>0));
% 
 %selected_item=intersect(selected_item,find(feature_vector_real(:,1)>0));
 %selected_item=intersect(selected_item,find(feature_vector_real(:,2)<0));
 selected_item=intersect(selected_item,find(feature_vector_real(:,3)<-1));
 selected_item=intersect(selected_item,find(feature_vector_real(:,4)>1));
% selected_item=intersect(selected_item,find(feature_vector_imag(:,1)-feature_vector_imag(:,2)<0));
% selected_item=intersect(selected_item,find(feature_vector_imag(:,2)-feature_vector_imag(:,3)>0));
% selected_item=intersect(selected_item,find(feature_vector_imag(:,3)-feature_vector_imag(:,4)<0));
% 
selected_item=intersect(selected_item,find(feature_vector_imag(:,1)<0));
%selected_item=intersect(selected_item,find(feature_vector_imag(:,2)>1));
selected_item=intersect(selected_item,find(feature_vector_imag(:,3)>-1));
selected_item=intersect(selected_item,find(feature_vector_imag(:,4)<1));
%selected_item=intersect(selected_item,find(feature_vector(:,4)-feature_vector(:,5)<0));

%----------------using pca result, revise detect_set-----------
reduced_vector=feature_vector(selected_item,:);
record_crash_washed=record_crash_washed_double(:,selected_item);
feature_v_norm=feature_v_norm(selected_item,:);
feature_acc_norm=feature_acc_norm(selected_item,:);
feature_acc_on_v_past=feature_acc_on_v_past(selected_item,:);
feature_acc_on_v_past_norm=feature_acc_on_v_past_norm(selected_item,:);
%recons=recons(selected_item,:);
% figure(1);
% hold on;
% feature_vector=real(feature_vector);
% for i=1:size(feature_vector)
%     
%     plot3(feature_vector(i,1),feature_vector(i,2),feature_vector(i,3),'r+');
% end
% xlabel('pv1');
% ylabel('pv2');
% zlabel('pv3');
% plot3(median_vector(1),median_vector(2),median_vector(3),'bh');

figure(1);
hold on;
feature_vector=real(reduced_vector);
for i=1:size(feature_vector)
    
    plot(feature_vector(i,:),'b');
end
plot(mean(feature_vector),'r+');
plot(median(feature_vector),'r*');
plot(std(feature_vector)+mean(feature_vector),'r');
plot(-std(feature_vector)+mean(feature_vector),'r');
grid on;


figure(2);
hold on;
feature_vector=imag(reduced_vector);
for i=1:size(feature_vector)
    
    plot(feature_vector(i,:),'b');
end
plot(mean(feature_vector),'r+');
plot(median(feature_vector),'r*');
plot(std(feature_vector)+mean(feature_vector),'r');
plot(-std(feature_vector)+mean(feature_vector),'r');
grid on;


figure(3);
feature_vector=real(feature_v_norm);
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

figure(4);
feature_vector=imag(feature_v_norm);
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
