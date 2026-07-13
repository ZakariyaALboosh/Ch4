%% RUN_ALL_CHAPTER4 Complete Chapter 4 S/X-band preliminary design run.
clear; clc;
projectDir = fileparts(mfilename('fullpath')); if isempty(projectDir), projectDir=pwd; end
addpath(fullfile(projectDir,'src'));
figDir=fullfile(projectDir,'results','figures'); tabDir=fullfile(projectDir,'results','tables'); matDir=fullfile(projectDir,'results','mat');
if ~exist(figDir,'dir'), mkdir(figDir); end; if ~exist(tabDir,'dir'), mkdir(tabDir); end; if ~exist(matDir,'dir'), mkdir(matDir); end
cfg = config_chapter4(); c = 299792458;

fprintf('1/8 Receiver cascade studies...\n');
[sRxTable,sSelectedRx] = runReceiverStudy(cfg.s, cfg.general.referenceTemperatureK); export_table_csv(sRxTable, fullfile(tabDir,'sband_receiver_noise.csv'));
[xRxTable,xSelectedRx] = runReceiverStudy(cfg.x, cfg.general.referenceTemperatureK); export_table_csv(xRxTable, fullfile(tabDir,'xband_receiver_noise.csv'));
plotNoise(sRxTable,'S-band',fullfile(figDir,'sband_noise_vs_prelna_loss'),cfg.output); plotNoise(xRxTable,'X-band',fullfile(figDir,'xband_noise_vs_prelna_loss'),cfg.output);

fprintf('2/8 Dish gain, beamwidth, and pointing studies...\n');
[sDish,sPoint] = dishStudy(cfg.s); [xDish,xPoint] = dishStudy(cfg.x);
export_table_csv(sDish, fullfile(tabDir,'sband_dish_trade.csv')); export_table_csv(xDish, fullfile(tabDir,'xband_dish_trade.csv'));
export_table_csv(sPoint, fullfile(tabDir,'sband_pointing_loss.csv')); export_table_csv(xPoint, fullfile(tabDir,'xband_pointing_loss.csv'));
plotDish(sDish,'Gain_dBi','Gain (dBi)','S-band dish gain',fullfile(figDir,'sband_gain_vs_diameter'),cfg.output);
plotDish(xDish,'Gain_dBi','Gain (dBi)','X-band dish gain',fullfile(figDir,'xband_gain_vs_diameter'),cfg.output);
plotDish(sDish,'HPBW_deg','HPBW (deg)','S-band beamwidth',fullfile(figDir,'sband_beamwidth_vs_diameter'),cfg.output);
plotDish(xDish,'HPBW_deg','HPBW (deg)','X-band beamwidth',fullfile(figDir,'xband_beamwidth_vs_diameter'),cfg.output);
fig=figure('Visible',cfg.output.figureVisible); plot(sPoint.Pointing_Error_deg,sPoint.Pointing_Loss_dB,'-o',xPoint.Pointing_Error_deg,xPoint.Pointing_Loss_dB,'-s'); xlabel('Pointing error (deg)'); ylabel('Pointing loss (dB)'); title('Pointing loss comparison for selected dishes'); legend('S-band','X-band','Location','northwest'); grid on; save_plot(fig,fullfile(figDir,'pointing_loss_comparison'),cfg.output);

fprintf('3/8 Pass geometry and tracking rates...\n');
pass = simple_orbit_pass(cfg); passTable = table(pass.time, pass.tSec, pass.azDeg, pass.elDeg, pass.rangeKm, pass.radialVelocityMps, pass.azRateDegPerSec, pass.elRateDegPerSec, pass.accessMask, repmat(string(pass.source),numel(pass.tSec),1), 'VariableNames', {'Time_UTC','Time_From_Pass_Start_s','Azimuth_deg','Elevation_deg','Range_km','Radial_Velocity_mps','Azimuth_Rate_deg_per_s','Elevation_Rate_deg_per_s','Above_Minimum_Elevation','Source'}); export_table_csv(passTable, fullfile(tabDir,'pass_geometry.csv'));
plotPass(pass,cfg,figDir);

