%------parameters---------
% maxium distance of two flies which we consider as a 'pair'
maxium_detection_distance=100;
% minium distance that we consider as a 'collision'
minium_crash_distance=5;

%-----wash the data----------------
k=[trackers(:).end]-[trackers(:).start];
trackerW=trackers(k>20);

%-----------sort the trace by time---------------
% record_t is a struct which record fruit flies in each frame
% 'id' means the index of the fruit fly in tr
record_t=struct('id',{[]},'states',{[]});
for i=1:max([trackers(:).end])
    record_t(i).id=[];
    record_t(i).states=[];
    record_t(i).velocity=[];
end
for i = 1:size(trackerW,2)
    states=trackerW(i).states;
    velocity=states(1:3,2:end)-states(1:3,1:end-1);
    start=trackerW(i).start;
    trackerW(i).Bs=[];
    for j=1:size(states,2)-1
        current=j+start-1;
        record_t(current).id=[record_t(current).id i];
        record_t(current).states=[record_t(current).states states(:,j)];
        record_t(current).velocity=[record_t(current).velocity velocity(:,j)];
    end
end

record_crash=struct('id',{[]},'states',{[]});
%-----------find crash pair---------------------
result_num=0;
for time=1:size(record_t,2)
    states=[record_t(time).states(:,:)];
    velocity=[record_t(time).velocity(:,:)];
   
    id=record_t(time).id;
    for i=1:size(id,2)
        for j=1:size(id,2)
            if i==j
                continue;
            end
            %filter by maxium detection distance
            if (distance(states(1:3,i),states(1:3,j))<maxium_detection_distance)     
                delta_p=states(1:3,i)-states(1:3,j);
                delta_v=velocity(1:3,i)-velocity(1:3,j);                   
                delta_t=delta_p./-delta_v;
                min_dist=norm(cross(delta_p,delta_v))/norm(delta_v);
                min_dist_t=sqrt(norm(delta_p)^2-min_dist^2)/norm(delta_v);
                pos_crash_A=states(1:3,i)+min_dist_t*velocity(1:3,i);
                pos_crash_B=states(1:3,j)+min_dist_t*velocity(1:3,j);
                % filter by minium distance 
                % let delta_t>0 to ensure two flies will collision in the
                % future but not the past
                if min_dist<minium_crash_distance && min(delta_t)>0
                    
                    % B_record is a temp struct for recording Bs
                    B_record=[];
                    B_record.index_a=id(i);
                    B_record.index_b=id(j);
                    B_record.time_detect=time;
                    B_record.time_end=time+min_dist_t;
                    B_record.min_dist=min_dist;
                    B_record.pos_a=pos_crash_A;
                    B_record.pos_b=pos_crash_B;
                    
                    % add new result in trackerW, which is the method used
                    % to record multiple Bs in newest version
                    trackerW(id(i)).Bs=[trackerW(id(i)).Bs; B_record];
                    
                    %add new result in record_crash, fallback method for
                    %only two fruit flies
                    result_num=result_num+1;
                    record_crash(result_num).time_start=time;
                    record_crash(result_num).time_end=time+min_dist_t;
                    record_crash(result_num).id=[id(i) id(j)];
                    record_crash(result_num).states=[states(:,i) states(:,j)];
                    record_crash(result_num).velocity=[velocity(:,i) velocity(:,j)];
                    record_crash(result_num).delta_time=min_dist_t;
                    record_crash(result_num).min_dist=min_dist;
                end
                
            end
        end
    end
end

clear time B_record;
clear states velocity start k;
clear delta_p delta_v delta_t min_dist min_dist_t;
clear current i id j;