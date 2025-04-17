unit Seven.Logging.Targets;

{$SCOPEDENUMS ON}

interface

uses
  Seven.Logging, System.Classes, System.IOUtils, System.Generics.Collections, System.JSON;

type
  TConsoleTarget = class(TInterfacedObject, ILogTarget)
  private
    FMinLevel: TLogLevel;
    FCategoryMinLevels: TDictionary<string, TLogLevel>;
  public
    constructor Create(MinLevel: TLogLevel = TLogLevel.Trace);
    destructor Destroy; override;
    procedure AddCategoryMinLevel(const Category: string; MinLevel: TLogLevel);
    procedure WriteLog(const Msg: TLogMessage);
  end;

  TFileTarget = class(TInterfacedObject, ILogTarget)
  private
    FFileName: string;
    FMinLevel: TLogLevel;
    FMaxSize: Int64;
    FCategoryMinLevels: TDictionary<string, TLogLevel>;
    procedure RotateFile;
  public
    constructor Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
    destructor Destroy; override;
    procedure AddCategoryMinLevel(const Category: string; MinLevel: TLogLevel);
    procedure WriteLog(const Msg: TLogMessage);
  end;

  TXmlFileTarget = class(TInterfacedObject, ILogTarget)
  private
    FFileName: string;
    FMinLevel: TLogLevel;
    FMaxSize: Int64;
    FCategoryMinLevels: TDictionary<string, TLogLevel>;
    procedure RotateFile;
  public
    constructor Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
    destructor Destroy; override;
    procedure AddCategoryMinLevel(const Category: string; MinLevel: TLogLevel);
    procedure WriteLog(const Msg: TLogMessage);
  end;

  TJsonFileTarget = class(TInterfacedObject, ILogTarget)
  private
    FFileName: string;
    FMinLevel: TLogLevel;
    FMaxSize: Int64;
    FCategoryMinLevels: TDictionary<string, TLogLevel>;
    FStreamWriter: TStreamWriter;
    procedure RotateFile;
    function ShouldLog(const Msg: TLogMessage): Boolean;
  public
    constructor Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
    destructor Destroy; override;
    procedure AddCategoryMinLevel(const Category: string; MinLevel: TLogLevel);
    procedure WriteLog(const Msg: TLogMessage);
  end;

implementation

uses
  System.SysUtils,
  Seven.Logging.LogLevels;

{ TConsoleTarget }

constructor TConsoleTarget.Create(MinLevel: TLogLevel = TLogLevel.Trace);
begin
  FMinLevel := MinLevel;
  FCategoryMinLevels := TDictionary<string, TLogLevel>.Create;
end;

destructor TConsoleTarget.Destroy;
begin
  FCategoryMinLevels.Free;
  inherited;
end;

procedure TConsoleTarget.AddCategoryMinLevel(const Category: string; MinLevel: TLogLevel);
begin
  FCategoryMinLevels.AddOrSetValue(Category, MinLevel);
end;

procedure TConsoleTarget.WriteLog(const Msg: TLogMessage);
var
  EffectiveMinLevel: TLogLevel;
  LogLine: string;
begin
  if FCategoryMinLevels.TryGetValue(Msg.Category, EffectiveMinLevel) then
  begin
    if Ord(Msg.Level) < Ord(EffectiveMinLevel) then
      Exit;
  end
  else
  begin
    if Ord(Msg.Level) < Ord(FMinLevel) then
      Exit;
  end;
  LogLine := '';
  if Msg.EventId.Id <> 0 then
    LogLine := Format('[EventId: %d - %s] ', [Msg.EventId.Id, Msg.EventId.Name]);
  if Msg.Scope <> '' then
    LogLine := LogLine + Format('[%s] %s [%s] (%s): %s', [
      DateTimeToStr(Msg.Timestamp),
      Msg.Category,
      LogLevelToString(Msg.Level),
      Msg.Scope,
      Msg.Message
    ])
  else
    LogLine := LogLine + Format('[%s] %s [%s]: %s', [
      DateTimeToStr(Msg.Timestamp),
      Msg.Category,
      LogLevelToString(Msg.Level),
      Msg.Message
    ]);
  if Msg.ExceptionMessage <> '' then
    LogLine := LogLine + ' - Exception: ' + Msg.ExceptionMessage;
  WriteLn(LogLine);
end;

{ TFileTarget }

constructor TFileTarget.Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
begin
  FFileName := FileName;
  FMinLevel := MinLevel;
  FMaxSize := MaxSize;
  FCategoryMinLevels := TDictionary<string, TLogLevel>.Create;
end;

destructor TFileTarget.Destroy;
begin
  FCategoryMinLevels.Free;
  inherited;
end;

procedure TFileTarget.AddCategoryMinLevel(const Category: string; MinLevel: TLogLevel);
begin
  FCategoryMinLevels.AddOrSetValue(Category, MinLevel);
end;

procedure TFileTarget.RotateFile;
var
  NewName: string;
