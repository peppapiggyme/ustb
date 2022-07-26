clear all;
close all;

M = 45;

%% Download data
url='https://nyhirse.medisin.ntnu.no/ustb/data/gcnr/';   % if not found data will be downloaded from here
filename='invitro_20.uff';
tools.download(filename, url, data_path);   

%% Load data
mix = uff.channel_data();
mix.read([data_path filesep filename],'/mix');
channel_SNR = h5read([data_path filesep filename],'/channel_SNR');;
channel_SNR = reshape(channel_SNR,[4 5]);

%% Regions

% cyst geometry -> this should go in the uff
x0=-0.2118e-3;                
z0=15.62e-3; 
r=3e-3;                 

sca=uff.linear_scan('x_axis', x0 + linspace(-4e-3,9e-3,256).','z_axis', z0 + linspace(-4e-3,4e-3,2.5*256).');

% stand off distance <- based on aperture size
r_off = 0.5e-3;                     % overwrite to handle larger pulse duration

% boundaries
ri=r-r_off;
Ai=pi*ri^2;
d=sqrt((sca.x-x0).^2+(sca.z-z0).^2);
l=sqrt(Ai);
skip=6e-3;

% masks
mask_i=d<ri;
mask_o= ((sca.x>(x0+skip-l/2)).*(sca.x<(x0+skip+l/2)).*(sca.z>(z0-l/2)).*(sca.z<(z0+l/2)))>0;

sum(mask_i)
sum(mask_o)

figure;
subplot(2,1,1)
imagesc(sca.x_axis*1e3, sca.z_axis*1e3, reshape(mask_i,[sca.N_z_axis sca.N_x_axis] )); axis equal;
subplot(2,1,2)
imagesc(sca.x_axis*1e3, sca.z_axis*1e3, reshape(mask_o,[sca.N_z_axis sca.N_x_axis] )); axis equal;

%% Prepare beamforming
pipe=pipeline();
pipe.scan=sca;
pipe.channel_data = mix;

pipe.transmit_apodization.window=uff.window.flat;
pipe.transmit_apodization.f_number = 1;
pipe.transmit_apodization.minimum_aperture = M*mix.probe.pitch;
pipe.transmit_apodization.maximum_aperture = M*mix.probe.pitch;

pipe.receive_apodization.window=uff.window.flat;
pipe.receive_apodization.f_number = 1;
pipe.receive_apodization.minimum_aperture = M*mix.probe.pitch;
pipe.receive_apodization.maximum_aperture = M*mix.probe.pitch;

das=midprocess.das();
das.dimension = dimension.both;
b_das = pipe.go({ das });

%%
b_das.plot(); hold on;
tools.plot_circle(x0*1e3,z0*1e3,ri*1e3,'r-');
plot(1e3*(x0+skip+[-l/2 l/2 l/2 -l/2 -l/2]),...
     1e3*(z0+[-l/2 -l/2 l/2 l/2 -l/2]),...
     'b-','Linewidth',3);

 
%% DAS

% evaluate contrast
[C, CNR, Pmax, GCNR_das]=meanContrast(M, channel_SNR, b_das, mask_o, mask_i, 'DAS');
%%
f = figure(11);hold all;
tools.plot_circle(x0*1e3,z0*1e3,ri*1e3,'r-');
plot(1e3*(x0+skip+[-l/2 l/2 l/2 -l/2 -l/2]),...
     1e3*(z0+[-l/2 -l/2 l/2 l/2 -l/2]),...
     'b-','Linewidth',3);
saveas(f,'Figures/invitro_das_regions.eps','eps2c')
% hold on;
% tools.plot_circle(x0*1e3,z0*1e3,ri*1e3,'r-');
% tools.plot_circle(x0*1e3,z0*1e3,ro*1e3,'g--');
% tools.plot_circle(x0*1e3,z0*1e3,rO*1e3,'g--');

%% S-DAS

% compresion
slope=10;
xA=[linspace(0,-25,3) -60+linspace(0,25,3)].';
yA=[linspace(0,-25,3)/slope -60+linspace(0,25,3)/slope].';

