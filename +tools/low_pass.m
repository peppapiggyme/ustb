function [pf, h, w, delay] = low_pass(p, Fs, F)
    % function filtered_p = low_pass(p, Fs, [upper_freq_on upper_freq_off])
    
    % filter specification
    A = [1, 0];                                             % band type: 0='stop', 1='pass'
    dev = [0.1, 0.0001];                                    % max ripple in pass-band and stop-band
    [N, Wn, beta, ftype] = kaiserord(F, A, dev, Fs);        % window parameters
    b = fir1(N, Wn, ftype, kaiser(N+1,beta), 'noscale');    % filter design

    [h, w] = freqz(b);
    
    % filtering
    [~, delay] = max(abs(hilbert(b)));
    pf = filter(b, 1, p, [], 1);    
end

