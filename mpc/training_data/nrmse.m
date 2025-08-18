predict = cell2mat(output);
error = cell2mat(error);
target = predict+error;

y = rmse(target, predict)/mean(target)

function e = rmse(y,yhat)

e = sqrt(sum((y-yhat).^2)/length(y));

end