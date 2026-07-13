function summary = data_budget(bandName, environmentName, link, netDataRateBps, passesPerDay, exampleImageSizeMB)
dtVector = diff(link.tSec(:)); usableIntervals = link.usableMask(1:end-1) & link.usableMask(2:end);
usableTimeSec = sum(dtVector(usableIntervals)); dataBits = usableTimeSec * netDataRateBps; dataMB = dataBits/8/1e6; dailyDataMB = dataMB*passesPerDay;
summary = table(string(bandName), string(environmentName), usableTimeSec, dataMB, passesPerDay, dailyDataMB, exampleImageSizeMB, floor(dataMB/exampleImageSizeMB), floor(dailyDataMB/exampleImageSizeMB), ...
 'VariableNames', {'Band','Environment','Usable_Time_s','Data_per_Pass_MB','Assumed_Passes_per_Day','Data_per_Day_MB','Example_Image_Size_MB','Images_per_Pass','Images_per_Day'});
end