begin
  NewName := ChangeFileExt(FFileName, '') + '_' + FormatDateTime('yyyymmdd_hhnnss', Now) + ExtractFileExt(FFileName);
  TFile.Move(FFileName, NewName);
end;

procedure TFileTarget.WriteLog(const Msg: TLogMessage);
var
  EffectiveMinLevel: TLogLevel;
  LogLine: string;
begin
  if FCategoryMinLevels.TryGetValue(Msg.Category, EffectiveMinLevel) then
  begin
    if Ord(Msg.Level) < Ord(EffectiveMinLevel) then
      Exit;
  end
  else
  begin
    if Ord(Msg.Level) < Ord(FMinLevel) then
      Exit;
  end;
  if (FMaxSize > 0) and TFile.Exists(FFileName) and (TFile.GetSize(FFileName) >= FMaxSize) then
    RotateFile;
  LogLine := '';
  if Msg.EventId.Id <> 0 then
    LogLine := Format('[EventId: %d - %s] ', [Msg.EventId.Id, Msg.EventId.Name]);
  if Msg.Scope <> '' then
    LogLine := LogLine + Format('[%s] %s [%s] (%s): %s', [
      DateTimeToStr(Msg.Timestamp),
      Msg.Category,
      LogLevelToString(Msg.Level),
      Msg.Scope,
      Msg.Message
    ])
  else
    LogLine := LogLine + Format('[%s] %s [%s]: %s', [
      DateTimeToStr(Msg.Timestamp),
      Msg.Category,
      LogLevelToString(Msg.Level),
      Msg.Message
    ]);
  if Msg.ExceptionMessage <> '' then
    LogLine := LogLine + ' - Exception: ' + Msg.ExceptionMessage;
  TFile.AppendAllText(FFileName, LogLine + sLineBreak);
end;

{ TXmlFileTarget }

constructor TXmlFileTarget.Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
begin
  FFileName := FileName;
  FMinLevel := MinLevel;
  FMaxSize := MaxSize;
  FCategoryMinLevels := TDictionary<string, TLogLevel>.Create;
end;

destructor TXmlFileTarget.Destroy;
begin
  FCategoryMinLevels.Free;
  inherited;
end;

procedure TXmlFileTarget.AddCategoryMinLevel(const Category: string; MinLevel: TLogLevel);
begin
  FCategoryMinLevels.AddOrSetValue(Category, MinLevel);
end;

procedure TXmlFileTarget.RotateFile;
var
  NewName: string;
begin
  NewName := ChangeFileExt(FFileName, '') + '_' + FormatDateTime('yyyymmdd_hhnnss', Now) + ExtractFileExt(FFileName);
  TFile.Move(FFileName, NewName);
end;

procedure TXmlFileTarget.WriteLog(const Msg: TLogMessage);
var
  EffectiveMinLevel: TLogLevel;
  XmlLine: string;
begin
  if FCategoryMinLevels.TryGetValue(Msg.Category, EffectiveMinLevel) then
  begin
    if Ord(Msg.Level) < Ord(EffectiveMinLevel) then
      Exit;
  end
  else
  begin
    if Ord(Msg.Level) < Ord(FMinLevel) then
      Exit;
  end;
  if (FMaxSize > 0) and TFile.Exists(FFileName) and (TFile.GetSize(FFileName) >= FMaxSize) then
    RotateFile;
  if Msg.ExceptionMessage <> '' then
    if Msg.EventId.Id <> 0 then
      if Msg.Scope <> '' then
        XmlLine := Format('<log timestamp="%s" category="%s" level="%s" scope="%s" eventId="%d" eventName="%s" exception="%s">%s</log>',
          [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '"', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Scope, '"', '"', [rfReplaceAll]), Msg.EventId.Id, StringReplace(Msg.EventId.Name, '"', '"', [rfReplaceAll]), StringReplace(Msg.ExceptionMessage, '"', '"', [rfReplaceAll]), StringReplace(Msg.Message, '"', '"', [rfReplaceAll])])
      else
        XmlLine := Format('<log timestamp="%s" category="%s" level="%s" eventId="%d" eventName="%s" exception="%s">%s</log>',
          [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '"', [rfReplaceAll]), LogLevelToString(Msg.Level), Msg.EventId.Id, StringReplace(Msg.EventId.Name, '"', '"', [rfReplaceAll]), StringReplace(Msg.ExceptionMessage, '"', '"', [rfReplaceAll]), StringReplace(Msg.Message, '"', '"', [rfReplaceAll])])
    else
      if Msg.Scope <> '' then
        XmlLine := Format('<log timestamp="%s" category="%s" level="%s" scope="%s" exception="%s">%s</log>',
          [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '"', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Scope, '"', '"', [rfReplaceAll]), StringReplace(Msg.ExceptionMessage, '"', '"', [rfReplaceAll]), StringReplace(Msg.Message, '"', '"', [rfReplaceAll])])
      else
        XmlLine := Format('<log timestamp="%s" category="%s" level="%s" exception="%s">%s</log>',
          [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '"', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.ExceptionMessage, '"', '"', [rfReplaceAll]), StringReplace(Msg.Message, '"', '"', [rfReplaceAll])])
  else
    if Msg.EventId.Id <> 0 then
      if Msg.Scope <> '' then
        XmlLine := Format('<log timestamp="%s" category="%s" level="%s" scope="%s" eventId="%d" eventName="%s">%s</log>',
          [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '"', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Scope, '"', '"', [rfReplaceAll]), Msg.EventId.Id, StringReplace(Msg.EventId.Name, '"', '"', [rfReplaceAll]), StringReplace(Msg.Message, '"', '"', [rfReplaceAll])])
      else
        XmlLine := Format('<log timestamp="%s" category="%s" level="%s" eventId="%d" eventName="%s">%s</log>',
          [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '"', [rfReplaceAll]), LogLevelToString(Msg.Level), Msg.EventId.Id, StringReplace(Msg.EventId.Name, '"', '"', [rfReplaceAll]), StringReplace(Msg.Message, '"', '"', [rfReplaceAll])])
    else
      if Msg.Scope <> '' then
        XmlLine := Format('<log timestamp="%s" category="%s" level="%s" scope="%s">%s</log>',
          [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '"', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Scope, '"', '"', [rfReplaceAll]), StringReplace(Msg.Message, '"', '"', [rfReplaceAll])])
      else
        XmlLine := Format('<log timestamp="%s" category="%s" level="%s">%s</log>',
          [DateTimeToStr(Msg.Timestamp), StringReplace(Msg.Category, '"', '"', [rfReplaceAll]), LogLevelToString(Msg.Level), StringReplace(Msg.Message, '"', '"', [rfReplaceAll])]);
  TFile.AppendAllText(FFileName, XmlLine + sLineBreak);
