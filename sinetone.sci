function y = sinetone(freq, rate, sec, ampl)
//Return a sinetone of the input
//Calling Sequence:
//y= sinetone(freq)
//y= sinetone(freq, rate)
//y= sinetone(freq, rate, sec)
//y= sinetone(freq, rate, sec, ampl)
//Parameters:
//freq: frequency of sinetone
//rate: sampling rate
//sec: length in seconds
//ampl: amplitude
//Description:
//Return a sinetone of frequency 'freq' with a length of 'sec' seconds at sampling rate 'rate' and with amplitude 'ampl'.
//The arguments freq and ampl may be vectors of common size. The defaults are rate = 8000, sec = 1, and ampl = 64.
//Examples:
//sinetone(5, 2, 1, 8)
//ans = [4.89E-15; -9.79E-15]

    funcprot(0);
    rhs= argn(2);

    select rhs
        case 1 then
            rate = 8000;
            sec = 1;
            ampl = 64;
        case 2 then
            sec = 1;
            ampl = 64;
        case 3 then
            ampl = 64;
        case 4 then
            break;
        else
            error("sinetone: wrong number of input arguments");
    end

    if (isvector(freq) & isvector(ampl) & size(freq) ~= size(ampl)) then
        error("sinetone: freq and ampl must be vectors of equal size");
    end

    if ( ~(isscalar(rate) && isscalar(sec)) ) then
        error("sinetone: rate and sec must be scalars")
    end

    n = length (freq);
    ns = round (rate * sec);
    y = zeros (ns, n);

    for k = 1:n
        y(:, k) = ampl(k) * sin (2 * %pi * (1:ns) / rate * freq(k))';
    end

endfunction

//tests:
