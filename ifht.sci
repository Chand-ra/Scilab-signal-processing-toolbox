function m = ifht(d, n, dim)
//Calculate the inverse Fast Hartley Transform of real input D.
//Calling Sequence:
//m: ifht(d)
//m: ifht(d,n)
//m: ifht(d,n,dim)
//Parameters: 
//d: real or complex scalar or vector
//n: Similar to the options of FFT function
//dim: Similar to the options of FFT function 
//Description:
//Calculate the inverse Fast Hartley Transform of real input d. If d is a matrix, the inverse Hartley transform is calculated along the columns by default.
//The options n and dim are similar to the options of FFT function.
//The forward and inverse Hartley transforms are the same (except for a scale factor of 1/N for the inverse hartley transform), but implemented using different functions.
//The definition of the forward hartley transform for vector d, m[K] = 1/N \sum_{i=0}^{N-1} d[i]*(cos[K*2*pi*i/N] + sin[K*2*pi*i/N]),
//for 0 <= K < N. m[K] = 1/N \sum_{i=0}^{N-1} d[i]*CAS[K*i], for 0 <= K < N.
//Examples:
//ifht(1 : 4)
//ans = [2.5, -1, -0.5, 0]
  
  funcprot(0);
  rhs = argn(2);
  if (rhs < 1 | rhs > 3)
    error("Wrong number of input arguments.");
  end
  dimension = size(d);
  nd = find(dimension ~= 1, 1);
  if (rhs == 3)
    if isempty(n)
      y = fft(d, 1, dim);
    else
      dimension(dim)=n;
      y=fft(resize_matrix(d, dimension), 1, dim);
    end
  elseif (rhs == 2)
    if isempty(n)
      y = fft(d, 1, nd);
    else
      dimension(nd) = n;
      y=fft(resize_matrix(d, dimension), 1, nd)
    end
  else
     y = fft(d, 1, nd);
  end

  m = real(y) + imag(y);

endfunction

//input validation:
//assert_checkerror("ifht()", "Wrong number of input arguments.");
//assert_checkerror("ifht(1, 2, 3, 4)", "Wrong number of input arguments.");

////tests:
//assert_checkequal(ifht(1+2*%i), 3);
//assert_checkequal(ifht((1:4)), [2.5, -1, -0.5, 0]);
//assert_checkequal(ifht([1:4]', 2), [1.5; -0.5]);
//assert_checkequal(ifht([1:4]', 2, 2), [0.5 0.5; 1 1; 1.5 1.5; 2 2]);
//assert_checkequal(ifht([-1 2; 3 -5]), [1 -1.5; -2 3.5]);
//assert_checkalmostequal(ifht([1:3; -2:-5]), [2, -0.7887, -0.2113], 5*10^-4);
//assert_checkequal(ifht([1:3; -2:-5], 1, 1), [1:3]);
//assert_checkequal(ifht([1+2*%i, 3*%i; -4-3*%i, -5*%i]), [-2 -1; 5 4]);
//assert_checkequal(ifht([1+2*%i, 3*%i; -4-3*%i, -5*%i], 1, 2), [3; -7]);
