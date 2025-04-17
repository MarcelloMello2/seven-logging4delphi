unit Seven.Logging;

{$SCOPEDENUMS ON}

interface

uses
  Seven.Logging.LogLevels, System.Generics.Collections, System.SysUtils;

type
  TLogLevel = Seven.Logging.LogLevels.TLogLevel;

  ILogScope = interface;

  ILogger = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    procedure Log(Level: TLogLevel; const Message: string; Exception: Exception = nil);
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
    Message: string;
    Timestamp: TDateTime;
    Scope: string;
    ExceptionMessage: string;
  end;

  ILogTarget = interface
    ['{C3D4E5F6-7890-1234-CDEF-123456789012}']
    procedure WriteLog(const Msg: TLogMessage);
  end;

  function LogLevelToString(Level: TLogLevel): string;

implementation

function LogLevelToString(Level: TLogLevel): string;
begin
  Result := Seven.Logging.LogLevels.LogLevelToString(Level);
end;

end.