unit Seven.Logging.Providers;

{$SCOPEDENUMS ON}

interface

uses
  Seven.Logging, Seven.Logging.Targets;

type
  TConsoleLogProvider = class(TInterfacedObject, ILogProvider)
  private
    FMinLevel: TLogLevel;
  public
    constructor Create(MinLevel: TLogLevel = TLogLevel.Trace);
    function CreateLogTarget: ILogTarget;
  end;

  TFileLogProvider = class(TInterfacedObject, ILogProvider)
  private
    FFileName: string;
    FMinLevel: TLogLevel;
    FMaxSize: Int64;
  public
    constructor Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
    function CreateLogTarget: ILogTarget;
  end;

  TXmlFileLogProvider = class(TInterfacedObject, ILogProvider)
  private
    FFileName: string;
    FMinLevel: TLogLevel;
    FMaxSize: Int64;
  public
    constructor Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
    function CreateLogTarget: ILogTarget;
  end;

implementation

{ TConsoleLogProvider }

constructor TConsoleLogProvider.Create(MinLevel: TLogLevel = TLogLevel.Trace);
begin
  FMinLevel := MinLevel;
end;

function TConsoleLogProvider.CreateLogTarget: ILogTarget;
begin
  Result := TConsoleTarget.Create(FMinLevel);
end;

{ TFileLogProvider }

constructor TFileLogProvider.Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
begin
  FFileName := FileName;
  FMinLevel := MinLevel;
  FMaxSize := MaxSize;
end;

function TFileLogProvider.CreateLogTarget: ILogTarget;
begin
  Result := TFileTarget.Create(FFileName, FMinLevel, FMaxSize);
end;

{ TXmlFileLogProvider }

constructor TXmlFileLogProvider.Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
begin
  FFileName := FileName;
  FMinLevel := MinLevel;
  FMaxSize := MaxSize;
end;

function TXmlFileLogProvider.CreateLogTarget: ILogTarget;
begin
  Result := TXmlFileTarget.Create(FFileName, FMinLevel, FMaxSize);
end;

end.
