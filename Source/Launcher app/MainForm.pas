unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ButtonGroup, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Imaging.pngimage, System.Types;

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

type
  TButtonRec = record
    Param: String;
    Text: String;
    Enabled: Boolean;
  end;

  TMainLauncherForm = class(TForm)
    tmr1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
    StartTickCount, SecondsRunning, PrevSecondsRunning: Cardinal;
    FNumLastRowsNotVisible, FNumFirstRowsNotVisible: Integer;
    BitMapBuffer, BitmapRotated, BitMapScaled: TBitmap;
    PngBackGround, PngSelection, PngNoSelection: TPngImage;
    Path, LaunchParams, StartParams, Title: String;
    LeftKey, RightKey, LaunchKey, QuitKey: Word;
    ScaleM, ScaleD, SelectedButton, DoRotate: Integer;
    Buttons: Array[1..NumButtonRows*NumButtonCols] of TButtonRec;
    DontSaveIni, DontReadSteamPathReg, SmoothResizeDraw: Boolean;
    procedure CMDialogKey(var msg: TCMDialogKey); message CM_DIALOGKEY;
    procedure DoLaunch(const aParams: String);
    procedure SetSelectedButton(Index:Integer);
    procedure SelectNext;
    procedure SelectPrev;
    procedure SaveIni;
    procedure LoadIni;
    procedure CaclulateNumLastRowsNotVisible;
    procedure CaclulateNumFirstRowsNotVisible;
  public
    { Public declarations }
  end;

var
  MainLauncherForm: TMainLauncherForm;

implementation

{$R *.dfm}

