unit Seven.Logging.Impl;

interface

uses
  Seven.Logging, Seven.Logging.Queue, Seven.Logging.Targets, System.Generics.Collections;

type
  TLogScope = class(TInterfacedObject, ILogScope)
  private
    FLogger: ILogger;
    FScopeName: string;
  public
    constructor Create(Logger: ILogger; const ScopeName: string);
    destructor Destroy; override;
    procedure EndScope;
  end;

  TLogger<T> = class(TInterfacedObject, ILogger)
  private
    FCategory: string;
    FScopes: TStack<string>;
    FQueue: TLogQueue;
  public
    constructor Create(Queue: TLogQueue);
    destructor Destroy; override;
    procedure Log(Level: TLogLevel; const Message: string);
    function IsEnabled(Level: TLogLevel): Boolean;
    function BeginScope(const ScopeName: string): ILogScope;
  end;

  TLoggerFactory = class
  public
    class function CreateLogger<T>(Queue: TLogQueue): ILogger;
  end;

implementation

uses
  System.Rtti, System.SysUtils;

{ TLogScope }

constructor TLogScope.Create(Logger: ILogger; const ScopeName: string);
begin
  FLogger := Logger;
  FScopeName := ScopeName;
end;

destructor TLogScope.Destroy;
begin
  EndScope;
  inherited;
end;

procedure TLogScope.EndScope;
begin
  // Pode logar o fim do escopo, se desejado
end;

{ TLogger<T> }

constructor TLogger<T>.Create(Queue: TLogQueue);
begin
  FCategory := TRttiContext.Create.GetType(TypeInfo(T)).Name;
  FScopes := TStack<string>.Create;
  FQueue := Queue;
end;

destructor TLogger<T>.Destroy;
begin
  FScopes.Free;
  inherited;
end;

procedure TLogger<T>.Log(Level: TLogLevel; const Message: string);
var
  ScopeContext: string;
  Msg: TLogMessage;
begin
  ScopeContext := '';
  if FScopes.Count > 0 then
    ScopeContext := FScopes.Peek;
  Msg.Category := FCategory;
  Msg.Level := Level;
  Msg.Message := Message;
  Msg.Timestamp := Now;
  Msg.Scope := ScopeContext;
  FQueue.Enqueue(Msg);
end;

function TLogger<T>.IsEnabled(Level: TLogLevel): Boolean;
begin
  Result := True; // Pode ser configurado
end;

function TLogger<T>.BeginScope(const ScopeName: string): ILogScope;
begin
  FScopes.Push(ScopeName);
  Result := TLogScope.Create(Self, ScopeName);
end;

{ TLoggerFactory }

class function TLoggerFactory.CreateLogger<T>(Queue: TLogQueue): ILogger;
begin
  Result := TLogger<T>.Create(Queue);
end;

end.