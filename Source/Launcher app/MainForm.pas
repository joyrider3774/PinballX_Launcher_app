unit MainForm;

//uses NLDJoystick created by Albert de Weerd (aka NGLN)
//https://www.nldelphi.com/showthread.php?29812-NLDJoystick
//http://svn.nldelphi.com/nldelphi/opensource/ngln/NLDJoystick/

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ButtonGroup, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Imaging.pngimage, System.Types, NLDJoystick;

const
  NumButtonRows = 3; //NumButtonRows multiplied by NumButtonCols
  NumButtonCols = 4;
  ButtonSpacing = 4; //in px
  BufferWidth = 800;
  BufferHeigth = 600;
  AutoLaunchInSecs = 7; //this is needed as pinballx will try to detect if a
                        //process has started and consider it failed if it
                        //does not after some time and return to the menu's
                        //i could not find a good fix to coop with that so
                        //the workaround is to make sure something is launched
                        //in time
  ButtonSize = 175;
  ButtonTextMargin = 2;
  ButtonStartxPos = 34;
  ButtonStartyPos = 34;

  JoyAxisPovSleep = 150;

type
  TButtonRec = record
    Param: String;
    Text: String;
    Enabled: Boolean;
  end;

  TMainLauncherForm = class(TForm)
    tmr1: TTimer;
    JoyPad: TNLDJoystick;
    tmrJoypadEnable: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure JoyPadButtonDown(Sender: TNLDJoystick;
      const Buttons: TJoyButtons);
    procedure JoyPadMove(Sender: TNLDJoystick; const JoyPos: TJoyRelPos;
      const Buttons: TJoyButtons);
    procedure tmrJoypadEnableTimer(Sender: TObject);
    procedure JoyPadPOVChanged(Sender: TNLDJoystick; Degrees: Single);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    StartTickCount, SecondsRunning, PrevSecondsRunning: Cardinal;
    FNumLastRowsNotVisible, FNumFirstRowsNotVisible, FForceForeGroundWindow: Integer;
    BitMapBuffer, BitmapRotated, BitMapScaled: TBitmap;
    PngBackGround, PngSelection, PngNoSelection: TPngImage;
    Path, LaunchParams, StartParams, Title: String;
    LeftKey, RightKey, LaunchKey, QuitKey: Word;
    ScaleM, ScaleD, SelectedButton, DoRotate, ScaleFontM, ScaleFontD,
    PosLeft, PosTop: Integer;
    FButtons: Array[1..NumButtonRows*NumButtonCols] of TButtonRec;
    DontSaveIni, DontReadSteamPathReg, SmoothResizeDraw, UseJoypad,
    ForceForeGroundWindowDone : Boolean;
    JoyLaunchButton, JoyLeftButton, JoyQuitButton, JoyRightButton,
    JoyLeftRightAxis: Integer;
    JoyAxisDeadZone: Double;
    JoyPovLeftMin, JoyPovLeftMax, JoyPovRightMin, JoyPovRightMax: Single;
    JoyAxisMustRelease, JoyPovMustRelease, JoyPovSelection,
    JoyAxisSelection, JoyButtonSelection, RepositionWindow: Boolean;

    procedure CMDialogKey(var msg: TCMDialogKey); message CM_DIALOGKEY;
    procedure DoLaunch(const aParams: String);
    procedure SetSelectedButton(Index:Integer);
    procedure SelectNext;
    procedure SelectPrev;
    procedure SaveIni;
    procedure LoadIni;
    procedure CaclulateNumLastRowsNotVisible;
    procedure CaclulateNumFirstRowsNotVisible;
    procedure DoQuit;
  public
    { Public declarations }
  end;

var
  MainLauncherForm: TMainLauncherForm;

implementation

{$R *.dfm}

uses
  System.Win.Registry, System.IniFiles, Winapi.ShellAPI, GDIPAPI, Utils, System.Math;

procedure TMainLauncherForm.DoQuit;
begin
  tmr1.Enabled := False;
  tmrJoypadEnable.Enabled := false;
  JoyPad.Active := false;
  Application.Terminate;
end;

procedure TMainLauncherForm.CaclulateNumFirstRowsNotVisible;
var
  x, y, Button: Integer;
begin
  FNumFirstRowsNotVisible := 0;
  for y := 0 to NumButtonRows -1 do
  begin
    for x := 0 to NumButtonCols -1 do
    begin
      button := y * NumButtonCols + x + 1;
      if FButtons[Button].Enabled then
        exit;
    end;
    Inc(FNumFirstRowsNotVisible);
  end;
end;

procedure TMainLauncherForm.CaclulateNumLastRowsNotVisible;
var
  x, y, Button: Integer;
begin
  FNumLastRowsNotVisible := 0;
  for y := NumButtonRows -1 downto 0 do
  begin
    for x := 0 to NumButtonCols -1 do
    begin
      button := y * NumButtonCols + x + 1;
      if FButtons[Button].Enabled then
        exit;
    end;
    Inc(FNumLastRowsNotVisible);
  end;