fprintf('4/8 Doppler analysis...\n');
sDop = -(pass.radialVelocityMps/c)*cfg.s.fcHz; xDop = -(pass.radialVelocityMps/c)*cfg.x.fcHz; [~,imin]=min(pass.rangeKm);
dopplerSummary = table(["S-band";"X-band"], [cfg.s.fcHz;cfg.x.fcHz]/1e9, [max(sDop);max(xDop)], [min(sDop);min(xDop)], [max(abs(sDop));max(abs(xDop))], [max(sDop)-min(sDop);max(xDop)-min(xDop)], [sDop(imin);xDop(imin)], 'VariableNames', {'Band','Frequency_GHz','Maximum_Positive_Doppler_Hz','Maximum_Negative_Doppler_Hz','Maximum_Absolute_Doppler_Hz','Peak_to_Peak_Doppler_Hz','Doppler_at_Closest_Approach_Hz'}); export_table_csv(dopplerSummary, fullfile(tabDir,'doppler_summary.csv'));
fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,sDop/1e3,'-',pass.tSec,xDop/1e3,'-'); xlabel('Time from pass start (s)'); ylabel('Doppler shift (kHz)'); title('S/X-band Doppler comparison'); legend('S-band','X-band'); grid on; save_plot(fig,fullfile(figDir,'sx_doppler_comparison'),cfg.output);

fprintf('5/8 Dynamic link budgets...\n');
linkSNom=dynamic_link_budget(cfg.s,pass,"nominal",sSelectedRx.equivalentNoiseTemperatureK); linkSAdv=dynamic_link_budget(cfg.s,pass,"adverse",sSelectedRx.equivalentNoiseTemperatureK);
linkXNom=dynamic_link_budget(cfg.x,pass,"nominal",xSelectedRx.equivalentNoiseTemperatureK); linkXAdv=dynamic_link_budget(cfg.x,pass,"adverse",xSelectedRx.equivalentNoiseTemperatureK);
exportLink(linkSNom,fullfile(tabDir,'sband_dynamic_link_nominal.csv')); exportLink(linkSAdv,fullfile(tabDir,'sband_dynamic_link_adverse.csv')); exportLink(linkXNom,fullfile(tabDir,'xband_dynamic_link_nominal.csv')); exportLink(linkXAdv,fullfile(tabDir,'xband_dynamic_link_adverse.csv'));
plotLinks(pass,linkSNom,linkXNom,linkSAdv,linkXAdv,figDir,cfg.output);

fprintf('6/8 Data budget and component templates...\n');
dataSummary = [data_budget("S-band","nominal",linkSNom,cfg.s.netDataRateBps,cfg.general.passesPerDay,cfg.general.exampleImageSizeMB); data_budget("S-band","adverse",linkSAdv,cfg.s.netDataRateBps,cfg.general.passesPerDay,cfg.general.exampleImageSizeMB); data_budget("X-band","nominal",linkXNom,cfg.x.netDataRateBps,cfg.general.passesPerDay,cfg.general.exampleImageSizeMB); data_budget("X-band","adverse",linkXAdv,cfg.x.netDataRateBps,cfg.general.passesPerDay,cfg.general.exampleImageSizeMB)]; export_table_csv(dataSummary, fullfile(tabDir,'data_budget_summary.csv'));
writeTemplates(tabDir);

fprintf('7/8 Optional antenna toolbox visualizations...\n');
if cfg.output.runOptionalAntenna
    addpath(fullfile(projectDir,'optional_antenna_toolbox'));
    try, simulate_sband_reflector(cfg,figDir); catch ME, fprintf('Optional S-band antenna simulation skipped: %s\n',ME.message); end
    try, simulate_xband_reflector(cfg,figDir); catch ME, fprintf('Optional X-band antenna simulation skipped: %s\n',ME.message); end
end

fprintf('8/8 Saving MAT file and summary report...\n');
save(fullfile(matDir,'chapter4_results.mat'),'cfg','pass','sRxTable','xRxTable','sSelectedRx','xSelectedRx','sDish','xDish','sPoint','xPoint','dopplerSummary','linkSNom','linkSAdv','linkXNom','linkXAdv','dataSummary');
writeSummary(fullfile(projectDir,'results','chapter4_simulation_summary.txt'),pass,cfg,sDish,xDish,sSelectedRx,xSelectedRx,dopplerSummary,dataSummary,linkSNom,linkXNom);
fprintf('Chapter 4 simulation package complete. Results written to %s\n', fullfile(projectDir,'results'));

