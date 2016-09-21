unit myTaskQueue;
{
  ���������������:
  ������� � ���������� �������
  ��������� ��������� �������
  �������� �� ���������� �������
  ������������ � ������� �������� �������� (�� �����)
  ���� ����������� ����� ��������� ������� � ������������ ������
}

interface

uses
  system.Notification,
  Generics.Collections;

type
  // TProc<T1,T2> = reference to procedure (Arg1: T1; Arg2: T2);
  TProcessRef<I> = reference to function(itm: I): String;

  //todo 1 : ��������
  TmyTaskQueue<T> = class
    FNotificationCenter: TNotificationCenter;
    FQueue: TQueue<T>;
    function isEmpty: Boolean;
    procedure DoNotification(const nuName, nuTitle, nuBody: string);
    function rplurals(n: integer; subj: string): string;
  private
  public
    constructor Create();
    destructor Destroy(); override;
    procedure Add(itm: T);
    procedure Clear;
    procedure Process(P: TProcessRef<T>);
    procedure ParallelProcess(P: TProcessRef<T>);
  end;

implementation

uses
  system.SysUtils, System.Threading;

{ TaskQueue<T> }
function TmyTaskQueue<T>.rplurals(n: integer; subj: string): string;
begin
  if n = 1 then // <�����>
    Result := subj + '��'  // subj+'�'
  else if (n > 0) and (n < 5) then
    Result := subj + '��'  // subj+'�'
  else
    Result := subj + '��'; // subj+'�';
end;

procedure TmyTaskQueue<T>.Add(itm: T);
begin
  FQueue.Enqueue(itm);
end;

procedure TmyTaskQueue<T>.Clear;
begin
  FQueue.Clear;
end;

constructor TmyTaskQueue<T>.Create;
begin
  inherited;
  FQueue := TQueue<T>.Create();
  FNotificationCenter := TNotificationCenter.Create(nil);
end;

destructor TmyTaskQueue<T>.Destroy;
begin
  FNotificationCenter.Free;
  FQueue.Free;
  inherited;
end;

procedure TmyTaskQueue<T>.DoNotification(const nuName, nuTitle, nuBody: string);
var
  MyNotification: TNotification;
begin
  MyNotification := FNotificationCenter.CreateNotification;
  try
    MyNotification.Name := nuName;
    MyNotification.Title := nuTitle;
    MyNotification.AlertBody := nuBody;
    FNotificationCenter.PresentNotification(MyNotification);
  finally
    MyNotification.Free;
  end;
end;

function TmyTaskQueue<T>.isEmpty: Boolean;
begin
  Result := not(FQueue.Count > 0);
end;

procedure TmyTaskQueue<T>.ParallelProcess(P: TProcessRef<T>);
var
  rs: string;
  jobs: integer;
  item: T;
begin
  jobs := FQueue.Count;
  while not isEmpty do
    try
      item := FQueue.Extract;
      TTask.Run(
        procedure begin
          P(item);
        end);
    finally
      // if Item is T then T(item).Free;
    end;
  //todo 2 : �������� Log � ��������: 0-������, 1-��������,2-���
  DoNotification('tskqueue', 'Info', format('��������� %d %s',
                  [jobs, rplurals(jobs, '�����')]));
end;

procedure TmyTaskQueue<T>.Process(P: TProcessRef<T>);
var
  rs: string;
  jobs: integer;
  item: T;
begin
  jobs := FQueue.Count;
  while not isEmpty do
    //          if TTask.CurrentTask.Status = TTaskStatus.Canceled then
    //            Exit;
    try
      item := FQueue.Extract;
      rs := P(item); // results.add(P(FQueue.Extract));
    finally
      // if Item is T then T(item).Free;
    end;
  //todo 2 : �������� Log � ��������: 0-������, 1-��������,2-���
  DoNotification('tskqueue', 'Info', format('��������� %d %s',
                  [jobs, rplurals(jobs, '�����')]));
end;

end.
