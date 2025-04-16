program Seven.Logging.DemoConsoleApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  Seven.Logging.DemoConsoleApp.Main in 'Seven.Logging.DemoConsoleApp.Main.pas',
  Seven.Logging.Impl in '..\src\Seven.Logging.Impl.pas',
  Seven.Logging.LogLevels in '..\src\Seven.Logging.LogLevels.pas',
  Seven.Logging in '..\src\Seven.Logging.pas',
  Seven.Logging.Queue in '..\src\Seven.Logging.Queue.pas',
  Seven.Logging.Targets in '..\src\Seven.Logging.Targets.pas';

begin
  try
    TDemoConsoleApp.Run();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
