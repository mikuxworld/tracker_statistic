function [ trackers_new ] = filter_overlapped_trace( trackers )
    %先过滤有效点大于10的轨迹
    %之后考察两两轨迹对，如果重合度高，取最长的
    count=0;
    k=[trackers(:).end]-[trackers(:).start];
    trackerW=trackers(k>10);
    trackers_new=[];
    for i=1:size(trackerW)
        flag=1;
        i
        for j=1:size(trackerW)
            if i~=j
                valid=pair_filter(trackerW,[i j]);
                if valid==0
                    flag=0;
                    break;
                end
            end
        end
        if flag==1
            count=count+1;
            trackers_new=[trackers_new trackerW(i)];
            
        end
    end
end

function valid=pair_filter(trackerW,pair)
    index1=pair(1);
    index2=pair(2);
    states1=trackerW(index1).states(1:3,:);
    states2=trackerW(index2).states(1:3,:);
    timer1=trackerW(index1).start:trackerW(index1).end;
    timer2=trackerW(index2).start:trackerW(index2).end;
    time_both_start=max(timer1(1),timer2(1));
    time_both_end=min(timer1(end),timer2(end));
    length1=size(timer1,2);
    length2=size(timer2,2);
    
    if time_both_start>=time_both_end
        valid=1;
        return;
    end
    
    %-----------filter--------------
    filter_min_avg_dist=4;
    filter_min_dist=0.05;
    %------1. too close trace -all--------------
    temp_states1=states1(1:3,find(timer1==time_both_start):find(timer1==time_both_end));
    temp_states2=states2(1:3,find(timer2==time_both_start):find(timer2==time_both_end));
    temp_diff=temp_states1-temp_states2;
    temp_sum=0; 
    for i=1:size(temp_diff,2)
        temp_dist=norm(temp_diff(1:3,i));
        if temp_dist<filter_min_dist && (length1<length2 || (length1==length2 && index1<index2))
            valid=0;
            return;
        end
        temp_sum=temp_sum+temp_dist;
    end
    
    if temp_sum/(time_both_end-time_both_start+1)<filter_min_avg_dist && (length1<length2 || (length1==length2 && index1<index2))
        valid=0;
        return;
    end
    valid=1;
end