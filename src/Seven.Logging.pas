unit Seven.Logging;

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs;

type

  /// <summary>
  /// Define os níveis de severidade de log.
  /// </summary>
  TLogLevel = (
    /// <summary>
    /// Logs que contêm as mensagens mais detalhadas. Essas mensagens podem conter dados sensíveis
    /// da aplicação. Essas mensagens estão desativadas por padrão e nunca devem ser habilitadas
    /// em ambiente de produção.
    /// </summary>
    Trace,

    /// <summary>
    /// Logs usados para investigação interativa durante o desenvolvimento. Esses logs devem conter
    /// principalmente informações úteis para depuração e não têm valor a longo prazo.
    /// </summary>
    Debug,

    /// <summary>
    /// Logs que acompanham o fluxo geral da aplicação. Esses logs devem ter valor a longo prazo.
    /// </summary>
    Information,

    /// <summary>
    /// Logs que destacam um evento anormal ou inesperado no fluxo da aplicação, mas que não fazem
    /// com que a execução da aplicação seja interrompida.
    /// </summary>
    Warning,

    /// <summary>
    /// Logs que destacam quando o fluxo de execução atual é interrompido devido a uma falha. Devem
    /// indicar uma falha na atividade atual, não uma falha em toda a aplicação.
    /// </summary>
    Error,

    /// <summary>
    /// Logs que descrevem um travamento não recuperável da aplicação ou do sistema, ou uma falha
    /// catastrófica que requer atenção imediata.
    /// </summary>
    Critical,

    /// <summary>
    /// Não é usado para escrever mensagens de log. Especifica que uma categoria de log não deve
    /// registrar nenhuma mensagem.
    /// </summary>
    None
  );

  /// <summary>
  /// Flags para indicar quais partes do contexto de rastreamento devem ser incluídas nos escopos de log.
  /// </summary>
  TActivityTrackingOption = (
    /// <summary>
    /// ID do Span será incluído no log.
    /// </summary>
    SpanId,

    /// <summary>
    /// ID do Trace será incluído no log.
    /// </summary>
    TraceId,

    /// <summary>
    /// ID do Pai será incluído no log.
    /// </summary>
    ParentId,

    /// <summary>
    /// Estado do Trace será incluído no log.
    /// </summary>
    TraceState,

    /// <summary>
    /// Flags do Trace serão incluídas no log.
    /// </summary>
    TraceFlags,

    /// <summary>
    /// Tags serão incluídas no log.
    /// </summary>
    Tags,

    /// <summary>
    /// Itens de bagagem serão incluídos no log.
    /// </summary>
    Baggage
  );

  /// <summary>
  /// Conjunto de opções de rastreamento de atividade.
  /// </summary>
  TActivityTrackingOptions = set of TActivityTrackingOption;

  /// <summary>
  ///   Fornece um mecanismo para liberar recursos não gerenciados.
  /// </summary>
  IDisposable = interface
    ['{FA2E3193-9311-452D-A15E-542E9BC03F5B}']

    /// <summary>
    ///   Realiza tarefas definidas pelo aplicativo associadas à liberação ou à redefinição
    ///   de recursos não gerenciados.
    /// </summary>
    procedure Dispose();
  end;

  ILogScopeDispose = interface;

  /// <summary>
  /// Define uma regra usada para filtrar mensagens de log
  /// </summary>
  TLoggerFilterRule = class
  private
    FProviderName: string;
    FCategoryName: string;
    FLogLevel: TLogLevel;
    FHasLogLevel: Boolean;
    FFilter: TFunc<string, string, TLogLevel, Boolean>;
  public
    /// <summary>
    /// Cria uma nova instância de <see cref="TLoggerFilterRule"/>.
    /// </summary>
    /// <param name="ProviderName">O nome do provedor a ser usado nesta regra de filtro.</param>
    /// <param name="CategoryName">O nome da categoria a ser usado nesta regra de filtro.</param>
    /// <param name="LogLevel">O <see cref="TLogLevel"/> a ser usado nesta regra de filtro.</param>
    /// <param name="Filter">O filtro a ser aplicado.</param>
    constructor Create(const ProviderName: string = '';
                       const CategoryName: string = '';
                       LogLevel: TLogLevel = TLogLevel.None;
                       HasLogLevel: Boolean = False;
                       Filter: TFunc<string, string, TLogLevel, Boolean> = nil);

    /// <summary>
    /// Obtém o tipo ou alias do provedor de logger ao qual esta regra se aplica.
    /// </summary>
    property ProviderName: string read FProviderName;

    /// <summary>
    /// Obtém a categoria de logger à qual esta regra se aplica.
    /// </summary>
    property CategoryName: string read FCategoryName;

    /// <summary>
    /// Obtém o <see cref="TLogLevel"/> mínimo das mensagens.
    /// </summary>
    property LogLevel: TLogLevel read FLogLevel;

    /// <summary>
    /// Indica se um LogLevel foi especificado para esta regra.
    /// </summary>
    property HasLogLevel: Boolean read FHasLogLevel;

    /// <summary>
    /// Obtém a função delegada de filtro que seria aplicada às mensagens que passaram pelo <see cref="TLogLevel"/>.
    /// </summary>
    property Filter: TFunc<string, string, TLogLevel, Boolean> read FFilter;

    /// <inheritdoc/>
    function ToString: string; override;
  end;

  /// <summary>
  /// Recupera instâncias configuradas de <typeparamref name="TOptions"/>.
  /// </summary>
  /// <typeparam name="TOptions">O tipo de opções sendo solicitado.</typeparam>
  IOptions<TOptions: class> = interface
    ['{F5A8C6B7-D9E0-4123-A4B5-C6D7E8F9A0B1}'] // GUID único para a interface

    /// <summary>
    /// Obtém a instância padrão configurada de <typeparamref name="TOptions"/>.
    /// </summary>
    function GetValue: TOptions;

    /// <summary>
    /// Obtém a instância padrão configurada de <typeparamref name="TOptions"/>.
    /// </summary>
    property Value: TOptions read GetValue;
  end;


  /// <summary>
  /// Representa um armazenamento de dados de escopo comuns.
  /// </summary>
  IExternalScopeProvider = interface
    ['{D6E7F8A9-B0C1-42D3-E4F5-A6B7C8D9E0F1}'] // GUID único para a interface

    /// <summary>
    /// Executa callback para cada objeto de escopo atualmente ativo em ordem de criação.
    /// Todos os callbacks têm garantia de serem chamados em linha a partir deste método.
    /// </summary>
    /// <param name="Callback">O callback a ser executado para cada objeto de escopo.</param>
    /// <param name="State">O objeto de estado a ser passado para o callback.</param>
    /// <typeparam name="TState">O tipo de estado a ser aceito.</typeparam>
    procedure ForEachScope(const Callback: TProc<TObject, TValue>; const State: TValue);

    /// <summary>
    /// Adiciona objeto de escopo à lista.
    /// </summary>
    /// <param name="State">O objeto de escopo.</param>
    /// <returns>O token <see cref="IDisposable"/> que remove o escopo ao ser liberado.</returns>
    function Push(const State: TObject): IDisposable;
  end;

  /// <summary>
  /// As opções para um LoggerFilter.
  /// </summary>
  TLoggerFilterOptions = class
  private
    FCaptureScopes: Boolean;
    FMinLevel: TLogLevel;
    FRulesInternal: TList<TLoggerFilterRule>;

    function GetRules: TList<TLoggerFilterRule>;

  public
    /// <summary>
    /// Cria uma nova instância de <see cref="TLoggerFilterOptions"/>.
    /// </summary>
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Obtém ou define um valor indicando se os escopos de log estão sendo capturados.
    /// </summary>
    /// <value>
    /// O valor padrão é <see langword="True" />
    /// </value>
    property CaptureScopes: Boolean read FCaptureScopes write FCaptureScopes;

    /// <summary>
    /// Obtém ou define o nível mínimo das mensagens de log se nenhuma das regras corresponder.
    /// </summary>
    property MinLevel: TLogLevel read FMinLevel write FMinLevel;

    /// <summary>
    /// Obtém a coleção de <see cref="TLoggerFilterRule"/> usada para filtrar mensagens de log.
    /// </summary>
    property Rules: TList<TLoggerFilterRule> read GetRules;

    /// <summary>
    /// Retorna uma string para depuração.
    /// </summary>
    function DebuggerToString: string;
  end;

  /// <summary>
  /// As opções para uma LoggerFactory.
  /// </summary>
  TLoggerFactoryOptions = class
  private
    FActivityTrackingOptions: TActivityTrackingOptions;
  public
    /// <summary>
    /// Cria uma nova instância de <see cref="TLoggerFactoryOptions"/>.
    /// </summary>
    constructor Create;

    /// <summary>
    /// Obtém ou define o valor <see cref="TLoggerFactoryOptions"/> para indicar quais partes da informação de contexto de rastreamento devem ser incluídas nos escopos de log.
    /// </summary>
    property ActivityTrackingOptions: TActivityTrackingOptions read FActivityTrackingOptions write FActivityTrackingOptions;
  end;

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
    function BeginScope(const state: TValue): ILogScopeDispose;
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

  ILogScopeDispose = interface
    ['{B2C3D4E5-F678-9012-BCDE-F12345678901}']
    procedure EndScope;
  end;

  /// <summary>
  /// Formatador para converter itens de formato nomeados como {ItemFormatoNomeado} para o formato usado por <see cref="Format(string, array of const)"/>.
  /// </summary>
  TLogValuesFormatter = class
  private
    const NullValue = '(null)';

  private
    FValueNames: TList<string>;
    FFormat: string;
    FOriginalFormat: string;

    class function FindBraceIndex(const Format: string; Brace: Char; StartIndex, EndIndex: Integer): Integer; static;
    class function FormatArgument(const Value: TValue): TValue; static;
    class function TryFormatArgumentIfNullOrEnumerable(const Value: TValue; out StringValue: TValue): Boolean; static;

  public
    constructor Create(const Format: string);
    destructor Destroy; override;

    /// <summary>
    /// Obtém o formato original.
    /// </summary>
    property OriginalFormat: string read FOriginalFormat;

    /// <summary>
    /// Obtém a lista de nomes de valores.
    /// </summary>
    property ValueNames: TList<string> read FValueNames;

    /// <summary>
    /// Formata um array de valores usando o formato definido.
    /// </summary>
    function Format(const Values: array of TValue): string; overload;

    /// <summary>
    /// Retorna apenas a string de formato.
    /// </summary>
    function Format: string; overload;

    /// <summary>
    /// Formata um único valor usando o formato definido.
    /// </summary>
    function Format(const Arg0: TValue): string; overload;

    /// <summary>
    /// Formata dois valores usando o formato definido.
    /// </summary>
    function Format(const Arg0, Arg1: TValue): string; overload;

    /// <summary>
    /// Formata três valores usando o formato definido.
    /// </summary>
    function Format(const Arg0, Arg1, Arg2: TValue): string; overload;