function [tbl, selected] = runReceiverStudy(band, T0)
losses = band.receiver.studyPreLnaLossDb(:);
totalGain = zeros(numel(losses),1); totalNf = zeros(numel(losses),1); teK = zeros(numel(losses),1);
for i=1:numel(losses)
    stages = cascadeStages(losses(i), band.receiver.activeDeviceName, band.receiver.activeGainDb, band.receiver.activeNfDb, band.receiver.postLnaLossDb);
    r = receiver_cascade(stages,T0); totalGain(i)=r.totalGainDb; totalNf(i)=r.totalNoiseFigureDb; teK(i)=r.equivalentNoiseTemperatureK;
end
tbl = table(repmat(band.name,numel(losses),1), losses, totalGain, totalNf, teK, 'VariableNames',{'Band','Pre_LNA_Loss_dB','Total_Gain_dB','Total_Noise_Figure_dB','Equivalent_Noise_Temperature_K'});
selected = receiver_cascade(cascadeStages(band.rxLossBeforeLnaDb, band.receiver.activeDeviceName, band.receiver.activeGainDb, band.receiver.activeNfDb, band.rxLossAfterLnaDb),T0);
end
function stages = cascadeStages(preLoss,name,gain,nf,postLoss)
stages(1)=struct('name','Pre-LNA passive loss','gainDb',-preLoss,'nfDb',preLoss); stages(2)=struct('name',char(name),'gainDb',gain,'nfDb',nf); stages(3)=struct('name','Post-LNA passive loss','gainDb',-postLoss,'nfDb',postLoss);
end
function plotNoise(tbl,bandName,out,cfgout), fig=figure('Visible',cfgout.figureVisible); plot(tbl.Pre_LNA_Loss_dB,tbl.Total_Noise_Figure_dB,'-o','LineWidth',1.5); xlabel('Pre-LNA loss (dB)'); ylabel('Total receiver NF (dB)'); title(string(bandName) + " receiver noise versus pre-LNA loss"); grid on; save_plot(fig,out,cfgout); end
function [dish,point] = dishStudy(band)
d=band.rxDishDiametersM(:); gain=compute_dish_gain(band.fcHz,d,band.dishEfficiency); hpbw=compute_beamwidth(band.fcHz,d); dish=table(repmat(band.name,numel(d),1),repmat(band.fcHz/1e9,numel(d),1),d,repmat(band.dishEfficiency,numel(d),1),gain,hpbw,'VariableNames',{'Band','Frequency_GHz','Diameter_m','Efficiency','Gain_dBi','HPBW_deg'});
errs=[0 0.2 0.5 1 2 3 5]'; selH=compute_beamwidth(band.fcHz,band.selectedDishDiameterM); point=table(repmat(band.name,numel(errs),1),repmat(band.selectedDishDiameterM,numel(errs),1),repmat(selH,numel(errs),1),errs,compute_pointing_loss(errs,selH),'VariableNames',{'Band','Selected_Diameter_m','HPBW_deg','Pointing_Error_deg','Pointing_Loss_dB'});
end
function plotDish(tbl,var,y,titleText,out,cfgout), fig=figure('Visible',cfgout.figureVisible); plot(tbl.Diameter_m,tbl.(var),'-o','LineWidth',1.5); xlabel('Dish diameter (m)'); ylabel(y); title(titleText); grid on; save_plot(fig,out,cfgout); end
function plotPass(pass,cfg,figDir)
names={'pass_elevation_vs_time','pass_azimuth_vs_time','pass_range_vs_time'}; ys={pass.elDeg,pass.azDeg,pass.rangeKm}; yl={'Elevation (deg)','Azimuth (deg)','Range (km)'}; tt={'Pass elevation','Pass azimuth','Pass slant range'};
for i=1:3, fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,ys{i},'LineWidth',1.3); xlabel('Time from pass start (s)'); ylabel(yl{i}); title(tt{i}); grid on; save_plot(fig,fullfile(figDir,names{i}),cfg.output); end
fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,abs(pass.azRateDegPerSec),pass.tSec,abs(pass.elRateDegPerSec)); yline(cfg.orbit.rotatorLimitDegPerSec,'--','Rotator limit'); xlabel('Time from pass start (s)'); ylabel('Rate (deg/s)'); title('Tracking rates'); legend('|Az rate|','|El rate|','Limit'); grid on; save_plot(fig,fullfile(figDir,'pass_tracking_rates'),cfg.output);
fig=figure('Visible',cfg.output.figureVisible); tiledlayout(2,2); nexttile; plot(pass.tSec,pass.elDeg); ylabel('El (deg)'); nexttile; plot(pass.tSec,pass.azDeg); ylabel('Az (deg)'); nexttile; plot(pass.tSec,pass.rangeKm); ylabel('Range (km)'); xlabel('Time (s)'); nexttile; plot(pass.azDeg,pass.elDeg); xlabel('Az (deg)'); ylabel('El (deg)'); title('Pass geometry summary'); save_plot(fig,fullfile(figDir,'pass_geometry_summary'),cfg.output);
end
function exportLink(link,path)
T=table(link.time,link.tSec,link.rangeKm,link.fsplDb,repmat(link.rxAntennaGainDbi,numel(link.tSec),1),repmat(link.eirpDbm,numel(link.tSec),1),link.rxPowerDbm,repmat(link.systemTemperatureK,numel(link.tSec),1),repmat(link.noisePowerDbm,numel(link.tSec),1),link.snrDb,link.ebnoDb,link.rawMarginDb,link.marginDb,link.usableMask,link.cumulativeDataMB,'VariableNames',{'Time_UTC','Time_From_Pass_Start_s','Range_km','FSPL_dB','Receive_Antenna_Gain_dBi','EIRP_dBm','Received_Carrier_dBm','System_Temperature_K','Noise_Power_dBm','SNR_dB','EbNo_dB','Raw_Margin_dB','Design_Margin_dB','Usable_Link','Cumulative_Data_MB'}); export_table_csv(T,path);
end
function plotLinks(pass,s,x,sa,xa,figDir,cfgout)
plotTwo(pass.tSec,s.fsplDb,x.fsplDb,'FSPL (dB)','Free-space path loss','fspl_sx_comparison',figDir,cfgout,false); plotTwo(pass.tSec,s.rxPowerDbm,x.rxPowerDbm,'Received carrier (dBm)','Received carrier power','rx_power_sx_comparison',figDir,cfgout,false); plotTwo(pass.tSec,s.ebnoDb,x.ebnoDb,'Eb/N0 (dB)','Nominal Eb/N0','ebno_sx_comparison',figDir,cfgout,false); plotTwo(pass.tSec,s.marginDb,x.marginDb,'Design margin (dB)','Nominal design margin','link_margin_sx_comparison',figDir,cfgout,true); plotTwo(pass.tSec,s.cumulativeDataMB,x.cumulativeDataMB,'Cumulative data (MB)','Nominal cumulative data','cumulative_data_sx_comparison',figDir,cfgout,false);
plotTwo(pass.tSec,s.marginDb,sa.marginDb,'Design margin (dB)','S-band nominal vs adverse margin','sband_margin_nominal_vs_adverse',figDir,cfgout,true,'Nominal','Adverse'); plotTwo(pass.tSec,x.marginDb,xa.marginDb,'Design margin (dB)','X-band nominal vs adverse margin','xband_margin_nominal_vs_adverse',figDir,cfgout,true,'Nominal','Adverse');
end
function plotTwo(t,a,b,yl,tt,name,figDir,cfgout,zero,varargin)
fig=figure('Visible',cfgout.figureVisible); plot(t,a,'-',t,b,'-','LineWidth',1.3); if zero, yline(0,'--','0 dB'); end; xlabel('Time from pass start (s)'); ylabel(yl); title(tt); if nargin>9, legend(varargin{1},varargin{2},'Location','best'); else, legend('S-band','X-band','Location','best'); end; grid on; save_plot(fig,fullfile(figDir,name),cfgout);
end
function writeTemplates(tabDir)
writeComponent(tabDir,'sband',{'Dish or reflector';'Helix feed';'Band-pass filter';'LNA';'Bias tee';'Coaxial cable';'Rotator';'Rotator controller';'bladeRF x40';'Raspberry Pi or computer'}); writeComponent(tabDir,'xband',{'Solid dish';'Horn feed';'Polarizer or OMT';'X-band filter';'X-band LNB or LNA';'Downconverter';'IF filter';'IF amplifier';'Bias tee or power supply';'Waveguide or coax';'Rotator';'bladeRF x40';'Raspberry Pi or computer'});
end
function writeComponent(tabDir,prefix,items)
n=numel(items); T=table(repmat("Receive chain",n,1),string(items),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("Editable preliminary worksheet",n,1),'VariableNames',{'Subsystem','Component_Function','Candidate_Model','Manufacturer','Frequency_Range','Gain_or_Loss_dB','Noise_Figure_dB','Power_Requirement','Connector','Estimated_Cost','Availability','Selected_Yes_No','Reason_for_Selection','Datasheet_Link_or_Source','Notes'}); export_table_csv(T,fullfile(tabDir,string(prefix) + "_component_selection_template.csv"));
B=table(repmat(upper(extractBefore(string(prefix),2)) + "-band",n,1),string(items),repmat("TBD",n,1),string(items),ones(n,1),repmat("TBD",n,1),repmat("TBD",n,1),repmat("Template",n,1),repmat("Editable; not final procurement",n,1),'VariableNames',{'Band','Item','Selected_Model','Function','Quantity','Estimated_Unit_Cost','Estimated_Total_Cost','Status','Notes'}); export_table_csv(B,fullfile(tabDir,string(prefix) + "_bom_template.csv"));
end
function writeSummary(path,pass,cfg,sDish,xDish,sRx,xRx,dop,data,linkS,linkX)
fid=fopen(path,'w'); cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'Simulation source for pass geometry: %s\n\n',pass.source);
fprintf(fid,'S-band selected dish diameter: %.2f m\nS-band calculated gain: %.2f dBi\nS-band HPBW: %.2f deg\nS-band selected receiver NF: %.2f dB\nS-band selected receiver equivalent noise temperature: %.1f K\nS-band maximum absolute Doppler: %.1f Hz\nS-band nominal usable pass time: %.1f s\nS-band nominal data per pass: %.2f MB\nS-band nominal minimum design margin: %.2f dB\n\n',cfg.s.selectedDishDiameterM,compute_dish_gain(cfg.s.fcHz,cfg.s.selectedDishDiameterM,cfg.s.dishEfficiency),compute_beamwidth(cfg.s.fcHz,cfg.s.selectedDishDiameterM),sRx.totalNoiseFigureDb,sRx.equivalentNoiseTemperatureK,dop.Maximum_Absolute_Doppler_Hz(1),data.Usable_Time_s(1),data.Data_per_Pass_MB(1),min(linkS.marginDb));
fprintf(fid,'X-band selected dish diameter: %.2f m\nX-band calculated gain: %.2f dBi\nX-band HPBW: %.2f deg\nX-band selected receiver NF: %.2f dB\nX-band selected receiver equivalent noise temperature: %.1f K\nX-band maximum absolute Doppler: %.1f Hz\nX-band nominal usable pass time: %.1f s\nX-band nominal data per pass: %.2f MB\nX-band nominal minimum design margin: %.2f dB\n\n',cfg.x.selectedDishDiameterM,compute_dish_gain(cfg.x.fcHz,cfg.x.selectedDishDiameterM,cfg.x.dishEfficiency),compute_beamwidth(cfg.x.fcHz,cfg.x.selectedDishDiameterM),xRx.totalNoiseFigureDb,xRx.equivalentNoiseTemperatureK,dop.Maximum_Absolute_Doppler_Hz(2),data.Usable_Time_s(3),data.Data_per_Pass_MB(3),min(linkX.marginDb));
fprintf(fid,'These results are preliminary design simulations based on simplified assumptions and datasheet-level values. They are not experimental verification of a constructed S-band or X-band station.\n');
if pass.source == "synthetic representative pass", fprintf(fid,'The orbit result is a synthetic representative pass and must not be presented as a precise satellite pass prediction.\n'); end
clear cleaner; type(path);
end
