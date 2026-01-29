unit DelphiFormatter;

interface

procedure Register;

implementation

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.IniFiles, System.IOUtils, VCL.Menus, ToolsAPI;

const
  SETTINGS_FILE = 'DelphiFormatterRedux.ini';
  DISPLAY_NAME = 'Delphi Formatter Redux';
  DEFAULT_LOG_MESSAGES : Boolean = False;
  LOG_DATE_FORMAT = 'yyyy/mm/dd HH:mm:ss.zzz';

type
  EFormatterError = class(Exception);

  TLogType = (ltInfo, ltWarning, ltError);

  TLogTypeHelper = record helper for TLogType
    function Name : string;
  end;

  TDelphiFormatterRedux = class
  private
    class var SettingsLoaded : Boolean;
    class var LogMessages : Boolean;
    class var FormatterExe : string;
    class var ConfigPath : string;
    class var MessageFormatSettings : TFormatSettings;
    class var SettingsLock : TObject;

    class function GetFormatterExe : string; static;
    class function GetConfigPath : string; static;
    class function GetActiveEditorBuffer : IOTAEditBuffer; static;
    class function GetSettingsFolder : string; static;
    class function GetPackageFolder : string; static;
    class function GetDefaultFormatterPath : string; static;
    class function GetDefaultConfigPath : string; static;
    class function GetSettingsIniPath : string; static;

    class procedure EnsureSettingsIniExists; static;
    class procedure LoadSettings; static;

    class procedure RunFormatter(const AFormatterExe, AConfigPath, AFileName : string); static;
    class procedure SaveFileViaOTA(const AFileName : string); static;
    class procedure ReloadFileViaOTA(const AFileName : string); static;

    class procedure LogToMessages(AType : TLogType; const AMessage : string); static;

    class procedure OutputMessage(const AText : string); static;
  public
    class procedure Execute; static;
  end;

  TDelphiFormatterReduxKeyBinding = class(TInterfacedObject, IOTAKeyboardBinding)
  private
    procedure ExecuteBinding(const AContext : IOTAKeyContext; AKeyCode : TShortcut; var ABindingResult : TKeyBindingResult);
  public
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    procedure BindKeyboard(const ABindingServices : IOTAKeyBindingServices);

    function GetBindingType : TBindingType;
    function GetDisplayName : string;
    function GetName : string;
  end;

class function TDelphiFormatterRedux.GetDefaultFormatterPath : string;
begin
  Result := TPath.GetFullPath(TPath.Combine(GetPackageFolder, '..\..\Formatter.exe'));
end;

class function TDelphiFormatterRedux.GetDefaultConfigPath : string;
begin
  Result := TPath.GetFullPath(TPath.Combine(GetPackageFolder, '..\..\Formatter.config'));
end;

class function TDelphiFormatterRedux.GetSettingsIniPath : string;
begin
  Result := TPath.Combine(GetSettingsFolder, SETTINGS_FILE);
end;

class function TDelphiFormatterRedux.GetSettingsFolder : string;
begin
  Result := TPath.Combine(TPath.GetHomePath, 'DelphiFormatterRedux');
end;

class function TDelphiFormatterRedux.GetPackageFolder : string;
var
  sModuleName : array [0 .. MAX_PATH - 1] of Char;
begin
  SetString(Result, sModuleName, GetModuleFileName(HInstance, sModuleName, Length(sModuleName)));
  Result := ExtractFilePath(Result);
end;

class procedure TDelphiFormatterRedux.EnsureSettingsIniExists;
var
  sIniPath : string;
  sSettingsFolder : string;
begin
  sSettingsFolder := GetSettingsFolder;

  if not TDirectory.Exists(sSettingsFolder) then
    TDirectory.CreateDirectory(sSettingsFolder);

  sIniPath := GetSettingsIniPath;

  if not FileExists(sIniPath) then
  begin
    OutputMessage(DISPLAY_NAME + ' - Settings file does not exist. Creating defaults.');

    var
    oIni := TIniFile.Create(sIniPath);
    try
      oIni.WriteString('Formatter', 'Exe', GetDefaultFormatterPath);
      oIni.WriteString('Formatter', 'Config', GetDefaultConfigPath);
      oIni.WriteBool('Formatter', 'LogMessages', DEFAULT_LOG_MESSAGES);
    finally
      oIni.Free;
    end;

    OutputMessage(DISPLAY_NAME + ' - Settings file created: ' + sIniPath);
    OutputMessage(DISPLAY_NAME +
      ' - Defaults will be used for this session. You can edit the file and re-open Delphi to apply the changes.');
  end;
end;

class procedure TDelphiFormatterRedux.LoadSettings;
var
  sFormatterFile : string;
  sConfigFile : string;
  sIniPath : string;
  bNeedLoad : Boolean;
