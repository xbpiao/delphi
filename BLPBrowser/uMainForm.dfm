object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'BLP'#27983#35272
  ClientHeight = 413
  ClientWidth = 561
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = mm1
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object btn1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btn1'
    TabOrder = 0
    OnClick = btn1Click
  end
  object scrlbx1: TScrollBox
    Left = 0
    Top = 0
    Width = 561
    Height = 413
    Align = alClient
    TabOrder = 1
    object img1: TImage
      Left = 0
      Top = 0
      Width = 105
      Height = 105
      AutoSize = True
    end
  end
  object mm1: TMainMenu
    Left = 304
    Top = 80
    object N1: TMenuItem
      Caption = #25991#20214
      object jpg1: TMenuItem
        Caption = #21516#21517#36716#25442#20026'jpg'
        ShortCut = 113
        OnClick = jpg1Click
      end
      object bmp1: TMenuItem
        Caption = #21516#21517#36716#25442#20026'bmp'
        ShortCut = 114
        OnClick = bmp1Click
      end
      object blp1: TMenuItem
        Caption = #21516#21517#36716#25442#20026'blp'
        ShortCut = 115
        OnClick = blp1Click
      end
      object N2: TMenuItem
        Caption = #21478#23384#20026'...'
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object N4: TMenuItem
        Caption = #36864#20986
        OnClick = N4Click
      end
    end
    object N5: TMenuItem
      Caption = #20851#20110
      object Piao409934701: TMenuItem
        Caption = 'Piao40993470'
      end
    end
  end
  object aplctnvnts1: TApplicationEvents
    OnMessage = aplctnvnts1Message
    Left = 288
    Top = 200
  end
end