end;

//to allow VK_TAB etc keycode to be shown / used in onkeydown
procedure TMainLauncherForm.CMDialogKey(var msg: TCMDialogKey);
begin
  msg.Result := 0;
end;

procedure TMainLauncherForm.tmr1Timer(Sender: TObject);
begin
  if (FForceForeGroundWindow = 1) or
    ((FForceForeGroundWindow = 2) and not ForceForeGroundWindowDone) then
  begin
    ForceForegroundWindow(Self.Handle);
    ForceForeGroundWindowDone := True;
  end;

  //Check if left mouse button is pressed if so pause the timer as we are
  //probably dragging the window
  if (GetAsyncKeyState(VK_LBUTTON) and $8000) <> 0 then
    StartTickCount := GetTickCount - (SecondsRunning * 1000);

  PrevSecondsRunning := SecondsRunning;
  SecondsRunning := (GetTickCount - StartTickCount) div 1000;

  //need to repaint to force showing countdown timer
  if PrevSecondsRunning <> SecondsRunning then
    Repaint;

  if SecondsRunning >= AutoLaunchInSecs then
  begin
    SecondsRunning := AutoLaunchInSecs;
    DoLaunch(FButtons[SelectedButton].Param);
  end;
end;

procedure TMainLauncherForm.tmrJoypadEnableTimer(Sender: TObject);
begin
  if not JoyPad.Active then
  begin
    JoyPad.Active := True;
    if JoyPad.Active then
      tmrJoypadEnable.Enabled := false;
  end
end;

procedure TMainLauncherForm.LoadIni;
var
  IniFile: TMemIniFile;
