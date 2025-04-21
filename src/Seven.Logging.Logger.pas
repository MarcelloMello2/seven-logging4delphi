unit Seven.Logging.Logger;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.TypInfo,
  System.Rtti,
  Seven.Logging.Types;

type
  /// <summary>
  /// Implementação da interface ILogger.
  /// </summary>
  TLogger = class(TInterfacedObject, ILogger)
  private
    FCategoryName: string;
    FLoggers: TArray<TLoggerInformation>;
    FMessageLoggers: TArray<TMessageLogger>;
    FScopeLoggers: TArray<TScopeLogger>;

    class procedure ThrowLoggingError(const Exceptions: TList<Exception>); static;
    function DebuggerToString: string;

    /// <summary>
    /// Classe para gerenciar múltiplos escopos.
    /// </summary>
    type
      TScope = class(TInterfacedObject, IDisposable)
      private
        FIsDisposed: Boolean;
        FDisposable0: IDisposable;
        FDisposable1: IDisposable;
        FDisposableArray: TArray<IDisposable>;
      public
        constructor Create(Count: Integer);
        procedure SetDisposable(Index: Integer; const Disposable: IDisposable);
        procedure Dispose;
      end;

  public
    constructor Create(const CategoryName: string; const Loggers: TArray<TLoggerInformation>);
    destructor Destroy; override;

    property Loggers: TArray<TLoggerInformation> read FLoggers write FLoggers;
    property MessageLoggers: TArray<TMessageLogger> read FMessageLoggers write FMessageLoggers;
    property ScopeLoggers: TArray<TScopeLogger> read FScopeLoggers write FScopeLoggers;

    // Implementação da interface ILogger
    procedure Log<TState>(LogLevel: TLogLevel; const EventId: TEventId;
      const State: TState; const AException: Exception;
      const Formatter: TFunc<TState, Exception, string>); overload;

//    procedure Log(const logLevel: TLogLevel; const eventId: TEventId; const state: TValue;
//                          const AException: Exception = nil; const formatter: TFunc<TValue, Exception, string> = nil); overload;


    function IsEnabled(const logLevel: TLogLevel): Boolean;

    function BeginScope<TState>(const State: TState): IDisposable; overload;
    function BeginScope(const state: TValue): ILogScopeDispose; overload;
  end;

  /// <summary>
  /// Classe utilitária para formatação de exibição de depuração.
  /// </summary>
  TDebuggerDisplayFormatting = class
  public
    /// <summary>
    /// Formata uma string de depuração para um logger.
    /// </summary>
    class function DebuggerToString(const Name: string; const Logger: ILogger): string; static;

    /// <summary>
    /// Calcula o nível mínimo de log habilitado para um logger.
    /// </summary>
    class function CalculateEnabledLogLevel(const Logger: ILogger): TLogLevel; overload; static;

    /// <summary>
    /// Verifica se um logger tem algum nível habilitado.
    /// </summary>
    class function CalculateEnabledLogLevel(const Logger: ILogger; out MinLevel: TLogLevel): Boolean; overload; static;
  end;

implementation

{ TLogger }

constructor TLogger.Create(const CategoryName: string; const Loggers: TArray<TLoggerInformation>);
begin
  inherited Create;
  FCategoryName := CategoryName;
  FLoggers := Loggers;
end;

destructor TLogger.Destroy;
begin
  // Liberar recursos, se necessário
  inherited;
end;

procedure TLogger.Log<TState>(LogLevel: TLogLevel; const EventId: TEventId;
  const State: TState; const AException: Exception;
  const Formatter: TFunc<TState, Exception, string>);
var
  I: Integer;
  Exceptions: TList<Exception>;
  ExLoggers: TArray<TMessageLogger>;
  CurrentLogger: TLogger;
begin
  ExLoggers := FMessageLoggers;
  if Length(ExLoggers) = 0 then
    Exit;

  Exceptions := nil;
  try
    for I := 0 to High(ExLoggers) do
    begin
      if not ExLoggers[I].IsEnabled(LogLevel) then
        Continue;

      CurrentLogger := ExLoggers[I].Logger as TLogger;

      try
        CurrentLogger.Log(LogLevel, EventId, State, AException, Formatter);
      except
        on Ex: Exception do
        begin
          if Exceptions = nil then
            Exceptions := TList<Exception>.Create;
          Exceptions.Add(Ex);
        end;
      end;
    end;

    if (Exceptions <> nil) and (Exceptions.Count > 0) then
      ThrowLoggingError(Exceptions);
  finally
    Exceptions.Free;
  end;
end;

function TLogger.IsEnabled(const LogLevel: TLogLevel): Boolean;
var
  I: Integer;
  Exceptions: TList<Exception>;
  ExLoggers: TArray<TMessageLogger>;
  CurrentLogger: ILogger;
