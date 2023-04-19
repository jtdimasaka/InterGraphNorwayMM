%% preprocessData.m
% This script extracts and preprocesses various datasets to become
% suitable for the implementation of the main machine learning model.
% These are the preprocessed variables (initialized).
clear, clc, close

%% load important reference files
% load global coords and fid for referencing
load("data\road_network\summaryLABEL.mat", ...
    "summaryCOORDS",...
    "date")
feature = struct();
feature.fid = summaryCOORDS(:,1);
feature.nodeidx = summaryCOORDS(:,2);
feature.x = summaryCOORDS(:,3);
feature.y = summaryCOORDS(:,4);
feature.YYYY = date(:,1);
feature.MM = date(:,2);
feature.DD = date(:,3);
feature.H = date(:,4);
feature.M = date(:,5);
feature.S = date(:,6);
feature.YYYY = string(arrayfun(@(x) sprintf('%04d', x), feature.YYYY, 'Uniform', 0));
feature.MM = string(arrayfun(@(x) sprintf('%02d', x), feature.MM, 'Uniform', 0));
feature.DD = string(arrayfun(@(x) sprintf('%02d', x), feature.DD, 'Uniform', 0));
feature.H = string(arrayfun(@(x) sprintf('%02d', x), feature.H, 'Uniform', 0));
feature.M = string(arrayfun(@(x) sprintf('%02d', x), feature.M, 'Uniform', 0));
feature.S = string(arrayfun(@(x) sprintf('%02d', x), feature.S, 'Uniform', 0));

%% load sample data for computational efficiency
% from subSAMPLE.m
load("data\subset_sample_5percent.mat", ...
    "subset")

%% MetNordic: hourly air_pressure_at_sea_level and wind_speed_10m

% initialize
air_pressure_at_sea_level = zeros(numel(subset.fid),1); %Pa
wind_speed_10m = zeros(numel(subset.fid),1); %m/s

% MetNordic_74896_row_col
row = zeros(numel(feature.fid),1);
col = zeros(numel(feature.fid),1);
i = 1;
if str2num(feature.YYYY(i)) == 2023
    MetNordicOpenDAP_file_path = "https://thredds.met.no/thredds/dodsC/metpparchive/";
else
    MetNordicOpenDAP_file_path = "https://thredds.met.no/thredds/dodsC/metpparchivev3/";
end
filepath = MetNordicOpenDAP_file_path + num2str(feature.YYYY(i)) + ...
              "/" + num2str(feature.MM(i)) + "/" + num2str(feature.DD(i)) + ...
              "/met_analysis_1_0km_nordic_" + num2str(feature.YYYY(i)) + ...
              num2str(feature.MM(i)) + num2str(feature.DD(i)) + "T" + ...
              num2str(feature.H(i)) + "Z.nc";
lon_i = ncread(filepath, "longitude");
lat_i = ncread(filepath, "latitude");
for i = 1:numel(feature.fid)
    tic
    disp(i*100/numel(feature.fid))
    [k,~] = dsearchn([lon_i(:) lat_i(:)],...
                [feature.x(i) feature.y(i)]);
    [row(i,1), col(i,1)] =  ind2sub(size(lon_i),k);
    toc
end
save("data\meteorological_data\data_features_MetNordic_74896_row_col.mat", ...
    "row",...
    "col",...
    '-mat');
load("data\meteorological_data\data_features_MetNordic_74896_row_col.mat",...
    "row",...
    "col");

% Extract meteorological data for each observations
for i = 1:numel(subset.fid) 
    if str2num(subset.YYYY(i)) == 2023
        MetNordicOpenDAP_file_path = "https://thredds.met.no/thredds/dodsC/metpparchive/";
    else
        MetNordicOpenDAP_file_path = "https://thredds.met.no/thredds/dodsC/metpparchivev3/";
    end
    filepath = MetNordicOpenDAP_file_path + subset.YYYY(i) + ...
                  "/" + subset.MM(i) + "/" + subset.DD(i) + ...
                  "/met_analysis_1_0km_nordic_" + subset.YYYY(i) + ...
                  subset.MM(i) + subset.DD(i) + "T" + ...
                  subset.H(i) + "Z.nc";
    idx = find(feature.nodeidx==subset.nodeidx(i) & feature.fid==subset.fid(i));
    air_pressure_at_sea_level(i,1) = ncread(filepath, "air_pressure_at_sea_level", ...
                                [row(idx) col(idx) 1], [1 1 1]); %Pa
    wind_speed_10m(i,1) = ncread(filepath, "wind_speed_10m", ...
                                [row(idx) col(idx) 1], [1 1 1]); %m/s
