%% RUN_ALL_CHAPTER4 Complete Chapter 4 S/X-band preliminary design run.
clear; clc;
projectDir = fileparts(mfilename('fullpath')); if isempty(projectDir), projectDir=pwd; end
addpath(fullfile(projectDir,'src'));
figDir=fullfile(projectDir,'results','figures'); tabDir=fullfile(projectDir,'results','tables'); matDir=fullfile(projectDir,'results','mat');
if ~exist(figDir,'dir'), mkdir(figDir); end; if ~exist(tabDir,'dir'), mkdir(tabDir); end; if ~exist(matDir,'dir'), mkdir(matDir); end
cfg = config_chapter4(); c = 299792458;
requiredFigures = chapter4_required_figures();
for k = 1:numel(requiredFigures)
    deleteIfExists(fullfile(figDir, requiredFigures{k}));
    deleteIfExists(fullfile(figDir, strrep(requiredFigures{k},'.png','.pdf')));
end

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
plotOrbitFigures(pass,cfg,figDir);
plotPass(pass,cfg,figDir);

fprintf('4/8 Doppler analysis...\n');
sDop = -(pass.radialVelocityMps/c)*cfg.s.fcHz; xDop = -(pass.radialVelocityMps/c)*cfg.x.fcHz; [~,imin]=min(pass.rangeKm);
dopplerSummary = table(["S-band";"X-band"], [cfg.s.fcHz;cfg.x.fcHz]/1e9, [max(sDop);max(xDop)], [min(sDop);min(xDop)], [max(abs(sDop));max(abs(xDop))], [max(sDop)-min(sDop);max(xDop)-min(xDop)], [sDop(imin);xDop(imin)], 'VariableNames', {'Band','Frequency_GHz','Maximum_Positive_Doppler_Hz','Maximum_Negative_Doppler_Hz','Maximum_Absolute_Doppler_Hz','Peak_to_Peak_Doppler_Hz','Doppler_at_Closest_Approach_Hz'}); export_table_csv(dopplerSummary, fullfile(tabDir,'doppler_summary.csv'));
fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,sDop/1e3,'-',pass.tSec,xDop/1e3,'-'); xlabel('Time from pass start (s)'); ylabel('Doppler shift (kHz)'); title('S/X-band Doppler comparison'); legend('S-band','X-band'); grid on; save_plot(fig,fullfile(figDir,'sx_doppler_comparison'),cfg.output);
fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,xDop/1e3,'LineWidth',1.3); xlabel('Time from pass start (s)'); ylabel('X-band Doppler shift (kHz)'); title('X-band Doppler shift over selected pass'); grid on; save_plot(fig,fullfile(figDir,'fig4_24_xband_doppler_vs_time'),cfg.output);

fprintf('5/8 Dynamic link budgets...\n');
linkSNom=dynamic_link_budget(cfg.s,pass,"nominal",sSelectedRx.equivalentNoiseTemperatureK); linkSAdv=dynamic_link_budget(cfg.s,pass,"adverse",sSelectedRx.equivalentNoiseTemperatureK);
linkXNom=dynamic_link_budget(cfg.x,pass,"nominal",xSelectedRx.equivalentNoiseTemperatureK); linkXAdv=dynamic_link_budget(cfg.x,pass,"adverse",xSelectedRx.equivalentNoiseTemperatureK);
exportLink(linkSNom,fullfile(tabDir,'sband_dynamic_link_nominal.csv')); exportLink(linkSAdv,fullfile(tabDir,'sband_dynamic_link_adverse.csv')); exportLink(linkXNom,fullfile(tabDir,'xband_dynamic_link_nominal.csv')); exportLink(linkXAdv,fullfile(tabDir,'xband_dynamic_link_adverse.csv'));
plotLinks(pass,linkSNom,linkXNom,linkSAdv,linkXAdv,figDir,cfg);

