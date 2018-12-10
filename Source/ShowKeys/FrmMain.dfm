object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Showkeys'
  ClientHeight = 95
  ClientWidth = 371
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object lblButtonPressed: TLabel
    Left = 0
    Top = 0
    Width = 371
    Height = 95
    Align = alClient
    Alignment = taCenter
    Caption = 'Press a button on the keyboard to see it'#39's code ...'
    Layout = tlCenter
    ExplicitWidth = 242
    ExplicitHeight = 13
  end
end
