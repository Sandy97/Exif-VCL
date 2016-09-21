unit uPooled;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client, FireDAC.Dapt,
  system.Threading, System.Diagnostics, FireDAC.Phys.MongoDB,
  FireDAC.Phys.MongoDBDef, System.Rtti, System.JSON.Types, System.JSON.Readers,
  System.JSON.BSON, System.JSON.Builders, FireDAC.Phys.MongoDBWrapper,
  FireDAC.Phys.IB, FireDAC.Phys.IBDef;

const
  DefaultConDefName = 'EMPLOYEE';
  DynConDefName = 'DYNEMPLOYEE';

type
  TForm12 = class(TForm)
    pnlMain: TPanel;
    Label1: TLabel;
    lblTotalExec: TLabel;
    Label2: TLabel;
    lblTotalTime: TLabel;
    btnRun: TButton;
    chPooled: TCheckBox;
    Memo1: TMemo;
    FDConnection1: TFDConnection;
    cbDynamicDef: TCheckBox;
    cbPPLFor: TCheckBox;
    procedure btnRunClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FCount: Integer;
    FStartTime: LongWord;
    ActualConDefName:string;
    procedure RunQuery;
    procedure Executed;
  public
    { Public declarations }
    procedure AddDynamicConDef;
  end;

var
  Form12: TForm12;

implementation

{$R *.dfm}

procedure TForm12.btnRunClick(Sender: TObject);
var
  i: Integer;
begin
  btnRun.Enabled := False;
//  FDManager.Close;
//  while FDManager.State <> dmsInactive do
//    Sleep(0);
  FDManager.Open;
  if cbDynamicDef.Checked then
    ActualConDefName:=DynConDefName
  else
    ActualConDefName:=DefaultConDefName;
  if chPooled.Checked then
    FDManager.ConnectionDefs.ConnectionDefByName(ActualConDefName).Params.Pooled := True
  else
    FDManager.ConnectionDefs.ConnectionDefByName(ActualConDefName).Params.Pooled := False;

  FStartTime := GetTickCount;
  FCount := 0;
  lblTotalExec.Caption := '---';
  lblTotalTime.Caption := '---';
  if cbPPLFor.Checked then begin
    TTask.Run(
      procedure
      var
        Total: integer;
        //Stopwatch: TStopWatch;
        ElapsedSeconds: Double;
      begin
        TParallel.For(1, 10,
          procedure(aIndex: integer)
          begin
            RunQuery;        //Total := PrimesBelow(200000);
        end);
      end);
  end
  else
    for i := 1 to 10 do
      TTask.Run(
        procedure
        var
          Total: integer;
          ElapsedSeconds: Double;
        begin
          RunQuery;        //Total := PrimesBelow(200000);
        end);

end;

procedure TForm12.AddDynamicConDef;
var
  oParams: TStrings;
begin
  FDManager.Close;
  while FDManager.State <> dmsInactive do
    Sleep(0);

  oParams := TStringList.Create;
  try
  oParams.Add('DriverID=IB');
  //oParams.Add('Server=gds_db');
  oParams.Add('Database=C:\data\EMPLOYEE.GDB');
  oParams.Add('User_Name=sysdba');
  oParams.Add('Password=masterkey');
//  oParams.Add('Pooled=True');
  FDManager.AddConnectionDef(DynConDefName, 'IB', oParams);
  finally
    oParams.Free;
  end;

end;

procedure TForm12.Executed;
begin
  Inc(FCount);
  if (FCount mod 10) = 0 then
    lblTotalExec.Caption := IntToStr(FCount);
  if FCount = 500 then begin
    lblTotalTime.Caption := FloatToStr((GetTickCount - FStartTime) / 1000.0);
    btnRun.Enabled := True;
  end;
end;

procedure TForm12.FormCreate(Sender: TObject);
begin
  AddDynamicConDef;
end;

procedure TForm12.FormDestroy(Sender: TObject);
begin
  FDManager.Close;
  //FDManager.ConnectionDefs.ConnectionDefByName(DynConDefName).Delete;
end;

procedure TForm12.RunQuery;
var
  oConn:  TFDConnection;
  oQuery: TFDQuery;
  i: Integer;
begin
  oConn  := TFDConnection.Create(nil);
  oQuery := TFDQuery.Create(nil);
  try
    oQuery.Connection := oConn;
    oConn.ConnectionDefName := ActualConDefName;
    for i := 1 to 50 do begin
      oQuery.SQL.Text := 'select count(*) from DEPARTMENT';
      oQuery.Open;
      oConn.Close;
      //Synchronize(FForm.Executed);
      TThread.Synchronize(nil,Form12.Executed);
    end;
  finally
    oConn.Free;
    oQuery.Free;
  end;
end;

initialization
  ReportMemoryLeaksOnShutdown := True;

end.

