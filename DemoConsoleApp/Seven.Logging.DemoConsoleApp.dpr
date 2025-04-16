program Seven.Logging.DemoConsoleApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Seven.Logging.DemoConsoleApp.Main in 'Seven.Logging.DemoConsoleApp.Main.pas',
  Seven.Logging.Impl in '..\src\Seven.Logging.Impl.pas',
  Seven.Logging.LogLevels in '..\src\Seven.Logging.LogLevels.pas',
  Seven.Logging in '..\src\Seven.Logging.pas',
  Seven.Logging.Queue in '..\src\Seven.Logging.Queue.pas',
  Seven.Logging.Targets in '..\src\Seven.Logging.Targets.pas',
  Seven.Logging.FileLogger in '..\src\Seven.Logging.FileLogger.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
