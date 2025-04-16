unit Seven.Logging.Targets;

interface

uses
  Seven.Logging, System.Classes;

type
  ILogTarget = interface
    ['{C3D4E5F6-7890-1234-CDEF-123456789012}']
    procedure WriteLog(const Msg: TLogMessage);
  end;

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
  System.IOUtils,
  Seven.Logging.LogLevels;

{ TConsoleTarget }

procedure TConsoleTarget.WriteLog(const Msg: TLogMessage);
begin
  WriteLn(Format('[%s] %s [%s]: %s', [
    DateTimeToStr(Msg.Timestamp),
    Msg.Category,
    LogLevelToString(Msg.Level),
    Msg.Message
  ]));
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
  XmlLine := Format('<log timestamp="%s" category="%s" level="%s">%s</log>',
    [DateTimeToStr(Msg.Timestamp), Msg.Category, LogLevelToString(Msg.Level), Msg.Message]);
  TFile.AppendAllText(FFileName, XmlLine + sLineBreak);
end;

end.