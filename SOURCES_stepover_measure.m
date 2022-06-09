%% this script takes in shapefiles and generates a few measurements
clear; close all

% import FDHI data
FDHI_data = readtable('data_FDHI.xlsx');

% import shapefiles and extract information from all of them 
shapefiles = dir('*.shp'); % access all shapefile names in the folder

% create results table
all_results = table();

for i=1:length(shapefiles)
    
% read shapefile
shapename = shapefiles(i).name;
lines = shaperead(shapename); 
name = strsplit(shapename,{'_','.'}); % string containing shapefile name

% extract info from shapefile name 

% feature type
shapefile_type = name{1};

% breached vs unbreached 
shapefile_subtype = name{2};

% earthquake name 
EQ_name= name{3};

% find data associated with select earthquake
EQ_select = find(strcmp(FDHI_data.eq_name,EQ_name));
EQ_ID = FDHI_data.EQ_ID(EQ_select);

%% measure length of lines (i.e. gap and step-over length) from shapefile)
L_line = []; %create vector to store length data
line_start_x = [];
line_start_y = [];
line_end_x = [];
line_end_y = [];

% measure the line or angle of each mapped feature (gap, step-over, bend splay)
for n = 1:length(lines) 
  L_line(n) =  measure_length(lines(n).X,lines(n).Y,shapefile_type); 
end 

% extract the beginning and end vertices of each line
for n = 1:length(lines) 
  [line_start_x(n),line_start_y(n),line_end_x(n),line_end_y(n)]...
      = extract_line_coordinates(lines(n).X,lines(n).Y); 
end 

%% extract info from the nearest data point near the step-over from the FDHI database
% subset section of the FDHI for desired earthquake
data = FDHI_data(EQ_select,:);

slip = data.fps_central_meters;
fault_zone_width = data.fzw_central_meters;
lithology = data.geology;
coordsx = data.longitude_degrees;
coordsy = data.latitude_degrees; 
EQ_style = data.style;
measurement_style = data.fps_style;
[coords_ref]=ll2utm(coordsy,coordsx);

% merge x and y coordinates for start and end points of each line
start_coords = [line_start_x' line_start_y'];
end_coords = [line_end_x' line_end_y'];

% create variables to fill in loop 
slip_line_start = [];
fault_zone_width_line_start = [];
lithology_line_start = {};
measurement_style_line_start = {};

slip_line_end = [];
fault_zone_width_line_end = [];
lithology_line_end = {};
measurement_style_line_end = {};

% find index of closest data point from FDHI database to each line vertex 
% first for the starting vertices
for n = 1:length(start_coords) 
  [slip_line_start(n),fault_zone_width_line_start(n),lithology_line_start{n},measurement_style_line_start{n}]...
      =  retrieve_FDHI_data(start_coords(n,:),coords_ref,slip,fault_zone_width,lithology,measurement_style); % measure step-over lengths
end 

% then for the ending vertices
for n = 1:length(end_coords) 
  [slip_line_end(n),fault_zone_width_line_end(n), lithology_line_end{n},measurement_style_line_end{n}]...
      =  retrieve_FDHI_data(end_coords(n,:),coords_ref,slip,fault_zone_width,lithology,measurement_style); % measure step-over lengths
end 

%% write data to text file

