function  [H] = file_to_matrix(input)
% Converts the file format of the code into the H matrix (double)
%   N, M
%   dv col indices (starting from 1)
%   dc row indices (starting from 1)

fid = fopen(input);
code_dim = str2num(fgetl(fid));
fclose(fid);
fid = fopen(input);
H = cell(code_dim(1),1);

for i =1:code_dim(1)+1
    H_cell{i} = str2num(fgetl(fid));
end

H = zeros(H_cell{1}(1), H_cell{1}(2))';

for  j = 1 : size(H, 2)
   disp(j)
   H(H_cell{j+1}(2:end), j) = 1;   
end

fclose(fid);

end