end

% save extracted data
save("data\meteorological_data\data_features_MetNordic_20percent.mat", ...
    "feature",...
    "subset",...
    "air_pressure_at_sea_level",...
    "wind_speed_10m",...
    '-mat');

%% seNorge2018: daily temperature and rainfall

% initialize
n_past = 10;
tg_npast = zeros(numel(subset.fid),n_past);
rr_npast = zeros(numel(subset.fid),n_past);
tg = zeros(numel(subset.fid),1);
rr = zeros(numel(subset.fid),1);

% seNorge2018_74896_row_col
row = zeros(numel(feature.fid),1);
col = zeros(numel(feature.fid),1);
i = 1;
seNorgeOpenDAP_file_path = "https://thredds.met.no/thredds/dodsC/senorge/seNorge_2018/Archive/seNorge2018_";
filepath = seNorgeOpenDAP_file_path+num2str(feature.YYYY(i))+".nc";
lon_i = ncread(filepath, "lon");
lat_i = ncread(filepath, "lat");
for i = 1:numel(feature.fid)
    tic
    disp(i*100/numel(feature.fid))
    [k,~] = dsearchn([lon_i(:) lat_i(:)],...
                [feature.x(i) feature.y(i)]);
    [row(i,1), col(i,1)] =  ind2sub(size(lon_i),k);
    toc
end
save("data\meteorological_data\data_features_seNorge_74896_row_col.mat", ...
    "row",...
    "col",...
    '-mat');
load("data\meteorological_data\data_features_seNorge_74896_row_col.mat",...
    "row",...
    "col");

% Extract meteorological data for each observations
for i = 1:numel(subset.fid) 
    disp(i)
    tic
    seNorgeOpenDAP_file_path = "https://thredds.met.no/thredds/dodsC/senorge/seNorge_2018/Archive/seNorge2018_";
    filepath = seNorgeOpenDAP_file_path+subset.YYYY(i)+".nc";
    idx = find(feature.nodeidx==subset.nodeidx(i) & feature.fid==subset.fid(i));

    dayCount = daysdif( datetime(str2num(feature.YYYY(idx)),1,1),...
                        datetime(str2num(feature.YYYY(idx)),...
                                 str2num(feature.MM(idx)),...
                                 str2num(feature.DD(idx)) ...
                                 ) ...
                       )+1;

    if dayCount < 10
        if mod((str2num(subset.YYYY(i))-1),4)==0 %leap year
            start_p = 366 - (n_past-dayCount) + 1;
        else
            start_p = 365 - (n_past-dayCount) + 1;
        end
        filepath_p = seNorgeOpenDAP_file_path+num2str(str2num(subset.YYYY(i))-1)+".nc";
        tg_npast(i,1:n_past) = [reshape(ncread(filepath_p, "tg", ...
                               [row(idx) col(idx) start_p], [1 1 (n_past-dayCount)]), ...
                               [1,(n_past-dayCount)]) ...
                                reshape(ncread(filepath, "tg", ...
                               [row(idx) col(idx) 1], [1 1 dayCount]), ...
                               [1,dayCount])];
        rr_npast(i,1:n_past) = [reshape(ncread(filepath_p, "rr", ...
                               [row(idx) col(idx) start_p], [1 1 (n_past-dayCount)]), ...
                               [1,(n_past-dayCount)]) ...
                                reshape(ncread(filepath, "rr", ...
                               [row(idx) col(idx) 1], [1 1 dayCount]), ...
                               [1,dayCount])];
    else
        tg_npast(i,1:n_past) = reshape(ncread(filepath, "tg", ...
                                              [row(idx) col(idx) dayCount-(n_past-1)], ...
                                              [1 1 n_past]), ...
                                       [1,n_past]);
        rr_npast(i,1:n_past) = reshape(ncread(filepath, "rr", ...
                                              [row(idx) col(idx) dayCount-(n_past-1)], ...
                                              [1 1 n_past]), ...
                                       [1,n_past]);
    end
    toc
end
tg = sum(tg_npast,2);
rr = sum(rr_npast,2);

% save extracted data
save("data\meteorological_data\data_features_seNorge_20percent.mat", ...
    "feature",...
    "subset",...
    "tg",...
    "rr",...
    "tg_npast",...
    "rr_npast",...
    '-mat');