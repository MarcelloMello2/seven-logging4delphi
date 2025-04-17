program Seven.Logging.DemoConsoleApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  Seven.Logging.Types in '..\src\Seven.Logging.Types.pas',
  Seven.Logging.DemoConsoleApp.Main in 'Seven.Logging.DemoConsoleApp.Main.pas',
  Seven.Logging.Logger in '..\src\Seven.Logging.Logger.pas';

begin
  try
    TDemoConsoleApp.Run();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
