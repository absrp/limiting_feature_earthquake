clear all; close all; 

FDHI_data = readtable('data_FDHI.xlsx');
EQ_ID = FDHI_data.EQ_ID;
EQ_name = FDHI_data.eq_name;
EQ_region = FDHI_data.region;
EQ_style = FDHI_data.style;
lat = FDHI_data.latitude_degrees;
lon = FDHI_data.longitude_degrees;
lat = double(lat); 
lon = double(lon); 


tableFDHI = table(EQ_ID, EQ_name, EQ_region); 
[~, ind] = unique(tableFDHI(:, [1 2 3]), 'rows');
lat = lat(ind);
lon = lon(ind);
style = EQ_style(ind); 
table = tableFDHI(ind,:);
table = rmmissing(table);
lat = rmmissing(lat); 
lon = rmmissing(lon); 
style = rmmissing(style);

%% make map of all earthquakes 
figure

ax = worldmap("World");
setm(ax,"Origin",[0 180 0])
load coastlines
geoshow(ax,'landareas.shp', 'FaceColor', [0.8000    0.8000    0.8000])
hold on 

% extract first coordinate from each map 

for n=1:max(EQ_ID)
    if strcmp(style{n},'Strike-Slip')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0.8510    0.3255    0.0980],'MarkerEdgeColor','none')
    elseif strcmp(style{n},'Reverse')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0    0.4471    0.7412],'MarkerEdgeColor','none') 
    elseif strcmp(style{n},'Reverse-Oblique')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0    0.4471    0.7412],'MarkerEdgeColor','none') 
    else
scatterm(lat(n),lon(n),'MarkerFaceColor',[0.4667    0.6745    0.1882],'MarkerEdgeColor','none') 
    end
end 

legend('Strike-Slip','Reverse','Normal')

figure
subplot(1,2,1)
usamap({'CA','NV','OR','WA','ID','UT'});
load coastlines
geoshow('usastatehi.shp', 'FaceColor', [0.8000    0.8000    0.8000])
hold on 

% extract first coordinate from each map 

for n=1:max(EQ_ID)
     if strcmp(style{n},'Strike-Slip')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0.8510    0.3255    0.0980],'MarkerEdgeColor','none')
    elseif strcmp(style{n},'Reverse')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0    0.4471    0.7412],'MarkerEdgeColor','none') 
    elseif strcmp(style{n},'Reverse-Oblique')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0    0.4471    0.7412],'MarkerEdgeColor','none') 
    else
scatterm(lat(n),lon(n),'MarkerFaceColor',[0.4667    0.6745    0.1882],'MarkerEdgeColor','none') 
    end
end 

subplot(1,2,2)

worldmap japan
load coastlines
geoshow('landareas.shp', 'FaceColor', [0.8000    0.8000    0.8000])
hold on 

% extract first coordinate from each map 

for n=1:max(EQ_ID)
     if strcmp(style{n},'Strike-Slip')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0.8510    0.3255    0.0980],'MarkerEdgeColor','none')
    elseif strcmp(style{n},'Reverse')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0    0.4471    0.7412],'MarkerEdgeColor','none') 
    elseif strcmp(style{n},'Reverse-Oblique')
scatterm(lat(n),lon(n),'MarkerFaceColor',[0    0.4471    0.7412],'MarkerEdgeColor','none') 
    else
scatterm(lat(n),lon(n),'MarkerFaceColor',[0.4667    0.6745    0.1882],'MarkerEdgeColor','none') 
    end
end 


%%

figure
usamap({'all'});
load coastlines
geoshow('usastatehi.shp', 'FaceColor', [0.8000    0.8000    0.8000])


figure 
usamap({'CA'});
load coastlines
geoshow('usastatehi.shp', 'FaceColor', [0.7608    0.6353    0.5529])
hold on 

Davis = [38.5449, -121.7405];
SC = [36.9741, -122.0308];
Ridgecrest = [35.766, -117.605];
EMC = [32.259, -115.287];
Landers = [34.1300, -116.2600];
HM = [34.595, -116.270];
CP = [34.3117, -117.4750];

scatterm(Davis(:,1),Davis(:,2),'*')
scatterm(SC(:,1),Davis(:,2),'*')
scatterm(Ridgecrest(:,1),Ridgecrest(:,2),'MarkerFaceColor',[0.6353    0.0784    0.1843],'MarkerEdgeColor','none')
scatterm(Landers(:,1),Landers(:,2),'MarkerFaceColor',[0.9294    0.6941    0.1255],'MarkerEdgeColor','none')
scatterm(HM(:,1),HM(:,2),'MarkerFaceColor',[0.9294    0.6941    0.1255],'MarkerEdgeColor','none')
scatterm(EMC(:,1),EMC(:,2),'MarkerFaceColor',[0.9294    0.6941    0.1255],'MarkerEdgeColor','none')
scatterm(CP(:,1),CP(:,2),'MarkerFaceColor',[0.4667    0.6745    0.1882],'MarkerEdgeColor','none')