uses
  System.Win.Registry, System.IniFiles, Winapi.ShellAPI, GDIPAPI, Utils, System.Math;


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
      if Buttons[Button].Enabled then
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
      if Buttons[Button].Enabled then
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
  ForceForegroundWindow(Self.Handle);
  PrevSecondsRunning := SecondsRunning;
  SecondsRunning := (GetTickCount - StartTickCount) div 1000;

  //need to repaint to force showing countdown timer
  if PrevSecondsRunning <> SecondsRunning then
    Repaint;

  if SecondsRunning >= AutoLaunchInSecs then
  begin
    tmr1.Enabled := False;
    SecondsRunning := AutoLaunchInSecs;
    DoLaunch(Buttons[SelectedButton].Param);
  end;
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
    ScaleM := IniFile.ReadInteger('SETTINGS', 'SCALEM', 1);
    ScaleD := IniFile.ReadInteger('SETTINGS', 'SCALED', 1);
    DoRotate := IniFile.ReadInteger('SETTINGS', 'ROTATE', 3);
    DontSaveIni := IniFile.ReadBool('SETTINGS', 'DONTSAVEINIONEXIT', False);

    DontReadSteamPathReg := IniFile.ReadBool('SETTINGS', 'DONTREADSTEAMPATHREG', False);
    SmoothResizeDraw := IniFile.ReadBool('SETTINGS', 'SMOOTHRESIZEDRAW', True);

    Title := IniFile.ReadString('SETTINGS', 'TITLE', 'Pinball FX3 Launcher');
    Buttons[1].Text := IniFile.ReadString('BUTTON_ONE', 'TEXT', 'One Player (Normal)');
    Buttons[1].Enabled := IniFile.ReadBool('BUTTON_ONE', 'ENABLED', True);
    Buttons[1].Param := IniFile.ReadString('BUTTON_ONE', 'PARAM', '');

    Buttons[2].Text := IniFile.ReadString('BUTTON_TWO', 'TEXT', 'Two Players (Normal)');
    Buttons[2].Enabled := IniFile.ReadBool('BUTTON_TWO', 'ENABLED', True);
    Buttons[2].Param := IniFile.ReadString('BUTTON_TWO', 'PARAM', '-hotseat_2');

    Buttons[3].Text := IniFile.ReadString('BUTTON_THREE', 'TEXT', 'Three Players (Normal)');
    Buttons[3].Enabled := IniFile.ReadBool('BUTTON_THREE', 'ENABLED', True);
    Buttons[3].Param := IniFile.ReadString('BUTTON_THREE', 'PARAM', '-hotseat_3');

    Buttons[4].Text := IniFile.ReadString('BUTTON_FOUR', 'TEXT', 'Four Players (Normal)');
    Buttons[4].Enabled := IniFile.ReadBool('BUTTON_FOUR', 'ENABLED', True);
    Buttons[4].Param := IniFile.ReadString('BUTTON_FOUR', 'PARAM', '-hotseat_4');

    Buttons[5].Text := IniFile.ReadString('BUTTON_FIVE', 'TEXT', 'One Player (Classic)');
    Buttons[5].Enabled := IniFile.ReadBool('BUTTON_FIVE', 'ENABLED', True);
    Buttons[5].Param := IniFile.ReadString('BUTTON_FIVE', 'PARAM', '-class');

    Buttons[6].Text := IniFile.ReadString('BUTTON_SIX', 'TEXT', 'Two Players (Classic)');
    Buttons[6].Enabled := IniFile.ReadBool('BUTTON_SIX', 'ENABLED', True);
    Buttons[6].Param := IniFile.ReadString('BUTTON_SIX', 'PARAM', '-class -hotseat_2');

    Buttons[7].Text := IniFile.ReadString('BUTTON_SEVEN', 'TEXT', 'Three Players (Classic)');
    Buttons[7].Enabled := IniFile.ReadBool('BUTTON_SEVEN', 'ENABLED', True);
    Buttons[7].Param := IniFile.ReadString('BUTTON_SEVEN', 'PARAM', '-class -hotseat_3');

    Buttons[8].Text := IniFile.ReadString('BUTTON_EIGHT', 'TEXT', 'Four Players (Classic)');
    Buttons[8].Enabled  := IniFile.ReadBool('BUTTON_EIGHT', 'ENABLED', True);
    Buttons[8].Param := IniFile.ReadString('BUTTON_EIGHT', 'PARAM', '-class -hotseat_4');

    Buttons[9].Text := IniFile.ReadString('BUTTON_NINE', 'TEXT', '');
    Buttons[9].Enabled  := IniFile.ReadBool('BUTTON_NINE', 'ENABLED', False);
    Buttons[9].Param := IniFile.ReadString('BUTTON_NINE', 'PARAM', '');

    Buttons[10].Text := IniFile.ReadString('BUTTON_TEN', 'TEXT', '');
    Buttons[10].Enabled  := IniFile.ReadBool('BUTTON_TEN', 'ENABLED', False);
    Buttons[10].Param := IniFile.ReadString('BUTTON_TEN', 'PARAM', '');

    Buttons[11].Text := IniFile.ReadString('BUTTON_ELEVEN', 'TEXT', '');
    Buttons[11].Enabled  := IniFile.ReadBool('BUTTON_ELEVEN', 'ENABLED', False);
    Buttons[11].Param := IniFile.ReadString('BUTTON_ELEVEN', 'PARAM', '');

    Buttons[12].Text := IniFile.ReadString('BUTTON_TWELVE', 'TEXT', '');
    Buttons[12].Enabled  := IniFile.ReadBool('BUTTON_TWELVE', 'ENABLED', False);
    Buttons[12].Param := IniFile.ReadString('BUTTON_TWELVE', 'PARAM', '');

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
    IniFile.WriteInteger('SETTINGS','SCALEM', ScaleM);
    IniFile.WriteInteger('SETTINGS','SCALED', ScaleD);
    IniFile.WriteBool('SETTINGS', 'DONTSAVEINIONEXIT', DontSaveIni);
    IniFile.WriteString('SETTINGS', 'TITLE', Title);
    IniFile.WriteBool('SETTINGS', 'DONTREADSTEAMPATHREG', DontReadSteamPathReg);
    IniFile.WriteInteger('SETTINGS', 'LASTACTIVEBUTTON', SelectedButton);
    IniFile.WriteInteger('SETTINGS', 'ROTATE', DoRotate);
    IniFile.WriteBool('SETTINGS', 'SMOOTHRESIZEDRAW', SmoothResizeDraw);


    IniFile.WriteString('BUTTON_ONE', 'TEXT',  Buttons[1].Text);
    IniFile.WriteBool('BUTTON_ONE', 'ENABLED', Buttons[1].Enabled);
    IniFile.WriteString('BUTTON_ONE', 'PARAM', Buttons[1].Param);

    IniFile.WriteString('BUTTON_TWO', 'TEXT', Buttons[2].Text);
    IniFile.WriteBool('BUTTON_TWO', 'ENABLED', Buttons[2].Enabled);
    IniFile.WriteString('BUTTON_TWO', 'PARAM', Buttons[2].Param);

    IniFile.WriteString('BUTTON_THREE', 'TEXT', Buttons[3].Text);
    IniFile.WriteBool('BUTTON_THREE', 'ENABLED', Buttons[3].Enabled);
    IniFile.WriteString('BUTTON_THREE', 'PARAM', Buttons[3].Param);

    IniFile.WriteString('BUTTON_FOUR', 'TEXT', Buttons[4].Text);
    IniFile.WriteBool('BUTTON_FOUR', 'ENABLED', Buttons[4].Enabled);
    IniFile.WriteString('BUTTON_FOUR', 'PARAM', Buttons[4].Param);

    IniFile.WriteString('BUTTON_FIVE', 'TEXT',  Buttons[5].Text );
    IniFile.WriteBool('BUTTON_FIVE', 'ENABLED', Buttons[5].Enabled);
    IniFile.WriteString('BUTTON_FIVE', 'PARAM', Buttons[5].Param);

    IniFile.WriteString('BUTTON_SIX', 'TEXT', Buttons[6].Text);
    IniFile.WriteBool('BUTTON_SIX', 'ENABLED', Buttons[6].Enabled);
    IniFile.WriteString('BUTTON_SIX', 'PARAM', Buttons[6].Param);

    IniFile.WriteString('BUTTON_SEVEN', 'TEXT', Buttons[7].Text);
    IniFile.WriteBool('BUTTON_SEVEN', 'ENABLED', Buttons[7].Enabled);
    IniFile.WriteString('BUTTON_SEVEN', 'PARAM', Buttons[7].Param);

    IniFile.WriteString('BUTTON_EIGHT', 'TEXT', Buttons[8].Text);
    IniFile.WriteBool('BUTTON_EIGHT', 'ENABLED', Buttons[8].Enabled);
    IniFile.WriteString('BUTTON_EIGHT', 'PARAM', Buttons[8].Param);

    IniFile.WriteString('BUTTON_NINE', 'TEXT', Buttons[9].Text);
    IniFile.WriteBool('BUTTON_NINE', 'ENABLED', Buttons[9].Enabled);
    IniFile.WriteString('BUTTON_NINE', 'PARAM', Buttons[9].Param);

    IniFile.WriteString('BUTTON_TEN', 'TEXT', Buttons[10].Text);
    IniFile.WriteBool('BUTTON_TEN', 'ENABLED', Buttons[10].Enabled );
    IniFile.WriteString('BUTTON_TEN', 'PARAM', Buttons[10].Param);

    IniFile.WriteString('BUTTON_ELEVEN', 'TEXT', Buttons[11].Text);
    IniFile.WriteBool('BUTTON_ELEVEN', 'ENABLED', Buttons[11].Enabled );
    IniFile.WriteString('BUTTON_ELEVEN', 'PARAM', Buttons[11].Param);

    IniFile.WriteString('BUTTON_TWELVE', 'TEXT', Buttons[12].Text);
    IniFile.WriteBool('BUTTON_TWELVE', 'ENABLED', Buttons[12].Enabled );
    IniFile.WriteString('BUTTON_TWELVE', 'PARAM', Buttons[12].Param);

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

  if SelectedButton > High(Buttons) then
    SelectedButton := Low(Buttons);

  if not Buttons[SelectedButton].Enabled then
  begin
    for Teller := SelectedButton to High(Buttons) do
      if Buttons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;

    for Teller := Low(Buttons) to SelectedButton do
      if Buttons[Teller].Enabled then
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

  if SelectedButton < Low(Buttons) then
    SelectedButton := High(Buttons);

  if not Buttons[SelectedButton].Enabled then
  begin
    for Teller := SelectedButton downto low(Buttons) do
      if Buttons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;

    for Teller := High(Buttons) downto SelectedButton do
      if Buttons[Teller].Enabled then
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
  if index < low(Buttons) then
    index := low(Buttons);
  if index > high(Buttons) then
    index := high(Buttons);

  //find next enabled button
  if not Buttons[Index].Enabled then
  begin
    for Teller := Index + 1 to Length(Buttons) do
      if Buttons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;

    for Teller := Low(Buttons) to Index -1 do
      if Buttons[Teller].Enabled then
      begin
        SelectedButton := Teller;
        exit;
      end;
  end;

  SelectedButton := Index;
