program PinballFX3Launcher;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {MainLauncherForm},
  Vcl.Themes,
  Vcl.Styles,
  System.SysUtils,
  Utils in 'Utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainLauncherForm, MainLauncherForm);
  Application.Run;
end.