//    /// <summary>
//    /// Formata valores, substituindo-os no array original.
//    /// </summary>
//    function FormatWithOverwrite(var Values: array of TValue): string;

    /// <summary>
    /// Obtém um par chave/valor para o índice especificado.
    /// </summary>
    function GetValue(const Values: array of TValue; Index: Integer): TPair<string, TValue>;

    /// <summary>
    /// Obtém todos os pares chave/valor para os valores especificados.
    /// </summary>
    function GetValues(const Values: array of TValue): TArray<TPair<string, TValue>>;
  end;


  /// <summary>
  /// LogValues para habilitar opções de formatação suportadas por <see cref="string.Format(IFormatProvider, string, object?)"/>.
  /// Isso também permite usar {NamedformatItem} na string de formato.
  /// </summary>
  TFormattedLogValues = record
  private
    const MaxCachedFormatters = 1024;
    const NullFormat = '[null]';

    class var FCount: Integer;
    class var FFormatters: TDictionary<string, TLogValuesFormatter>;
    class var FLock: TCriticalSection;

    var
      FFormatter: TLogValuesFormatter;
      FValues: TArray<TValue>;
      FOriginalMessage: string;

    class constructor Create;
    class destructor Destroy;

    function GetItem(Index: Integer): TPair<string, TValue>;
    function GetCount: Integer;

  public
    // para fins de teste
    property Formatter: TLogValuesFormatter read FFormatter;

    constructor Create(const Format: string; const Values: array of TValue);

    property Items[Index: Integer]: TPair<string, TValue> read GetItem; default;
    property Count: Integer read GetCount;

    function GetEnumerator: TEnumerator<TPair<string, TValue>>;

    function ToString: string;

    // Implementação IReadOnlyList
    // Nota: Delphi não tem interface IReadOnlyList diretamente equivalente,
    // mas podemos implementar IEnumerable
  end;

  TMessageFormatterFunc = function(const AState: TFormattedLogValues; const AError: Exception): string;

  /// <summary>
  /// Métodos de extensão ILogger para cenários comuns.
  /// </summary>
  TLoggerExtensions = class
  private
    class var FMessageFormatter: TMessageFormatterFunc;
    class constructor Create;
  public
    //------------------------------------------DEBUG------------------------------------------//

    /// <summary>
    /// Formata e escreve uma mensagem de log de depuração.
    /// </summary>
    /// <param name="Logger">O <see cref="ILogger"/> no qual escrever.</param>
    /// <param name="EventId">O id do evento associado ao log.</param>
    /// <param name="Exception">A exceção a ser registrada.</param>
    /// <param name="Message">String de formato da mensagem do log em formato de template. Exemplo: <c>"Usuário {User} logou de {Address}"</c>.</param>
    /// <param name="Args">Um array de objetos que contém zero ou mais objetos para formatar.</param>
    /// <example>
    /// <code language="delphi">
    /// TLoggerExtensions.LogDebug(Logger, 0, Exception, 'Erro ao processar requisição de {Address}', [Address]);
    /// </code>
    /// </example>
    class procedure LogDebug(const Logger: ILogger; const EventId: TEventId;
      const Exception: Exception; const Message: string;
      const Args: array of TValue); overload; static;

    /// <summary>
    /// Formata e escreve uma mensagem de log de depuração.
    /// </summary>
    /// <param name="Logger">O <see cref="ILogger"/> no qual escrever.</param>
    /// <param name="EventId">O id do evento associado ao log.</param>
    /// <param name="Message">String de formato da mensagem do log em formato de template. Exemplo: <c>"Usuário {User} logou de {Address}"</c>.</param>
    /// <param name="Args">Um array de objetos que contém zero ou mais objetos para formatar.</param>
    /// <example>
    /// <code language="delphi">
    /// TLoggerExtensions.LogDebug(Logger, 0, 'Processando requisição de {Address}', [Address]);
    /// </code>
    /// </example>
    class procedure LogDebug(const Logger: ILogger; const EventId: TEventId;
      const Message: string; const Args: array of TValue); overload; static;

    /// <summary>
    /// Formata e escreve uma mensagem de log de depuração.
    /// </summary>
    /// <param name="Logger">O <see cref="ILogger"/> no qual escrever.</param>
    /// <param name="Exception">A exceção a ser registrada.</param>
    /// <param name="Message">String de formato da mensagem do log em formato de template. Exemplo: <c>"Usuário {User} logou de {Address}"</c>.</param>
    /// <param name="Args">Um array de objetos que contém zero ou mais objetos para formatar.</param>
    /// <example>
    /// <code language="delphi">
    /// TLoggerExtensions.LogDebug(Logger, Exception, 'Erro ao processar requisição de {Address}', [Address]);
    /// </code>
    /// </example>
    class procedure LogDebug(const Logger: ILogger; const Exception: Exception;
      const Message: string; const Args: array of TValue); overload; static;

    /// <summary>
    /// Formata e escreve uma mensagem de log de depuração.
    /// </summary>
    /// <param name="Logger">O <see cref="ILogger"/> no qual escrever.</param>
    /// <param name="Message">String de formato da mensagem do log em formato de template. Exemplo: <c>"Usuário {User} logou de {Address}"</c>.</param>
    /// <param name="Args">Um array de objetos que contém zero ou mais objetos para formatar.</param>
    /// <example>
    /// <code language="delphi">
    /// TLoggerExtensions.LogDebug(Logger, 'Processando requisição de {Address}', [Address]);
    /// </code>
    /// </example>
    class procedure LogDebug(const Logger: ILogger; const Message: string;
      const Args: array of TValue); overload; static;

    //------------------------------------------TRACE------------------------------------------//

    /// <summary>
    /// Formata e escreve uma mensagem de log de rastreamento.
    /// </summary>
    class procedure LogTrace(const Logger: ILogger; const EventId: TEventId;
      const Exception: Exception; const Message: string;
      const Args: array of TValue); overload; static;

    class procedure LogTrace(const Logger: ILogger; const EventId: TEventId;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogTrace(const Logger: ILogger; const Exception: Exception;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogTrace(const Logger: ILogger; const Message: string;
      const Args: array of TValue); overload; static;

    //------------------------------------------INFORMATION------------------------------------------//

    /// <summary>
    /// Formata e escreve uma mensagem de log informativa.
    /// </summary>
    class procedure LogInformation(const Logger: ILogger; const EventId: TEventId;
      const Exception: Exception; const Message: string;
      const Args: array of TValue); overload; static;

    class procedure LogInformation(const Logger: ILogger; const EventId: TEventId;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogInformation(const Logger: ILogger; const Exception: Exception;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogInformation(const Logger: ILogger; const Message: string;
      const Args: array of TValue); overload; static;

    //------------------------------------------WARNING------------------------------------------//

    /// <summary>
    /// Formata e escreve uma mensagem de log de aviso.
    /// </summary>
    class procedure LogWarning(const Logger: ILogger; const EventId: TEventId;
      const Exception: Exception; const Message: string;
      const Args: array of TValue); overload; static;

    class procedure LogWarning(const Logger: ILogger; const EventId: TEventId;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogWarning(const Logger: ILogger; const Exception: Exception;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogWarning(const Logger: ILogger; const Message: string;
      const Args: array of TValue); overload; static;

    //------------------------------------------ERROR------------------------------------------//

    /// <summary>
    /// Formata e escreve uma mensagem de log de erro.
    /// </summary>
    class procedure LogError(const Logger: ILogger; const EventId: TEventId;
      const Exception: Exception; const Message: string;
      const Args: array of TValue); overload; static;

    class procedure LogError(const Logger: ILogger; const EventId: TEventId;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogError(const Logger: ILogger; const Exception: Exception;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogError(const Logger: ILogger; const Message: string;
      const Args: array of TValue); overload; static;

    //------------------------------------------CRITICAL------------------------------------------//

    /// <summary>
    /// Formata e escreve uma mensagem de log crítica.
    /// </summary>
    class procedure LogCritical(const Logger: ILogger; const EventId: TEventId;
      const Exception: Exception; const Message: string;
      const Args: array of TValue); overload; static;

    class procedure LogCritical(const Logger: ILogger; const EventId: TEventId;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogCritical(const Logger: ILogger; const Exception: Exception;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure LogCritical(const Logger: ILogger; const Message: string;
      const Args: array of TValue); overload; static;

    //------------------------------------------LOG------------------------------------------//

    /// <summary>
    /// Formata e escreve uma mensagem de log no nível especificado.
    /// </summary>
    class procedure Log(const Logger: ILogger; const LogLevel: TLogLevel;
      const Message: string; const Args: array of TValue); overload; static;

    class procedure Log(const Logger: ILogger; const LogLevel: TLogLevel;
      const EventId: TEventId; const Message: string;
      const Args: array of TValue); overload; static;

    class procedure Log(const Logger: ILogger; const LogLevel: TLogLevel;
      const Exception: Exception; const Message: string;
      const Args: array of TValue); overload; static;

    class procedure Log(const Logger: ILogger; const LogLevel: TLogLevel;
      const EventId: TEventId; const Exception: Exception;
      const Message: string; const Args: array of TValue); overload; static;

    //------------------------------------------Scope------------------------------------------//

    /// <summary>
    /// Formata a mensagem e cria um escopo.
    /// </summary>
    /// <param name="Logger">O <see cref="ILogger"/> no qual criar o escopo.</param>
    /// <param name="MessageFormat">String de formato da mensagem do log em formato de template. Exemplo: <c>"Usuário {User} logou de {Address}"</c>.</param>
    /// <param name="Args">Um array de objetos que contém zero ou mais objetos para formatar.</param>
    /// <returns>Um objeto de escopo descartável. Pode ser nulo.</returns>
    /// <example>
    /// <code language="delphi">
    /// var
    ///   Scope: IDisposable;
    /// begin
    ///   Scope := TLoggerExtensions.BeginScope(Logger, 'Processando requisição de {Address}', [Address]);
    ///   try
    ///     // Código dentro do escopo
    ///   finally
    ///     Scope := nil; // Libera o escopo
    ///   end;
    /// end;
    /// </code>
    /// </example>
    class function BeginScope(const Logger: ILogger; const MessageFormat: string;
      const Args: array of TValue): ILogScopeDispose; static;

  private
    class function MessageFormatter(const State: TFormattedLogValues;
      const Error: Exception): string; static;
  end;


  /// <summary>
  /// Enumerador para TFormattedLogValues
  /// </summary>
  TFormattedLogValuesEnumerator = class(TEnumerator<TPair<string, TValue>>)
  private
    FLogValues: TFormattedLogValues;
    FIndex: Integer;
    FCurrent: TPair<string, TValue>;
  public
    constructor Create(const ALogValues: TFormattedLogValues);
    function DoGetCurrent: TPair<string, TValue>; override;
    function DoMoveNext: Boolean; override;
//    procedure Reset; override;
    property Current: TPair<string, TValue> read DoGetCurrent;
  end;

  TLogicalUtils = class
    // Função auxiliar para selecionar um valor com base em uma condição
    class function IfThen<T>(Condition: Boolean; const TrueValue, FalseValue: T): T; static;
  end;

// Função auxiliar
function LogLevelToString(Level: TLogLevel): string;

const
  /// <summary>
  /// Nenhuma das partes do contexto de rastreamento será incluída no log.
  /// </summary>
  ATONone: TActivityTrackingOptions = [];

implementation

// Função auxiliar para selecionar um valor com base em uma condição
class function TLogicalUtils.IfThen<T>(Condition: Boolean; const TrueValue, FalseValue: T): T;
begin
  if Condition then
    Result := TrueValue
  else
    Result := FalseValue;
end;

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

function LogLevelToString(Level: TLogLevel): string;
begin
  case Level of
    TLogLevel.Trace: Result := 'TRACE';
    TLogLevel.Debug: Result := 'DEBUG';
    TLogLevel.Information: Result := 'INFO';
    TLogLevel.Warning: Result := 'WARNING';
    TLogLevel.Error: Result := 'ERROR';
    TLogLevel.Critical: Result := 'CRITICAL';
    TLogLevel.None: Result := 'NONE';
  else
    Result := 'UNKNOWN';
  end;
end;

{ TFormattedLogValues }

class constructor TFormattedLogValues.Create;
begin
  FCount := 0;
  FFormatters := TDictionary<string, TLogValuesFormatter>.Create;
  FLock := TCriticalSection.Create;
end;

class destructor TFormattedLogValues.Destroy;
begin
  FFormatters.Free;
  FLock.Free;
end;

constructor TFormattedLogValues.Create(const Format: string; const Values: array of TValue);
begin
  if (Length(Values) > 0) and (Format <> '') then
  begin
    if FCount >= MaxCachedFormatters then
    begin
      FLock.Enter;
      try
        if not FFormatters.TryGetValue(Format, FFormatter) then
          FFormatter := TLogValuesFormatter.Create(Format);
      finally
        FLock.Leave;
      end;
    end
    else
    begin
      FLock.Enter;
      try
        if not FFormatters.TryGetValue(Format, FFormatter) then
        begin
          FFormatter := TLogValuesFormatter.Create(Format);
          FFormatters.Add(Format, FFormatter);
          TInterlocked.Increment(FCount);
        end
        else
        begin
          FFormatter := FFormatters[Format];
        end;
      finally
        FLock.Leave;
      end;
    end;
  end
  else
  begin
    FFormatter := nil;
  end;

  if Format <> '' then
    FOriginalMessage := Format
  else
    FOriginalMessage := NullFormat;

  SetLength(FValues, Length(Values));
  for var I := 0 to Length(Values) - 1 do
    FValues[I] := Values[I];
end;

function TFormattedLogValues.GetItem(Index: Integer): TPair<string, TValue>;
begin
  if (Index < 0) or (Index >= Count) then
    raise EArgumentOutOfRangeException.Create('Index');

  if Index = Count - 1 then
    Result := TPair<string, TValue>.Create('{OriginalFormat}', FOriginalMessage)
  else
    Result := FFormatter.GetValue(FValues, Index);
end;

function TFormattedLogValues.GetCount: Integer;
begin
  if FFormatter = nil then
    Result := 1
  else
    Result := FFormatter.ValueNames.Count + 1;
end;

function TFormattedLogValues.GetEnumerator: TEnumerator<TPair<string, TValue>>;
begin
  Result := TFormattedLogValuesEnumerator.Create(Self);
end;

function TFormattedLogValues.ToString: string;
begin
  if FFormatter = nil then
    Result := FOriginalMessage
  else
    Result := FFormatter.Format(FValues);
end;

{ TFormattedLogValuesEnumerator }

constructor TFormattedLogValuesEnumerator.Create(const ALogValues: TFormattedLogValues);
begin
  inherited Create;
  FLogValues := ALogValues;
  FIndex := -1;
end;

function TFormattedLogValuesEnumerator.DoGetCurrent: TPair<string, TValue>;
begin
  Result := FCurrent;
end;

function TFormattedLogValuesEnumerator.DoMoveNext: Boolean;
begin
  if FIndex < FLogValues.Count - 1 then
  begin
    Inc(FIndex);
    FCurrent := FLogValues[FIndex];
    Result := True;
  end
  else
    Result := False;
end;

//procedure TFormattedLogValuesEnumerator.Reset;
//begin
//  FIndex := -1;
//end;

constructor TLogValuesFormatter.Create(const Format: string);
var
  Builder: TStringBuilder;
  ScanIndex, EndIndex, OpenBraceIndex, CloseBraceIndex, FormatDelimiterIndex: Integer;
  FormatSpan: string;
begin
  inherited Create;

  if Format = '' then
    raise EArgumentNilException.Create('Format não pode ser nulo');

  FOriginalFormat := Format;
  FValueNames := TList<string>.Create;

  Builder := TStringBuilder.Create(256);
  try
    ScanIndex := 0;
    EndIndex := Length(Format);

    while ScanIndex < EndIndex do
    begin
      OpenBraceIndex := FindBraceIndex(Format, '{', ScanIndex, EndIndex);
      if (ScanIndex = 0) and (OpenBraceIndex = EndIndex) then
      begin
        // Não foram encontrados marcadores
        FFormat := Format;
        Exit;
      end;

      CloseBraceIndex := FindBraceIndex(Format, '}', OpenBraceIndex, EndIndex);

      if CloseBraceIndex = EndIndex then
      begin
        Builder.Append(Copy(Format, ScanIndex, EndIndex - ScanIndex + 1));
        ScanIndex := EndIndex;
      end
      else
      begin
        // Sintaxe do item de formato: { índice[,alinhamento][ :stringFormato] }
        FormatSpan := Copy(Format, OpenBraceIndex, CloseBraceIndex - OpenBraceIndex + 1);
        FormatDelimiterIndex := Pos(',', FormatSpan);

        if FormatDelimiterIndex = 0 then
          FormatDelimiterIndex := Pos(':', FormatSpan);

        if FormatDelimiterIndex = 0 then
          FormatDelimiterIndex := CloseBraceIndex
        else
          FormatDelimiterIndex := FormatDelimiterIndex + OpenBraceIndex - 1;

        Builder.Append(Copy(Format, ScanIndex, OpenBraceIndex - ScanIndex + 1));
        Builder.Append(IntToStr(FValueNames.Count));
        FValueNames.Add(Copy(Format, OpenBraceIndex + 1, FormatDelimiterIndex - OpenBraceIndex - 1));
        Builder.Append(Copy(Format, FormatDelimiterIndex, CloseBraceIndex - FormatDelimiterIndex + 1));

        ScanIndex := CloseBraceIndex + 1;
      end;
    end;

    FFormat := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

destructor TLogValuesFormatter.Destroy;
begin
  FValueNames.Free;
  inherited;
end;

class function TLogValuesFormatter.FindBraceIndex(const Format: string; Brace: Char; StartIndex, EndIndex: Integer): Integer;
var
  BraceIndex, ScanIndex, BraceOccurrenceCount: Integer;
begin
  // Exemplo: {{prefixo{{{Argumento}}}sufixo}}.
  BraceIndex := EndIndex;
  ScanIndex := StartIndex;
  BraceOccurrenceCount := 0;

  while ScanIndex < EndIndex do
  begin
    if (BraceOccurrenceCount > 0) and (Format[ScanIndex] <> Brace) then
    begin
      if BraceOccurrenceCount mod 2 = 0 then
      begin
        // Número par de '{' ou '}' encontrados. Continue a busca com a próxima ocorrência.
        BraceOccurrenceCount := 0;
        BraceIndex := EndIndex;
      end
      else
      begin
        // Um '{' ou '}' não escapado foi encontrado.
        Break;
      end;
    end
    else if Format[ScanIndex] = Brace then
    begin
      if Brace = '}' then
      begin
        if BraceOccurrenceCount = 0 then
        begin
          // Para '}', pegue a primeira ocorrência.
          BraceIndex := ScanIndex;
        end;
      end
      else
      begin
        // Para '{', pegue a última ocorrência.
        BraceIndex := ScanIndex;
      end;

      Inc(BraceOccurrenceCount);
    end;

    Inc(ScanIndex);
  end;

  Result := BraceIndex;
end;

function TLogValuesFormatter.Format(const Values: array of TValue): string;
var
  FormattedValues: TArray<TVarRec>;
  I: Integer;
  FormatSettings: TFormatSettings;
begin
  // Sem tentar otimizar, sempre criamos um novo array para os valores formatados
  // Isso é mais seguro considerando como o TValue funciona no Delphi
  SetLength(FormattedValues, Length(Values));

  for I := 0 to High(Values) do
    FormattedValues[I] := FormatArgument(Values[I]).AsVarRec;

  FormatSettings := TFormatSettings.Invariant;

  if Length(Values) = 0 then
    Result := System.SysUtils.Format(FFormat, [], FormatSettings)
  else
    Result := System.SysUtils.Format(FFormat, FormattedValues, FormatSettings);
end;

//function TLogValuesFormatter.FormatWithOverwrite(var Values: array of TValue): string;
//var
//  I: Integer;
//  FormatSettings: TFormatSettings;
//begin
//  for I := 0 to High(Values) do
//    Values[I] := FormatArgument(Values[I]);
//
//  FormatSettings := TFormatSettings.Invariant;
//
//  if Length(Values) = 0 then
//    Result := System.SysUtils.Format(FFormat, [], FormatSettings)
//  else
//    Result := System.SysUtils.Format(FFormat, Values, FormatSettings);
//end;

function TLogValuesFormatter.Format: string;
begin
  Result := FFormat;
end;

function TLogValuesFormatter.Format(const Arg0: TValue): string;
var
  Arg0String: TValue;
  FormatSettings: TFormatSettings;
begin
  FormatSettings := TFormatSettings.Invariant;

  if not TryFormatArgumentIfNullOrEnumerable(Arg0, Arg0String) then
    Result := System.SysUtils.Format(FFormat, Arg0.AsVarRec, FormatSettings)
  else
    Result := System.SysUtils.Format(FFormat, Arg0String.AsVarRec, FormatSettings);
end;

function TLogValuesFormatter.Format(const Arg0, Arg1: TValue): string;
var
  Arg0String, Arg1String: TValue;
  HasArg0String, HasArg1String: Boolean;
  Args: array[0..1] of TVarRec;
  FormatSettings: TFormatSettings;
begin
  FormatSettings := TFormatSettings.Invariant;

  HasArg0String := TryFormatArgumentIfNullOrEnumerable(Arg0, Arg0String);
  HasArg1String := TryFormatArgumentIfNullOrEnumerable(Arg1, Arg1String);

  if HasArg0String or HasArg1String then
  begin
    Args[0] := TLogicalUtils.IfThen(HasArg0String, Arg0String, Arg0).AsVarRec;
    Args[1] := TLogicalUtils.IfThen(HasArg1String, Arg1String, Arg1).AsVarRec;
    Result := System.SysUtils.Format(FFormat, Args, FormatSettings);
  end
  else
  begin
    Args[0] := Arg0.AsVarRec;
    Args[1] := Arg1.AsVarRec;
    Result := System.SysUtils.Format(FFormat, Args, FormatSettings);
  end;
end;

function TLogValuesFormatter.Format(const Arg0, Arg1, Arg2: TValue): string;
var
  Arg0String, Arg1String, Arg2String: TValue;
  HasArg0String, HasArg1String, HasArg2String: Boolean;
  Args: array[0..2] of TVarRec;
  FormatSettings: TFormatSettings;
begin
  FormatSettings := TFormatSettings.Invariant;

  HasArg0String := TryFormatArgumentIfNullOrEnumerable(Arg0, Arg0String);
  HasArg1String := TryFormatArgumentIfNullOrEnumerable(Arg1, Arg1String);
  HasArg2String := TryFormatArgumentIfNullOrEnumerable(Arg2, Arg2String);

  if HasArg0String or HasArg1String or HasArg2String then
  begin
    Args[0] := TLogicalUtils.IfThen(HasArg0String, Arg0String, Arg0).AsVarRec;
    Args[1] := TLogicalUtils.IfThen(HasArg1String, Arg1String, Arg1).AsVarRec;
    Args[2] := TLogicalUtils.IfThen(HasArg2String, Arg2String, Arg2).AsVarRec;

    Result := System.SysUtils.Format(FFormat, Args, FormatSettings);
  end
  else
  begin
    Args[0] := Arg0.AsVarRec;
    Args[1] := Arg1.AsVarRec;
    Args[2] := Arg2.AsVarRec;

    Result := System.SysUtils.Format(FFormat, Args, FormatSettings);
  end;
end;

function TLogValuesFormatter.GetValue(const Values: array of TValue; Index: Integer): TPair<string, TValue>;
begin
  if (Index < 0) or (Index > FValueNames.Count) then
    raise EArgumentOutOfRangeException.Create('índice');

  if FValueNames.Count > Index then
    Result := TPair<string, TValue>.Create(FValueNames[Index], Values[Index])
  else
    Result := TPair<string, TValue>.Create('{OriginalFormat}', OriginalFormat);
end;

function TLogValuesFormatter.GetValues(const Values: array of TValue): TArray<TPair<string, TValue>>;
var
  I: Integer;
begin
  SetLength(Result, Length(Values) + 1);

  for I := 0 to FValueNames.Count - 1 do
    Result[I] := TPair<string, TValue>.Create(FValueNames[I], Values[I]);

  Result[High(Result)] := TPair<string, TValue>.Create('{OriginalFormat}', OriginalFormat);
end;

class function TLogValuesFormatter.FormatArgument(const Value: TValue): TValue;
var
  StringValue: TValue;
begin
  if TryFormatArgumentIfNullOrEnumerable(Value, StringValue) then
    Result := StringValue
  else
    Result := Value;
end;

class function TLogValuesFormatter.TryFormatArgumentIfNullOrEnumerable(const Value: TValue; out StringValue: TValue): Boolean;
var
  Builder: TStringBuilder;
  First: Boolean;
  EnumObject: TObject;
  Enumerator: IEnumerator;
  CurrentValue: TValue;
begin
  if Value.IsEmpty then
  begin
    StringValue := NullValue;
    Result := True;
    Exit;
  end;

  // Se o valor não é uma string, mas implementa IEnumerable
  if not Value.IsType<string> and Value.IsObject then
  begin
    raise ENotImplemented.Create('Ainda não fiz isso aqui abaixo');
//    EnumObject := Value.AsObject;
//
//    if (EnumObject <> nil) and
//       ((EnumObject.ClassName.StartsWith('TEnumerable<') or
//        (Supports(EnumObject, System.IEnumerable) and not (EnumObject is TStrings))) then
//    begin
//      Builder := TStringBuilder.Create(256);
//      try
//        First := True;
//
//        if Supports(EnumObject, IEnumerable) then
//          Enumerator := (EnumObject as IEnumerable).GetEnumerator
//        else
//          Enumerator := (EnumObject as TEnumerable).GetEnumerator;
//
//        while Enumerator.MoveNext do
//        begin
//          if not First then
//            Builder.Append(', ');
//
//          CurrentValue := TValue.FromVariant(Enumerator.Current);
//
//          if CurrentValue.IsEmpty then
//            Builder.Append(NullValue)
//          else
//            Builder.Append(CurrentValue.ToString);
//
//          First := False;
//        end;
//
//        StringValue := Builder.ToString;
//        Result := True;
//      finally
//        Builder.Free;
//      end;
//      Exit;
//    end;
  end;

  StringValue := TValue.Empty;
  Result := False;
end;

{ TLoggerExtensions }

class constructor TLoggerExtensions.Create;
begin
  FMessageFormatter := TLoggerExtensions.MessageFormatter;
end;

// Implementação dos métodos LogDebug

class procedure TLoggerExtensions.LogDebug(const Logger: ILogger; const EventId: TEventId;
  const Exception: Exception; const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Debug, EventId, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogDebug(const Logger: ILogger; const EventId: TEventId;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Debug, EventId, Message, Args);
end;

class procedure TLoggerExtensions.LogDebug(const Logger: ILogger; const Exception: Exception;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Debug, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogDebug(const Logger: ILogger; const Message: string;
  const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Debug, Message, Args);
end;

// Implementação dos métodos LogTrace

class procedure TLoggerExtensions.LogTrace(const Logger: ILogger; const EventId: TEventId;
  const Exception: Exception; const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Trace, EventId, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogTrace(const Logger: ILogger; const EventId: TEventId;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Trace, EventId, Message, Args);
end;

class procedure TLoggerExtensions.LogTrace(const Logger: ILogger; const Exception: Exception;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Trace, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogTrace(const Logger: ILogger; const Message: string;
  const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Trace, Message, Args);
end;

// Implementação dos métodos LogInformation

class procedure TLoggerExtensions.LogInformation(const Logger: ILogger; const EventId: TEventId;
  const Exception: Exception; const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Information, EventId, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogInformation(const Logger: ILogger; const EventId: TEventId;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Information, EventId, Message, Args);
end;

class procedure TLoggerExtensions.LogInformation(const Logger: ILogger; const Exception: Exception;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Information, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogInformation(const Logger: ILogger; const Message: string;
  const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Information, Message, Args);
end;

// Implementação dos métodos LogWarning

class procedure TLoggerExtensions.LogWarning(const Logger: ILogger; const EventId: TEventId;
  const Exception: Exception; const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Warning, EventId, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogWarning(const Logger: ILogger; const EventId: TEventId;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Warning, EventId, Message, Args);
end;

class procedure TLoggerExtensions.LogWarning(const Logger: ILogger; const Exception: Exception;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Warning, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogWarning(const Logger: ILogger; const Message: string;
  const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Warning, Message, Args);
end;

// Implementação dos métodos LogError

class procedure TLoggerExtensions.LogError(const Logger: ILogger; const EventId: TEventId;
  const Exception: Exception; const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Error, EventId, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogError(const Logger: ILogger; const EventId: TEventId;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Error, EventId, Message, Args);
end;

class procedure TLoggerExtensions.LogError(const Logger: ILogger; const Exception: Exception;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Error, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogError(const Logger: ILogger; const Message: string;
  const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Error, Message, Args);
end;

// Implementação dos métodos LogCritical

class procedure TLoggerExtensions.LogCritical(const Logger: ILogger; const EventId: TEventId;
  const Exception: Exception; const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Critical, EventId, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogCritical(const Logger: ILogger; const EventId: TEventId;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Critical, EventId, Message, Args);
end;

class procedure TLoggerExtensions.LogCritical(const Logger: ILogger; const Exception: Exception;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Critical, Exception, Message, Args);
end;

class procedure TLoggerExtensions.LogCritical(const Logger: ILogger; const Message: string;
  const Args: array of TValue);
begin
  Log(Logger, TLogLevel.Critical, Message, Args);
end;

// Implementação dos métodos Log

class procedure TLoggerExtensions.Log(const Logger: ILogger; const LogLevel: TLogLevel;
  const Message: string; const Args: array of TValue);
begin
  Log(Logger, LogLevel, TEventId.Create(0), nil, Message, Args);
end;

class procedure TLoggerExtensions.Log(const Logger: ILogger; const LogLevel: TLogLevel;
  const EventId: TEventId; const Message: string; const Args: array of TValue);
begin
  Log(Logger, LogLevel, EventId, nil, Message, Args);
end;

class procedure TLoggerExtensions.Log(const Logger: ILogger; const LogLevel: TLogLevel;
  const Exception: Exception; const Message: string; const Args: array of TValue);
begin
  Log(Logger, LogLevel, TEventId.Create(0), Exception, Message, Args);
end;

class procedure TLoggerExtensions.Log(const Logger: ILogger; const LogLevel: TLogLevel;
  const EventId: TEventId; const Exception: Exception; const Message: string;
  const Args: array of TValue);
var
  FormattedValues: TFormattedLogValues;
begin
  if Logger = nil then
    raise EArgumentNilException.Create('Logger não pode ser nulo');

  FormattedValues := TFormattedLogValues.Create(Message, Args);
  raise ENotImplemented.Create('Ainda não fiz isso aqui abaixo');
  // Logger.Log<TFormattedLogValues>(LogLevel, EventId, FormattedValues, Exception, FMessageFormatter);
end;

// Implementação de BeginScope

class function TLoggerExtensions.BeginScope(const Logger: ILogger;
  const MessageFormat: string; const Args: array of TValue): ILogScopeDispose;
begin
  if Logger = nil then
    raise EArgumentNilException.Create('Logger não pode ser nulo');

  raise ENotImplemented.Create('Ainda não fiz isso aqui abaixo');
//  Result := Logger.BeginScope<TFormattedLogValues>(TFormattedLogValues.Create(MessageFormat, Args));
end;

// Implementação do MessageFormatter
class function TLoggerExtensions.MessageFormatter(const State: TFormattedLogValues; const Error: Exception): string;
begin
  Result := State.ToString;
end;

constructor TLoggerFilterRule.Create(const ProviderName: string;
  const CategoryName: string; LogLevel: TLogLevel; HasLogLevel: Boolean;
  Filter: TFunc<string, string, TLogLevel, Boolean>);
begin
  inherited Create;

  FProviderName := ProviderName;
  FCategoryName := CategoryName;
  FLogLevel := LogLevel;
  FHasLogLevel := HasLogLevel;
  FFilter := Filter;
end;

function TLoggerFilterRule.ToString: string;
var
  FilterText: string;
begin
  if Assigned(FFilter) then
    FilterText := '(TODO: IMPLEMENTAR ESSE VALOR VIA RTTI)'
  else
    FilterText := 'nil';

  Result := Format('%s: ''%s'', %s: ''%s'', %s: ''%s'', %s: ''%s''',
    ['ProviderName', FProviderName,
     'CategoryName', FCategoryName,
     'LogLevel', TLogicalUtils.IfThen(FHasLogLevel, GetEnumName(TypeInfo(TLogLevel), Ord(FLogLevel)), 'null'),
     'Filter', FilterText]);
end;

constructor TLoggerFilterOptions.Create;
begin
  inherited Create;
  FCaptureScopes := True;
  FMinLevel := TLogLevel.None;
  FRulesInternal := TList<TLoggerFilterRule>.Create;
end;

destructor TLoggerFilterOptions.Destroy;
begin
  FRulesInternal.Free;
  inherited Destroy;
end;

function TLoggerFilterOptions.GetRules: TList<TLoggerFilterRule>;
begin
  Result := FRulesInternal;
end;

function TLoggerFilterOptions.DebuggerToString: string;
var
  DebugText: string;
begin
  if FMinLevel <> TLogLevel.None then
  begin
    DebugText := Format('MinLevel = %s', [GetEnumName(TypeInfo(TLogLevel), Ord(FMinLevel))]);
  end
  else
  begin
    // Exibe "Enabled = false". Isso deixa claro que o ILogger inteiro
    // está desativado e nada é escrito.
    //
    // Se "MinLevel = None" fosse exibido, alguém poderia pensar que o
    // nível mínimo está desativado e tudo é escrito.
    DebugText := 'Enabled = false';
  end;

  if FRulesInternal.Count > 0 then
  begin
    DebugText := DebugText + Format(', Rules = %d', [FRulesInternal.Count]);
  end;

  Result := DebugText;
end;

constructor TLoggerFactoryOptions.Create;
begin
  inherited Create;
  FActivityTrackingOptions := ATONone; // Padrão para conjunto vazio
end;

end.
