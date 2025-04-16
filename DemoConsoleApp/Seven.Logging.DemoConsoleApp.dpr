program Seven.Logging.DemoConsoleApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Seven.Logging.LogLevels in '..\src\Seven.Logging.LogLevels.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
