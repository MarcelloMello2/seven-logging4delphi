unit Seven.Logging.LogLevels;

{$SCOPEDENUMS ON}

interface

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
    Info,

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
    Fatal,

    /// <summary>
    /// Não é usado para escrever mensagens de log. Especifica que uma categoria de log não deve
    /// registrar nenhuma mensagem.
    /// </summary>
    None
  );


function LogLevelToString(Level: TLogLevel): string;

implementation

function LogLevelToString(Level: TLogLevel): string;
begin
  case Level of
    TLogLevel.Trace: Result := 'TRACE';
    TLogLevel.Debug: Result := 'DEBUG';
    TLogLevel.Info: Result := 'INFO';
    TLogLevel.Warning: Result := 'WARNING';
    TLogLevel.Error: Result := 'ERROR';
    TLogLevel.Fatal: Result := 'FATAL';
    TLogLevel.None: Result := 'NONE';
  else
    Result := 'UNKNOWN';
  end;
end;

end.
