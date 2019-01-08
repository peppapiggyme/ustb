clear all;
close all;

%%
%filename = 'phantom_2dB.uff';
filename = [data_path,filesep,'phantom_1d8dB.uff'];
channel_data = uff.channel_data();
channel_data.read(filename,'/channel_data')


scan=uff.linear_scan('x_axis',linspace(-20e-3,20e-3,1024).','z_axis',linspace(6e-3,52.5e-3,2048).')

%if strcmp(filename,'phantom_2dB.uff')
    channel_data.data(:,:,1) = 0;
    [f, F] = tools.power_spectrum(channel_data.data,channel_data.sampling_frequency);
    
    figure(777);
    subplot(2,1,1);
    plot(f,db(F));
    
    % interpolation_factor = 2;
    %
    % channel_data.data = interpft(double(channel_data.data),length(channel_data.data)*interpolation_factor);
    % channel_data.sampling_frequency = channel_data.sampling_frequency*2;
    
    freq_lim = [1e6 1.5e6];
    data_filtered = tools.high_pass(channel_data.data, channel_data.sampling_frequency,freq_lim);
    channel_data.data = data_filtered;
    
    [f, F] = tools.power_spectrum(channel_data.data,channel_data.sampling_frequency);
    
    subplot(2,1,1);hold on;
    plot(f,db(F),'r');
    title('After filtering and interpolation');
    
    
    channel_data.name = {['Experimental dynamic range phantom. Recorded on a Verasonics Vantage 256 with a L11 probe. See the reference for details']};
    channel_data.sound_speed = 1470;
%%
%% Beamformer
%
% With *channel_data* and a *scan* we have all we need to produce an
% ultrasound image. We now use a USTB structure *beamformer*, that takes an
% *apodization* structure in addition to the *channel_data* and *scan*.

mid = midprocess.das();
mid.channel_data=channel_data;
mid.scan=scan;
mid.dimension = dimension.transmit();

mid.receive_apodization.window=uff.window.boxcar;
mid.receive_apodization.f_number=1.75;

mid.transmit_apodization.window=uff.window.boxcar;
mid.transmit_apodization.f_number=1.75;


%%
[weights,array_gain_compensation,geo_spreading_compensation] = ...
                                           tools.uniform_fov_weighting(mid);
%% 
b_data_weights = uff.beamformed_data();                                       
b_data_weights.scan = scan;
b_data_weights.data = weights(:);
%%

% Delay and sum on receive, then coherent compounding
b_data_tx = mid.go();


%% DELAY AND SUM
das=postprocess.coherent_compounding();
das.input = b_data_tx;
b_data_das = das.go();
f1 = figure(3);clf;
imagesc(b_data_das.scan.x_axis*1000,b_data_das.scan.z_axis*1000,b_data_das.get_image);
colormap gray;caxis([-60 0]);axis image;title('DAS');xlabel('x [mm]');ylabel('z [mm]');
set(gca,'FontSize',14);

%%
cf = postprocess.coherence_factor();
cf.dimension = dimension.receive;
cf.receive_apodization = mid.receive_apodization;
cf.transmit_apodization = mid.transmit_apodization;
cf.input = b_data_tx;
b_data_cf = cf.go();
f2 = figure(2);
imagesc(b_data_das.scan.x_axis*1000,b_data_das.scan.z_axis*1000,b_data_cf.get_image);
colormap gray;caxis([-60 0]);axis image;title('CF');xlabel('x [mm]');ylabel('z [mm]');
set(gca,'FontSize',14);

%%
pcf = postprocess.phase_coherence_factor();
pcf.dimension = dimension.receive;
pcf.receive_apodization = mid.receive_apodization;
pcf.transmit_apodization = mid.transmit_apodization;
pcf.input = b_data_tx;
b_data_pcf = pcf.go();
f3 = figure(3);clf;
imagesc(b_data_das.scan.x_axis*1000,b_data_das.scan.z_axis*1000,b_data_pcf.get_image);
colormap gray;caxis([-60 0]);axis image;title('PCF');xlabel('x [mm]');ylabel('z [mm]');
set(gca,'FontSize',14);

