unit Seven.Logging.FileLogger;

interface

uses
  Seven.Logging, Seven.Logging.LogLevels, System.Classes;

type
  TFileLogger = class(TInterfacedObject, ILogger)
  private
    FLogFile: TStreamWriter; // Stream writer for file operations
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;
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

constructor TFileLogger.Create(const FileName: string);
begin
  FLogFile := TStreamWriter.Create(FileName, True); // True appends to file
end;

destructor TFileLogger.Destroy;
begin
  FLogFile.Free; // Clean up the stream writer
  inherited;
end;

procedure TFileLogger.Log(Level: TLogLevel; const Msg: string);
begin
  FLogFile.WriteLine(Format('[%s] %s', [LogLevelToString(Level), Msg]));
end;

procedure TFileLogger.Trace(const Msg: string);
begin
  Log(TLogLevel.Trace, Msg);
end;

procedure TFileLogger.Debug(const Msg: string);
begin
  Log(TLogLevel.Debug, Msg);
end;

procedure TFileLogger.Info(const Msg: string);
begin
  Log(TLogLevel.Info, Msg);
end;

procedure TFileLogger.Warning(const Msg: string);
begin
  Log(TLogLevel.Warning, Msg);
end;

procedure TFileLogger.Error(const Msg: string);
begin
  Log(TLogLevel.Error, Msg);
end;

procedure TFileLogger.Fatal(const Msg: string);
begin
  Log(TLogLevel.Fatal, Msg);
end;

end.