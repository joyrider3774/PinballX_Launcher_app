unit FrmMain;

//uses NLDJoystick created by Albert de Weerd (aka NGLN)
//https://www.nldelphi.com/showthread.php?29812-NLDJoystick
//http://svn.nldelphi.com/nldelphi/opensource/ngln/NLDJoystick/

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, NLDJoystick, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    JoyPad: TNLDJoystick;
    tmrJoyenable: TTimer;
    lblInfo: TLabel;
    procedure tmrJoyenableTimer(Sender: TObject);
    procedure JoyPadButtonDown(Sender: TNLDJoystick;
      const Buttons: TJoyButtons);
    procedure FormCreate(Sender: TObject);
    procedure JoyPadMove(Sender: TNLDJoystick; const JoyPos: TJoyRelPos;
      const Buttons: TJoyButtons);
    procedure JoyPadPOVChanged(Sender: TNLDJoystick; Degrees: Single);
  private
    { Private declarations }
    FLastJoyButton: Integer;
    FLastJoyRelPos: TJoyRelPos;
    FLastPOVDegrees: Single;
    function ButtonSetLength(Buttons: TJoyButtons): Integer;
    function ButtonValueFromButtons(Buttons: TJoyButtons): Integer;
    procedure UpdateLabel;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses System.Math, Winapi.MMSystem;

{$R *.dfm}

procedure TMainForm.UpdateLabel;
begin
  if not JoyPad.Active then
  begin
    lblInfo.Caption := 'Please Attach a joypad / joystick';
    exit;
  end;

  if FLastJoyButton = -1 then
    lblInfo.Caption := 'Please Press a single button only'
  else
    if FLastJoyButton = -2 then
      lblInfo.Caption := 'Please Press a single button only (Multiple detected)'
    else
      lblInfo.Caption := 'Last (single) button pressed: ' + IntToStr(FLastJoyButton);

  if axX in JoyPad.Axises then
    lblInfo.Caption := lblInfo.Caption + #13#10 + 'Joypad X-Axis (Value = ' + IntToStr(Integer(axX)) + '): ' + FloatToStr(RoundTo(FLastJoyRelPos.X, -2));
  if axY in JoyPad.Axises then
    lblInfo.Caption := lblInfo.Caption + #13#10 + 'Joypad Y-Axis (Value = ' + IntToStr(Integer(axY)) + '): ' + FloatToStr(RoundTo(FLastJoyRelPos.Y, -2));
  if axZ in JoyPad.Axises then
    lblInfo.Caption := lblInfo.Caption + #13#10 + 'Joypad Z-Axis (Value = ' + IntToStr(Integer(axZ)) + '): ' + FloatToStr(RoundTo(FLastJoyRelPos.Z, -2));
  if axR in JoyPad.Axises then
    lblInfo.Caption := lblInfo.Caption + #13#10 + 'Joypad R-Axis (Value = ' + IntToStr(Integer(axR)) + '): ' + FloatToStr(RoundTo(FLastJoyRelPos.R, -2));
  if axU in JoyPad.Axises then
    lblInfo.Caption := lblInfo.Caption + #13#10 + 'Joypad U-Axis (Value = ' + IntToStr(Integer(axU)) + '): ' + FloatToStr(RoundTo(FLastJoyRelPos.U, -2));
  if axV in JoyPad.Axises then
    lblInfo.Caption := lblInfo.Caption + #13#10 + 'Joypad V-Axis (Value = ' + IntToStr(Integer(axV)) + '): ' + FloatToStr(RoundTo(FLastJoyRelPos.V, -2));

  if FLastPOVDegrees > 360 then
    lblInfo.Caption := lblInfo.Caption + #13#10 + 'Joypad POV Degrees: Centered'
  else
    lblInfo.Caption := lblInfo.Caption + #13#10 + 'Joypad POV Degrees: ' + FloatToStr(RoundTo(FLastPOVDegrees, -2));
end;

function TMainForm.ButtonValueFromButtons(Buttons: TJoyButtons): Integer;
var
  Button: TJoyButton;
begin
  Result := -1;

  for Button in Buttons do
  begin
    Result := Integer(Button);
    break;
  end;
end;

function TMainForm.ButtonSetLength(Buttons: TJoyButtons): Integer;
var
  Button: TJoyButton;
begin
  Result := 0;
  for Button in Buttons do
    inc(Result);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FLastJoyButton := -1;
end;

procedure TMainForm.JoyPadButtonDown(Sender: TNLDJoystick;
  const Buttons: TJoyButtons);
begin
  if ButtonSetLength(Buttons) <> 1 then
    FLastJoyButton := -2
  else
    FLastJoyButton := ButtonValueFromButtons(Buttons);
  UpdateLabel;
end;

procedure TMainForm.JoyPadMove(Sender: TNLDJoystick; const JoyPos: TJoyRelPos;
  const Buttons: TJoyButtons);
begin
  FLastJoyRelPos := JoyPos;
  UpdateLabel;
end;

procedure TMainForm.JoyPadPOVChanged(Sender: TNLDJoystick; Degrees: Single);
begin
  FLastPOVDegrees := Degrees;
end;

procedure TMainForm.tmrJoyenableTimer(Sender: TObject);
begin
  if not JoyPad.Active then
  begin
    JoyPad.Active := True;
    if JoyPad.Active then
    begin
      tmrJoyenable.Enabled := false;
      UpdateLabel;
    end;
  end
  else
    UpdateLabel;
end;

end.
