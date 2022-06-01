%% this script takes in shapefiles and generates a few measurements
clear; close all

% import shapefiles 
lines = shaperead('splay_breached_Landers.shp'); 
FDHI_data = readtable('data_FDHI.xlsx');

EQ_ID = inputdlg({'Earthquake ID number'}); 
EQ_ID = cell2mat(EQ_ID); EQ_ID = str2double(EQ_ID);
% check that the selected earthquake is the correct one
EQ_ID_FDHI = FDHI_data.EQ_ID;
EQ_select = find(EQ_ID_FDHI == EQ_ID);
EQ_name = FDHI_data.eq_name(EQ_select);
disp(EQ_name(1))
mapper = {'MAPPERNAME'} % input your name here

% input type of shapefile 
shapefile_type= inputdlg({'Is it a gap (G), a step-over (S), a splay (P), or a bend (B)?'}); 
shapefile_subtype = inputdlg({'Is it a breached (B) or unbreached (U) feature?'});

%% measure length of lines (i.e. gap and step-over length) from shapefile)
L_line = []; %create vector to store length data
line_start_x = [];
line_start_y = [];
line_end_x = [];
line_end_y = [];

% measure the line of each mapped feature (gap, step-over)
for n = 1:length(lines) 
  L_line(n) =  measure_length(lines(n).X,lines(n).Y,shapefile_type{1}); 
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
style = data.style;
[coords_ref]=ll2utm(coordsy,coordsx);

% merge x and y coordinates for start and end points of each line
start_coords = [line_start_x' line_start_y'];
end_coords = [line_end_x' line_end_y'];

% create variables to fill in loop 
slip_line_start = [];
fault_zone_width_line_start = [];
lithology_line_start = {};

slip_line_end = [];
fault_zone_width_line_end = [];
lithology_line_end = {};

% figure

% find index of closest data point from FDHI database to each line vertex 
% first for the starting vertices
for n = 1:length(start_coords) 
  [slip_line_start(n),fault_zone_width_line_start(n),lithology_line_start{n}]...
      =  retrieve_FDHI_data(start_coords(n,:),coords_ref,slip,fault_zone_width,lithology); % measure step-over lengths
end 

% then for the ending vertices
for n = 1:length(end_coords) 
  [slip_line_end(n),fault_zone_width_line_end(n), lithology_line_end{n}]...
      =  retrieve_FDHI_data(end_coords(n,:),coords_ref,slip,fault_zone_width,lithology); % measure step-over lengths
end 

%% write data to table

allresults = table((repelem(EQ_ID(1),length(start_coords)))',(repelem(EQ_name(1),length(start_coords)))',(repelem(style(1),length(start_coords)))',(repelem(shapefile_type(1),length(start_coords)))',(repelem(shapefile_subtype(1),length(start_coords)))',...
    L_line',start_coords(:,1),start_coords(:,2),slip_line_start',fault_zone_width_line_start',lithology_line_start',end_coords(:,1),end_coords(:,2),slip_line_end',...
    fault_zone_width_line_end',lithology_line_end',repelem(mapper,length(start_coords))');

allresults.Properties.VariableNames = {'FDHI ID','Earthquake','Style','Feature','Breached or unbreached','Length (m) or angle (deg)',...
    'Start Easting', 'Start Northing', 'Start slip (m)', 'Start FZW (m)', 'Start lithology',...
    'End Easting', 'End Northing', 'End slip (m)', 'End FZW (m)','End lithology','Mapper'};

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

if shapefile_type == 'P' % check if shapefile type is a splay
% measure angle between lines
v1=[fault_x(1),fault_y(1)]-[fault_x(2),fault_y(2)];
v2=[fault_x(end),fault_y(end)]-[fault_x(2),fault_y(2)];
L=acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
L = rad2deg(L);
disp('angle')

elseif shapefile_type == 'B' % check if shapefile type is a splay
% measure angle between lines
v1=[fault_x(2),fault_y(2)]-[fault_x(1),fault_y(1)];
v2=[fault_x(end),fault_y(end)]-[fault_x(2),fault_y(2)];
L=acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
L = rad2deg(L);
disp('angle')

else
% calculate length
x_1 = fault_x(1:end-1);
x_2 = fault_x(2:end);
y_1 = fault_y(1:end-1);
y_2 = fault_y(2:end);
segment_length = sqrt((x_1-x_2).^2+(y_1-y_2).^2); % note transformation to local coordinate system 
L = sum(segment_length);
disp('length')
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
function [slip_line,fault_zone_width_line,lithology_line] = retrieve_FDHI_data(coords_xy,coords_ref,slip,fault_zone_width,lithology)
[k,~] = dsearchn(coords_ref,coords_xy); % k is the index of the coords that are the closest in the FDHI database
slip_line = slip(k);
fault_zone_width_line = fault_zone_width(k);
lithology_line = lithology(k);
% scatter(coords_xy(:,1),coords_xy(:,2),'k','filled') 
% hold on
% coords_refplot = coords_ref(k,:)
% scatter(coords_refplot(:,1),coords_refplot(:,2),'r','filled')
% scatter(coords_ref(:,1), coords_ref(:,2), 'b')
end