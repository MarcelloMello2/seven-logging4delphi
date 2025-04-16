unit Seven.Logging.DemoConsoleApp.Main;

interface

uses
  Seven.Logging, Seven.Logging.Queue, Seven.Logging.Targets, Seven.Logging.Impl, System.Generics.Collections;

type

  TMyService = class
  end;

  TDemoConsoleApp = class sealed
    class procedure Run(); static;
  end;


implementation

uses
  System.SysUtils;

class procedure TDemoConsoleApp.Run();
var
  Queue: TLogQueue;
  Targets: TList<ILogTarget>;
  WriterThread: TLogWriterThread;
  Logger: ILogger;
  Scope: ILogScope;
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
      // Simulate an exception
      try
        raise Exception.Create('Test exception');
      except
        on E: Exception do
          Logger.Log(TLogLevel.Error, 'Erro na operação', E);
      end;
    finally
      Scope := nil; // End scope
    end;

    Logger.Log(TLogLevel.Info, 'Fim da operação');

    // Wait a bit to ensure logs are written
    Sleep(100);
  finally
    WriterThread.Terminate;
//    Queue.FEvent.SetEvent;
    WriterThread.WaitFor;
    WriterThread.Free;
    Queue.Free;
  end;
end;

end.
