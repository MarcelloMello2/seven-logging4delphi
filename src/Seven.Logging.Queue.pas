unit Seven.Logging.Queue;

{$SCOPEDENUMS ON}

interface

uses
  System.Classes, System.Generics.Collections, Seven.Logging, System.SyncObjs;

type
  TLogQueue = class
  private
    FQueue: TThreadedQueue<TLogMessage>;
//    FEvent: TEvent;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ShutDown();
    procedure Enqueue(const Msg: TLogMessage);
    function Dequeue(out Msg: TLogMessage): Boolean;
  end;

  TLogWriterThread = class(TThread)
  private
    FQueue: TLogQueue;
    FTargets: TList<ILogTarget>;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;
  public
    constructor Create(Queue: TLogQueue; Targets: TList<ILogTarget>);
    destructor Destroy; override;
  end;

implementation

{ TLogQueue }

constructor TLogQueue.Create;
begin
  FQueue := TThreadedQueue<TLogMessage>.Create(1000);
//  FEvent := TEvent.Create;
end;

destructor TLogQueue.Destroy;
begin
  FQueue.Free;
//  FEvent.Free;
  inherited;
end;

procedure TLogQueue.ShutDown;
begin
  FQueue.DoShutDown();
end;

procedure TLogQueue.Enqueue(const Msg: TLogMessage);
begin
  FQueue.PushItem(Msg);
//  FEvent.SetEvent;
end;

function TLogQueue.Dequeue(out Msg: TLogMessage): Boolean;
begin
  Result := FQueue.PopItem(Msg) = wrSignaled;
end;

{ TLogWriterThread }

constructor TLogWriterThread.Create(Queue: TLogQueue; Targets: TList<ILogTarget>);
begin
  inherited Create(False);
  FQueue := Queue;
  FTargets := Targets;
  Priority := tpLower;
end;

destructor TLogWriterThread.Destroy;
begin
  FTargets.Free;
  inherited;
end;

procedure TLogWriterThread.Execute;
var
  Msg: TLogMessage;
  Target: ILogTarget;
begin
  while not Terminated do
  begin
    if FQueue.Dequeue(Msg) then
    begin
      for Target in FTargets do
        Target.WriteLog(Msg);
    end
    else
    begin
//      FQueue.FEvent.WaitFor();
    end;
  end;
end;

procedure TLogWriterThread.TerminatedSet;
begin
  inherited;
  FQueue.ShutDown();
end;

end.