f=fit(xA,yA,'smoothingspline')
figure;
xx=linspace(-60,0,100); 
plot(xx,xx,'r--','linewidth',2); hold on; grid on; axis equal;
plot(xx,f(xx)','linewidth',2);
xlim([-60 0]);
ylim([-62 2]);
set(gca,'FontSize', 12);
xlabel('Input [dB]');
ylabel('Output [sB]');
legend('linear','S-curve','Location','NorthWest')

% anechoic
b_sdas = uff.beamformed_data(b_das);
b_sdas.data = 20*log10(abs(b_das.data)./max(abs(b_das.data)));
b_sdas.data = 10.^(reshape(f(b_sdas.data),size(b_sdas.data))/20);

% evaluate contrast
[C, CNR, Pmax, GCNR_sdas]=meanContrast(M, channel_SNR, b_sdas, mask_o, mask_i, 'S-DAS');

%% beamforming on transmit
das.dimension = dimension.transmit;
b_transmit = pipe.go({ das });

%% CF

% beamform
cf = postprocess.coherence_factor();
cf.dimension = dimension.receive;
cf.transmit_apodization = das.transmit_apodization;
cf.receive_apodization = das.receive_apodization;
cf.input = b_transmit;
cf_anechoic = cf.go();

% evaluate contrast
[C, CNR, Pmax, GCNR_cf]=meanContrast(M, channel_SNR, cf.CF, mask_o, mask_i, 'CF');

%% PCF

% beamform
pcf = postprocess.phase_coherence_factor();
pcf.center_frequency = 5e6;
pcf.dimension = dimension.receive;
pcf.gamma=1;
pcf.transmit_apodization = das.transmit_apodization;
pcf.receive_apodization = das.receive_apodization;
pcf.input = b_transmit;
pcf_anechoic = pcf.go();

% evaluate contrast
[C, CNR, Pmax, GCNR_pcf]=meanContrast(M, channel_SNR, pcf.FCC, mask_o, mask_i, 'PCF');

%% GCF

% beamform
gcf = postprocess.generalized_coherence_factor;
gcf.dimension = dimension.receive;
gcf.M0=4;
gcf.transmit_apodization = das.transmit_apodization;
gcf.receive_apodization = das.receive_apodization;
gcf.input = b_transmit;
gcf_anechoic = gcf.go();

% evaluate contrast
[C, CNR, Pmax, GCNR_gcf]=meanContrast(M, channel_SNR, gcf.GCF, mask_o, mask_i, 'GCF');

%% DMAS

% process DMAS
dmas=postprocess.delay_multiply_and_sum();
dmas.dimension = dimension.receive;
dmas.transmit_apodization = pipe.transmit_apodization;
dmas.receive_apodization = pipe.receive_apodization;
dmas.input = b_transmit;
dmas.channel_data = mix;
b_dmas = dmas.go();

% evaluate contrast
[C, CNR, Pmax, GCNR_dmas]=meanContrast(M, channel_SNR, b_dmas, mask_o, mask_i, 'DMAS');

%% SLSC 

% important that we use only M elements, centered around the abscissa of the pixel. 
% Changing that will alter the SNR ratio.

% Set up the SLSC postprocess
slsc = postprocess.short_lag_spatial_coherence();
slsc.receive_apodization = das.receive_apodization;
slsc.dimension = dimension.receive;
slsc.channel_data = mix;
slsc.maxM = 14;
slsc.input = b_transmit;
slsc.K_in_lambda = 1;

Q = slsc.maxM./M

% Pick out the M channels that contains data, thus only the M elemetns
% centered around the abscissa of the pixel. This is taken care of by the
% apodization so we can just pick up the element signals that are larger than 0.

% Data buffers
aux_data = zeros(sca.N_z_axis*sca.N_x_axis,1,1,mix.N_frames);
aux_data_clamped = zeros(sca.N_z_axis*sca.N_x_axis,1,1,mix.N_frames);
data_cube_M_elements = complex(zeros(sca.N_z_axis,sca.N_x_axis,M,1));
for f = 1:mix.N_frames
    f
    % Reshape the beamformed data as a cube (Z,X,Elements)
    data_cube = reshape(b_transmit.data(:,:,1,f),sca.N_z_axis,sca.N_x_axis,mix.N_channels);
    for x = 1: sca.N_x_axis
        sum_over_z = abs(sum(squeeze(data_cube(:,x,:)),1));
        elements_with_data = sum_over_z>0;
        data_cube_M_elements(:,x,:) = data_cube(:,x,elements_with_data);
    end
    
    % Call the actual implementation of the SLSC calculations, but using
    % the cube which has only M elements
    [image,slsc_values] = slsc.short_lag_spatial_coherence_implementation(data_cube_M_elements);
    image(image<0) = 0; % Set negative coherence values to zero
    
    slsc_img = squeeze(sum(slsc_values(:,:,:),2));
    slsc_img = slsc_img./max(slsc_img(:)); %According to previous publications
    
    % Make one clamped version
    slsc_img_clamped = slsc_img;
    slsc_img_clamped(slsc_img_clamped < 0 ) = 0;
    aux_data_clamped(:,1,1,f) = slsc_img_clamped(:);
    
    % In the other we  can shift the negative coherence to something
    % positive.
    slsc_img = slsc_img + abs(min(slsc_img(:)));
    aux_data(:,1,1,f) = slsc_img(:);
end

% Put the resulting SLSC images in a beamformed data
b_slsc_M_shifted = uff.beamformed_data();
b_slsc_M_shifted.scan = sca;
b_slsc_M_shifted.data = aux_data;

b_slsc_M_clamped = uff.beamformed_data();
b_slsc_M_clamped.scan = sca;
b_slsc_M_clamped.data = aux_data_clamped;

% contrast
[C, CNR, Pmax, GCNR_slsc]=meanContrast(M, channel_SNR, b_slsc_M_clamped, mask_o, mask_i, 'SLSC');

%% write Latex table
str = '';
for n=5:-1:1
    % SNR
    str = str + sprintf("%0.1f & ",10*log10(channel_SNR(1,n)));
    % DAS
    str = str + sprintf("%0.4f & ",GCNR_das(1,n));
    % S-DAS
    str = str + sprintf("%0.4f & ",GCNR_sdas(1,n));
    % CF
    str = str + sprintf("%0.4f & ",GCNR_cf(1,n));
    % PCF
    str = str + sprintf("%0.4f & ",GCNR_pcf(1,n));
    % GCF
    str = str + sprintf("%0.4f & ",GCNR_gcf(1,n));
    % DMAS
    str = str + sprintf("%0.4f & ",GCNR_dmas(1,n));
    % SLSC
    str = str + sprintf("%0.4f \\\\ ",GCNR_slsc(1,n));   
end

%% GCNR difference
[aa ind]=max(abs(GCNR_cf(1,:)-GCNR_das(1,:)));
aa=GCNR_cf(1,ind)-GCNR_das(1,ind);
fprintf('Maximum deviation CF at %0.1f dB: %0.2f\n',10*log10(channel_SNR(1,ind)),aa) 

[aa ind]=max(abs(GCNR_gcf(1,:)-GCNR_das(1,:)));
aa=GCNR_gcf(1,ind)-GCNR_das(1,ind);
fprintf('Maximum deviation GCF at %0.1f dB: %0.2f\n',10*log10(channel_SNR(1,ind)),aa) 

[aa ind]=max(abs(GCNR_pcf(1,:)-GCNR_das(1,:)));
aa=GCNR_pcf(1,ind)-GCNR_das(1,ind);
fprintf('Maximum deviation PCF at %0.1f dB: %0.2f\n',10*log10(channel_SNR(1,ind)),aa) 

[aa ind]=max(abs(GCNR_dmas(1,:)-GCNR_das(1,:)));
aa=GCNR_dmas(1,ind)-GCNR_das(1,ind);
fprintf('Maximum deviation DMAS at %0.1f dB: %0.2f\n',10*log10(channel_SNR(1,ind)),aa) 

[aa ind]=max(abs(GCNR_slsc(1,:)-GCNR_das(1,:)));
aa=GCNR_slsc(1,ind)-GCNR_das(1,ind);
fprintf('Maximum deviation SLSC at %0.1f dB: %0.2f\n',10*log10(channel_SNR(1,ind)),aa) 



