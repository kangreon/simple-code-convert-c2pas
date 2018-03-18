unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  IniFiles;

type
  TForm2 = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Edit1: TEdit;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    function ConvertFunction(const S: string): string;
    function ClearText(Text: string): string;
    function SkipSpace(const S: string; var Index: Integer): Boolean;
    function GetTextSize(const S: string; Index, Size: Integer): string;
    function FindCharNotBackSlash(const S: string; Index: Integer;
      C: Char): Integer;
    function GetWords(const S: string): TStrings;
    function GetCName(const S: string; var Index: Integer): string;
    function GetCNum(const S: string; var Index: Integer): string;
    function GetLine(var Source: TStrings): TStringList;
    function ConvertVariable(VarC: TStrings; out IsConst: Boolean): string;
    function CType2Pas(const S: string; out IsReplace: Boolean): string;
    function ConvertVariables(Words: TStrings): string;
    function GetVariable(var Source: TStrings): TStrings;
    { Private declarations }
  public
    FIni: TIniFile;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
begin
  Memo2.Lines.Text := ConvertFunction(Memo1.Lines.Text);
end;

function TForm2.SkipSpace(const S: string; var Index: Integer): Boolean;
var
  c, i: Integer;
begin
  if Index < 1 then Index := 1;

  c := Length(s);
  for i := Index to c do
  begin
    if CharInSet(S[i], [' ', #9, #13]) then
    begin
      Index := i;
    end
    else
    begin
      Index := i;
      Result := True;
      Exit;
    end;
  end;

  Index := c + 1;
  Result := False;
end;

function TForm2.GetTextSize(const S: string; Index, Size: Integer): string;
begin
  Result := Copy(S, Index, Size);
  while Length(Result) <> Size do
    Result := Result + ' ';
end;

function TForm2.FindCharNotBackSlash(const S: string; Index: Integer;
  C: Char): Integer;
var
  i, j: Integer;
begin
  Result := 0;

  repeat
    i := Pos('\' + C, S, Index);
    j := Pos(C, S, Index);

    if (i = 0) then i := j + 1;
    if (j = 0) then Exit;

  until j < i;

  Result := j;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  FIni := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Settings.ini');
  Edit1.Text := FIni.ReadString('main', 'ext', '');
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  Memo1.Clear;
  Memo1.PasteFromClipboard;
  Button1.Click;
  Memo2.SelectAll;
  Memo2.CopyToClipboard;
end;

function TForm2.ClearText(Text: string): string;
var
  S, Tag: string;
  Index, i: Integer;
begin
  S := Trim(StringReplace(Text, #13#10, #13, [rfReplaceAll]));
  Result := '';
  Index := 1;
  while Index <= Length(S) do
  begin
    Tag := GetTextSize(S, Index, 2);
    if (Tag[1] = '/') and (Tag[2] = '/') then
    begin
      i := Pos(#13, S, Index);
      // Комментарий заканчивает этот файл
      if i = 0 then Break;
      Index := i;
    end
    else if (Tag[1] = '/') and (Tag[2] = '*') then
    begin
      i := Pos('*/', S, Index);

      if i = 0 then Break;
      Index := i + 2;
    end
    else if (Tag[1] = '(') and (Tag[2] = '*') then
    begin
      i := Pos('*)', S, Index);

      if i = 0 then Break;
      Index := i + 2;
    end
    else if Tag[1] = '"' then
    begin
      i := FindCharNotBackSlash(S, Index, '"');
      if i = 0 then Break;

      Result := Copy(S, Index, i - Index + 1);
      Index := i + 1;
    end
    else if Tag[1] = '''' then
    begin
      i := FindCharNotBackSlash(S, Index, '''');
      if i = 0 then Break;

      Result := Result + Copy(S, Index, i - Index + 1);
      Index := i + 1;
    end
    else
    begin
      if (S[Index] = #13) or (S[Index] = #9) then
        S[Index] := ' ';

      if S[Index] = ' ' then
      begin
        if (Result <> '') and (Result[Length(Result)] <> ' ') then
          Result := Result + S[Index];
      end
      else
      begin
        if CharInSet(S[Index], ['(', ')', '*', ';', '[', ']', ',']) then
        begin
          Result := TrimRight(Result);
        end;

        Result := Result + S[Index];
      end;

      Index := Index + 1;
    end;
  end;
end;

function TForm2.GetCName(const S: string; var Index: Integer): string;
var
  i, c: Integer;
begin
  Result := '';
  c := Length(S);
  for i := Index to c do
  begin
    if CharInSet(S[i], ['a'..'z', 'A'..'Z', '_', '0'..'9']) then
    begin
      Result := Result + S[i];
      Index := i + 1;
    end
    else
    begin
      Index := i;
      Break;
    end;
  end;
end;

function TForm2.GetCNum(const S: string; var Index: Integer): string;
var
  i, c: Integer;
begin
  c := Length(S);
  for i := Index to c do
  begin
    if CharInSet(S[i], ['0'..'9']) or ((Result = '0') and (S[i] = 'x')) then
    begin
      Result := Result + S[i];
      Index := i + 1;
    end
    else
    begin
      Index := i;
      Break;
    end;
  end;
end;

function TForm2.GetWords(const S: string): TStrings;
var
  Index, i: Integer;
  C: Char;
begin
  Result := TStringList.Create;
  Index := 1;

  while Index <= Length(S) do
  begin
    C := S[Index];
    case C of
      '"', '''':
        begin
          i := FindCharNotBackSlash(S, Index, C);
          if i = 0 then Break;
          Result.Add(Copy(S, Index, i - Index + 1));
          Index := i + 1;
        end;
      'a'..'z', 'A'..'Z', '_':
        begin
          Result.Add(GetCName(S, Index));
        end;

      '0'..'9':
        Result.Add(GetCNum(S, Index));
      ' ':
        begin
          Inc(Index);
        end
    else
      Result.Add(S[Index]);
      Inc(Index);
    end;
  end;
end;

function TForm2.GetLine(var Source: TStrings): TStringList;
var
  S: string;
begin
  Result := TStringList.Create;

  while Source.Count > 0 do
  begin
    S := Source[0];
    Result.Add(S);
    Source.Delete(0);
    if S = ';' then
      Break;
  end;
end;

function TForm2.CType2Pas(const S: string; out IsReplace: Boolean): string;
const
  CType: array of string = [
    'char',
    'signed char',
    'unsigned char',

    'short', 'short int', 'signed short', 'signed short int',
    'unsigned short', 'unsigned short int',

    'int', 'signed', 'signed int',
    'unsigned', 'unsigned int',

    'long', 'long int', 'signed long', 'signed long int',
    'unsigned long', 'unsigned long int', 'uint32_t',

    'long long', 'long long int', 'signed long long', 'signed long long int', 'int64_t',
    'unsigned long long', 'unsigned long long int', 'uint64_t',

    'float', 'double', 'long double',
    'size_t', 'uint8_t',
    'void',

    'int8_t'
  ];

  PasType: array of string = [
    'AnsiChar',
    'AnsiChar',
    'AnsiChar',

    'SmallInt', 'SmallInt', 'SmallInt', 'SmallInt',
    'Word', 'Word',

    'Integer', 'Integer', 'Integer',
    'Cardinal', 'Cardinal',

    'Integer', 'Integer', 'Integer', 'Integer',
    'Cardinal', 'Cardinal', 'UInt32',

    'Int64', 'Int64', 'Int64', 'Int64', 'Int64',
    'UInt64', 'UInt64', 'UInt64',

    'Float', 'Double', 'External',
    'NativeUInt', 'UInt8',
    'Pointer',

    'SmallInt'
  ];
var
  i, c: Integer;
begin
  Result := S;
  IsReplace := False;
  c := Length(CType);
  for i := 0 to c - 1 do
  begin
    if S = CType[i] then
    begin
      IsReplace := True;
      Result := PasType[i];
      Break;
    end;
  end;
end;

procedure TForm2.Edit1Change(Sender: TObject);
begin
  FIni.WriteString('main', 'ext', Edit1.Text);
end;

function TForm2.ConvertVariable(VarC: TStrings; out IsConst: Boolean): string;
var
  Str: TStrings;
  VarType, PasType: string;
  IsReplace: Boolean;
  StarCount, i: Integer;
begin
  Result := '';
  IsConst := False;
  if VarC.Count = 0 then Exit;

  Str := TStringList.Create;
  Str.Assign(VarC);
  try
    if Str[0] = 'const' then
    begin
      IsConst := True;
      Str.Delete(0);
    end
    else if Str[0] = 'enum' then
    begin
      Str.Delete(0);
    end;

    VarType := '';
    while Str.Count > 0 do
    begin
      if Str[0] <> '*' then
      begin
        VarType := VarType + ' ' + Str[0];
        Str.Delete(0);
      end
      else
        Break;
    end;

    PasType := CType2Pas(Trim(VarType), IsReplace);
    StarCount := 0;

    while Str.Count > 0 do
    begin
      if Str[0] = 'const' then
      begin
        Str.Delete(0);
        IsConst := True;
      end
      else if Str[0] = '*' then
      begin
        Inc(StarCount);
        Str.Delete(0);
      end
      else
        Str.Delete(0);
    end;

    if StarCount > 0 then
    begin
      if PasType = 'UInt8' then
        PasType := 'Byte';

      if PasType = 'Pointer' then
        Dec(StarCount);

      for i := 0 to StarCount - 1 do
        PasType := 'P' + PasType;
    end
    else
    begin
      if not IsReplace or (PasType = 'Pointer') then
        PasType := 'T' + PasType;
    end;

    Result := PasType;
  finally
    Str.Free;
  end;
end;

function TForm2.GetVariable(var Source: TStrings): TStrings;
begin
  Result := TStringList.Create;

  while Source.Count > 0 do
  begin
    if Source[0] = ',' then
    begin
      Source.Delete(0);
      Break;
    end
    else
    begin
      Result.Add(Source[0]);
      Source.Delete(0);
    end;
  end;
end;

function TForm2.ConvertVariables(Words: TStrings): string;
var
  VarList: TStrings;
  VarName, VarType: string;
  IsConst: Boolean;
begin
  Result := '';
  if Words.Count < 2 then
    Exit;
  while Words.Count > 0 do
  begin
    VarList := GetVariable(Words);
    try
      if VarList.Count < 2 then
        raise Exception.Create(Words.Text);

      VarName := VarList[VarList.Count - 1];
      VarList.Delete(VarList.Count - 1);

      VarType := ConvertVariable(VarList, IsConst);

      Result := Result + '; ';
      if IsConst then
        Result := Result + 'const ';

      if VarName = 'type' then
        VarName := 'type_';

      Result := Result + VarName + ': ' + VarType;
    finally
      VarList.Free;
    end;
  end;

  if Length(Result) > 2 then
    Delete(Result, 1, 2);
end;

function TForm2.ConvertFunction(const S: string): string;
var
  W, RetList, Words, VarList: TStrings;
  Line, FuncName, RetType, FuncLine: string;
  i, FunctionParamStart, FunctionParamEnd: Integer;
  IsConst: Boolean;
begin
  Result := ClearText(S);
  W := GetWords(Result);
  Result := '';
  try
    while W.Count > 0 do
    begin
      Words := GetLine(W);
      RetList := TStringList.Create;
      VarList := TStringList.Create;
      try
        FunctionParamStart := Words.IndexOf('(');
        FunctionParamEnd := -1;
        for i := Words.Count - 1 downto 0 do
          if Words[i] = ')' then
          begin
            FunctionParamEnd := i;
            Break;
          end;

        for i := FunctionParamStart + 1 to FunctionParamEnd - 1 do
          VarList.Add(Words[i]);

        if (FunctionParamStart = -1) or (FunctionParamEnd = -1) then
        begin
          Result := 'Не найдены параметры функции';
          Exit;
        end;

        for i := 0 to FunctionParamStart - 2 do
          RetList.Add(Words[i]);

        if FunctionParamStart <= 1 then
        begin
          Result := 'ParseError 1';
          Exit;
        end;

        RetType := ConvertVariable(RetList, IsConst);
        FuncName := Words[FunctionParamStart - 1];

        if RetType = 'TPointer' then
          FuncLine := 'procedure '
        else
          FuncLine := 'function ';

        FuncLine := FuncLine + FuncName;
        if True {Param exist} then
        begin
          FuncLine := FuncLine + '(' + ConvertVariables(VarList) + ')';
        end;

        if RetType <> 'TPointer' then
          FuncLine := FuncLine + ': ' + RetType;

        FuncLine := FuncLine + ';';

        while Length(FuncLine) < 79 do
        begin
          FuncLine := FuncLine + ' ';
        end;

        FuncLine := FuncLine + ' ' + Edit1.Text;

        Result := Result + FuncLine + #13#10;
      finally
        VarList.Free;
        RetList.Free;
        Words.Free;
      end;
    end;

//    Result := W.Text;
  finally
    W.Free;
  end;
end;

end.
