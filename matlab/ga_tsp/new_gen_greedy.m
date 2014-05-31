function [gen] = new_gen_greedy(i, list_size, point_list, dista)
    
    gen = zeros(list_size);
    gen(1) = 1;
    aux = 10000000;
    indice = 0;
    
    for n=2:list_size
        for l=1:list_size
            if ((dista(l,n) < aux) && ((l ~= n) && n_appartient(l,gen, list_size)))
                aux = dista(l,n);
                indice = l;
            end
        end
        gen(n)=indice;
    end
    
            
function[boole] = n_appartient(i, gen, list_size)
                
    aux = 0;           
    for k=1:list_size
        if i == gen(k)
            aux = 1;
        end
    end
    boole = (aux == 0);
                