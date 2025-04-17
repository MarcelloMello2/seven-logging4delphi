unit Seven.Logging.Targets;

{$SCOPEDENUMS ON}

interface

uses
  Seven.Logging, System.Classes, System.IOUtils;

type
  TConsoleTarget = class(TInterfacedObject, ILogTarget)
  private
    FMinLevel: TLogLevel;
  public
    constructor Create(MinLevel: TLogLevel = TLogLevel.Trace);
    procedure WriteLog(const Msg: TLogMessage);
  end;

  TFileTarget = class(TInterfacedObject, ILogTarget)
  private
    FFileName: string;
    FMinLevel: TLogLevel;
    FMaxSize: Int64;
    procedure RotateFile;
  public
    constructor Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
    procedure WriteLog(const Msg: TLogMessage);
  end;

  TXmlFileTarget = class(TInterfacedObject, ILogTarget)
  private
    FFileName: string;
    FMinLevel: TLogLevel;
    FMaxSize: Int64;
    procedure RotateFile;
  public
    constructor Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
    procedure WriteLog(const Msg: TLogMessage);
  end;

implementation

uses
  System.SysUtils;

{ TConsoleTarget }

constructor TConsoleTarget.Create(MinLevel: TLogLevel = TLogLevel.Trace);
begin
  FMinLevel := MinLevel;
end;

procedure TConsoleTarget.WriteLog(const Msg: TLogMessage);
var
  LogLine: string;
begin
  if Ord(Msg.Level) < Ord(FMinLevel) then
    Exit;
  if Msg.Scope <> '' then
    LogLine := Format('[%s] %s [%s] (%s): %s', [
      DateTimeToStr(Msg.Timestamp),
      Msg.Category,
      LogLevelToString(Msg.Level),
      Msg.Scope,
      Msg.Message
    ])
  else
    LogLine := Format('[%s] %s [%s]: %s', [
      DateTimeToStr(Msg.Timestamp),
      Msg.Category,
      LogLevelToString(Msg.Level),
      Msg.Message
    ]);
  if Msg.ExceptionMessage <> '' then
    LogLine := LogLine + ' - Exception: ' + Msg.ExceptionMessage;
  WriteLn(LogLine);
end;

{ TFileTarget }

constructor TFileTarget.Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
begin
  FFileName := FileName;
  FMinLevel := MinLevel;
  FMaxSize := MaxSize;
end;

procedure TFileTarget.RotateFile;
var
  NewName: string;
begin
  NewName := ChangeFileExt(FFileName, '') + '_' + FormatDateTime('yyyymmdd_hhnnss', Now) + ExtractFileExt(FFileName);
  TFile.Move(FFileName, NewName);
end;

procedure TFileTarget.WriteLog(const Msg: TLogMessage);
var
  LogLine: string;
begin
  if Ord(Msg.Level) < Ord(FMinLevel) then
    Exit;
  if (FMaxSize > 0) and TFile.Exists(FFileName) and (TFile.GetSize(FFileName) >= FMaxSize) then
    RotateFile;
  if Msg.Scope <> '' then
    LogLine := Format('[%s] %s [%s] (%s): %s', [
      DateTimeToStr(Msg.Timestamp),
      Msg.Category,
      LogLevelToString(Msg.Level),
      Msg.Scope,
      Msg.Message
    ])
  else
    LogLine := Format('[%s] %s [%s]: %s', [
      DateTimeToStr(Msg.Timestamp),
      Msg.Category,
      LogLevelToString(Msg.Level),
      Msg.Message
    ]);
  if Msg.ExceptionMessage <> '' then
    LogLine := LogLine + ' - Exception: ' + Msg.ExceptionMessage;
  TFile.AppendAllText(FFileName, LogLine + sLineBreak);
end;

{ TXmlFileTarget }

constructor TXmlFileTarget.Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
begin
  FFileName := FileName;
  FMinLevel := MinLevel;
  FMaxSize := MaxSize;
end;

procedure TXmlFileTarget.RotateFile;
var
  NewName: string;
begin
  NewName := ChangeFileExt(FFileName, '') + '_' + FormatDateTime('yyyymmdd_hhnnss', Now) + ExtractFileExt(FFileName);
  TFile.Move(FFileName, NewName);
end;

procedure TXmlFileTarget.WriteLog(const Msg: TLogMessage);
var
  XmlLine: string;
begin
  if Ord(Msg.Level) < Ord(FMinLevel) then
    Exit;
  if (FMaxSize > 0) and TFile.Exists(FFileName) and (TFile.GetSize(FFileName) >= FMaxSize) then
    RotateFile;
  if Msg.ExceptionMessage <> '' then
    if Msg.Scope <> '' then
      XmlLine := Format('<log timestamp="%s" category="%s" level="%s" scope="%s" exception="%s">%s</log>',
        [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '&quot;', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Scope, '"', '&quot;', [rfReplaceAll]), StringReplace(Msg.ExceptionMessage, '"', '&quot;', [rfReplaceAll]), StringReplace(Msg.Message, '"', '&quot;', [rfReplaceAll])])
    else
      XmlLine := Format('<log timestamp="%s" category="%s" level="%s" exception="%s">%s</log>',
        [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '&quot;', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.ExceptionMessage, '"', '&quot;', [rfReplaceAll]), StringReplace(Msg.Message, '"', '&quot;', [rfReplaceAll])])
  else
    if Msg.Scope <> '' then
      XmlLine := Format('<log timestamp="%s" category="%s" level="%s" scope="%s">%s</log>',
        [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '&quot;', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Scope, '"', '&quot;', [rfReplaceAll]), StringReplace(Msg.Message, '"', '&quot;', [rfReplaceAll])])
    else
      XmlLine := Format('<log timestamp="%s" category="%s" level="%s">%s</log>',
        [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '&quot;', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Message, '"', '&quot;', [rfReplaceAll])]);
  TFile.AppendAllText(FFileName, XmlLine + sLineBreak);
end;

end.