end;

procedure TMainLauncherForm.DoLaunch(const aParams: string);
begin
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
  LaunchParams := '';
  ScaleM := 1;
  ScaleD := 1;
  SecondsRunning := 0;

  PngBackGround := TPngImage.Create;
  PngSelection := TPngImage.Create;
  PngNoSelection := TPngImage.Create;

  sFilePath := ExtractFilePath(ParamStr(0));
  PngBackGround.LoadFromFile(sFilePath + 'background.png');
  PngSelection.LoadFromFile(sFilePath + 'butselection.png');
  PngNoSelection.LoadFromFile(sFilePath + 'butnoselection.png');

  LoadIni;

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
  begin
    tmr1.Enabled := False;
    DoLaunch(Buttons[SelectedButton].Param);
  end;

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
  begin
    tmr1.Enabled := False;
    Application.Terminate;
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

  BitMapBuffer.Canvas.Font.Size := 17;
  TextRect.Left := 5;
  TextRect.Top := 5;
  TextRect.Width := BitMapBuffer.Width - 5;
  TextRect.Height := 50;
  DrawText(BitMapBuffer.Canvas.Handle, Title,
    -1, TextRect, DT_CENTER or DT_SINGLELINE);

  BitMapBuffer.Canvas.Font.Size := 10;
  TextRect.Left := 5;
  TextRect.Top := BitMapBuffer.Height - 20;
  TextRect.Width := BitMapBuffer.Width - 5;
  TextRect.Height := 20;
  DrawText(BitMapBuffer.Canvas.Handle,'Launcher Created by Willems Davy ' +
  '(Joyrider3774) - Launching in ' + IntToStr(AutoLaunchInSecs - SecondsRunning),
    -1, TextRect, DT_CENTER or DT_SINGLELINE);

  BitMapBuffer.Canvas.Font.Size := 15;
  for x := 0 to NumButtonCols - 1 do
    for y := 0 to NumButtonRows - 1 do
    begin
      button := y * NumButtonCols + x + 1;

      if Buttons[Button].Enabled then
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
        TextHeight := DrawText(BitMapBuffer.Canvas.Handle, Buttons[button].Text,
          -1, TextRect, DT_CENTER or DT_WORDBREAK or DT_EDITCONTROL or DT_CALCRECT);

        TextRect.Left := ((ButtonSize + ButtonSpacing) * x) + ButtonStartxPos + ButtonTextMargin;
        TextTop := ((ButtonSize + ButtonSpacing) * y) + ButtonStartyPos + ButtonVCenter + ButtonTextMargin + (((ButtonSize - (2 * ButtonTextMargin)) div 2) - (TextHeight div 2));
        if TextTop < ((ButtonSize + ButtonSpacing) * y) + ButtonStartyPos + ButtonVCenter + ButtonTextMargin then
          TextRect.Top := ((ButtonSize + ButtonSpacing) * y) + ButtonStartyPos + ButtonVCenter + ButtonTextMargin
        else
          TextRect.Top := TextTop;

        TextRect.Width := ButtonSize - (2 * ButtonTextMargin);
        TextRect.Height := ButtonSize - (2 * ButtonTextMargin);
        DrawText(BitMapBuffer.Canvas.Handle, Buttons[button].Text,
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

end.
