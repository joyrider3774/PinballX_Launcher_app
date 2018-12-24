object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'ShowJoypad'
  ClientHeight = 159
  ClientWidth = 467
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblInfo: TLabel
    Left = 0
    Top = 0
    Width = 467
    Height = 159
    Align = alClient
    Alignment = taCenter
    Caption = 'Please Attach a joypad / joystick'
    Layout = tlCenter
    ExplicitWidth = 157
    ExplicitHeight = 13
  end
  object JoyPad: TNLDJoystick
    Active = True
    Advanced = True
    OnButtonDown = JoyPadButtonDown
    OnMove = JoyPadMove
    OnPOVChanged = JoyPadPOVChanged
    Left = 80
    Top = 16
  end
  object tmrJoyenable: TTimer
    Interval = 250
    OnTimer = tmrJoyenableTimer
    Left = 24
    Top = 16
  end
end
