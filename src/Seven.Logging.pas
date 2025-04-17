unit Seven.Logging;

{$SCOPEDENUMS ON}

interface

uses
  Seven.Logging.LogLevels, System.Generics.Collections, System.SysUtils;

type
  TLogLevel = Seven.Logging.LogLevels.TLogLevel;

  TEventId = record
    Id: Integer;
    Name: string;
    class function Create(Id: Integer; const Name: string): TEventId; static;
  end;

  ILogScope = interface;

  ILogger = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    procedure Log(Level: TLogLevel; const Message: string; Exception: Exception = nil); overload;
    procedure Log(Level: TLogLevel; EventId: TEventId; const Message: string; Exception: Exception = nil); overload;
    function IsEnabled(Level: TLogLevel): Boolean;
    function BeginScope(const ScopeName: string): ILogScope;
  end;

  ILogScope = interface
    ['{B2C3D4E5-F678-9012-BCDE-F12345678901}']
    procedure EndScope;
  end;

  TLogMessage = record
    Category: string;
    Level: TLogLevel;
    EventId: TEventId;
    Message: string;
    Timestamp: TDateTime;
    Scope: string;
    ExceptionMessage: string;
  end;

  ILogTarget = interface
    ['{C3D4E5F6-7890-1234-CDEF-123456789012}']
    procedure WriteLog(const Msg: TLogMessage);
  end;

  ILogProvider = interface
    ['{8F0939F7-68CD-480F-973B-21EAC361E24C}']
    function CreateLogTarget: ILogTarget;
  end;

  TLogConfiguration = class
  private
    FProviders: TList<ILogProvider>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddProvider(Provider: ILogProvider);
    function GetTargets: TList<ILogTarget>;
  end;

implementation

{ TEventId }

class function TEventId.Create(Id: Integer; const Name: string): TEventId;
begin
  Result.Id := Id;
  Result.Name := Name;
end;

{ TLogConfiguration }

constructor TLogConfiguration.Create;
begin
  FProviders := TList<ILogProvider>.Create;
end;

destructor TLogConfiguration.Destroy;
begin
  FProviders.Free;
  inherited;
end;

procedure TLogConfiguration.AddProvider(Provider: ILogProvider);
begin
  FProviders.Add(Provider);
end;

function TLogConfiguration.GetTargets: TList<ILogTarget>;
var
  Provider: ILogProvider;
begin
  Result := TList<ILogTarget>.Create;
  for Provider in FProviders do
    Result.Add(Provider.CreateLogTarget);
end;

end.
