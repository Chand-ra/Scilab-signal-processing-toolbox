function y = filter2 (b, x, shape)
//Apply the 2-D FIR filter b to x.
//Calling Sequence:
//y =  fftconv(b, x)
//y = fftconv(b, x, shape)
//Parameters:
//b, x: vectors
//If the optional argument 'shape' is specified, return a vector of the desired shape. 
//Possible values are:
//  "full"- pad x with zeros on all sides before filtering.
//  "same"- unpadded x (default)
//  "valid"- trim x after filtering so edge effects are no included.
//Examples:
//filter2([1,3], [4,5])
//ans =
//[19, 5]

  funcprot(0);
  rhs = argn(2);

  if (rhs < 2 | rhs > 3) then
    error("filter2: wrong number of input arguments");
  end
  if (rhs < 3) then
    shape = "same";
  end
  [nr, nc] = size(b);
  y = conv2(x, b(nr:-1:1, nc:-1:1), shape);

endfunction

//input validation:
//assert_checkerror("filter2()", "filter2: wrong number of input arguments");
//assert_checkerror("filter2(1, 2, 3, 4)", "Wrong number of input arguments.");

//tests:
//assert_checkequal(filter2([1, 2; 3, 5], [1, 3; 5, 7]), [57, 24; 19, 7]);
//assert_checkequal(filter2(1, 5), filter2(1, 5, "same"));
//assert_checkequal(filter2([1, 2], [4; 5; 6], "full"), [8, 4; 10, 5; 12, 6]);
//assert_checkequal(filter2([3; 1], [5; 4], "valid"), 19);
