unit Seven.Logging.ConsoleLogger;

interface

uses
  Seven.Logging, Seven.Logging.LogLevels;

type
  TConsoleLogger = class(TInterfacedObject, ILogger)
  public
    procedure Log(Level: TLogLevel; const Msg: string);
    procedure Trace(const Msg: string);
    procedure Debug(const Msg: string);
    procedure Info(const Msg: string);
    procedure Warning(const Msg: string);
    procedure Error(const Msg: string);
    procedure Fatal(const Msg: string);
  end;

implementation

uses
  System.SysUtils;

procedure TConsoleLogger.Log(Level: TLogLevel; const Msg: string);
begin
  Writeln(Format('[%s] %s', [LogLevelToString(Level), Msg]));
end;

procedure TConsoleLogger.Trace(const Msg: string);
begin
  Log(TLogLevel.Trace, Msg);
end;

procedure TConsoleLogger.Debug(const Msg: string);
begin
  Log(TLogLevel.Debug, Msg);
end;

procedure TConsoleLogger.Info(const Msg: string);
begin
  Log(TLogLevel.Info, Msg);
end;

procedure TConsoleLogger.Warning(const Msg: string);
begin
  Log(TLogLevel.Warning, Msg);
end;

procedure TConsoleLogger.Error(const Msg: string);
begin
  Log(TLogLevel.Error, Msg);
end;

procedure TConsoleLogger.Fatal(const Msg: string);
begin
  Log(TLogLevel.Fatal, Msg);
end;

end.