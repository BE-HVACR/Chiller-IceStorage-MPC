%prepare delayed inputs
function xd = delay(x,dl)
ncol = size(x,2);
xd = [];
for j=1:ncol 
    v = x(:,j);
    for i = 1:dl
       d = v(1:end-i,1);
       d = [zeros(i,1);d];
       v=[v,d];
    end
    xd = [xd,v];
end

% drop the first few items

end