begin
  ExLoggers := FMessageLoggers;
  if Length(ExLoggers) = 0 then
    Exit(False);

  Result := False;
  Exceptions := nil;
  try
    for I := 0 to High(ExLoggers) do
    begin
      if not ExLoggers[I].IsEnabled(LogLevel) then
        Continue;

      CurrentLogger := ExLoggers[I].Logger;

      try
        if CurrentLogger.IsEnabled(LogLevel) then
        begin
          Result := True;
          Break;
        end;
      except
        on Ex: Exception do
        begin
          if Exceptions = nil then
            Exceptions := TList<Exception>.Create;
          Exceptions.Add(Ex);
        end;
      end;
    end;

    if (Exceptions <> nil) and (Exceptions.Count > 0) then
      ThrowLoggingError(Exceptions);
  finally
    Exceptions.Free;
  end;
end;

function TLogger.BeginScope<TState>(const State: TState): IDisposable;
var
  ExLoggers: TArray<TScopeLogger>;
  Scope: TScope;
  I: Integer;
  Exceptions: TList<Exception>;
begin
  ExLoggers := FScopeLoggers;

  if Length(ExLoggers) = 0 then
    Exit(TNullScope.Instance);

  if Length(ExLoggers) = 1 then
    Exit(ExLoggers[0].CreateScope<TState>(State));

  Scope := TScope.Create(Length(ExLoggers));
  Exceptions := nil;

  try
    for I := 0 to High(ExLoggers) do
    begin
      try
        Scope.SetDisposable(I, ExLoggers[I].CreateScope<TState>(State));
      except
        on Ex: Exception do
        begin
          if Exceptions = nil then
            Exceptions := TList<Exception>.Create;
          Exceptions.Add(Ex);
        end;
      end;
    end;

    if (Exceptions <> nil) and (Exceptions.Count > 0) then
      ThrowLoggingError(Exceptions);
  finally
    Exceptions.Free;
  end;

  Result := Scope;
end;

class procedure TLogger.ThrowLoggingError(const Exceptions: TList<Exception>);
var
  AggEx: EAggregateException;
begin
  AggEx := EAggregateException.Create('Ocorreu um erro ao escrever para o(s) logger(s).');
  AggEx.InnerExceptions.AddRange(Exceptions);
  raise AggEx;
end;

function TLogger.DebuggerToString: string;
begin
  Result := TDebuggerDisplayFormatting.DebuggerToString(FCategoryName, Self);
end;

{ TLogger.TScope }

constructor TLogger.TScope.Create(Count: Integer);
begin
  inherited Create;

  FIsDisposed := False;

  if Count > 2 then
    SetLength(FDisposableArray, Count - 2);
end;

procedure TLogger.TScope.SetDisposable(Index: Integer; const Disposable: IDisposable);
begin
  case Index of
    0: FDisposable0 := Disposable;
    1: FDisposable1 := Disposable;
  else
    FDisposableArray[Index - 2] := Disposable;
  end;
end;

procedure TLogger.TScope.Dispose;
var
  I: Integer;
begin
  if not FIsDisposed then
  begin
    if FDisposable0 <> nil then
      FDisposable0 := nil;

    if FDisposable1 <> nil then
      FDisposable1 := nil;

    if Length(FDisposableArray) > 0 then
    begin
      for I := 0 to High(FDisposableArray) do
        FDisposableArray[I] := nil;
    end;

    FIsDisposed := True;
  end;
end;

class function TDebuggerDisplayFormatting.DebuggerToString(const Name: string;
  const Logger: ILogger): string;
var
  MinLevel: TLogLevel;
  HasEnabledLevel: Boolean;
begin
  HasEnabledLevel := CalculateEnabledLogLevel(Logger, MinLevel);

  Result := Format('Name = "%s"', [Name]);

  if HasEnabledLevel then
    Result := Result + Format(', MinLevel = %s',
      [GetEnumName(TypeInfo(TLogLevel), Ord(MinLevel))])
  else
    // Exibe "Enabled = false". Isso deixa claro que o ILogger inteiro
    // está desativado e nada é escrito.
    //
    // Se "MinLevel = None" fosse exibido, alguém poderia pensar que o
    // nível mínimo está desativado e tudo é escrito.
    Result := Result + ', Enabled = false';
end;

class function TDebuggerDisplayFormatting.CalculateEnabledLogLevel(const Logger: ILogger): TLogLevel;
var
  HasEnabledLevel: Boolean;
begin
  if CalculateEnabledLogLevel(Logger, Result) then
    Exit
  else
    Result := TLogLevel.None;
end;

class function TDebuggerDisplayFormatting.CalculateEnabledLogLevel(const Logger: ILogger;
  out MinLevel: TLogLevel): Boolean;
const
  LogLevels: array[0..5] of TLogLevel = (
    TLogLevel.Critical,
    TLogLevel.Error,
    TLogLevel.Warning,
    TLogLevel.Information,
    TLogLevel.Debug,
    TLogLevel.Trace
  );
var
  I: Integer;
begin
  Result := False;
  MinLevel := TLogLevel.None;

  // Verifica os níveis de log do mais alto para o mais baixo.
  // Reporta o nível de log mais baixo habilitado.
  for I := 0 to High(LogLevels) do
  begin
    if not Logger.IsEnabled(LogLevels[I]) then
      Break;

    MinLevel := LogLevels[I];
    Result := True;
  end;
end;

end.
