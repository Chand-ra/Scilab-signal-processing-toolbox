function y = sinewave (m, n, d)
//Return a m-element vector with the i-th element given by {sin (2 * pi * (i+d-1) / n}.
//Calling Sequence:
//y= sinewave(m)
//y= sinewave(m,n)
//y= sinewave(m,n,d)
//Parameters:
//m: Input vector
//n: The default value for n is m
//d: The default value for d is 0 
//Examples:
//sivewave(1, 4, 1)
//ans = 1

  funcprot(0);
  rhs = argn(2);
  if (rhs < 1 | rhs > 3) then
    error("sinewave: wrong number of input arguments");
  end
  
  if (m < 0) then
    error("sinewave: arg1 (m) must be non-negative");
  end

  if (rhs < 2) then
    n = m;
  end
  if (n == 0) then
    error("sinewave: arg2 (n) must be non-zero");
  end
  
  if (rhs < 3) then
    d = 0;
  end
 
  y = sin(((1 : m) + d - 1) * 2 * %pi / n);

endfunction

//tests:
//assert_checkequal(sinewave(1), 0);
//assert_checkequal(sinewave(1), sinewave(1, 1,0));
//assert_checkequal(sinewave(3, 4), sinewave(3, 4, 0));
//assert_checkalmostequal(sinewave(1, 12, 1), 1/2, %eps);
//assert_checkalmostequal(sinewave(1, 12, 2), sqrt(3)/2, %eps);
//assert_checkalmostequal(sinewave(1, 20, 1), (sqrt(5)-1)/4, %eps);
