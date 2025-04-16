unit Seven.Logging.Queue;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  Seven.Logging,
  Seven.Logging.Targets;

type
  TLogQueue = class
  private
    FQueue: TThreadedQueue<TLogMessage>;
  public
    FEvent: TEvent;
    constructor Create;
    destructor Destroy; override;
    procedure Enqueue(const Msg: TLogMessage);
    function Dequeue(out Msg: TLogMessage): Boolean;
  end;

  TLogWriterThread = class(TThread)
  private
    FQueue: TLogQueue;
    FTargets: TList<ILogTarget>;
  protected
    procedure Execute; override;
  public
    constructor Create(Queue: TLogQueue; Targets: TList<ILogTarget>);
    destructor Destroy; override;
  end;

implementation

{ TLogQueue }

constructor TLogQueue.Create;
begin
  FQueue := TThreadedQueue<TLogMessage>.Create(1000);
  FEvent := TEvent.Create;
end;

destructor TLogQueue.Destroy;
begin
  FQueue.Free;
  FEvent.Free;
  inherited;
end;

procedure TLogQueue.Enqueue(const Msg: TLogMessage);
begin
  FQueue.PushItem(Msg);
  FEvent.SetEvent;
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
      FQueue.FEvent.WaitFor(1000);
  end;
end;

end.