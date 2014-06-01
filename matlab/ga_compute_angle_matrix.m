function[matrix] = ga_compute_angle_matrix(point_list, list_size)

    matrix=zeros(list_size,list_size);
    
    for i=1:list_size
        for j=1:list_size
            for k=1:list_size
            
                dx1=point_list(2*i-1) - point_list(2*j-1);
                dy1=point_list(2*i)   - point_list(2*j);
            
                dx2=point_list(2*k-1) - point_list(2*j-1);
                dy2=point_list(2*k)   - point_list(2*j);
            
                scalar = dx1*dx2 + dy1*dy2;
                cross = dx1*dy2 - dy1*dx2;
                normes = sqrt(dx1*dx1 + dy1*dy1)*sqrt(dx2*dx2 + dy2*dy2);
                quot = scalar/normes;
                
                if (normes ~= 0 && (abs(quot) <= 1 && cross ~= 0))
                    matrix(i,j,k) = cross/abs(cross) * acos(quot);
                else
                    matrix(i,j,k) = 0;
                end
            end
        end
    end
            
end