fprintf('6/8 Data budget and component templates...\n');
dataSummary = [data_budget("S-band","nominal",linkSNom,cfg.s.netDataRateBps,cfg.general.passesPerDay,cfg.general.exampleImageSizeMB); data_budget("S-band","adverse",linkSAdv,cfg.s.netDataRateBps,cfg.general.passesPerDay,cfg.general.exampleImageSizeMB); data_budget("X-band","nominal",linkXNom,cfg.x.netDataRateBps,cfg.general.passesPerDay,cfg.general.exampleImageSizeMB); data_budget("X-band","adverse",linkXAdv,cfg.x.netDataRateBps,cfg.general.passesPerDay,cfg.general.exampleImageSizeMB)]; export_table_csv(dataSummary, fullfile(tabDir,'data_budget_summary.csv'));
writeTemplates(tabDir);

fprintf('7/8 Optional antenna toolbox visualizations...\n');
addpath(fullfile(projectDir,'optional_antenna_toolbox'));
antennaStatus.s = "analytical approximation"; antennaStatus.x = "analytical approximation";
if cfg.output.runOptionalAntenna
    try, antennaStatus.s = simulate_sband_reflector(cfg,figDir); catch ME, fprintf('S-band antenna figure generation failed: %s\n',ME.message); end
    try, antennaStatus.x = simulate_xband_reflector(cfg,figDir); catch ME, fprintf('X-band antenna figure generation failed: %s\n',ME.message); end
else
    antennaStatus.s = simulate_sband_reflector(cfg,figDir); antennaStatus.x = simulate_xband_reflector(cfg,figDir);
end

