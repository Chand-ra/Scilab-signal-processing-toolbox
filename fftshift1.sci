function y = fftshift1(x, dim)
//Performs a shift of the vector x, for use with the fft1 and ifft1 functions, in order to move the frequency 0 to the center of the vector or matrix.
//Calling Sequence:
// fftshift1 (x)
// fftshift1 (x, dim)
//Parameters:
//x- It is a vector of N elements corresponding to time samples
//dim- The optional DIM argument can be used to limit the dimension along which the permutation occurs
//Examples:
//x = [0:6]
//fftshift(x)
//ans =
//4 5 6 0 1 2 3

  funcprot(0);
  rhs = argn(2);
  if (rhs < 1 | rhs > 2) then
    error ("fftshift1: wrong number of arguments");
  end

 if (~or(type(x) == [1 5 8 10 4 6]))
    error ("fftshitft1: arg1 (x) must be a vector or matrix");
  end

  if (rhs == 2) then
    if (~(isscalar(dim) & dim > 0 & dim == fix(dim))) then
      error ("fftshift1: arg2 (dim) must be a positive integer");
    end
    nd = ndims(x);
    sz = size(x);
    sz2 = ceil(sz(dim) / 2);
    dim_idx = [sz2+1:sz(dim), 1:sz2];
    idx = repmat({':'}, 1, max(size(size(x))));
    idx(dim)= {dim_idx};
    y = x(idx{:});
  else
    if (isvector(x)) then
      xl = length(x);
      xx = ceil(xl/2);
      y = x([xx+1:xl, 1:xx]);
    else
      nd = ndims(x);
      sz = size(x);
      sz2 = ceil(sz ./ 2);
      idx = cell();
      for i = 1:nd
          idx{i} = [sz2(i) + 1:sz(i), 1:sz2(i)];
      end
      y = x(idx{1}, idx{2});
    end
  end

endfunction

//input validation:
//assert_checkerror("fftshift1()", "fftshift1: wrong number of arguments");
//assert_checkerror("fftshift1(1, 2, 3)", "Wrong number of input arguments.");
//assert_checkerror("fftshift1(0:2, -1)", "fftshift1: arg2 (dim) must be a positive integer");
//assert_checkerror("fftshift1(0:2, 0:3)", "fftshift1: arg2 (dim) must be a positive integer");

//test mx1 input:
//x = [0:7];
//y = fftshift1 (x);
//assert_checkequal (y, [4 5 6 7 0 1 2 3]);
//assert_checkequal (fftshift1(y), x);

//test 1xm input:
//x = [0:7]';
//y = fftshift1(x);
//assert_checkequal(y, [4;5;6;7;0;1;2;3]);
//assert_checkequal(fftshift1(y), x);

//test mxn input:
//x = [0:3];
//x = [x;2*x;3*x+1;4*x+1];
//y = fftshift1 (x);
//assert_checkequal(y, [[7 10 1 4];[9 13 1 5];[2 3 0 1];[4 6 0 2]]);
//assert_checkequal(fftshift1(y), x);

//test dim is provided:
//x = [0:3];
//x = [x;2*x;3*x+1;4*x+1];
//y = fftshift(x, 1);
//assert_checkequal(y, [[1 4 7 10];[1 5 9 13];[0 1 2 3];[0 2 4 6]]);
//assert_checkequal(fftshift(y, 1), x);
