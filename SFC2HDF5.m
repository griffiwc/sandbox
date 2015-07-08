function [] = SFC2HDF5(FilePath,RunNumber,OutputFileName)
% SFC2HDF5(DataFolder,RunNumber,OutputFileName)
% Import SFC file and exports into HDF5.
% HDF5 file is opened and Datasets/Attributes that are already
% present in the HDF5 will be overwritten, assuming the same layout
% of the Dataset. 
% As timing information is needed to sort the data into the cycle structure
% an error is thrown if this information can not be optained from the HDF5
% file
%
% Input:    
%   -DataFolder: Folder where run can be found
%   -RunNumber: The Runnumber of the run to import (integer)
%   -OutputFileName: Name of the HDF5 file the data should be written to

%% Private subfuntions used in this script:
%  importedmdata(FilePath,FileName,'FormatString',FormatString,'StructNames',StructNames)
%  group2hdf5(branchID,GroupName)
%  PerCycleData2hdf5(RootID,Data,NameOfSubGroub,HDF5FieldNames,DataFieldNames,ColumnNames)

%% Check input arguments
if nargin<3
    error('SFC2HDF5: not enough input arguments')
end

%% Define dataset names 

% FileName
RunNumberStr = num2str(RunNumber,'%.6i');
FileName=[RunNumberStr,'-0_SFC.edm'];

% SubGroup
NameOfSubGroup = 'SFC';

% Define HDF5FieldNames and ColumnNames can be extracted from the Header
HDF5FieldNames = cell(1,6+10+2);
DataFieldNames = cell(1,6+10+2);
% ASCII code in HEX for + = 0x2B 
% ASCII code in HEX for - = 0x2D
ColumnNames = {{'curr_x0x2B'},{'curr_x0x2D'},{'curr_y0x2B'},...
    {'curr_y0x2D'},{'curr_z0x2B'},{'curr_z0x2D'}};
for ind = 1:6
    HDF5FieldNames{ind} = ['Current' int2str(ind)];
    DataFieldNames{ind} = {'Current'};
end
for ind = 1:10
    HDF5FieldNames{6+ind} = ['FluxGate' num2str(ind,'%.2i')];
    DataFieldNames{6+ind} = {'BxMean','BxStd','ByMean','ByStd',...
        'BzMean','BzStd'};
    if ind == 1
    ColumnNames{6+ind} = {...
        ['B' int2str(ind-1) 'X'],['sigma'],...
        ['B' int2str(ind-1) 'Y'],['sigma1' ],...
        ['B' int2str(ind-1) 'Z'],['sigma2' ]};
    else
    ColumnNames{6+ind} = {...
        ['B' int2str(ind-1) 'X'],['sigma' int2str((ind-1)*3)],...
        ['B' int2str(ind-1) 'Y'],['sigma' int2str((ind-1)*3+1)],...
        ['B' int2str(ind-1) 'Z'],['sigma' int2str((ind-1)*3+2)]};
    end
end


% ASCII code in HEX for ? = 0x3F

HDF5FieldNames{17} = 'Filter';
DataFieldNames{17} = {'Filter'}; 
ColumnNames{17} = {'filter0x3F'};

HDF5FieldNames{18} = 'Dynamic';
DataFieldNames{18} = {'Dynamic'}; 
ColumnNames{18} = {'SFCdynamic0x3F'};

%% Import data

% FormatString is not mentioned in the header
FormatString = ['%f-%f-%f_%f:%f:%f_%*s' repmat(' %f',1,74)];
Data = importedmdata(FilePath,FileName,'FormatString',FormatString);

% Check import
DisplayMSG='SFC';
if isempty(Data)
    warning('SFC2HDF5:importerror',...
        ['Failed to import: ',DisplayMSG])
    return
elseif isempty(Data.date)
    warning('SFC2HDF5:importerror',...
        ['Failed to import: ',DisplayMSG])
    return
else
    disp(['Imported ',DisplayMSG])
end


%% Add imported data to HDF5 file

% Check if HDF5 file exist and open it
DefPar = 'H5P_DEFAULT';
if exist(OutputFileName,'file')==2
    OutputFID=H5F.open(OutputFileName,'H5F_ACC_RDWR',DefPar);
else
    error(['SFC2HDF5: no HDF5 file found for run ' RunNumberStr])
end

% Get ID of the root group
RootID=group2hdf5(OutputFID,['/Run',RunNumberStr]);

% Add Data to HDF5
PerCycleData2hdf5(RootID,Data,NameOfSubGroup,...
    HDF5FieldNames,DataFieldNames,ColumnNames)

disp(['Added ',DisplayMSG])

%% Add attributes

% Add name attribute to HDF5 file
Names = {'X+','X-','Y+','Y-','Z+','Z-'};
% Add attribute name from header
for ind = 1:6
    PerCycleAttr2HDF5(RootID,NameOfSubGroup,HDF5FieldNames{ind},...
        Names{ind},'Name');
end

disp(['Added ',DisplayMSG, ' attributes'])



% Close root group
H5G.close(RootID)

% Close ouptut file
H5F.close(OutputFID)

end