begin
  bNeedLoad := not SettingsLoaded;

  if bNeedLoad then
  begin
    TMonitor.Enter(SettingsLock);
    try
      bNeedLoad := not SettingsLoaded;

      if bNeedLoad then
      begin
        MessageFormatSettings := TFormatSettings.Create;

        EnsureSettingsIniExists;

        sIniPath := GetSettingsIniPath;

        var
        oIni := TIniFile.Create(sIniPath);
        try
          sFormatterFile := Trim(oIni.ReadString('Formatter', 'Exe', GetDefaultFormatterPath));
          sConfigFile := Trim(oIni.ReadString('Formatter', 'Config', GetDefaultConfigPath));
          LogMessages := oIni.ReadBool('Formatter', 'LogMessages', DEFAULT_LOG_MESSAGES);
        finally
          oIni.Free;
        end;

        sFormatterFile := ExpandFileName(sFormatterFile);
        if (sFormatterFile = '') or not FileExists(sFormatterFile) then
          raise EFormatterError.Create('Formatter.exe was not found: ' + sFormatterFile);

        sConfigFile := ExpandFileName(sConfigFile);
        if (sConfigFile = '') or not FileExists(sConfigFile) then
          raise EFormatterError.Create('Formatter config was not found: ' + sConfigFile);

        FormatterExe := sFormatterFile;
        ConfigPath := sConfigFile;
        SettingsLoaded := True;

        OutputMessage(DISPLAY_NAME + ' - Settings loaded. Log info messages: ' + BoolToStr(LogMessages, True));
      end;
    finally
      TMonitor.Exit(SettingsLock);
    end;
  end;
end;

class function TDelphiFormatterRedux.GetFormatterExe : string;
begin
  LoadSettings;
  Result := FormatterExe;
end;

class function TDelphiFormatterRedux.GetConfigPath : string;
begin
  LoadSettings;
  Result := ConfigPath;
end;

class procedure TDelphiFormatterRedux.LogToMessages(AType : TLogType; const AMessage : string);
var
  sStamp : string;
begin
  if (AType > ltInfo) or LogMessages then
  begin
    sStamp := FormatDateTime(LOG_DATE_FORMAT, Now, MessageFormatSettings);
    OutputMessage(Format('%s [%s] %s - %s', [sStamp, DISPLAY_NAME, AType.Name, AMessage]));
  end;
end;

class procedure TDelphiFormatterRedux.OutputMessage(const AText : string);
var
  oMsgSvc : IOTAMessageServices;
begin
  if Supports(BorlandIDEServices, IOTAMessageServices, oMsgSvc) then
    oMsgSvc.AddTitleMessage(AText);
end;

class function TDelphiFormatterRedux.GetActiveEditorBuffer : IOTAEditBuffer;
var
  oEditorSvc : IOTAEditorServices;
  oView : IOTAEditView;
begin
  Result := nil;

  if Supports(BorlandIDEServices, IOTAEditorServices, oEditorSvc) then
  begin
    oView := oEditorSvc.TopView;
    if oView <> nil then
      Result := oView.Buffer;
  end;
end;

class procedure TDelphiFormatterRedux.SaveFileViaOTA(const AFileName : string);
var
  oActionSvc : IOTAActionServices;
begin
  if Supports(BorlandIDEServices, IOTAActionServices, oActionSvc) then
  begin
    try
      oActionSvc.SaveFile(AFileName);
    except
      on E : Exception do
        raise EFormatterError.CreateFmt('Failed to save file via OTA: %s (%s)', [AFileName, E.Message]);
    end;
  end
  else
    raise EFormatterError.Create('IOTAActionServices unavailable.');
end;

class procedure TDelphiFormatterRedux.ReloadFileViaOTA(const AFileName : string);
var
  oActionSvc : IOTAActionServices;
begin
  if Supports(BorlandIDEServices, IOTAActionServices, oActionSvc) then
  begin
    try
      oActionSvc.ReloadFile(AFileName);
    except
      on E : Exception do
        raise EFormatterError.CreateFmt('Failed to reload file via OTA: %s (%s)', [AFileName, E.Message]);
    end;
  end
  else
    raise EFormatterError.Create('IOTAActionServices unavailable.');
end;

class procedure TDelphiFormatterRedux.RunFormatter(const AFormatterExe, AConfigPath, AFileName : string);
var
  sCmd : string;
  sCmdLine : UnicodeString;
  oSI : TStartupInfoW;
  oPI : TProcessInformation;
  dwWaitResult : Cardinal;
  dwExitCode : Cardinal;
