unit Seven.Logging.Impl;

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils, Seven.Logging, Seven.Logging.Queue, System.Generics.Collections, System.Rtti;

type
  TLogScope = class(TInterfacedObject, ILogScope)
  private
    FOnEndScope: TProc;
  public
    constructor Create(OnEndScope: TProc);
    destructor Destroy; override;
    procedure EndScope;
  end;

  TLogger<T> = class(TInterfacedObject, ILogger)
  private
    FCategory: string;
    FQueue: TLogQueue;
    FScopes: TStack<string>;
  public
    constructor Create(Queue: TLogQueue);
    destructor Destroy; override;
    procedure Log(Level: TLogLevel; const Message: string; Exception: Exception = nil); overload;
    procedure Log(Level: TLogLevel; EventId: TEventId; const Message: string; Exception: Exception = nil); overload;
    function IsEnabled(Level: TLogLevel): Boolean;
    function BeginScope(const ScopeName: string): ILogScope;
  end;

  TLoggerFactory = class
  public
    class function CreateLogger<T>(Queue: TLogQueue): ILogger;
  end;

implementation

{ TLogScope }

constructor TLogScope.Create(OnEndScope: TProc);
begin
  FOnEndScope := OnEndScope;
end;

destructor TLogScope.Destroy;
begin
  if Assigned(FOnEndScope) then
    FOnEndScope();
  inherited;
end;

procedure TLogScope.EndScope;
begin
  // Optionally, call FOnEndScope here if needed
end;

{ TLogger<T> }

constructor TLogger<T>.Create(Queue: TLogQueue);
begin
  FCategory := TRttiContext.Create.GetType(TypeInfo(T)).Name;
  FQueue := Queue;
  FScopes := TStack<string>.Create;
end;

destructor TLogger<T>.Destroy;
begin
  FScopes.Free;
  inherited;
end;

procedure TLogger<T>.Log(Level: TLogLevel; const Message: string; Exception: Exception = nil);
begin
  Log(Level, TEventId.Create(0, ''), Message, Exception);
end;

procedure TLogger<T>.Log(Level: TLogLevel; EventId: TEventId; const Message: string; Exception: Exception = nil);
var
  Msg: TLogMessage;
  Scope: string;
begin
  if FScopes.Count > 0 then
    Scope := FScopes.Peek
  else
    Scope := '';
  Msg.Category := FCategory;
  Msg.Level := Level;
  Msg.EventId := EventId;
  Msg.Message := Message;
  Msg.Timestamp := Now;
  Msg.Scope := Scope;
  if Assigned(Exception) then
    Msg.ExceptionMessage := Exception.Message
  else
    Msg.ExceptionMessage := '';
  FQueue.Enqueue(Msg);
end;

function TLogger<T>.IsEnabled(Level: TLogLevel): Boolean;
begin
  Result := True; // For now, always enabled. Can be configured later.
end;

function TLogger<T>.BeginScope(const ScopeName: string): ILogScope;
begin
  FScopes.Push(ScopeName);
  Result := TLogScope.Create(procedure begin FScopes.Pop; end);
end;

{ TLoggerFactory }

class function TLoggerFactory.CreateLogger<T>(Queue: TLogQueue): ILogger;
begin
  Result := TLogger<T>.Create(Queue);
end;

end.
