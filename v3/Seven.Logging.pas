unit Seven.Logging;

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  Seven.Logging.LogLevels;

type
  TLogLevel = Seven.Logging.LogLevels.TLogLevel;
  ILogScope = interface;


  /// <summary>
  /// Identifica um evento de log. O identificador primário é a propriedade "Id", com a propriedade "Name" fornecendo uma breve descrição deste tipo de evento.
  /// </summary>
  TEventId = record
  private
    FId: Integer;
    FName: string;
  public
    /// <summary>
    /// Inicializa uma instância da estrutura <see cref="TEventId"/>.
    /// </summary>
    /// <param name="id">O identificador numérico para este evento.</param>
    /// <param name="name">O nome deste evento.</param>
    constructor Create(AId: Integer; const AName: string = '');

    /// <summary>
    /// Converte implicitamente um <see cref="Integer"/> para um <see cref="TEventId"/>.
    /// </summary>
    /// <param name="i">O <see cref="Integer"/> a ser convertido para um TEventId.</param>
    class operator Implicit(AValue: Integer): TEventId;

    /// <summary>
    /// Verifica se duas instâncias especificadas de <see cref="TEventId"/> têm o mesmo valor. Elas são iguais se tiverem o mesmo ID.
    /// </summary>
    /// <param name="left">O primeiro <see cref="TEventId"/>.</param>
    /// <param name="right">O segundo <see cref="TEventId"/>.</param>
    /// <returns><see langword="true" /> se os objetos forem iguais.</returns>
    class operator Equal(const Left, Right: TEventId): Boolean;

    /// <summary>
    /// Verifica se duas instâncias especificadas de <see cref="TEventId"/> têm valores diferentes.
    /// </summary>
    /// <param name="left">O primeiro <see cref="TEventId"/>.</param>
    /// <param name="right">O segundo <see cref="TEventId"/>.</param>
    /// <returns><see langword="true" /> se os objetos não forem iguais.</returns>
    class operator NotEqual(const Left, Right: TEventId): Boolean;

    /// <summary>
    /// Compara a instância atual com outro objeto do mesmo tipo. Dois eventos são iguais se tiverem o mesmo ID.
    /// </summary>
    /// <param name="other">Um objeto para comparar com este objeto.</param>
    /// <returns><see langword="true" /> se o objeto atual for igual a <paramref name="other" />; caso contrário, <see langword="false" />.</returns>
    function Equals(const Other: TEventId): Boolean; overload;

    /// <inheritdoc />
    function Equals(Obj: TObject): Boolean; overload;

    /// <inheritdoc />
    function GetHashCode: Integer;

    /// <inheritdoc />
    function ToString: string;

    /// <summary>
    /// Obtém o identificador numérico para este evento.
    /// </summary>
    property Id: Integer read FId;

    /// <summary>
    /// Obtém o nome deste evento.
    /// </summary>
    property Name: string read FName;
  end;


  /// <summary>
  /// Representa um tipo usado para realizar logging.
  /// </summary>
  /// <remarks>Agrega a maioria dos padrões de logging em um único método.</remarks>
  ILogger = interface
    ['{B2C3D4E5-F6A7-48B9-C0D1-E2F3A4B5C6D7}'] // GUID único para a interface

    /// <summary>
    /// Escreve uma entrada de log.
    /// </summary>
    /// <param name="logLevel">A entrada será escrita neste nível.</param>
    /// <param name="eventId">Id do evento.</param>
    /// <param name="state">A entrada a ser escrita. Também pode ser um objeto.</param>
    /// <param name="exception">A exceção relacionada a esta entrada.</param>
    /// <param name="formatter">Função para criar uma mensagem <see cref="string"/> do <paramref name="state"/> e <paramref name="exception"/>.</param>
    /// <typeparam name="TState">O tipo do objeto a ser escrito.</typeparam>
    procedure Log(const logLevel: TLogLevel; const eventId: TEventId; const state: TValue;
                          const exception: Exception = nil; const formatter: TFunc<TValue, Exception, string> = nil);

    /// <summary>
    /// Verifica se o <paramref name="logLevel"/> fornecido está habilitado.
    /// </summary>
    /// <param name="logLevel">Nível a ser verificado.</param>
    /// <returns><see langword="true" /> se estiver habilitado.</returns>
    function IsEnabled(const logLevel: TLogLevel): Boolean;

    /// <summary>
    /// Inicia um escopo de operação lógica.
    /// </summary>
    /// <param name="state">O identificador para o escopo.</param>
    /// <typeparam name="TState">O tipo do estado para iniciar o escopo.</typeparam>
    /// <returns>Um <see cref="IDisposable"/> que encerra o escopo de operação lógica ao ser liberado.</returns>
    function BeginScope(const state: TValue): ILogScope;
  end;

  /// <summary>
  /// Representa um tipo que pode criar instâncias de <see cref="ILogger"/>.
  /// </summary>
  ILoggerProvider = interface(IInterface)
    ['{5E199118-FB31-4FFE-B1BA-0092BE7001C8}']

    /// <summary>
    /// Cria uma nova instância de <see cref="ILogger"/>.
    /// </summary>
    /// <param name="categoryName">O nome da categoria para mensagens produzidas pelo logger.</param>
    /// <returns>A instância de <see cref="ILogger"/> que foi criada.</returns>
    function CreateLogger(const categoryName: string): ILogger;
  end;

  /// <summary>
  /// Representa um tipo usado para configurar o sistema de log e criar instâncias de <see cref="ILogger"/> a partir
  /// dos <see cref="ILoggerProvider"/>s registrados.
  /// </summary>
  ILoggerFactory = interface(IInterface)
    ['{66B731B1-384A-4799-99AE-CDF51076495C}']

    /// <summary>
    /// Cria uma nova instância de <see cref="ILogger"/>.
    /// </summary>
    /// <param name="categoryName">O nome da categoria para mensagens produzidas pelo logger.</param>
    /// <returns>O <see cref="ILogger"/>.</returns>
    function CreateLogger(const categoryName: string): ILogger;

    /// <summary>
    /// Adiciona um <see cref="ILoggerProvider"/> ao sistema de log.
    /// </summary>
    /// <param name="provider">O <see cref="ILoggerProvider"/>.</param>
    procedure AddProvider(const provider: ILoggerProvider);
  end;

  ILogger = interface
    ['{B6A9661C-EC54-4CF7-BB32-44F5683B778C}']
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

constructor TEventId.Create(AId: Integer; const AName: string = '');
begin
  FId := AId;
  FName := AName;
end;

class operator TEventId.Implicit(AValue: Integer): TEventId;
begin
  Result := TEventId.Create(AValue);
end;

class operator TEventId.Equal(const Left, Right: TEventId): Boolean;
begin
  Result := Left.Equals(Right);
end;

class operator TEventId.NotEqual(const Left, Right: TEventId): Boolean;
begin
  Result := not Left.Equals(Right);
end;

function TEventId.Equals(const Other: TEventId): Boolean;
begin
  Result := Id = Other.Id;
end;

function TEventId.Equals(Obj: TObject): Boolean;
begin
  Result := False;
  if Obj is TEventId then
    Result := Equals(TEventId(Obj));
end;

function TEventId.GetHashCode: Integer;
begin
  Result := Id;
end;

function TEventId.ToString: string;
begin
  if FName = '' then
    Result := IntToStr(Id)
  else
    Result := FName;
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
