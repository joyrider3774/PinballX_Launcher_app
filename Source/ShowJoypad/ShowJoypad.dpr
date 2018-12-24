program ShowJoypad;

uses
  Vcl.Forms,
  FrmMain in 'FrmMain.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
