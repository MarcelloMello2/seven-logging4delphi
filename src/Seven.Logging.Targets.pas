unit Seven.Logging.Targets;

{$SCOPEDENUMS ON}

interface

uses
  Seven.Logging, System.Classes, System.IOUtils;

type
  TConsoleTarget = class(TInterfacedObject, ILogTarget)
  public
    procedure WriteLog(const Msg: TLogMessage);
  end;

  TFileTarget = class(TInterfacedObject, ILogTarget)
  private
    FFileName: string;
  public
    constructor Create(const FileName: string);
    procedure WriteLog(const Msg: TLogMessage);
  end;

  TXmlFileTarget = class(TInterfacedObject, ILogTarget)
  private
    FFileName: string;
  public
    constructor Create(const FileName: string);
    procedure WriteLog(const Msg: TLogMessage);
  end;

implementation

uses
  System.SysUtils,
  Seven.Logging.LogLevels;

{ TConsoleTarget }

procedure TConsoleTarget.WriteLog(const Msg: TLogMessage);
var
  LogLine: string;
begin
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

constructor TFileTarget.Create(const FileName: string);
begin
  FFileName := FileName;
end;

procedure TFileTarget.WriteLog(const Msg: TLogMessage);
var
  LogLine: string;
begin
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

constructor TXmlFileTarget.Create(const FileName: string);
begin
  FFileName := FileName;
end;

procedure TXmlFileTarget.WriteLog(const Msg: TLogMessage);
var
  XmlLine: string;
begin
  if Msg.ExceptionMessage <> '' then
    XmlLine := Format('<log timestamp="%s" category="%s" level="%s" exception="%s">%s</log>',
      [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '&quot;', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.ExceptionMessage, '"', '&quot;', [rfReplaceAll]), StringReplace(Msg.Message, '"', '&quot;', [rfReplaceAll])])
  else
    XmlLine := Format('<log timestamp="%s" category="%s" level="%s">%s</log>',
      [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '&quot;', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Message, '"', '&quot;', [rfReplaceAll])]);
  TFile.AppendAllText(FFileName, XmlLine + sLineBreak);
end;

end.