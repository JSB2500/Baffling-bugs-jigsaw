object Main: TMain
  Left = 242
  Top = 172
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Baffling Bugs Jigsaw'
  ClientHeight = 324
  ClientWidth = 334
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 256
    Width = 66
    Height = 13
    Caption = 'Current piece:'
  end
  object Label2: TLabel
    Left = 8
    Top = 280
    Width = 113
    Height = 13
    Caption = 'Num combinations tried:'
  end
  object Label3: TLabel
    Left = 8
    Top = 304
    Width = 122
    Height = 13
    Caption = 'Combinations per second:'
  end
  object InitialiseButton: TButton
    Left = 256
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Initialise'
    TabOrder = 0
    OnClick = InitialiseButtonClick
  end
  object OutputControl: TScrollBoxWithCanvas
    Left = 8
    Top = 8
    Width = 241
    Height = 241
    TabOrder = 1
    OnPaint = OutputControlPaint
  end
  object PieceIndexUpDownContro: TUpDown
    Left = 256
    Top = 39
    Width = 16
    Height = 24
    TabOrder = 2
    OnClick = PieceIndexUpDownControClick
  end
  object PieceIndexControl: TEditInteger
    Left = 280
    Top = 40
    Width = 49
    Height = 21
    AllowBlank = False
    UseDefault = False
    DefaultValue = 0
    ReadOnly = True
    TabOrder = 3
    Value = 0
    CheckMinValue = True
    MinValue = 0
    CheckMaxValue = True
    MaxValue = 0
  end
  object TestPiecesControl: TCheckBox
    Left = 256
    Top = 72
    Width = 73
    Height = 17
    Caption = 'Test pieces'
    TabOrder = 4
    OnClick = TestPiecesControlClick
  end
  object GroupBox1: TGroupBox
    Left = 256
    Top = 96
    Width = 73
    Height = 89
    Caption = 'Rotation'
    TabOrder = 5
    object Rotate0Control: TRadioButton
      Left = 8
      Top = 16
      Width = 50
      Height = 17
      Caption = '0'
      TabOrder = 0
      OnClick = Rotate0ControlClick
    end
    object Rotate90Control: TRadioButton
      Left = 8
      Top = 32
      Width = 50
      Height = 17
      Caption = '90'
      TabOrder = 1
      OnClick = Rotate0ControlClick
    end
    object Rotate180Control: TRadioButton
      Left = 8
      Top = 48
      Width = 50
      Height = 17
      Caption = '180'
      TabOrder = 2
      OnClick = Rotate0ControlClick
    end
    object Rotate270Control: TRadioButton
      Left = 8
      Top = 64
      Width = 50
      Height = 17
      Caption = '270'
      TabOrder = 3
      OnClick = Rotate0ControlClick
    end
  end
  object SolveButton: TButton
    Left = 256
    Top = 192
    Width = 75
    Height = 25
    Caption = 'Solve'
    TabOrder = 6
    OnClick = SolveButtonClick
  end
  object StopButton: TButton
    Left = 256
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 7
    OnClick = StopButtonClick
  end
  object CurrentPieceIndexControl: TEditInteger
    Left = 136
    Top = 253
    Width = 113
    Height = 21
    AllowBlank = False
    UseDefault = False
    DefaultValue = 0
    TabOrder = 8
    Value = 0
    CheckMinValue = True
    MinValue = 0
    CheckMaxValue = True
    MaxValue = 0
  end
  object ShowControl: TCheckBox
    Left = 256
    Top = 304
    Width = 73
    Height = 17
    Caption = 'Show'
    TabOrder = 11
  end
  object CombinationsPerSecondControl: TEditNumber
    Left = 136
    Top = 301
    Width = 113
    Height = 21
    AllowBlank = False
    UseDefault = False
    DisplayFormat = enfSignificantFigures
    Precision = 5
    ReadOnly = True
    TabOrder = 10
    CheckMinValue = True
    CheckMaxValue = True
  end
  object NumCombinationsTriedControl: TEditNumber
    Left = 136
    Top = 276
    Width = 113
    Height = 21
    AllowBlank = False
    UseDefault = False
    DisplayFormat = enfSignificantFigures
    Precision = 5
    ReadOnly = True
    TabOrder = 9
    CheckMinValue = True
    CheckMaxValue = True
  end
end
