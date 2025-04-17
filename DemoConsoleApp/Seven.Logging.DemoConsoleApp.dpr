program Seven.Logging.DemoConsoleApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  Seven.Logging in '..\src\Seven.Logging.pas',
  Seven.Logging.DemoConsoleApp.Main in 'Seven.Logging.DemoConsoleApp.Main.pas';

begin
  try
    TDemoConsoleApp.Run();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