allresults_i = table(...
    repelem(EQ_ID(1),length(start_coords))', ...
    repelem(string(EQ_name),length(start_coords))',...
    repelem(EQ_style(1),length(start_coords))',...
    repelem(string(shapefile_type),length(start_coords))',...
    repelem(string(shapefile_subtype),length(start_coords))',...
    L_line',...
    start_coords(:,1),...
    start_coords(:,2),...
    slip_line_start',...
    fault_zone_width_line_start',...
    lithology_line_start',...
    measurement_style_line_start',...
    end_coords(:,1),...
    end_coords(:,2),...
    slip_line_end',...
    fault_zone_width_line_end',...
    lithology_line_end',...
    measurement_style_line_end');

all_results = [all_results; allresults_i];

disp(i) % keeps track of progress
end

%% export results

% assign header to table
all_results.Properties.VariableNames = {'FDHI ID',...
    'Earthquake',...
    'Style',...
    'Feature',...
    'Breached or unbreached',...
    'Length (m) or angle (deg)',...
    'Start Easting',...
    'Start Northing',...
    'Start slip (m)',...
    'Start FZW (m)',...
    'Start lithology',...
    'Start measurement style',...
    'End Easting',...
    'End Northing',...
    'End slip (m)',...
    'End FZW (m)',...
    'End lithology',...
    'End measurement style'};

% export file
writetable(all_results,'all_results.csv'); 

%% function dumpster
% functions that are called in the script go here 
function [L] = measure_length(fault_x,fault_y,shapefile_type)
fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
fault_y =fault_y(~isnan(fault_y));
if fault_y<90
[fault_x,fault_y]=ll2utm(fault_y,fault_x);
else
end

% measure angle or length depending on shapefile type 

if strcmp(shapefile_type,'splay') % check if shapefile type is a splay
% measure angle between lines
v1=[fault_x(1),fault_y(1)]-[fault_x(2),fault_y(2)];
v2=[fault_x(end),fault_y(end)]-[fault_x(2),fault_y(2)];
L=acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
L = rad2deg(L);

elseif strcmp(shapefile_type,'bend') % check if shapefile type is a bend
% measure angle between lines
v1=[fault_x(2),fault_y(2)]-[fault_x(1),fault_y(1)];
v2=[fault_x(end),fault_y(end)]-[fault_x(2),fault_y(2)];
L=acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
L = rad2deg(L);
L = 180-L;

elseif strcmp(shapefile_type,'stepover') % check if shapefile type is a step-over
% calculate length
x_1 = fault_x(1:end-1);
x_2 = fault_x(2:end);
y_1 = fault_y(1:end-1);
y_2 = fault_y(2:end);
segment_length = sqrt((x_1-x_2).^2+(y_1-y_2).^2); % note transformation to local coordinate system 
L = sum(segment_length);

elseif strcmp(shapefile_type,'gap')  % check if shapefile type is a gap
% calculate length
x_1 = fault_x(1:end-1);
x_2 = fault_x(2:end);
y_1 = fault_y(1:end-1);
y_2 = fault_y(2:end);
segment_length = sqrt((x_1-x_2).^2+(y_1-y_2).^2); % note transformation to local coordinate system 
L = sum(segment_length);

else
    disp('ERROR: Shapefile type must be a splay, gap, bend, or step-over (stepover)')
end 
end 
function [line_start_x,line_start_y,line_end_x,line_end_y] = extract_line_coordinates(fault_x,fault_y)
fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
fault_y =fault_y(~isnan(fault_y));
if fault_y<90
[fault_x,fault_y]=ll2utm(fault_y,fault_x);
else
end
line_start_x = fault_x(1);
line_start_y = fault_y(1);
line_end_x = fault_x(end);
line_end_y = fault_y(end);
end 
function [slip_line,fault_zone_width_line,lithology_line,measurement_style_line] = retrieve_FDHI_data(coords_xy,coords_ref,slip,fault_zone_width,lithology,measurement_style)
[k,~] = dsearchn(coords_ref,coords_xy); % k is the index of the coords that are the closest in the FDHI database
slip_line = slip(k);
fault_zone_width_line = fault_zone_width(k);
lithology_line = lithology(k);
measurement_style_line = measurement_style(k);
% scatter(coords_xy(:,1),coords_xy(:,2),'k','filled') 
% hold on
% coords_refplot = coords_ref(k,:)
% scatter(coords_refplot(:,1),coords_refplot(:,2),'r','filled')
% scatter(coords_ref(:,1), coords_ref(:,2), 'b')
end