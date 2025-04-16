unit Seven.Logging.DemoConsoleApp.Main;

interface

uses
  System.Generics.Collections,
  Seven.Logging,
  Seven.Logging.Queue,
  Seven.Logging.Targets,
  Seven.Logging.Impl;

type
  TMyService = class
  end;

procedure Run;

implementation

procedure Run;
var
  Queue: TLogQueue;
  WriterThread: TLogWriterThread;
  Logger: ILogger;
  Scope: ILogScope;
  Targets: TList<ILogTarget>;
begin
  Queue := TLogQueue.Create;
  Targets := TList<ILogTarget>.Create;
  try
    Targets.Add(TConsoleTarget.Create);
    Targets.Add(TFileTarget.Create('log.txt'));
    Targets.Add(TXmlFileTarget.Create('log.xml'));
    WriterThread := TLogWriterThread.Create(Queue, Targets);
    Logger := TLoggerFactory.CreateLogger<TMyService>(Queue);

    Logger.Log(TLogLevel.Info, 'Início da operação');

    Scope := Logger.BeginScope('OperacaoCritica');
    try
      Logger.Log(TLogLevel.Debug, 'Fazendo algo importante');
    finally
      Scope.EndScope;
    end;

    Logger.Log(TLogLevel.Info, 'Fim da operação');

    WriterThread.Terminate;
    Queue.FEvent.SetEvent;
    WriterThread.WaitFor;
    WriterThread.Free;
  finally
    Queue.Free;
  end;
end;

end.
