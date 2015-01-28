function filtered_p = band_pass(p,Fs,F)
    % function filtered_p = band_pass(p,Fs,F)
    
    % filter specification
    A=[0 1 0];                % band type: 0='stop', 1='pass'
    dev=[1e-3 1e-3 1e-3];     % ripple/attenuation spec
    [M,Wn,beta,typ]= kaiserord(F,A,dev,Fs);  % window parameters
    b=fir1(M,Wn,typ,kaiser(M+1,beta),'noscale'); % filter design

    % filtering
    filt_delay=round((length(b)-1)/2);
    filtered_p=filter(b,1,[p; zeros(filt_delay,size(p,2),size(p,3),size(p,4))],[],1);

    % correcting the delay
    filtered_p=filtered_p((filt_delay+1):end,:,:);

end