fprintf('8/8 Saving MAT file and summary report...\n');
save(fullfile(matDir,'chapter4_results.mat'),'cfg','pass','sRxTable','xRxTable','sSelectedRx','xSelectedRx','sDish','xDish','sPoint','xPoint','dopplerSummary','linkSNom','linkSAdv','linkXNom','linkXAdv','dataSummary','antennaStatus');
writeSummary(fullfile(projectDir,'results','chapter4_simulation_summary.txt'),pass,cfg,sDish,xDish,sSelectedRx,xSelectedRx,dopplerSummary,dataSummary,linkSNom,linkXNom);
validate_chapter4_outputs();
package_overleaf_figures(pass, antennaStatus);
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
names={'pass_elevation_vs_time','pass_azimuth_vs_time','pass_range_vs_time'}; thesisNames={'fig4_6_elevation_vs_time','fig4_7_azimuth_vs_time','fig4_8_slant_range_vs_time'}; ys={pass.elDeg,pass.azDeg,pass.rangeKm}; yl={'Elevation (deg)','Azimuth (deg)','Slant range (km)'}; tt={'Pass elevation','Pass azimuth','Pass slant range'};
for i=1:3, fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,ys{i},'LineWidth',1.3); xlabel('Time from pass start (s)'); ylabel(yl{i}); title(tt{i}); grid on; save_plot(fig,fullfile(figDir,names{i}),cfg.output); fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,ys{i},'LineWidth',1.3); xlabel('Time from pass start (s)'); ylabel(yl{i}); title(tt{i}); grid on; save_plot(fig,fullfile(figDir,thesisNames{i}),cfg.output); end
fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,abs(pass.azRateDegPerSec),pass.tSec,abs(pass.elRateDegPerSec)); yline(cfg.orbit.rotatorLimitDegPerSec,'--','Rotator limit'); xlabel('Time from pass start (s)'); ylabel('Rate (deg/s)'); title('Tracking rates'); legend('|Az rate|','|El rate|','Limit'); grid on; save_plot(fig,fullfile(figDir,'pass_tracking_rates'),cfg.output);
fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,abs(pass.azRateDegPerSec),'LineWidth',1.3); yline(cfg.orbit.rotatorLimitDegPerSec,'--','Rotator limit'); xlabel('Time from pass start (s)'); ylabel('Azimuth rate (deg/s)'); title('Azimuth tracking rate'); legend('|Azimuth rate|','Limit','Location','best'); grid on; save_plot(fig,fullfile(figDir,'fig4_9_azimuth_rate_vs_time'),cfg.output);
fig=figure('Visible',cfg.output.figureVisible); plot(pass.tSec,abs(pass.elRateDegPerSec),'LineWidth',1.3); yline(cfg.orbit.rotatorLimitDegPerSec,'--','Rotator limit'); xlabel('Time from pass start (s)'); ylabel('Elevation rate (deg/s)'); title('Elevation tracking rate'); legend('|Elevation rate|','Limit','Location','best'); grid on; save_plot(fig,fullfile(figDir,'fig4_10_elevation_rate_vs_time'),cfg.output);
fig=figure('Visible',cfg.output.figureVisible); tiledlayout(2,2); nexttile; plot(pass.tSec,pass.elDeg); ylabel('El (deg)'); nexttile; plot(pass.tSec,pass.azDeg); ylabel('Az (deg)'); nexttile; plot(pass.tSec,pass.rangeKm); ylabel('Range (km)'); xlabel('Time (s)'); nexttile; plot(pass.azDeg,pass.elDeg); xlabel('Az (deg)'); ylabel('El (deg)'); title('Pass geometry summary'); save_plot(fig,fullfile(figDir,'pass_geometry_summary'),cfg.output);
end
function exportLink(link,path)
T=table(link.time,link.tSec,link.rangeKm,link.fsplDb,repmat(link.rxAntennaGainDbi,numel(link.tSec),1),repmat(link.eirpDbm,numel(link.tSec),1),link.rxPowerDbm,repmat(link.systemTemperatureK,numel(link.tSec),1),repmat(link.noisePowerDbm,numel(link.tSec),1),link.snrDb,link.ebnoDb,link.rawMarginDb,link.marginDb,link.usableMask,link.cumulativeDataMB,'VariableNames',{'Time_UTC','Time_From_Pass_Start_s','Range_km','FSPL_dB','Receive_Antenna_Gain_dBi','EIRP_dBm','Received_Carrier_dBm','System_Temperature_K','Noise_Power_dBm','SNR_dB','EbNo_dB','Raw_Margin_dB','Design_Margin_dB','Usable_Link','Cumulative_Data_MB'}); export_table_csv(T,path);
end
function plotLinks(pass,s,x,sa,xa,figDir,cfg)
cfgout = cfg.output;
plotTwo(pass.tSec,s.fsplDb,x.fsplDb,'FSPL (dB)','Free-space path loss','fspl_sx_comparison',figDir,cfgout,false); plotTwo(pass.tSec,s.rxPowerDbm,x.rxPowerDbm,'Received carrier (dBm)','Received carrier power','rx_power_sx_comparison',figDir,cfgout,false); plotTwo(pass.tSec,s.ebnoDb,x.ebnoDb,'Eb/N0 (dB)','Nominal Eb/N0','ebno_sx_comparison',figDir,cfgout,false); plotTwo(pass.tSec,s.marginDb,x.marginDb,'Design margin (dB)','Nominal design margin','link_margin_sx_comparison',figDir,cfgout,true); plotTwo(pass.tSec,s.cumulativeDataMB,x.cumulativeDataMB,'Cumulative data (MB)','Nominal cumulative data','cumulative_data_sx_comparison',figDir,cfgout,false);
plotTwo(pass.tSec,s.marginDb,sa.marginDb,'Design margin (dB)','S-band nominal vs adverse margin','sband_margin_nominal_vs_adverse',figDir,cfgout,true,'Nominal','Adverse'); plotTwo(pass.tSec,x.marginDb,xa.marginDb,'Design margin (dB)','X-band nominal vs adverse margin','xband_margin_nominal_vs_adverse',figDir,cfgout,true,'Nominal','Adverse');
plotTwo(pass.tSec,s.marginDb,sa.marginDb,'Design margin (dB)','S-band nominal and adverse link margins','fig4_16_sband_link_margin_vs_time',figDir,cfgout,true,'Nominal','Adverse');
plotTwo(pass.tSec,x.marginDb,xa.marginDb,'Design margin (dB)','X-band nominal and adverse link margins','fig4_26_xband_link_margin_vs_time',figDir,cfgout,true,'Nominal','Adverse');
plotSingle(pass.tSec,s.rxPowerDbm,'Received carrier (dBm)','S-band received power','fig4_15_sband_received_power_vs_time',figDir,cfgout);
plotSingle(pass.tSec,x.rxPowerDbm,'Received carrier (dBm)','X-band received power','fig4_25_xband_received_power_vs_time',figDir,cfgout);
plotSingle(pass.tSec,s.cumulativeDataMB,'Cumulative data (MB)','S-band cumulative received data','fig4_17_sband_cumulative_data_vs_time',figDir,cfgout);
plotSingle(pass.tSec,x.cumulativeDataMB,'Cumulative data (MB)','X-band cumulative received data','fig4_27_xband_cumulative_data_vs_time',figDir,cfgout);
err=linspace(0,3,200); hp=compute_beamwidth(cfg.x.fcHz,cfg.x.selectedDishDiameterM); loss=compute_pointing_loss(err(:),hp); plotSingle(err,loss,'Pointing loss (dB)','X-band pointing loss vs angular error','fig4_23_xband_pointing_loss',figDir,cfgout,'Pointing error (deg)');
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

