function H = hurst(x)
//Estimate the Hurst parameter of sample X via the rescaled range statistic.
//Calling Sequence:
//hurst(x)
//Parameters:
//x: x is a vector or matrix
//Description:
//This function estimates the Hurst parameter of sample x using the rescaled range statistic.
//If x is a matrix, the parameter is estimated for every column.
//Examples:
//hurst([10, 15, 3])
//ans = 0.045019

  funcprot(0);
  if (argn(2) ~= 1)
    error("hurst: wrong number of input arguments");
  end

  if (isscalar(x))
    error ("hurst: argument must not be a scalar");
  end
  if (isvector(x))
    x = x(:);
  end

  [xr, xc] = size (x);

  s = stdev(x);
  w = cumsum(x - mean(x));
  RS = (max(w) - min(w)) ./ s;
  H = log(RS) / log(xr);

endfunction

//input validation:
//assert_checkerror("hurst()", "hurst: wrong number of input arguments");
//assert_checkerror("hurst(1, 2, 3)", "Wrong number of input arguments.");
//assert_checkerror("hurst(1)", "hurst: argument must not be a scalar");

//tests:
//assert_checkalmostequal(hurst([1, 5, 7, 14, 6]), 0.31180, 5*10^-5);
//assert_checkalmostequal(hurst([3; 6; 9; 5]), 0.24271, 5*10^-5);
//assert_checkalmostequal(hurst([-1, 9, 4; 7, 4, -3; 6, 12, -18]), 1.06622, 5*10^-5);