begin
  sCmd := '"' + AFormatterExe + '"' + ' -config "' + AConfigPath + '"' + ' -b -silent "' + AFileName + '"';

  sCmdLine := sCmd;

  ZeroMemory(@oSI, SizeOf(oSI));
  oSI.cb := SizeOf(oSI);
  oSI.dwFlags := STARTF_USESHOWWINDOW;
  oSI.wShowWindow := SW_HIDE;

  ZeroMemory(@oPI, SizeOf(oPI));

  if not CreateProcessW(nil, PWideChar(sCmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, nil, oSI, oPI) then
    raise EFormatterError.CreateFmt('Failed to run formatter. Win32 error %d', [GetLastError]);

  try
    dwWaitResult := WaitForSingleObject(oPI.hProcess, INFINITE);
    if dwWaitResult <> WAIT_OBJECT_0 then
      raise EFormatterError.CreateFmt('Failed waiting for formatter (WaitForSingleObject=%d).', [dwWaitResult]);

    dwExitCode := 0;
    if GetExitCodeProcess(oPI.hProcess, dwExitCode) then
    begin
      if dwExitCode <> 0 then
        raise EFormatterError.CreateFmt('Formatter returned exit code %d.', [dwExitCode]);
    end
    else
      raise EFormatterError.CreateFmt('Failed to get formatter exit code. Win32 error %d', [GetLastError]);
  finally
    CloseHandle(oPI.hThread);
    CloseHandle(oPI.hProcess);
  end;
end;

class procedure TDelphiFormatterRedux.Execute;
var
  sFile : string;
  oBuffer : IOTAEditBuffer;
begin
  oBuffer := GetActiveEditorBuffer;
  if oBuffer = nil then
    raise EFormatterError.Create('No active editor buffer.');

  sFile := oBuffer.FileName;
  if sFile = '' then
    raise EFormatterError.Create('Active file has not been saved yet. Please save it first.');

  LogToMessages(ltInfo, 'Saving: ' + sFile);
  SaveFileViaOTA(sFile);

  if not FileExists(sFile) then
    raise EFormatterError.Create('File does not exist on disk after saving: ' + sFile);

  LogToMessages(ltInfo, 'Running: ' + GetFormatterExe);
  RunFormatter(GetFormatterExe, GetConfigPath, sFile);

  LogToMessages(ltInfo, 'Reloading: ' + sFile);
  ReloadFileViaOTA(sFile);

  LogToMessages(ltInfo, 'Done.');
end;

procedure TDelphiFormatterReduxKeyBinding.AfterSave;
begin
end;

procedure TDelphiFormatterReduxKeyBinding.BeforeSave;
begin
end;

procedure TDelphiFormatterReduxKeyBinding.Destroyed;
begin
end;

procedure TDelphiFormatterReduxKeyBinding.Modified;
begin
end;

procedure TDelphiFormatterReduxKeyBinding.BindKeyboard(const ABindingServices : IOTAKeyBindingServices);
begin
  ABindingServices.AddKeyBinding([TextToShortCut('Ctrl+D')], ExecuteBinding, nil);
end;

procedure TDelphiFormatterReduxKeyBinding.ExecuteBinding(const AContext : IOTAKeyContext; AKeyCode : TShortcut;
  var ABindingResult : TKeyBindingResult);
begin
  try
    TDelphiFormatterRedux.Execute;
  except
    on E : Exception do
      TDelphiFormatterRedux.LogToMessages(ltError, E.Message);
  end;

  ABindingResult := krHandled;
end;

function TDelphiFormatterReduxKeyBinding.GetBindingType : TBindingType;
begin
  Result := btPartial;
end;

function TDelphiFormatterReduxKeyBinding.GetDisplayName : string;
begin
  Result := DISPLAY_NAME;
end;

function TDelphiFormatterReduxKeyBinding.GetName : string;
begin
  Result := 'DelphiFormatterReduxKeyBinding';
end;

procedure Register;
var
  KeySvc : IOTAKeyboardServices;
begin
  if Supports(BorlandIDEServices, IOTAKeyboardServices, KeySvc) then
    KeySvc.AddKeyboardBinding(TDelphiFormatterReduxKeyBinding.Create);
end;

{ TLogTypeHelper }

function TLogTypeHelper.Name : string;
begin
  case Self of
    ltInfo :
      Result := 'Information';
    ltWarning :
      Result := 'Warning';
    ltError :
      Result := 'Error';
  end;
end;

initialization

TDelphiFormatterRedux.SettingsLoaded := False;
TDelphiFormatterRedux.LogMessages := DEFAULT_LOG_MESSAGES;
TDelphiFormatterRedux.SettingsLock := TObject.Create;

finalization

TDelphiFormatterRedux.SettingsLock.Free;

end.
