function x = autoreg_matrix (y, k)
// Given a time series (vector) Y, return a matrix with ones in the first column and the first K lagged values of Y in the other columns.
//Calling Sequence:
//autoreg_matrix(Y, K)
//Parameters:
//Y: vector
//K: scalar or vector
//Description:
// Given a time series (vector) Y, return a matrix with ones in the first column and the first K lagged values of Y in the other columns.
//In other words, for T > K, '[1, Y(T-1), ..., Y(T-K)]' is the t-th row of the result.
//The resulting matrix may be used as a regressor matrix in autoregressions.
//Examples:
//autoreg_matrix([1,2,3],2)
//ans =
//      1.    0.    0.
//      1.    1.    0.
//      1.    2.    1.

  funcprot(0);

  if (argn(2) ~= 2)
    error("autoreg_matrix: wrong number of input arguments") ;
  end

  if (~ (isvector (y)))
    error ("autoreg_matrix: y must be a vector");
  end

  T = length (y);
  y = matrix(y, T, 1);
  x = ones (T, k+1);
  for j = 1 : k
    x(:, j+1) = [(zeros(j, 1)); y(1:T-j)];
  end

endfunction

//input validation:
//assert_checkerror("autoreg_matrix(1)", "autoreg_matrix: wrong number of input arguments");
//assert_checkerror("autoreg_matrix(1, 2, 3)", "Wrong number of input arguments.");
//assert_checkerror("autoreg_matrix(1, 2)", "autoreg_matrix: y must be a vector");
//assert_checkerror("autoreg_matrix([1, 2; 3, 4], 2)", "autoreg_matrix: y must be a vector");

//tests:
//assert_checkequal(autoreg_matrix([1, 2, 3], 2), [1, 0, 0; 1, 1, 0; 1, 2, 1]);
//assert_checkequal(autoreg_matrix([1, 2, 3], 1), autoreg_matrix([1; 2; 3], 1));
//assert_checkequal(autoreg_matrix([1+2*%i, 5+4*%i, -4*%i, -1-6*%i], 1), [1, 0; 1, 1 + 2*%i; 1, 5 + 4*%i; 1, -4*%i]);
//assert_checkequal(autoreg_matrix([1+2*%i, 5+4*%i, -4*%i, -1-6*%i], 3), autoreg_matrix([1+2*%i, 5+4*%i, -4*%i, -1-6*%i], 3));