begin
  IniFile := TMemIniFile.Create(ExtractFilePath(ParamStr(0)) + ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini'));
  try
    LeftKey := IniFile.ReadInteger('SETTINGS','LEFTKEY', VK_LSHIFT);
    RightKey := IniFile.ReadInteger('SETTINGS','RIGHTKEY', VK_RSHIFT);
    LaunchKey := IniFile.ReadInteger('SETTINGS','LAUNCHKEY', VK_RETURN);
    QuitKey := IniFile.ReadInteger('SETTINGS','QUITKEY', Ord('Q'));
    StartParams := IniFile.ReadString('SETTINGS', 'STARTPARAMS', '-applaunch 442120');
    Path := IniFile.ReadString('SETTINGS', 'PATH', '');
    RepositionWindow := IniFile.ReadBool('SETTINGS', 'REPOSITIONWINDOW', False);
    PosLeft := IniFile.ReadInteger('SETTINGS', 'POSLEFT', 0);
    PosTop := IniFile.ReadInteger('SETTINGS', 'POSTOP', 0);
    ScaleM := IniFile.ReadInteger('SETTINGS', 'SCALEM', 1);
    ScaleD := IniFile.ReadInteger('SETTINGS', 'SCALED', 1);
    ScaleFontM := IniFile.ReadInteger('SETTINGS', 'SCALEFONTM', 1);
    ScaleFontD := IniFile.ReadInteger('SETTINGS', 'SCALEFONTD', 1);
    DoRotate := IniFile.ReadInteger('SETTINGS', 'ROTATE', 3);
    DontSaveIni := IniFile.ReadBool('SETTINGS', 'DONTSAVEINIONEXIT', False);
    DontReadSteamPathReg := IniFile.ReadBool('SETTINGS', 'DONTREADSTEAMPATHREG', False);
    SmoothResizeDraw := IniFile.ReadBool('SETTINGS', 'SMOOTHRESIZEDRAW', True);
    Title := IniFile.ReadString('SETTINGS', 'TITLE', 'Pinball FX3 Launcher');
    FForceForeGroundWindow := IniFile.ReadInteger('SETTINGS', 'FORCEFOREGROUNDWINDOW', 0);

    UseJoypad := IniFile.ReadBool('JOYPAD', 'USEJOYPAD', False);
    JoyLeftButton := IniFile.ReadInteger('JOYPAD', 'LEFTBUTTON', 4);
    JoyRightButton := IniFile.ReadInteger('JOYPAD', 'RIGHTBUTTON', 5);
    JoyLaunchButton := IniFile.ReadInteger('JOYPAD', 'LAUNCHBUTTON', 0);
    JoyQuitButton := IniFile.ReadInteger('JOYPAD', 'QUITBUTTON', 6);
    JoyLeftRightAxis := IniFile.ReadInteger('JOYPAD', 'LEFTRIGHTAXIS', 0);
    JoyAxisDeadZone := IniFile.ReadFloat('JOYPAD', 'LEFTRIGHTAXISDEADZONE', 0.5);
    JoyPovLeftMin := IniFile.ReadFloat('JOYPAD', 'JOYPOVLEFTMIN', 260);
    JoyPovLeftMax := IniFile.ReadFloat('JOYPAD', 'JOYPOVLEFTMAX', 280);
    JoyPovRightMin := IniFile.ReadFloat('JOYPAD', 'JOYPOVRIGHTMIN', 80);
    JoyPovRightMax := IniFile.ReadFloat('JOYPAD', 'JOYPOVRIGHTMAX', 100);
    JoyAxisSelection := IniFile.ReadBool('JOYPAD', 'JOYAXISSELECTION', True);
    JoyPovSelection := IniFile.ReadBool('JOYPAD', 'JOYPOVSELECTION', True);
    JoyButtonSelection := IniFile.ReadBool('JOYPAD', 'JOYBUTTONSELECTION', True);

    FButtons[1].Text := IniFile.ReadString('BUTTON_ONE', 'TEXT', 'One Player (Normal)');
    FButtons[1].Enabled := IniFile.ReadBool('BUTTON_ONE', 'ENABLED', True);
    FButtons[1].Param := IniFile.ReadString('BUTTON_ONE', 'PARAM', '');

    FButtons[2].Text := IniFile.ReadString('BUTTON_TWO', 'TEXT', 'Two Players (Normal)');
    FButtons[2].Enabled := IniFile.ReadBool('BUTTON_TWO', 'ENABLED', True);
    FButtons[2].Param := IniFile.ReadString('BUTTON_TWO', 'PARAM', '-hotseat_2');

    FButtons[3].Text := IniFile.ReadString('BUTTON_THREE', 'TEXT', 'Three Players (Normal)');
    FButtons[3].Enabled := IniFile.ReadBool('BUTTON_THREE', 'ENABLED', True);
    FButtons[3].Param := IniFile.ReadString('BUTTON_THREE', 'PARAM', '-hotseat_3');

    FButtons[4].Text := IniFile.ReadString('BUTTON_FOUR', 'TEXT', 'Four Players (Normal)');
    FButtons[4].Enabled := IniFile.ReadBool('BUTTON_FOUR', 'ENABLED', True);
    FButtons[4].Param := IniFile.ReadString('BUTTON_FOUR', 'PARAM', '-hotseat_4');

    FButtons[5].Text := IniFile.ReadString('BUTTON_FIVE', 'TEXT', 'One Player (Classic)');
    FButtons[5].Enabled := IniFile.ReadBool('BUTTON_FIVE', 'ENABLED', True);
    FButtons[5].Param := IniFile.ReadString('BUTTON_FIVE', 'PARAM', '-class');

    FButtons[6].Text := IniFile.ReadString('BUTTON_SIX', 'TEXT', 'Two Players (Classic)');
    FButtons[6].Enabled := IniFile.ReadBool('BUTTON_SIX', 'ENABLED', True);
    FButtons[6].Param := IniFile.ReadString('BUTTON_SIX', 'PARAM', '-class -hotseat_2');

    FButtons[7].Text := IniFile.ReadString('BUTTON_SEVEN', 'TEXT', 'Three Players (Classic)');
    FButtons[7].Enabled := IniFile.ReadBool('BUTTON_SEVEN', 'ENABLED', True);
    FButtons[7].Param := IniFile.ReadString('BUTTON_SEVEN', 'PARAM', '-class -hotseat_3');

    FButtons[8].Text := IniFile.ReadString('BUTTON_EIGHT', 'TEXT', 'Four Players (Classic)');
    FButtons[8].Enabled  := IniFile.ReadBool('BUTTON_EIGHT', 'ENABLED', True);
    FButtons[8].Param := IniFile.ReadString('BUTTON_EIGHT', 'PARAM', '-class -hotseat_4');

    FButtons[9].Text := IniFile.ReadString('BUTTON_NINE', 'TEXT', '');
    FButtons[9].Enabled  := IniFile.ReadBool('BUTTON_NINE', 'ENABLED', False);
    FButtons[9].Param := IniFile.ReadString('BUTTON_NINE', 'PARAM', '');

    FButtons[10].Text := IniFile.ReadString('BUTTON_TEN', 'TEXT', '');
    FButtons[10].Enabled  := IniFile.ReadBool('BUTTON_TEN', 'ENABLED', False);
    FButtons[10].Param := IniFile.ReadString('BUTTON_TEN', 'PARAM', '');

    FButtons[11].Text := IniFile.ReadString('BUTTON_ELEVEN', 'TEXT', '');
    FButtons[11].Enabled  := IniFile.ReadBool('BUTTON_ELEVEN', 'ENABLED', False);
    FButtons[11].Param := IniFile.ReadString('BUTTON_ELEVEN', 'PARAM', '');

    FButtons[12].Text := IniFile.ReadString('BUTTON_TWELVE', 'TEXT', '');
    FButtons[12].Enabled  := IniFile.ReadBool('BUTTON_TWELVE', 'ENABLED', False);
    FButtons[12].Param := IniFile.ReadString('BUTTON_TWELVE', 'PARAM', '');

    SetSelectedButton(IniFile.ReadInteger('SETTINGS', 'LASTACTIVEBUTTON', 1));
  finally
    FreeAndNil(IniFile);
  end;
end;

procedure TMainLauncherForm.SaveIni;
var
  IniFile: TMemIniFile;
begin
  IniFile := TMemIniFile.Create(ExtractFilePath(ParamStr(0))  + ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini'));
  try
    IniFile.WriteInteger('SETTINGS','LEFTKEY', LeftKey);
    IniFile.WriteInteger('SETTINGS','RIGHTKEY', RightKey);
    IniFile.WriteInteger('SETTINGS','LAUNCHKEY', LaunchKey);
    IniFile.WriteInteger('SETTINGS','QUITKEY', QuitKey);
    IniFile.WriteString('SETTINGS', 'STARTPARAMS', StartParams);
    IniFile.WriteString('SETTINGS', 'PATH', Path);
    IniFile.WriteBool('SETTINGS', 'REPOSITIONWINDOW', RepositionWindow);
    IniFile.WriteInteger('SETTINGS', 'POSLEFT', Left);
    IniFile.WriteInteger('SETTINGS', 'POSTOP', Top);
    IniFile.WriteInteger('SETTINGS','SCALEM', ScaleM);
    IniFile.WriteInteger('SETTINGS','SCALED', ScaleD);
    IniFile.WriteInteger('SETTINGS','SCALEFONTM', ScaleFontM);
    IniFile.WriteInteger('SETTINGS','SCALEFONTD', ScaleFontD);
    IniFile.WriteBool('SETTINGS', 'DONTSAVEINIONEXIT', DontSaveIni);
    IniFile.WriteString('SETTINGS', 'TITLE', Title);
    IniFile.WriteBool('SETTINGS', 'DONTREADSTEAMPATHREG', DontReadSteamPathReg);
    IniFile.WriteInteger('SETTINGS', 'LASTACTIVEBUTTON', SelectedButton);
    IniFile.WriteInteger('SETTINGS', 'ROTATE', DoRotate);
    IniFile.WriteBool('SETTINGS', 'SMOOTHRESIZEDRAW', SmoothResizeDraw);
    IniFile.WriteInteger('SETTINGS', 'FORCEFOREGROUNDWINDOW', FForceForeGroundWindow);

    IniFile.WriteBool('JOYPAD', 'USEJOYPAD', UseJoypad);
    IniFile.WriteInteger('JOYPAD', 'LEFTBUTTON', JoyLeftButton);
    IniFile.WriteInteger('JOYPAD', 'RIGHTBUTTON', JoyRightButton);
    IniFile.WriteInteger('JOYPAD', 'LAUNCHBUTTON', JoyLaunchButton);
    IniFile.WriteInteger('JOYPAD', 'QUITBUTTON', JoyQuitButton);
    IniFile.WriteInteger('JOYPAD', 'LEFTRIGHTAXIS', JoyLeftRightAxis);
    IniFile.WriteFloat('JOYPAD', 'LEFTRIGHTAXISDEADZONE', JoyAxisDeadZone);
    IniFile.WriteFloat('JOYPAD', 'JOYPOVLEFTMIN', JoyPovLeftMin);
    IniFile.WriteFloat('JOYPAD', 'JOYPOVLEFTMAX', JoyPovLeftMax);
    IniFile.WriteFloat('JOYPAD', 'JOYPOVRIGHTMIN', JoyPovRightMin);
    IniFile.WriteFloat('JOYPAD', 'JOYPOVRIGHTMAX', JoyPovRightMax);
    IniFile.WriteBool('JOYPAD', 'JOYAXISSELECTION', JoyAxisSelection);
    IniFile.WriteBool('JOYPAD', 'JOYPOVSELECTION', JoyPovSelection);
    IniFile.WriteBool('JOYPAD', 'JOYBUTTONSELECTION', JoyButtonSelection);

    IniFile.WriteString('BUTTON_ONE', 'TEXT',  FButtons[1].Text);
    IniFile.WriteBool('BUTTON_ONE', 'ENABLED', FButtons[1].Enabled);
    IniFile.WriteString('BUTTON_ONE', 'PARAM', FButtons[1].Param);

    IniFile.WriteString('BUTTON_TWO', 'TEXT', FButtons[2].Text);
    IniFile.WriteBool('BUTTON_TWO', 'ENABLED', FButtons[2].Enabled);
    IniFile.WriteString('BUTTON_TWO', 'PARAM', FButtons[2].Param);

    IniFile.WriteString('BUTTON_THREE', 'TEXT', FButtons[3].Text);
    IniFile.WriteBool('BUTTON_THREE', 'ENABLED', FButtons[3].Enabled);
    IniFile.WriteString('BUTTON_THREE', 'PARAM', FButtons[3].Param);

    IniFile.WriteString('BUTTON_FOUR', 'TEXT', FButtons[4].Text);
    IniFile.WriteBool('BUTTON_FOUR', 'ENABLED', FButtons[4].Enabled);
    IniFile.WriteString('BUTTON_FOUR', 'PARAM', FButtons[4].Param);

    IniFile.WriteString('BUTTON_FIVE', 'TEXT',  FButtons[5].Text );
    IniFile.WriteBool('BUTTON_FIVE', 'ENABLED', FButtons[5].Enabled);
    IniFile.WriteString('BUTTON_FIVE', 'PARAM', FButtons[5].Param);

    IniFile.WriteString('BUTTON_SIX', 'TEXT', FButtons[6].Text);
    IniFile.WriteBool('BUTTON_SIX', 'ENABLED', FButtons[6].Enabled);
    IniFile.WriteString('BUTTON_SIX', 'PARAM', FButtons[6].Param);

    IniFile.WriteString('BUTTON_SEVEN', 'TEXT', FButtons[7].Text);
    IniFile.WriteBool('BUTTON_SEVEN', 'ENABLED', FButtons[7].Enabled);
    IniFile.WriteString('BUTTON_SEVEN', 'PARAM', FButtons[7].Param);

    IniFile.WriteString('BUTTON_EIGHT', 'TEXT', FButtons[8].Text);
    IniFile.WriteBool('BUTTON_EIGHT', 'ENABLED', FButtons[8].Enabled);
    IniFile.WriteString('BUTTON_EIGHT', 'PARAM', FButtons[8].Param);

    IniFile.WriteString('BUTTON_NINE', 'TEXT', FButtons[9].Text);
    IniFile.WriteBool('BUTTON_NINE', 'ENABLED', FButtons[9].Enabled);
    IniFile.WriteString('BUTTON_NINE', 'PARAM', FButtons[9].Param);

    IniFile.WriteString('BUTTON_TEN', 'TEXT', FButtons[10].Text);
    IniFile.WriteBool('BUTTON_TEN', 'ENABLED', FButtons[10].Enabled );
    IniFile.WriteString('BUTTON_TEN', 'PARAM', FButtons[10].Param);

    IniFile.WriteString('BUTTON_ELEVEN', 'TEXT', FButtons[11].Text);
    IniFile.WriteBool('BUTTON_ELEVEN', 'ENABLED', FButtons[11].Enabled );
    IniFile.WriteString('BUTTON_ELEVEN', 'PARAM', FButtons[11].Param);

    IniFile.WriteString('BUTTON_TWELVE', 'TEXT', FButtons[12].Text);
    IniFile.WriteBool('BUTTON_TWELVE', 'ENABLED', FButtons[12].Enabled );
    IniFile.WriteString('BUTTON_TWELVE', 'PARAM', FButtons[12].Param);

    IniFile.UpdateFile;
  finally
    FreeAndNil(IniFile);
  end;
end;




procedure TMainLauncherForm.SelectNext;
var
  Teller: Integer;
begin
  Inc(SelectedButton);

  if SelectedButton > High(FButtons) then
    SelectedButton := Low(FButtons);

  if not FButtons[SelectedButton].Enabled then
  begin
    for Teller := SelectedButton to High(FButtons) do
      if FButtons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;

    for Teller := Low(FButtons) to SelectedButton do
      if FButtons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;
  end;

end;

procedure TMainLauncherForm.SelectPrev;
var
  Teller: Integer;
begin
  Dec(SelectedButton);

  if SelectedButton < Low(FButtons) then
    SelectedButton := High(FButtons);

  if not FButtons[SelectedButton].Enabled then
  begin
    for Teller := SelectedButton downto low(FButtons) do
      if FButtons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;

    for Teller := High(FButtons) downto SelectedButton do
      if FButtons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;
  end;
end;

procedure TMainLauncherForm.SetSelectedButton(Index:Integer);
var
  Teller: Integer;
begin
  if index < low(FButtons) then
    index := low(FButtons);
  if index > high(FButtons) then
    index := high(FButtons);

  //find next enabled button
  if not FButtons[Index].Enabled then
  begin
    for Teller := Index + 1 to Length(FButtons) do
      if FButtons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;

    for Teller := Low(FButtons) to Index -1 do
      if FButtons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;
  end;

  SelectedButton := Index;
end;

procedure TMainLauncherForm.DoLaunch(const aParams: string);
begin
  tmr1.Enabled := False;
  tmrJoypadEnable.Enabled := false;
  JoyPad.Active := false;
  Application.Terminate;
  if not FileExists(Path) then
  begin
    Application.MessageBox(PChar('Binary location does not exist... ' + #13#10#13#10 +
      'Path: ' + Path + #13#10 +
      'Try Adding ''Path'' value to Settings.ini manually ... Exiting...'), 'Error', MB_ICONERROR + MB_OK);
  end
  else
    Shellexecute(GetDesktopWindow, 'open', PChar(Path),
      PChar(Trim(Trim(StartParams + ' ' + aParams) + ' ' + ParamStr(1))),
      PChar(ExtractFilePath(Path)), SW_SHOWNORMAL);
end;

procedure TMainLauncherForm.FormCreate(Sender: TObject);
var
  oReg: TRegistry;
  sFilePath: String;
begin
  ForceForeGroundWindowDone := false;
  LaunchParams := '';
  ScaleM := 1;
  ScaleD := 1;
  SecondsRunning := 0;
  JoyAxisMustRelease := false;
  JoyPovMustRelease := false;

  PngBackGround := TPngImage.Create;
  PngSelection := TPngImage.Create;
  PngNoSelection := TPngImage.Create;

  sFilePath := ExtractFilePath(ParamStr(0));
  PngBackGround.LoadFromFile(sFilePath + 'background.png');
  PngSelection.LoadFromFile(sFilePath + 'butselection.png');
  PngNoSelection.LoadFromFile(sFilePath + 'butnoselection.png');

  LoadIni;

  if UseJoyPad then
  begin
    joyPad.Active := True;
    if not JoyPad.Active then
      tmrJoypadEnable.Enabled := true;
  end;


  if (Path = '') and not DontReadSteamPathReg then
  begin
    oReg := TRegistry.Create(KEY_READ);
    try
      oReg.RootKey := HKEY_CURRENT_USER;
      if oReg.OpenKey('Software\Valve\Steam', false) then
        if oReg.ValueExists('SteamPath') then
        begin
          Path := oReg.ReadString('SteamPath');
          Path := IncludeTrailingPathDelimiter(Path) + 'Steam.exe';
          if not FileExists(Path) then
            Path := '';
        end;
    finally
      FreeAndNil(oReg);
    end;
  end;

  CaclulateNumLastRowsNotVisible;
  CaclulateNumFirstRowsNotVisible;

  if (DoRotate < 0) or (DoRotate > 3) then
    DoRotate := 0;

  BitmapRotated := TBitmap.Create;
  BitmapRotated.PixelFormat := pf24bit;

  //AdJust form based on rotation
  if (DoRotate = 1) or (DoRotate = 3) then
  begin
    Width := BufferHeigth;
    Height := BufferWidth;
    BitmapRotated.SetSize(BufferHeigth, BufferWidth);
  end
  else
  begin
    Width := BufferWidth;
    Height := BufferHeigth;
    BitmapRotated.SetSize(BufferWidth, BufferHeigth);
  end;

  BitMapBuffer := TBitmap.Create;
  BitMapBuffer.PixelFormat := pf24bit;
  BitMapBuffer.SetSize(BufferWidth, BufferHeigth);
  BitMapScaled := nil;

  ScaleBy(ScaleM, ScaleD);

  if RoundTo(ScaleM / ScaleD, -2) <> 1.00 then
  begin
    BitMapScaled := TBitmap.Create;
    BitMapScaled.PixelFormat := pf24bit;
    BitMapScaled.SetSize(Width, Height);
  end;

  if RepositionWindow then
  begin
    Position := poDesigned;
    Left := PosLeft;
    Top := PosTop;
  end;

  StartTickCount := GetTickCount;
end;


procedure TMainLauncherForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(BitMapBuffer);
  FreeAndNil(PngBackGround);
  FreeAndNil(PngSelection);
  FreeAndNil(PngNoSelection);
  if Assigned(BitMapScaled) then
    FreeAndNil(BitMapScaled);

  if not FileExists(ExtractFilePath(ParamStr(0)) + ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini')) then
    SaveIni
  else if not DontSaveIni then
    SaveIni;
end;

procedure TMainLauncherForm.FormKeyDown(Sender: TObject; var Key: Word;
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

  if (RealKey = LaunchKey) then
    DoLaunch(FButtons[SelectedButton].Param);

  if RealKey = LeftKey then
  begin
    SelectPrev;
    RePaint;
  end;

  if RealKey = RightKey then
  begin
    SelectNext;
    Repaint;
  end;

  if RealKey = QuitKey then
    DoQuit;
end;

procedure TMainLauncherForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const
  SC_DRAGMOVE = $F012;
begin
  if Button = mbLeft then
  begin
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, SC_DRAGMOVE, 0);
  end;
end;


procedure TMainLauncherForm.FormPaint(Sender: TObject);
var
  x, y, TextHeight, button, TextTop, ButtonVCenter: Integer;
  TextRect: TRect;
begin
  ButtonVCenter := (FNumLastRowsNotVisible * ((ButtonSize + ButtonSpacing) div 2)) -
    (FNumFirstRowsNotVisible * ((ButtonSize + ButtonSpacing) div 2));
  BitMapBuffer.Canvas.StretchDraw(Rect(0,0, BitMapBuffer.Width, BitMapBuffer.Height), PngBackGround);

  BitMapBuffer.Canvas.Font := Canvas.Font;
  BitMapBuffer.Canvas.Brush.Style := bsClear;
  BitMapBuffer.Canvas.Font.Color := clWhite;
  BitMapBuffer.Canvas.Font.PixelsPerInch := MulDiv(96, ScaleFontM, ScaleFontD);

  BitMapBuffer.Canvas.Font.Size := 17;

  TextRect.Left := 5;
  TextRect.Top := 5;
  TextRect.Width := BitMapBuffer.Width - 5;
  TextRect.Height := MulDiv(50, ScaleFontM, ScaleFontD);
  DrawText(BitMapBuffer.Canvas.Handle, Title,
    -1, TextRect, DT_CENTER or DT_SINGLELINE);

  BitMapBuffer.Canvas.Font.Size := 10;
  TextRect.Left := 5;
  TextRect.Top := BitMapBuffer.Height - 20 - 5;
  TextRect.Width := BitMapBuffer.Width - 10;
  TextRect.Height := 20;
  TextHeight := DrawText(BitMapBuffer.Canvas.Handle, 'Launcher Created by Willems Davy ' +
    '(Joyrider3774) - Launching in ' + IntToStr(AutoLaunchInSecs - SecondsRunning),
    -1, TextRect, DT_CENTER or DT_WORDBREAK or DT_CALCRECT);

  TextRect.Left := 5;
  TextRect.Top := BitMapBuffer.Height - TextHeight - 5;
  TextRect.Width := BitMapBuffer.Width - 10;
  TextRect.Height := TextHeight;

  DrawText(BitMapBuffer.Canvas.Handle,'Launcher Created by Willems Davy ' +
    '(Joyrider3774) - Launching in ' + IntToStr(AutoLaunchInSecs - SecondsRunning),
    -1, TextRect, DT_CENTER or DT_WORDBREAK);

  BitMapBuffer.Canvas.Font.Size := 15;
  for x := 0 to NumButtonCols - 1 do
    for y := 0 to NumButtonRows - 1 do
    begin
      button := y * NumButtonCols + x + 1;

      if FButtons[Button].Enabled then
      begin
        if button = SelectedButton then
        begin
          BitMapBuffer.Canvas.Draw(((ButtonSize + ButtonSpacing) * x) + ButtonStartxPos , ((ButtonSize + ButtonSpacing) * y) + ButtonStartyPos + ButtonVCenter, PngSelection);
          BitMapBuffer.Canvas.Font.Color := clWhite;
        end
        else
        begin
          BitMapBuffer.Canvas.Draw(((ButtonSize + ButtonSpacing) * x) + ButtonStartxPos , ((ButtonSize + ButtonSpacing) * y) + ButtonStartyPos + ButtonVCenter , PngNoSelection);
          BitMapBuffer.Canvas.Font.Color := clBlack;
        end;

        // + 2 for padding
        TextRect.Left := ((ButtonSize + ButtonSpacing) * x) + ButtonStartxPos + ButtonTextMargin;
        TextRect.Top := (ButtonSize + ButtonSpacing * y) + ButtonStartyPos + ButtonVCenter + ButtonTextMargin;
        TextRect.Width := ButtonSize - (2 * ButtonTextMargin);
        TextRect.Height := ButtonSize - (2 * ButtonTextMargin);
        TextHeight := DrawText(BitMapBuffer.Canvas.Handle, FButtons[button].Text,
          -1, TextRect, DT_CENTER or DT_WORDBREAK or DT_EDITCONTROL or DT_CALCRECT);

        TextRect.Left := ((ButtonSize + ButtonSpacing) * x) + ButtonStartxPos + ButtonTextMargin;
        TextTop := ((ButtonSize + ButtonSpacing) * y) + ButtonStartyPos + ButtonVCenter + ButtonTextMargin + (((ButtonSize - (2 * ButtonTextMargin)) div 2) - (TextHeight div 2));
        if TextTop < ((ButtonSize + ButtonSpacing) * y) + ButtonStartyPos + ButtonVCenter + ButtonTextMargin then
          TextRect.Top := ((ButtonSize + ButtonSpacing) * y) + ButtonStartyPos + ButtonVCenter + ButtonTextMargin
        else
          TextRect.Top := TextTop;

        TextRect.Width := ButtonSize - (2 * ButtonTextMargin);
        TextRect.Height := ButtonSize - (2 * ButtonTextMargin);
        DrawText(BitMapBuffer.Canvas.Handle, FButtons[button].Text,
          -1, TextRect, DT_CENTER or DT_EDITCONTROL or DT_WORDBREAK);
      end;

    end;

  if DoRotate = 0 then
     RotateFlipBitmap(BitMapBuffer, BitmapRotated, RotateNoneFlipNone);

  if DoRotate = 1 then
    RotateFlipBitmap(BitMapBuffer, BitmapRotated,  Rotate90FlipNone);

  if DoRotate = 2 then
    RotateFlipBitmap(BitMapBuffer, BitmapRotated, Rotate180FlipNone);

  if DoRotate = 3 then
  begin
    RotateFlipBitmap(BitMapBuffer, BitmapRotated, Rotate270FlipNone);
  end;

  if RoundTo(ScaleM / ScaleD, -2) <> 1.00 then
  begin
    if SmoothResizeDraw then
    begin
      SmoothScaleBitmap(BitmapRotated, BitMapScaled, Width, Height);
      Canvas.Draw(0, 0, BitMapScaled);
    end
    else
      Canvas.StretchDraw(Rect(0,0, Width, Height), BitmapRotated);
  end
  else
    Canvas.Draw(0, 0, BitmapRotated);
end;

procedure TMainLauncherForm.JoyPadButtonDown(Sender: TNLDJoystick;
  const Buttons: TJoyButtons);
begin
  if JoyButtonSelection and (JoyLeftButton > -1) and (JoyLeftButton < 32) then
    if TJoyButton(JoyLeftButton) in Buttons then
    begin
      SelectPrev;
      RePaint;
    end;

  if JoyButtonSelection and (JoyRightButton > -1) and (JoyRightButton < 32) then
    if TJoyButton(JoyRightButton) in Buttons then
    begin
      SelectNext;
      Repaint;
    end;

  if (JoyLaunchButton > -1) and (JoyLaunchButton < 32) then
    if TJoyButton(JoyLaunchButton) in Buttons then
      DoLaunch(FButtons[SelectedButton].Param);

  if (JoyQuitButton > -1) and (JoyQuitButton < 32) then
    if TJoyButton(JoyQuitButton) in Buttons then
      DoQuit
end;

procedure TMainLauncherForm.JoyPadMove(Sender: TNLDJoystick;
  const JoyPos: TJoyRelPos; const Buttons: TJoyButtons);
begin
  if not JoyAxisSelection then exit;

  if (JoyLeftRightAxis > -1) and (JoyLeftRightAxis < 6) then
    if TJoyAxis(JoyLeftRightAxis) in JoyPad.Axises then
      case TJoyAxis(JoyLeftRightAxis) of
        axX:
          if Joypos.X < -JoyAxisDeadZone then
          begin
            if not JoyAxisMustRelease then
            begin
              SelectPrev;
              Repaint;
              JoyAxisMustRelease := True;
            end;
          end
          else
            if JoyPos.X > JoyAxisDeadZone then
            begin
              if not JoyAxisMustRelease then
              begin
                SelectNext;
                Repaint;
                JoyAxisMustRelease := True;
              end;
            end
            else
              JoyAxisMustRelease := False;
        axY:
          if Joypos.Y < -JoyAxisDeadZone then
          begin
            if not JoyAxisMustRelease then
            begin
              SelectPrev;
              Repaint;
              JoyAxisMustRelease := True;
            end;
          end
          else
            if JoyPos.Y > JoyAxisDeadZone then
            begin
              if not JoyAxisMustRelease then
              begin
                SelectNext;
                Repaint;
                JoyAxisMustRelease := True;
              end;
            end
            else
              JoyAxisMustRelease := False;
        axZ:
          if Joypos.Z < -JoyAxisDeadZone then
          begin
            if not JoyAxisMustRelease then
            begin
              SelectPrev;
              Repaint;
              JoyAxisMustRelease := True;
            end;
          end
          else
            if JoyPos.Z > JoyAxisDeadZone then
            begin
              if not JoyAxisMustRelease then
              begin
                SelectNext;
                Repaint;
                JoyAxisMustRelease := True;
              end;
            end
            else
              JoyAxisMustRelease := False;
        axR:
          if Joypos.R < -JoyAxisDeadZone then
          begin
            if not JoyAxisMustRelease then
            begin
              SelectPrev;
              Repaint;
              JoyAxisMustRelease := True;
            end;
          end
          else
            if JoyPos.R > JoyAxisDeadZone then
            begin
              if not JoyAxisMustRelease then
              begin
                SelectNext;
                Repaint;
                JoyAxisMustRelease := True;
              end;
            end
            else
              JoyAxisMustRelease := False;
        axU:
          if Joypos.U < -JoyAxisDeadZone then
          begin
            if not JoyAxisMustRelease then
            begin
              SelectPrev;
              Repaint;
              JoyAxisMustRelease := True;
            end;
          end
          else
            if JoyPos.U > JoyAxisDeadZone then
            begin
              if not JoyAxisMustRelease then
              begin
                SelectNext;
                Repaint;
                JoyAxisMustRelease := True;
              end;
            end
            else
              JoyAxisMustRelease := False;
        axV:
          if Joypos.V < -JoyAxisDeadZone then
          begin
            if not JoyAxisMustRelease then
            begin
              SelectPrev;
              Repaint;
              JoyAxisMustRelease := True;
            end;
          end
          else
            if JoyPos.V > JoyAxisDeadZone then
            begin
              if not JoyAxisMustRelease then
              begin
                SelectNext;
                Repaint;
                JoyAxisMustRelease := True;
              end;
            end
            else
              JoyAxisMustRelease := False;
      end;
end;

procedure TMainLauncherForm.JoyPadPOVChanged(Sender: TNLDJoystick;
  Degrees: Single);
begin
  if not JoyPovSelection then exit;

  if (Degrees >= JoyPovLeftMin) and (Degrees <= JoyPovLeftMax) then
  begin
    if not JoyPovMustRelease then
    begin
      SelectPrev;
      Repaint;
      JoyPovMustRelease := True;
    end;
  end
  else
    if (Degrees >= JoyPovRightMin) and (Degrees <= JoyPovRightMax) then
    begin
      if not JoyPovMustRelease then
      begin
        SelectNext;
        Repaint;
        JoyPovMustRelease := True;
      end;
    end
    else
      JoyPovMustRelease := False;
end;

end.
