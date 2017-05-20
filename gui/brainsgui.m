function varargout = brainsgui(varargin)
% BRAINSGUI MATLAB code for brainsgui.fig
%      BRAINSGUI, by itself, creates a new BRAINSGUI or raises the existing
%      singleton*.
%
%      H = BRAINSGUI returns the handle to a new BRAINSGUI or the handle to
%      the existing singleton*.
%
%      BRAINSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BRAINSGUI.M with the given input arguments.
%
%      BRAINSGUI('Property','Value',...) creates a new BRAINSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before brainsgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to brainsgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help brainsgui

% Last Modified by GUIDE v2.5 19-May-2017 21:26:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @brainsgui_OpeningFcn, ...
                   'gui_OutputFcn',  @brainsgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before brainsgui is made visible.
function brainsgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to brainsgui (see VARARGIN)

% Choose default command line output for brainsgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes brainsgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = brainsgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start_master.
function start_master_Callback(hObject, eventdata, handles)
% hObject    handle to start_master (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
brains.start_master();


% --- Executes on button press in start_slave.
function start_slave_Callback(hObject, eventdata, handles)
% hObject    handle to start_slave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
brains.start_slave();


% --- Executes on button press in start_calibration.
function start_calibration_Callback(hObject, eventdata, handles)
% hObject    handle to start_calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
brains.start_calibration();
