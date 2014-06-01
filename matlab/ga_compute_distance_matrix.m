function matrix = ga_compute_distance_matrix(point_list)
    matrix=zeros(size(point_list,1),size(point_list,1));
    for i=1:size(point_list,1)
        for j=1:size(point_list,1)
            matrix(i,j) = norm(point_list(i,:)-point_list(j,:));  
        end
    end
end
