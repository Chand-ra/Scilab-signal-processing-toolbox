function varargout = pwelch(x,varargin)
    //
    // COMPATIBILITY LEVEL
    // Argument positions and defaults depend on compatibility level selected
    // by calling pwelch without arguments or with a single string argument.
    //   native:      compatib=1; prev_compat=pwelch(); prev_compat=pwelch([]);
    //   matlab R11:  compatib=2; prev_compat=pwelch('R11-');
    //   matlab R12:  compatib=3; prev_compat=pwelch('R12+');
    //   spectrum.welch defaults:  compatib=4; prev_compat=pwelch('psd');
    // In each case, the returned value is the PREVIOUS compatibility string.
    //
    nargin = argn(2)
    compat_str = {[]; 'R11-'; 'R12+'; 'psd'};
    global compatib
    if ( isempty(compatib) || compatib<=0 || compatib>4 )
      // legal values are 1, 2, 3, 4
      compatib = 1;
    end
    if ( nargin <= 0 )
      error( 'pwelch: Need at least 1 arg. Use help pwelch.' );
    elseif ( nargin==1 && (type(x) == 10 ) || isempty(x)) 
      varargout(1) = compat_str{compatib};
      if ( isempty(x) ) // native
        compatib = 1;
      elseif ( ~strcmp(x,'R11-') )
        compatib = 2;
      elseif ( ~strcmp(x,'R12+') )
        compatib = 3;
      elseif ( ~strcmp(x,'psd') )
        compatib = 4;
      else
        error( 'pwelch: compatibility arg must be empty, R11-, R12+ or psd' );
      end
      // return
    //
   
    // Check fixed argument
    elseif ( isempty(x) || ~isvector(x) )
      error( 'pwelch: arg 1 (x) must be vector.' );
    else
      //  force x to be COLUMN vector
      if ( size(x,1)==1 )
        x=x(:);
      end
      //
      // Look through all args to check if  cross PSD, transfer function or
      // coherence is required.  If yes, the second arg is data vector "y".
      arg2_is_y = 0;
      x_len = max(size(x));
      nvarargin = max(size(varargin));
      for iarg=1:nvarargin
        arg = varargin(iarg);
        if ( ~isempty(arg) && (type(arg) == 10 ) && ...
             ( ~strcmp(arg,'cross') || ~strcmp(arg,'trans') || ...
               ~strcmp(arg,'coher') || ~strcmp(arg,'ypower') ))
          // OK. Need "y". Grab it from 2nd arg.
          arg = varargin(1);
          if ( nargin<2 || isempty(arg) || ~isvector(arg) || max(size(arg))~=x_len )
            error( 'pwelch: arg 2 (y) must be vector, same length as x.' );
          end
          // force  COLUMN vector
          y = varargin(1)(:);
          arg2_is_y = 1;
          break;
        end
      end
      //
      // COMPATIBILITY
      // To select default argument values, "compatib" is used as an array index.
      // Index values are   1=native,  2=R11,  3=R12,  4=spectrum.welch
      //
      //  argument positions:
      //  arg_posn = varargin index of window, overlap, Nfft, Fs and conf
      //             args respectively, a value of zero ==>> arg does not exist
      arg_posn = [1 2 3 4 5;  // native
                  3 4 1 2 5;  // Matlab R11- pwelch
                  1 2 3 4 0;  // Matlab R12+ pwelch
                  1 2 3 4 5]; // spectrum.welch defaults
      arg_posn  = arg_posn(compatib,:) + arg2_is_y;
      //
      //  SPECIFY SOME DEFAULT VALUES for (not all) optional arguments
      //  Use compatib as array index.
      //  Fs = sampling frequency
      Fs        = [ 1.0 2*%pi 2*%pi 2*%pi ];
      Fs        = Fs(compatib);
      //  plot_type: 1='plot'|'squared'; 5='db'|'dB'
      plot_type = [ 1 5 5 5 ];
      plot_type = plot_type(compatib);
      //  rm_mean: 3='long-mean'; 0='no-strip'|'none'
      rm_mean   = [ 3 0 0 0 ];
      rm_mean   = rm_mean(compatib);
      // use max_overlap=x_len-1 because seg_len is not available yet
      // units of overlap are different for each version:
      //    fraction, samples, or percent
      max_overlap = [ 0.95 x_len-1 x_len-1 95];
      max_overlap = max_overlap(compatib);
      // default confidence interval
      //  if there are more than 2 return values and if there is a "conf" arg
      conf      = 0.95 * (nargout>2) * (arg_posn(5)>0);
      //
      is_win    = 0;    // =0 means valid window arg is not provided yet
      Nfft      = [];   // default depends on segment length
      overlap   = [];   // WARNING: units can be //samples, fraction or percentage
      range     = ~isreal(x) || ( arg2_is_y && ~isreal(y) );
      is_sloppy = 0;
      n_results = 0;
      do_power  = 0;
      do_cross  = 0;
      do_trans  = 0;
      do_coher  = 0;
      do_ypower = 0;
    //
    //  DECODE AND CHECK OPTIONAL ARGUMENTS
      end_numeric_args = 0;
      for iarg = 1+arg2_is_y:nvarargin
        arg = varargin(iarg);
        if ( ( type (arg) == 10 ) )
          // first string arg ==> no more numeric args
          // non-string args cannot follow a string arg
          end_numeric_args = 1;
          //
          // decode control-string arguments
          if ( ~strcmp(arg,'sloppy') )
            is_sloppy = ~is_win || is_win==1;
          elseif ( ~strcmp(arg,'plot') || ~strcmp(arg,'squared') )
            plot_type = 1;
          elseif ( ~strcmp(arg,'semilogx') )
            plot_type = 2;
          elseif ( ~strcmp(arg,'semilogy') )
            plot_type = 3;
          elseif ( ~strcmp(arg,'loglog') )
            plot_type = 4;
          elseif ( ~strcmp(arg,'db') || ~strcmp(arg,'dB') )
            plot_type = 5;
          elseif ( ~strcmp(arg,'half') || ~strcmp(arg,'onesided') )
            range = 0;
          elseif ( ~strcmp(arg,'whole') || ~strcmp(arg,'twosided') )
            range = 1;
          elseif ( ~strcmp(arg,'shift') || ~strcmp(arg,'centerdc') )
            range = 2;
          elseif ( ~strcmp(arg,'long-mean') )
            rm_mean = 3;
          elseif ( ~strcmp(arg,'linear') )
            rm_mean = 2;
          elseif ( ~strcmp(arg,'short') || ~strcmp(arg,'mean') )
            rm_mean = 1;
          elseif ( ~strcmp(arg,'no-strip') || ~strcmp(arg,'none') )
            rm_mean = 0;
          elseif ( ~strcmp(arg, 'power' ) )
            if ( ~do_power )
              n_results = n_results+1;
              do_power = n_results;
            end
          elseif ( ~strcmp(arg, 'cross' ) )
            if ( ~do_cross )
              n_results = n_results+1;
              do_cross = n_results;
            end
          elseif ( ~strcmp(arg, 'trans' ) )
            if ( ~do_trans )
              n_results = n_results+1;
              do_trans = n_results;
            end
          elseif ( ~strcmp(arg, 'coher' ) )
            if ( ~do_coher )
              n_results = n_results+1;
              do_coher = n_results;
            end
          elseif ( ~strcmp(arg, 'ypower' ) )
            if ( ~do_ypower )
              n_results = n_results+1;
              do_ypower = n_results;
            end
          else
            error( 'pwelch: string arg %d illegal value: %s', iarg+1, arg );
          end
          // end of processing string args
          //
        elseif ( end_numeric_args )
          if ( ~isempty(arg) )
            // found non-string arg after a string arg ... oops
            error( 'pwelch: control arg must be string' );
          end
        //
        // first 4 optional arguments are numeric -- in fixed order
        //
        // deal with "Fs" and "conf" first because empty arg is a special default
        // -- "Fs" arg -- sampling frequency
        elseif ( iarg == arg_posn(4) )
          if ( isempty(arg) )
            Fs = 1;
          elseif ( ~isscalar(arg) || ~isreal(arg) || arg<0 )
            error( 'pwelch: arg %d (Fs) must be real scalar >0', iarg+1 );
          else
            Fs = arg;
          end
        //
        //  -- "conf" arg -- confidence level
        //    guard against the "it cannot happen" iarg==0
        elseif ( arg_posn(5) && iarg == arg_posn(5) )
          if ( isempty(arg) )
            conf = 0.95;
          elseif ( ~isscalar(arg) || ~isreal(arg) || arg < 0.0 || arg >= 1.0 )
            error( 'pwelch: arg %d (conf) must be real scalar, >=0, <1',iarg+1 );
          else
            conf = arg;
          end
        //
        // skip all empty args from this point onward
        elseif ( isempty(arg) )
          1;
        //
        //  -- "window" arg -- window function
        elseif ( iarg == arg_posn(1) )
          if ( isscalar(arg) )
            is_win = 1;
          elseif ( isvector(arg) )
            is_win = max(size(arg));
            if ( size(arg,2)>1 )  // vector must be COLUMN vector
              arg = arg(:);
            end
          else
            is_win = 0;
          end
          if ( ~is_win )
            error( 'pwelch: arg %d (window) must be scalar or vector', iarg+1 );
          elseif ( is_win==1 && ( ~isreal(arg) || fix(arg)~=arg || arg<=3 ) )
            error( 'pwelch: arg %d (window) must be integer >3', iarg+1 );
          elseif ( is_win>1 && ( ~isreal(arg) ) )
            error( 'pwelch: arg %d (window) vector must be real and >=0',iarg+1);
          end
          window = arg;
          is_sloppy = 0;
        //
        // -- "overlap" arg -- segment overlap
        elseif ( iarg == arg_posn(2) )
          if (~isscalar(arg) || ~isreal(arg) || arg<0 || arg>max_overlap )
            error( 'pwelch: arg %d (overlap) must be real from 0 to %f', ...
                   iarg+1, max_overlap );
          end
          overlap = arg;
        //
        // -- "Nfft" arg -- FFT length
        elseif ( iarg == arg_posn(3) )
          if ( ~isscalar(arg) || ~isreal(arg) || fix(arg)~=arg || arg<0 )
            error( 'pwelch: arg %d (Nfft) must be integer >=0', iarg+1 );
          end
          Nfft = arg;
        //
        else
          error( 'pwelch: arg %d  must be string', iarg+1 );
        end
      end
      if ( conf>0 && (n_results && ~do_power ) )
        error('pwelch: can give confidence interval for x power spectrum only' );
      end
      //
      // end DECODE AND CHECK OPTIONAL ARGUMENTS.
      //
      // SETUP REMAINING PARAMETERS
      // default action is to calculate power spectrum only
      if ( ~n_results )
        n_results = 1;
        do_power = 1;
      end
      need_Pxx = do_power || do_trans || do_coher;
      need_Pxy = do_cross || do_trans || do_coher;
      need_Pyy = do_coher || do_ypower;
      log_two = log(2);
      nearly_one = 0.99999999999;
      //
      // compatibility-options
      // provides exact compatibility with Matlab R11 or R12
      //
      // Matlab R11 compatibility
      if ( compatib==2 )
        if ( isempty(Nfft) )
          Nfft = min( 256, x_len );
        end
        if ( is_win > 1 )
          seg_len = min( max(size(window)), Nfft );
          window = window(1:seg_len);
        else
          if ( is_win )
            // window arg is scalar
            seg_len = window;
          else
            seg_len = Nfft;
          end
          // make Hann window (don't depend on sigproc)
          xx = seg_len - 1;
          window = 0.5 - 0.5 * cos( (2*%pi/xx)*[0:xx].' );
        end
      //
      // Matlab R12 compatibility
      elseif ( compatib==3 )
        if ( is_win > 1 )
          // window arg provides window function
          seg_len = max(size(window));
        else
          // window arg does not provide window function; use Hamming
          if ( is_win )
            // window arg is scalar
            seg_len = window;
          else
            // window arg not available; use R12 default, 8 windows
            // ignore overlap arg; use overlap=50% -- only choice that makes sense
            // this is the magic formula for 8 segments with 50% overlap
            seg_len = fix( (x_len-3)*2/9 );
          end
          // make Hamming window (don't depend on sigproc)
          xx = seg_len - 1;
          window = 0.54 - 0.46 * cos( (2*%pi/xx)*[0:xx].' );
        end
        if ( isempty(Nfft) )
          Nfft = max( 256, 2^ceil(log(seg_len)*nearly_one/log_two) );
        end
      // Matlab R14 psd(spectrum.welch) defaults
      elseif ( compatib==4 )
        if ( is_win > 1 )
          // window arg provides window function
          seg_len = max(size(window));
        else
          // window arg does not provide window function; use Hamming
          if ( is_win )
            // window arg is scalar
            seg_len = window;
          else
            // window arg not available; use default seg_len = 64
            seg_len = 64;
          end
          // make Hamming window (don't depend on sigproc)
          xx = seg_len - 1;
          window = 0.54 - 0.46 * cos( (2*%pi/xx)*[0:xx].' );
        end
        // Now we know segment length,
        // so we can set default overlap as number of samples
        if ( ~isempty(overlap) )
          overlap = fix(seg_len * overlap / 100 );
        end
        if ( isempty(Nfft) )
          Nfft = max( 256, 2^ceil(log(seg_len)*nearly_one/log_two) );
        end
      //
      // default compatibility level
      else // if ( compatib==1 )
        // calculate/adjust segment lenght, window function
        if ( is_win > 1 )
          // window arg provides window function
          seg_len = max(size(window));
        else
          // window arg does not provide window function; use Hamming
          if ( is_win )       // window arg is scalar
            seg_len = window;
          else
            // window arg not available; use default length:
            // = sqrt(max(size(x))) rounded up to nearest integer power of 2
            if ( isempty(overlap) )
              overlap=0.5;
            end
            seg_len = 2 ^ ceil( log(sqrt(x_len/(1-overlap)))*nearly_one/log_two );
          end
          // make Hamming window (don't depend on sigproc)
          xx = seg_len - 1;
          window = 0.54 - 0.46 * cos( (2*%pi/xx)*[0:xx].' );
        end
        // Now we know segment length,
        // so we can set default overlap as number of samples
        if ( ~isempty(overlap) )
          overlap = fix(seg_len * overlap);
        end
        //
        // calculate FFT length
        if ( isempty(Nfft) )
          Nfft = seg_len;
        end
        if ( is_sloppy )
          Nfft = 2 ^ ceil( log(Nfft) * nearly_one / log_two );
        end
      end
      // end of compatibility options
      //
      // minimum FFT length is seg_len
      Nfft = max( Nfft, seg_len );
      // Mean square of window is required for normalizing PSD amplitude.
      win_meansq = (window.' * window) / seg_len;
      //
      // Set default or check overlap.
      if ( isempty(overlap) )
        overlap = fix(seg_len /2);
      elseif ( overlap >= seg_len )
        error( 'pwelch: arg (overlap=%d) too big. Must be <max(size(window)=%d',...
               overlap, seg_len );
      end
      //
      // Pad data with zeros if shorter than segment. This should not happen.
      if ( x_len < seg_len )
        x = [x; zeros(seg_len-x_len,1)];
        if ( arg2_is_y )
          y = [y; zeros(seg_len-x_len,1)];
        end
        x_len = seg_len;
      end
      // end SETUP REMAINING PARAMETERS
      //
      //
      // MAIN CALCULATIONS
      // Remove mean from the data
      if ( rm_mean == 3 )
        n_ffts = max( 0, fix( (x_len-seg_len)/(seg_len-overlap) ) ) + 1;
        x_len  = min( x_len, (seg_len-overlap)*(n_ffts-1)+seg_len );
        if ( need_Pxx || need_Pxy )
          x = x - sum( x(1:x_len) ) / x_len;
        end
        if ( arg2_is_y || need_Pxy)
          y = y - sum( y(1:x_len) ) / x_len;
        end
      end
      //
      // Calculate and accumulate periodograms
      //   xx and yy are padded data segments
      //   Pxx, Pyy, Pyy are periodogram sums, Vxx is for confidence interval
      xx = zeros(Nfft,1);
      yy = xx;
      Pxx = xx;
      Pxy = xx;
      Pyy = xx;
      if ( conf>0 )
        Vxx = xx;
      else
        Vxx = [];
      end
      n_ffts = 0;
      for start_seg = [1:seg_len-overlap:x_len-seg_len+1]
        end_seg = start_seg+seg_len-1;
        // Don't truncate/remove the zero padding in xx and yy
        if ( need_Pxx || need_Pxy )
          if ( rm_mean==1 ) // remove mean from segment
            xx(1:seg_len) = window .* ( ...
              x(start_seg:end_seg) - sum(x(start_seg:end_seg)) / seg_len);
          elseif ( rm_mean == 2 ) // remove linear trend from segment
            xx(1:seg_len) = window .* detrend( x(start_seg:end_seg) );
          else // rm_mean==0 or 3
            xx(1:seg_len) = window .* x(start_seg:end_seg);
          end
          fft_x = fft1(xx);
        end
        if ( need_Pxy || need_Pyy )
          if ( rm_mean==1 ) // remove mean from segment
            yy(1:seg_len) = window .* ( ...
              y(start_seg:end_seg) - sum(y(start_seg:end_seg)) / seg_len);
          elseif ( rm_mean == 2 ) // remove linear trend from segment
            yy(1:seg_len) = window .* detrend( y(start_seg:end_seg) );
          else // rm_mean==0 or 3
            yy(1:seg_len) = window .* y(start_seg:end_seg);
          end
          fft_y = fft1(yy);
        end
        if ( need_Pxx )
          // force Pxx to be real; pgram = periodogram
          pgram = real(fft_x .* conj(fft_x));
          Pxx = Pxx + pgram;
          // sum of squared periodograms is required for confidence interval
          if ( conf>0 )
            Vxx = Vxx + pgram .^2;
          end
        end
        if ( need_Pxy )
          // Pxy (cross power spectrum) is complex. Do not force to be real.
          Pxy = Pxy + fft_y .* conj(fft_x);
        end
        if ( need_Pyy )
          // force Pyy to be real
          Pyy = Pyy + real(fft_y .* conj(fft_y));
        end
        n_ffts = n_ffts +1;
      end
      //
      // Calculate confidence interval
      //    -- incorrectly assumes that the periodogram has Gaussian probability
      //       distribution (actually, it has a single-sided (e.g. exponential)
      //       distribution.
      // Sample variance of periodograms is (Vxx-Pxx.^2/n_ffts)/(n_ffts-1).
      //    This method of calculating variance is more susceptible to round-off
      //  error, but is quicker, and for double-precision arithmetic and the
      //  inherently noisy periodogram (variance==mean^2), it should be OK.
      if ( conf>0 && need_Pxx )
        if ( n_ffts<2 )
          Vxx = zeros(Nfft,1);
        else
          // Should use student distribution here (for unknown variance), but tinv
          // is not a core Matlab function (is in statistics toolbox. Grrr)
          Vxx = (erfinv(conf)*sqrt(2*n_ffts/(n_ffts-1))) * sqrt(Vxx-Pxx.^2/n_ffts);
        end
      end
      //
      // Convert two-sided spectra to one-sided spectra (if range == 0).
      // For one-sided spectra, contributions from negative frequencies are added
      // to the positive side of the spectrum -- but not at zero or Nyquist
      // (half sampling) frequencies.  This keeps power equal in time and spectral
      // domains, as required by Parseval theorem.
      //
      if (  ~ range  )
        if (modulo(Nfft,2) == 0 )    // one-sided, Nfft is even
          psd_len = Nfft/2+1;
          if ( need_Pxx )
            Pxx = Pxx(1:psd_len) + [0; Pxx(Nfft:-1:psd_len+1); 0];
            if ( conf>0 )
              Vxx = Vxx(1:psd_len) + [0; Vxx(Nfft:-1:psd_len+1); 0];
            end
          end
          if ( need_Pxy )
            Pxy = Pxy(1:psd_len) + conj([0; Pxy(Nfft:-1:psd_len+1); 0]);
          end
          if ( need_Pyy )
            Pyy = Pyy(1:psd_len) + [0; Pyy(Nfft:-1:psd_len+1); 0];
          end
        else                    // one-sided, Nfft is odd
          psd_len = (Nfft+1)/2;
          if ( need_Pxx )
            Pxx = Pxx(1:psd_len) + [0; Pxx(Nfft:-1:psd_len+1)];
            if ( conf>0 )
              Vxx = Vxx(1:psd_len) + [0; Vxx(Nfft:-1:psd_len+1)];
            end
          end
          if ( need_Pxy )
            Pxy = Pxy(1:psd_len) + conj([0; Pxy(Nfft:-1:psd_len+1)]);
          end
          if ( need_Pyy )
            Pyy = Pyy(1:psd_len) + [0; Pyy(Nfft:-1:psd_len+1)];
          end
        end
      else                      // two-sided (and shifted)
        psd_len = Nfft;
      end
      // end MAIN CALCULATIONS
      //
      // SCALING AND OUTPUT
      // Put all results in matrix, one row per spectrum
      //   Pxx, Pxy, Pyy are sums of periodograms, so "n_ffts"
      //   in the scale factor converts them into averages
      spectra    = zeros(psd_len,n_results);
      spect_type = zeros(n_results,1);
      scale = n_ffts * seg_len * Fs * win_meansq;
      if ( do_power )
        spectra(:,do_power) = Pxx / scale;
        spect_type(do_power) = 1;
        if ( conf>0 )
          Vxx = [Pxx-Vxx Pxx+Vxx]/scale;
        end
      end
      if ( do_cross )
        spectra(:,do_cross) = Pxy / scale;
        spect_type(do_cross) = 2;
      end
      if ( do_trans )
        spectra(:,do_trans) = Pxy ./ Pxx;
        spect_type(do_trans) = 3;
      end
      if ( do_coher )
        // force coherence to be real
        spectra(:,do_coher) = real(Pxy .* conj(Pxy)) ./ Pxx ./ Pyy;
        spect_type(do_coher) = 4;
      end
      if ( do_ypower )
        spectra(:,do_ypower) = Pyy / scale;
        spect_type(do_ypower) = 5;
      end
      freq = [0:psd_len-1].' * ( Fs / Nfft );
      //
      // range='shift': Shift zero-frequency to the middle
      if ( range == 2 )
        len2 = fix((Nfft+1)/2);
        spectra = [ spectra(len2+1:Nfft,:); spectra(1:len2,:)];
        freq    = [ freq(len2+1:Nfft)-Fs; freq(1:len2)];
        if ( conf>0 )
          Vxx = [ Vxx(len2+1:Nfft,:); Vxx(1:len2,:)];
        end
      end
      //
      //  RETURN RESULTS or PLOT
      if ( nargout>=2 && conf>0 )
        varargout(2) = Vxx;
      end
      if ( nargout>=(2+(conf>0)) )
        // frequency is 2nd or 3rd return value,
        // depends on if 2nd is confidence interval
        varargout(2+(conf>0)) = freq;
      end
      if ( nargout>=1 )
        varargout(1) = spectra;
      else
        //
        // Plot the spectra if there are no return variables.
        plot_title=['power spectrum x ';
                    'cross spectrum   ';
                    'transfer function';
                    'coherence        ';
                    'power spectrum y ' ];
        for ii = 1: n_results
          if ( conf>0 && spect_type(ii)==1 )
            Vxxxx = Vxx;
          else
            Vxxxx = [];
          end
          if ( n_results > 1 )
            figure();
          end
          if ( plot_type == 1 )
            plot(freq,[abs(spectra(:,ii)) Vxxxx]);
          elseif ( plot_type == 2 )
            semilogx(freq,[abs(spectra(:,ii)) Vxxxx]);
          elseif ( plot_type == 3 )
            semilogy(freq,[abs(spectra(:,ii)) Vxxxx]);
          elseif ( plot_type == 4 )
            loglog(freq,[abs(spectra(:,ii)) Vxxxx]);
          elseif ( plot_type == 5 )  // db
            ylabel( 'amplitude (dB)' );
            plot(freq,[10*log10(abs(spectra(:,ii))) 10*log10(abs(Vxxxx))]);
          end
          title( char(plot_title(spect_type(ii),:)) );
          ylabel( 'amplitude' );
          // Plot phase of cross spectrum and transfer function
          if ( spect_type(ii)==2 || spect_type(ii)==3 )
            figure();
            if ( plot_type==2 || plot_type==4 )
              semilogx(freq,180/%pi*angle(spectra(:,ii)));
            else
              plot(freq,180/%pi*angle(spectra(:,ii)));
            end
            title( char(plot_title(spect_type(ii),:)) );
            ylabel( 'phase' );
          end
        end
      end
    end
  endfunction

function res =  fft1 (D, N, DIM)
    funcprot(0);
    lhs = argn(1)
    rhs = argn(2)
    if (rhs < 1 | rhs > 3)
        error("Wrong number of input arguments.")
    end
    dimension = size(D);
    // first non-singleton dimension
    nsdim = find(dimension >1,1)
    if isempty(nsdim) then
        nsdim = 1 // default to 1 to avoid error while calling fft
    end    
    select(rhs)
    case 1 then
        res = fft(D, -1, nsdim);
    case 2 then
        if isempty(N) then
            n = size(D, nsdim);
        else
            n = N;
        end
        new_size = size(D);
        new_size(nsdim) = n;
        D = resize_matrix(D, new_size);
        res = fft(D, -1, nsdim);
    case 3 then
        if isempty(N) then
            n = size(D, DIM);
        else
            n = N;
        end
        new_size = size(D);
        new_size(DIM) = n;
        D = resize_matrix(D, new_size);
        res= fft(D, -1, DIM);
        end
endfunction

function varargout = tfestimate(varargin)
//Estimate transfer function of system with input x and output y. Use the Welch (1967) periodogram/FFT method.
//Calling Sequence:
//tfestimate (x, y)
//tfestimate (x, y, window)
//tfestimate (x, y, window, overlap)
//tfestimate (x, y, window, overlap, Nfft)
//tfestimate (x, y, window, overlap, Nfft, Fs)
//tfestimate (x, y, window, overlap, Nfft, Fs, range)
//Parameters:
//x: system-input time-series data. Real pr complex vector.
//y: system-output time-series data. Real or complex vector, same dimension as x.
//window: [real vector] of window-function values between 0 and 1; the data segment has the same length as the window. Default window shape is Hamming.
//[integer scalar] length of each data segment. The default value is window=sqrt(length(x)) rounded up to the nearest integer power of 2. 
// overlap: [real scalar] segment overlap expressed as a multiple of window or segment length. 0 <= overlap < 1, The default is overlap = 0.5.
// Nfft: [integer scalar] Length of FFT.  The default is the length of the "window" vector or has the same value as the scalar "window" argument. 
//If Nfft is larger than the segment length, "seg_len", the data segment is padded with "Nfft-seg_len" zeros.  The default is no padding. Nfft values smaller than the length of the data segment (or window) are ignored silently.
// Fs: [real scalar] sampling frequency (Hertz); default = 1.0
// range: 'half', 'onesided' : frequency range of the spectrum is zero up to but not including Fs/2. Power from negative frequencies is added to the positive side of the spectrum,
//but not at zero or Nyquist (Fs/2) frequencies.  This keeps power equal in time and spectral domains. 'whole', 'twosided': frequency range of the spectrum is  -Fs/2 to Fs/2, with negative frequencies stored in "wrap around" order after the positive frequencies; e.g. frequencies for a 10-point 'twosided' spectrum are 0 0.1 0.2 0.3 0.4 0.5 -0.4 -0.3 -0.2 -0.1 'shift', 'centerdc' : same as 'whole' but with the first half of the spectrum swapped with second half to put the zero-frequency value in the middle. If data (x and y) are real, the default range is 'half', otherwise default range is 'whole'.
//Description:
//Estimate transfer function of system with input x and output y. Use the Welch (1967) periodogram/FFT method.
//Examples:
//[Pxx, freq] = tfestimate([1 2 3], [4 5 6])
//Pxx =
//   1.7500 + 0.0000i
//   1.5947 + 0.3826i
//   1.2824 + 0.0000i
//
//freq =
//   0.00000
//   0.25000
//   0.50000

  funcprot(0);
  if (nargin() < 2 || nargin() > 7)
    error("Wrong number of input arguments.");
  end
  nvarargin = length(varargin);
  for iarg = 1:nvarargin
    arg = varargin(iarg);
    if ( ~isempty(arg) && (type(arg) == 10) && ( ~strcmp(arg,'power') || ~strcmp(arg,'cross') || ~strcmp(arg,'trans') || ~strcmp(arg,'coher') || ~strcmp(arg,'ypower') ))
      varargin(iarg) = [];
    end
  end
  varargin(nvarargin + 1) = 'trans';

  if (nargout() == 0)
    pwelch(varargin(:));
  elseif (nargout() == 1)
    Pxx = pwelch(varargin(:));
    varargout(1) = Pxx;
  elseif (nargout() >= 2)
    [Pxx,f] = pwelch(varargin(:));
    varargout(1) = Pxx;
    varargout(2) = f;
  end

endfunction

//tests:
//assert_checkerror("tfestimate(1)", "Wrong number of input arguments.");
//assert_checkerror("tfestimate(1, 2, 3, 4, 5, 6, 7, 8)", "Wrong number of input arguments.");
//tfestimate([1 2 3], [4 5 6]);
//tfestimate([-1 -2 -3], [4 5 6], 'power');
//tfestimate([-1; -2; -3], [-4 -5 -6], 'power', 'cross');
//y = tfestimate([1; 2; 3], [4; 5; 6], 'coher', 'trans');
//assert_checkalmostequal(y, [1.75; 1.59472+0.38256*%i; 1.28235], 5*10^-5);
//[a b] = tfestimate([1 -2 -3], [4; 5; 6], 'ypower', 'trans');
//assert_checkalmostequal(a, [-1.1667; -1.1029-0.1912*%i; -1.5797], 5*10^-4);
//assert_checkalmostequal(b, [0; 0.25; 0.5], %eps);
//tfestimate([5-1 4+2*%i 4 -1-3*%i], [1+%i -5*%i 6 -6]);
