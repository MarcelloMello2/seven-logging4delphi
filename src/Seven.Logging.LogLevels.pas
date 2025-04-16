unit Seven.Logging.LogLevels;

{$SCOPEDENUMS ON}

interface

type

  /// <summary>
  /// Define os n�veis de severidade de log.
  /// </summary>
  TLogLevel = (
    /// <summary>
    /// Logs que cont�m as mensagens mais detalhadas. Essas mensagens podem conter dados sens�veis
    /// da aplica��o. Essas mensagens est�o desativadas por padr�o e nunca devem ser habilitadas
    /// em ambiente de produ��o.
    /// </summary>
    Trace,

    /// <summary>
    /// Logs usados para investiga��o interativa durante o desenvolvimento. Esses logs devem conter
    /// principalmente informa��es �teis para depura��o e n�o t�m valor a longo prazo.
    /// </summary>
    Debug,

    /// <summary>
    /// Logs que acompanham o fluxo geral da aplica��o. Esses logs devem ter valor a longo prazo.
    /// </summary>
    Info,

    /// <summary>
    /// Logs que destacam um evento anormal ou inesperado no fluxo da aplica��o, mas que n�o fazem
    /// com que a execu��o da aplica��o seja interrompida.
    /// </summary>
    Warning,

    /// <summary>
    /// Logs que destacam quando o fluxo de execu��o atual � interrompido devido a uma falha. Devem
    /// indicar uma falha na atividade atual, n�o uma falha em toda a aplica��o.
    /// </summary>
    Error,

    /// <summary>
    /// Logs que descrevem um travamento n�o recuper�vel da aplica��o ou do sistema, ou uma falha
    /// catastr�fica que requer aten��o imediata.
    /// </summary>
    Fatal,

    /// <summary>
    /// N�o � usado para escrever mensagens de log. Especifica que uma categoria de log n�o deve
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
