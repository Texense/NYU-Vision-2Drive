%% L6 convertion function: L6EUse has the same dimensionality as C;
% L6pars is a cell containing parameters for the linear function

function y = L6Convert(x, L6pars)
    y = L6pars{1} * (x - L6pars{2});
    % Apply the initial linear mapping
    if strcmp(L6pars{end},'quadratic') 
        % in this case, we will use the following three points to determine
        % an inverse function of quadratic function
        x_data = L6pars{4}; y_data = L6pars{3};
        % Create the matrix A for the system of equations
        A = [x_data.^2, x_data, ones(3, 1)];

        % Solve for the coefficients [a; b; c]
        Quad_coeff = A \ y_data;

        % Display the coefficients
        a = Quad_coeff(1);
        b = Quad_coeff(2);
        c = Quad_coeff(3);
        % fprintf('The quadratic function is y = %.4fx^2 + %.4fx + %.4f\n', a, b, c);
        xAdj = x(x > y_data(1));
        y(y > x_data(1)) = (-b + sqrt(b^2 - 4*a*c + 4*a*xAdj)) / (2*a);
    else % piecewise linear
        % Number of pairs beyond the threshold
        numPairs = (length(L6pars) - 3) / 2;
        if length(L6pars)>=3
            % Arrays for piecewise linear interpolation
            xPoints = [L6pars{3}];  % Starting with the threshold
            yPoints = [L6pars{3}];  % Assuming y = x at the threshold

            % Construct the arrays for interpolation based on the provided rules
            for n = 2:numPairs+1
                yPoints(end+1) = L6pars{2*n+1};  % y values to be mapped
                xPoints(end+1) = L6pars{2*n};    % Corresponding y values after mapping
            end

            % Ensure xPoints are in increasing order along with their corresponding yPoints
            [xPoints, sortIdx] = sort(xPoints, 'ascend');
            yPoints = yPoints(sortIdx);
            IdInter = y > L6pars{3} & y <= xPoints(end);
            IdExter = y > xPoints(end);
            y(IdInter) = interp1(xPoints, yPoints, y(IdInter), 'linear');
            y(IdExter) = interp1(xPoints, yPoints, y(IdExter), 'linear', 'extrap');
        end
    end
end


% function L6EUse = L6Convert(C,L6pars)
% 
% if length(L6pars)==2
%     L6EUse =  L6pars{1}*(C-L6pars{2});
% elseif length(L6pars) >= 3
%     BentStart = L6pars{3} % starting point to bend
%     
% 
%     L6EUsePre = L6pars{1}*(C-L6pars{2});
%     L6EUse = L6EUsePre;
%     L6EUse(L6EUse > L6pars{3}) = ...
%         L6pars{3} + (L6EUsePre(L6EUsePre > L6pars{3}) - L6pars{3}) * ...
%         (L6pars{5} - L6pars{3})/(L6pars{4}- L6pars{3});
% else
%     error('Illigal L4->L6 parameters')
% end
% 
% end