function deleteIfExists(path)
if exist(path,'file'), delete(path); end
end

function plotSingle(t,y,yl,tt,name,figDir,cfgout,xlab)
if nargin < 8, xlab = 'Time from pass start (s)'; end
fig=figure('Visible',cfgout.figureVisible); plot(t,y,'LineWidth',1.3); xlabel(xlab); ylabel(yl); title(tt); grid on; save_plot(fig,fullfile(figDir,name),cfgout);
end

function plotOrbitFigures(pass,cfg,figDir)
sc=pass.scenario; idx=sc.selectedIdx; pos=sc.positionEcefM; Re=6371; fig=figure('Visible',cfg.output.figureVisible); [xe,ye,ze]=sphere(48); surf(Re*xe,Re*ye,Re*ze,'FaceAlpha',0.25,'EdgeColor','none'); hold on; plot3(pos(:,1)/1000,pos(:,2)/1000,pos(:,3)/1000,'Color',[0.2 0.2 0.8]); plot3(pos(idx,1)/1000,pos(idx,2)/1000,pos(idx,3)/1000,'r','LineWidth',2); gs=llaToEcefPlot(cfg.gs.latDeg,cfg.gs.lonDeg,cfg.gs.altM); plot3(gs(1)/1000,gs(2)/1000,gs(3)/1000,'kp','MarkerFaceColor','y','MarkerSize',12); axis equal; xlabel('ECEF x (km)'); ylabel('ECEF y (km)'); zlabel('ECEF z (km)'); title('Chapter 4 orbit/scenario view: ' + string(sc.source)); legend('Earth','Propagated trajectory','Selected visible pass','Ground station','Location','best'); grid on; if sc.source == "synthetic representative pass", text(0,0,1.25*Re,'Synthetic representative orbit -- not precise propagation','FontWeight','bold'); end; save_plot(fig,fullfile(figDir,'fig4_3_orbit_3d_scenario'),cfg.output);
fig=figure('Visible',cfg.output.figureVisible); lon=sc.lonDeg; lat=sc.latDeg; br=[false; abs(diff(lon))>180]; lon(br)=NaN; lat(br)=NaN; plot(lon,lat,'Color',[0.2 0.2 0.8]); hold on; plot(sc.lonDeg(idx),sc.latDeg(idx),'r','LineWidth',2); plot(cfg.gs.lonDeg,cfg.gs.latDeg,'kp','MarkerFaceColor','y','MarkerSize',12); xlabel('Longitude (deg)'); ylabel('Latitude (deg)'); title('Satellite ground track and selected visible pass'); legend('Full track','Selected pass','Zawiya ground station','Location','best'); xlim([-180 180]); ylim([-90 90]); grid on; save_plot(fig,fullfile(figDir,'fig4_4_ground_track'),cfg.output);
fig=figure('Visible',cfg.output.figureVisible); tmin=minutes(sc.time-sc.time(1)); stairs(tmin, double(sc.accessMask),'LineWidth',1.3); ylim([-0.1 1.2]); yticks([0 1]); yticklabels({'Not visible','Visible'}); xlabel('Time from analysis start (min)'); ylabel('Access state'); title(sprintf('Access visibility, minimum elevation %.1f deg (%s)',cfg.gs.minElevationDeg,sc.source)); grid on; save_plot(fig,fullfile(figDir,'fig4_5_access_visibility'),cfg.output);
end
function ecef=llaToEcefPlot(lat,lon,alt)
a=6378137; e2=6.69437999014e-3; N=a/sqrt(1-e2*sind(lat)^2); ecef=[(N+alt)*cosd(lat)*cosd(lon),(N+alt)*cosd(lat)*sind(lon),(N*(1-e2)+alt)*sind(lat)];
end