%%
gcf=postprocess.generalized_coherence_factor_OMHR();
gcf.dimension = dimension.receive;
gcf.transmit_apodization = mid.transmit_apodization;
gcf.receive_apodization = mid.receive_apodization;
gcf.input = b_data_tx;
gcf.channel_data = channel_data;
gcf.M0 = 2;
b_data_gcf = gcf.go();
f4 = figure(4);
imagesc(b_data_das.scan.x_axis*1000,b_data_das.scan.z_axis*1000,b_data_gcf.get_image);
colormap gray;caxis([-60 0]);axis image;title('GCF');xlabel('x [mm]');ylabel('z [mm]');
set(gca,'FontSize',14);

%%
mv = postprocess.capon_minimum_variance();
mv.dimension = dimension.receive;
mv.transmit_apodization = mid.transmit_apodization;
mv.receive_apodization = mid.receive_apodization;
mv.input = b_data_tx;
mv.scan = scan;
mv.channel_data = channel_data;
mv.K_in_lambda = 1.5;
mv.L_elements = channel_data.probe.N/2;
mv.regCoef = 1/100;
b_data_mv = mv.go();
%%
f5 = figure(6);clf;
imagesc(b_data_das.scan.x_axis*1000,b_data_das.scan.z_axis*1000,b_data_mv.get_image);
colormap gray;caxis([-60 0]);axis image;title('MV');xlabel('x [mm]');ylabel('z [mm]');
set(gca,'FontSize',14);

%% Process DMAS
dmas=postprocess.delay_multiply_and_sum();
dmas.dimension = dimension.receive;
dmas.transmit_apodization = mid.transmit_apodization;
dmas.receive_apodization = mid.receive_apodization;
dmas.input = b_data_tx;
dmas.channel_data = channel_data;
b_data_dmas = dmas.go();
b_data_dmas.plot(6,['DMAS'])

%%
dmas_img = b_data_dmas.get_image('none');
dmas_img = db(abs(dmas_img./max(dmas_img(:))));
f7 = figure(7);clf;
imagesc(b_data_das.scan.x_axis*1000,b_data_das.scan.z_axis*1000,dmas_img);
colormap gray;caxis([-60 0]);axis image;title('DMAS');xlabel('x [mm]');ylabel('z [mm]');
set(gca,'FontSize',14);

%% EIGENSPACE BASED MINIMUM VARIANCE
ebmv=postprocess.eigenspace_based_minimum_variance();
ebmv.dimension = dimension.receive;
ebmv.input = b_data_tx;
ebmv.channel_data = channel_data;
ebmv.scan = scan;
ebmv.K_in_lambda = 1.5;
ebmv.gamma = 0.5;
ebmv.L_elements = floor(channel_data.probe.N/2);
ebmv.transmit_apodization = mid.transmit_apodization;
ebmv.receive_apodization = mid.receive_apodization;
ebmv.regCoef = 1/100;

b_data_ebmv = ebmv.go();

ebmv_img = b_data_ebmv.get_image('none');
ebmv_img = db(abs(ebmv_img./max(ebmv_img(:))));
f6 = figure(8);clf;
imagesc(b_data_das.scan.x_axis*1000,b_data_das.scan.z_axis*1000,ebmv_img);
colormap gray;caxis([-60 0]);axis image;title('EBMV');xlabel('x [mm]');ylabel('z [mm]');
set(gca,'FontSize',14);

%%
channel_data.name = {'v2 Experimental dynamic range phantom. Recorded on a Verasonics Vantage 256 with a L11 probe. See the reference for details'};
channel_data.author = {'Alfonso Rodriguez-Molares <alfonso.r.molares@ntnu.no>','Ali Fatemi <ali.fatemi@ntnu.no>','Ole Marius Hoel Rindal <omrindal@ifi.uio.no'};
channel_data.reference = {'Rindal, O. M. H., Austeng, A., Fatemi, A., & Rodriguez-Molares, A. (2018). The effect of dynamic range transformations in the estimation of contrast. Submitted to IEEE Transactions on Ultrasonics, Ferroelectrics, and Frequency Control.'};
channel_data.version = {'1.0.1'};

channel_data.print_authorship

channel_data.write(filename,'channel_data');
%%

b_data_das.write(filename,'/b_data_das');
b_data_cf.write(filename,'/b_data_cf');
b_data_pcf.write(filename,'/b_data_pcf');
b_data_gcf.write(filename,'/b_data_gcf');
b_data_mv.write(filename,'/b_data_mv');
b_data_ebmv.write(filename,'/b_data_ebmv');
b_data_dmas.write(filename,'/b_data_dmas');