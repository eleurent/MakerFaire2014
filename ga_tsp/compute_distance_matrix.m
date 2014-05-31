function[matrix] = compute_distance_matrix(point_list,list_size)

    matrix=zeros(list_size,list_size);
    
    for i=1:list_size
        for j=1:list_size
            
            dx=point_list(2*i-1,1) - point_list(2*j-1,1);
            dy=point_list(2*i,1)   - point_list(2*j,1);
            matrix(i,j) = sqrt(dx*dx + dy*dy);
            
        end
    end
            
end