end;

{ TJsonFileTarget }

constructor TJsonFileTarget.Create(const FileName: string; MinLevel: TLogLevel = TLogLevel.Trace; MaxSize: Int64 = 0);
begin
  FFileName := FileName;
  FMinLevel := MinLevel;
  FMaxSize := MaxSize;
  FCategoryMinLevels := TDictionary<string, TLogLevel>.Create;
  FStreamWriter := TStreamWriter.Create(FFileName, True); // Append mode
end;

destructor TJsonFileTarget.Destroy;
begin
  FCategoryMinLevels.Free;
  if Assigned(FStreamWriter) then
    FStreamWriter.Free;
  inherited;
end;

procedure TJsonFileTarget.AddCategoryMinLevel(const Category: string; MinLevel: TLogLevel);
begin
  FCategoryMinLevels.AddOrSetValue(Category, MinLevel);
end;

function TJsonFileTarget.ShouldLog(const Msg: TLogMessage): Boolean;
var
  EffectiveMinLevel: TLogLevel;
begin
  if FCategoryMinLevels.TryGetValue(Msg.Category, EffectiveMinLevel) then
    Result := Ord(Msg.Level) >= Ord(EffectiveMinLevel)
  else
    Result := Ord(Msg.Level) >= Ord(FMinLevel);
end;

procedure TJsonFileTarget.RotateFile;
var
  NewName: string;
begin
  if Assigned(FStreamWriter) then
  begin
    FStreamWriter.Close;
    FStreamWriter.Free;
    FStreamWriter := nil;
  end;
  NewName := ChangeFileExt(FFileName, '') + '_' + FormatDateTime('yyyymmdd_hhnnss', Now) + ExtractFileExt(FFileName);
  TFile.Move(FFileName, NewName);
  FStreamWriter := TStreamWriter.Create(FFileName, True);
end;

procedure TJsonFileTarget.WriteLog(const Msg: TLogMessage);
var
  Json: TJSONObject;
  EventIdObj: TJSONObject;
begin
  if not ShouldLog(Msg) then
    Exit;
  if (FMaxSize > 0) and TFile.Exists(FFileName) and (TFile.GetSize(FFileName) >= FMaxSize) then
    RotateFile;
  Json := TJSONObject.Create;
  try
    Json.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Msg.Timestamp));
    Json.AddPair('category', Msg.Category);
    Json.AddPair('level', LogLevelToString(Msg.Level));
    Json.AddPair('message', Msg.Message);
    if Msg.Scope <> '' then
      Json.AddPair('scope', Msg.Scope);
    if Msg.EventId.Id <> 0 then
    begin
      EventIdObj := TJSONObject.Create;
      EventIdObj.AddPair('id', TJSONNumber.Create(Msg.EventId.Id));
      EventIdObj.AddPair('name', Msg.EventId.Name);
      Json.AddPair('eventId', EventIdObj);
    end;
    if Msg.ExceptionMessage <> '' then
      Json.AddPair('exception', Msg.ExceptionMessage)
    else
      Json.AddPair('exception', TJSONNull.Create);
    FStreamWriter.WriteLine(Json.ToString);
  finally
    Json.Free;
  end;
end;

end.
