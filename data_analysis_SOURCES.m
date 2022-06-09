%%% Analysis of feature measurements
clear all ; close all ;
results = readtable('all_results.csv'); 

EQ_ID = results.FDHIID; 
style_EQ = results.Style; 
feature = results.Feature; 
BU = results.BreachedOrUnbreached;
LA = results.Length_m_OrAngle_deg_;
slip_first = results.StartSlip_m_;
slip_second = results.EndSlip_m_;
style_first = results.StartMeasurementStyle;
style_second = results.EndMeasurementStyle;
FZW_first = results.StartFZW_m_;
FZW_second = results.EndFZW_m_;
lithology_first = results.StartLithology;
lithology_second = results.EndLithology; 

%% length analysis 

%% angle analysis 

%% lithology analysis 

%% slip analysis 

%% FZW analysis