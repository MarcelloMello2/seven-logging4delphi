unit Seven.Logging;

interface

uses
  Seven.Logging.LogLevels, System.Generics.Collections;

type
  TLogLevel = Seven.Logging.LogLevels.TLogLevel;

  ILogScope = interface;

  ILogger = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    procedure Log(Level: TLogLevel; const Message: string);
    function IsEnabled(Level: TLogLevel): Boolean;
    function BeginScope(const ScopeName: string): ILogScope;
    procedure Trace(const Msg: string);
    procedure Debug(const Msg: string);
    procedure Info(const Msg: string);
    procedure Warning(const Msg: string);
    procedure Error(const Msg: string);
    procedure Fatal(const Msg: string);
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
  end;

implementation

end.
