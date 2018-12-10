unit Utils;

interface

uses
  GDIPAPI, GDIPOBJ, System.Types, Winapi.Windows, System.SysUtils, Vcl.Graphics;

procedure RotateFlipBitmap(Bitmap, Dest: TBitmap; RotateFlipType: TRotateFlipType);
procedure SmoothScaleBitmap(Source, Dest: TBitmap; OutWidth, OutHeight: integer);
function ForceForegroundWindow(hwnd: THandle): Boolean;

implementation

//https://www.nldelphi.com/showthread.php?42769-Bitmap-90-graden-roteren&p=358213&viewfull=1#post358213
//GolezTrol
procedure RotateFlipBitmap(Bitmap, Dest: TBitmap; RotateFlipType: TRotateFlipType);
var
  GdipBitmap: Pointer;
  NewBitmap: HBITMAP;
begin
  GdipCreateBitmapFromHBITMAP(Bitmap.Handle, 0, GdipBitmap);
  GdipImageRotateFlip(GdipBitmap, RotateFlipType);
  GdipCreateHBITMAPFromBitmap(GdipBitmap, NewBitmap, 0);
  Dest.Handle := NewBitmap;
end;

//https://stackoverflow.com/questions/33608134/fast-way-to-resize-an-image-mixing-fmx-and-vcl-code
//Dalija Prasnikar
procedure SmoothScaleBitmap(Source, Dest: TBitmap; OutWidth, OutHeight: integer);
var
  src, dst: TGPBitmap;
  g: TGPGraphics;
  h: HBITMAP;
begin
  src := TGPBitmap.Create(Source.Handle, 0);
  try
    dst := TGPBitmap.Create(OutWidth, OutHeight);
    try
      g := TGPGraphics.Create(dst);
      try
        g.SetInterpolationMode(InterpolationModeHighQuality);
        g.SetPixelOffsetMode(PixelOffsetModeHighQuality);
        g.SetSmoothingMode(SmoothingModeHighQuality);
        g.DrawImage(src, 0, 0, dst.GetWidth, dst.GetHeight);
      finally
        g.Free;
      end;
      dst.GetHBITMAP(0, h);
      Dest.Handle := h;
    finally
      dst.Free;
    end;
  finally
    src.Free;
  end;
end;

//https://www.swissdelphicenter.ch/en/showcode.php?id=261
//unknown

{
  Windows 98/2000 doesn't want to foreground a window when
  some other window has the keyboard focus.
  ForceForegroundWindow is an enhanced SetForeGroundWindow/bringtofront
  function to bring a window to the front.
}


{
  Manchmal funktioniert die SetForeGroundWindow Funktion
  nicht so, wie sie sollte; besonders unter Windows 98/2000,
  wenn ein anderes Fenster den Fokus hat.
  ForceForegroundWindow ist eine "verbesserte" Version von
  der SetForeGroundWindow API-Funktion, um ein Fenster in
  den Vordergrund zu bringen.
}


function ForceForegroundWindow(hwnd: THandle): Boolean;
const
  SPI_GETFOREGROUNDLOCKTIMEOUT = $2000;
  SPI_SETFOREGROUNDLOCKTIMEOUT = $2001;
var
  ForegroundThreadID: DWORD;
  ThisThreadID: DWORD;
  timeout: DWORD;
begin
  if IsIconic(hwnd) then ShowWindow(hwnd, SW_RESTORE);

  if GetForegroundWindow = hwnd then Result := True
  else
  begin
    // Windows 98/2000 doesn't want to foreground a window when some other
    // window has keyboard focus

    if ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion > 4)) or
      ((Win32Platform = VER_PLATFORM_WIN32_WINDOWS) and
      ((Win32MajorVersion > 4) or ((Win32MajorVersion = 4) and
      (Win32MinorVersion > 0)))) then
    begin
      // Code from Karl E. Peterson, www.mvps.org/vb/sample.htm
      // Converted to Delphi by Ray Lischner
      // Published in The Delphi Magazine 55, page 16

      Result := False;
      ForegroundThreadID := GetWindowThreadProcessID(GetForegroundWindow, nil);
      ThisThreadID := GetWindowThreadPRocessId(hwnd, nil);
      if AttachThreadInput(ThisThreadID, ForegroundThreadID, True) then
      begin
        BringWindowToTop(hwnd); // IE 5.5 related hack
        SetForegroundWindow(hwnd);
        AttachThreadInput(ThisThreadID, ForegroundThreadID, False);
        Result := (GetForegroundWindow = hwnd);
      end;
      if not Result then
      begin
        // Code by Daniel P. Stasinski
        SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @timeout, 0);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(0),
          SPIF_SENDCHANGE);
        BringWindowToTop(hwnd); // IE 5.5 related hack
        SetForegroundWindow(hWnd);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(timeout), SPIF_SENDCHANGE);
      end;
    end
    else
    begin
      BringWindowToTop(hwnd); // IE 5.5 related hack
      SetForegroundWindow(hwnd);
    end;

    Result := (GetForegroundWindow = hwnd);
  end;
end; { ForceForegroundWindow }


end.
