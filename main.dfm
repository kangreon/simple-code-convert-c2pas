object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 290
  ClientWidth = 493
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 487
    Height = 89
    Align = alTop
    Lines.Strings = (
      'int av_bitstream_filter_filter(AVBitStreamFilterContext *bsfc,'
      
        '                               AVCodecContext *avctx, const char' +
        ' *args,'
      
        '                               uint8_t **poutbuf, int *poutbuf_s' +
        'ize,'
      
        '                               const uint8_t *buf, int buf_size,' +
        ' int keyframe);')
    TabOrder = 0
    ExplicitLeft = 48
    ExplicitTop = 56
    ExplicitWidth = 185
  end
  object Memo2: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 98
    Width = 487
    Height = 89
    Align = alTop
    Lines.Strings = (
      'Memo2')
    TabOrder = 1
    ExplicitLeft = -2
  end
  object Panel1: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 256
    Width = 487
    Height = 31
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 212
    object Button1: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 75
      Height = 25
      Align = alLeft
      Caption = 'function'
      TabOrder = 0
      OnClick = Button1Click
      ExplicitLeft = 0
    end
    object Button2: TButton
      AlignWithMargins = True
      Left = 84
      Top = 3
      Width = 75
      Height = 25
      Align = alLeft
      Caption = 'Func buf'
      TabOrder = 1
      OnClick = Button2Click
      ExplicitLeft = 88
      ExplicitTop = 8
    end
  end
  object Edit1: TEdit
    AlignWithMargins = True
    Left = 3
    Top = 193
    Width = 487
    Height = 21
    Align = alTop
    TabOrder = 3
    Text = 'Edit1'
    OnChange = Edit1Change
    ExplicitWidth = 121
  end
end
