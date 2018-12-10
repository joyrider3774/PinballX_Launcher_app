unit FrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    lblButtonPressed: TLabel;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    procedure CMDialogKey(var msg: TCMDialogKey); message CM_DIALOGKEY;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

//to allow VK_TAB etc keycode to be shown / used in onkeydown
procedure TMainForm.CMDialogKey(var msg: TCMDialogKey);
begin
  msg.Result := 0;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  RealKey: Word;
begin
  if Application.Terminated then Exit;

  RealKey := Key;

  if RealKey = VK_SHIFT then
    if GetKeyState(VK_LSHIFT) < 0 then
      RealKey := VK_LSHIFT
    else
      if GetKeyState(VK_RSHIFT) < 0 then
        RealKey := VK_RSHIFT;

  if RealKey = VK_CONTROL then
    if GetKeyState(VK_LCONTROL) < 0 then
      RealKey := VK_LCONTROL
    else
      if GetKeyState(VK_RCONTROL) < 0 then
        RealKey := VK_RCONTROL;

  if RealKey = VK_MENU then
    if GetKeyState(VK_LMENU) < 0 then
      RealKey := VK_LMENU
    else
      if GetKeyState(VK_RMENU) < 0 then
        RealKey := VK_RMENU;

  lblButtonPressed.Caption := 'Last Key Pressed: ' + IntToStr(RealKey);
end;

end.
