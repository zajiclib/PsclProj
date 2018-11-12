program Sico;

uses
  Vcl.Forms,
  SR_demo in 'SR_demo.pas' {frmMain},
  Convert in 'Convert.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
