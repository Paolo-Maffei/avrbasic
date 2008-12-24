(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit
  MStrings;

{$N+}
interface
uses
{$IFDEF Win32}
  SysUtils
{$ELSE}
  Objects,
  Strings
{$ENDIF};

const
  HexNum: PCHAR = '0123456789ABCDEF';

const
  MaxChar = 512;
  FillChr: Char = ' ';

type
  PCString = ^CString;
  CString = array[0..MaxChar] of Char;

function Otsad(Txt: string): string;

procedure Add(Dest: PChar; Source: Char);
procedure Del(Txt: PChar; Start, Count: Integer);

function Isnumeric(Txt: string): Boolean;
function Isalpha(Ch: Char): Boolean;

function _Replace(Txt: string; Mida, Millega: Char): string;
function GetWord(var Txt: string; Erase: Boolean): string;
function KillSpace(Txt: string): string;
function ToLower(Txt: string): string;
function ToUpper(Txt: string): string;
function Mirror(Txt: string): string;
function L2Oct(Nr, Len: LongInt): string;
function Oct2L(Nr: LongInt): LongInt;
function L2Hex(Nr, Len: CARDINAL): string;
function L2Bin(bb: Byte): string;
function Bin2S(Txt: string): Byte;

function PasStr(S: string): PChar;
function I2C(Nr: Integer; Len: Byte): PChar;
function L2C(Nr: LongInt; Len: Byte): PChar;
function M2C(Nr: Double; Len: Byte): PChar;
function R2C(Nr: Real; Len: Byte): PChar;

function I2S(Nr: Integer; Len: Byte): string;
function L2S(Nr: LongInt; Len: Byte): string;
function M2S(Nr: Double; Len: Byte): string;
function R2S(Nr: Real; Len: Byte): string;

function S2I(Txt: string): Integer;
function S2M(Txt: string): real;
function S2L(Txt: string): LongInt;
function S2R(Txt: string): Real;

function SetLen(Nr, Len: LongInt): string;
function Set_koma(Nr: longint): string;
function SetStr(count, ascii: Byte): string;
function GetStr(mida: string; var kust: string): Byte;
function Getfmask(param: string): string;

function KillStr(Txt, What: string): string;
function Num(Txt: string): Boolean;


{Si}
function Hex2W(Hex: string): Word;

implementation

function Otsad(Txt: string): string;
begin
  while (Txt[1] = ' ') and (Txt <> '') do
    Delete(Txt, 1, 1);

  while (Txt[Length(Txt)] = ' ') and (Txt <> '') do
    Delete(Txt, Length(Txt), 1);
  Otsad := Txt;
end;


procedure Add(Dest: PChar; Source: Char);
var
  I: Integer;
begin
  I := StrLen(Dest);
  Dest[I] := Source;
  Dest[I + 1] := #0;
end;

procedure Del(Txt: PChar; Start, Count: Integer);
var
  S: Integer;
begin
  S := StrLen(Txt);
  if ((Start + Count) > S) then
    Exit;
  Move(Txt[Start + Count], Txt[Start], StrLen(Txt) - Count);
  Txt[S - Count] := #0;
end;


function Num(Txt: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(Txt) do
    if (IsAlpha(Txt[I])) then begin
      Num := False;
      Exit;
    end;

  Num := True;
end;

function KillSpace(Txt: string): string;
var
  I: Integer;
begin
  for I := 1 to Length(Txt) do
    if (Txt[I] = #32) then
      Delete(Txt, I, 1);
  KillSpace := Txt;
end;

function _Replace;
var
  I: Integer;
begin
  for I := 1 to Length(Txt) do
    if (Txt[I] = Mida) then
      Txt[I] := Millega;

  _Replace := Txt;
end;

function GetWord;
var
  Tmp: string;
  I: Integer;
begin

  Tmp := Txt;
  while (Tmp[1] = ' ') and (Tmp <> '') do
    Delete(Tmp, 1, 1);

  I := 1;
  while (Tmp[I] <> ' ') and (I <= Length(Tmp)) do
    Inc(I);

  Tmp := Copy(Tmp, 1, I);
  if (Erase) then begin
    while (Txt[1] = ' ') and (Txt <> '') do
      Delete(Txt, 1, 1);
    Delete(Txt, 1, Length(Tmp));
  end;

  if (Tmp[Length(Tmp)] = ' ') and (Tmp <> '') then
    Delete(Tmp, Length(Tmp), 1);
  GetWord := Tmp;
end;

function ToLower(Txt: string): string;
var
  I: Integer;
begin
  for I := 1 to Length(Txt) do
    if (Txt[i] > chr(ord('A') - 1)) and (Txt[i] < chr(ord('Z') + 1)) then
      Txt[i] := chr(ord(Txt[i]) + 32);
  ToLower := Txt;
end;

function ToUpper(Txt: string): string;
var
  I: Integer;
begin
  for I := 1 to Length(Txt) do
    Txt[I] := UpCase(Txt[I]);
  ToUpper := Txt;
end;

function Mirror(Txt: string): string;
var
  T: string;
  I: Integer;
begin
  T := '';
  for i := Length(Txt) downto 1 do
    T := T + Txt[i];
  Mirror := T;
end;

function Oct2L(Nr: LongInt): LongInt;
const
  Pwd: array[1..6] of Word = (0, 8, 64, 512, 4096, 32768);
var
  Txt: string;
  I: Integer;
  J,
    L: LongInt;
begin
  Txt := L2S(Nr, 0);
  L := 0;
  for I := Length(Txt) downto 2 do begin
    J := Byte(Txt[Length(Txt) - I + 1]);
    L := L + (J - 48) * Pwd[I];
  end;
  L := L + (Byte(Txt[Length(Txt)]) - 48);
  Oct2L := L;
end;

function L2Oct;
const
  OctNr: array[0..7] of Char = ('0', '1', '2', '3', '4', '5', '6', '7');
var
  I, J: Integer;
  S: string;
begin
  S := '';
  repeat
    I := Nr div 8;
    J := Nr mod 8;
    Nr := I;
    S := OctNr[j] + S;
  until Nr = 0;
  if (Length(s) > Len) then
    Delete(S, 1, Length(S) - Len)
  else
    while Length(s) < Len do
      S := '0' + S;
  L2Oct := S;
end;

function L2Hex;
const
  HexNr: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
var
  I, J: Integer;
  S: string;
begin
  S := '';
  repeat
    I := Nr div 16;
    J := Nr mod 16;
    Nr := I;
    S := HexNr[j] + S;
  until Nr = 0;
  if (Len > 0) then
    if (Length(s) > Len) then
      Delete(S, 1, Length(S) - Len)
    else
      while Length(s) < Len do
        S := '0' + S;
  L2Hex := S;
end;

function L2Bin(bb: Byte): string;
const

  BinNr: array[0..7] of Byte =
  (1, 2, 4, 8, 16, 32, 64, 128);

var
  I: Integer;
  T: string;
begin
  T := '';
  for I := 0 to 7 do
    if ((Bb and BinNr[i]) = BinNr[i]) then
      T := T + '1'
    else
      T := T + '0';
  L2Bin := T;
end;

function Bin2S(Txt: string): Byte;
const
  BinNr: array[1..8] of Byte =
  (1, 2, 4, 8, 16, 32, 64, 128);
var
  Pp, I: Integer;
begin
  pp := 0;
  while Length(Txt) < 8 do
    Txt := '0' + Txt;

  for i := 1 to Length(Txt) do
    if Txt[i] = '1' then
      inc(pp, binNr[9 - i]);
  bin2s := pp;
end;

function SetLen;
var
  Txt: string;
begin
  str(Nr, Txt);
  if (Len < Length(Txt)) then
    Delete(Txt, 1, Length(Txt) - Len)
  else
    while Length(Txt) < Len do
      Txt := '0' + Txt;
  SetLen := Txt;
end;


function I2S(Nr: Integer; Len: Byte): string;
var
  S: string;
begin
  Str(Nr, S);
  if Len > 0 then
    while (Length(S) < Len) do
      if (S[1] <> '-') and (S[1] <> '+') then
        S := FillChr + S
      else
        Insert(FillChr, S, 2);
  I2S := S;
end;

function M2S(Nr: Double; Len: Byte): string;
var
  S: string;
begin
  Str(Nr: 0: 2, S);
  if Len > 0 then
    while (Length(S) < Len) do
      if (S[1] <> '-') and (S[1] <> '+') then
        S := FillChr + S
      else
        Insert(FillChr, S, 2);

  M2S := S;
end;

function L2S(Nr: LongInt; Len: Byte): string;
var
  S: string;
begin
  Str(Nr, S);
  if Len > 0 then
    while (Length(S) < Len) do
      if (S[1] <> '-') and (S[1] <> '+') then
        S := FillChr + S
      else
        Insert(FillChr, S, 2);

  L2S := S;
end;

function R2S(Nr: Real; Len: Byte): string;
var
  S: string;
begin
  Str(Nr: 0: 2, S);
  while (Length(S) < Len) do
    if (S[1] <> '-') and (S[1] <> '+') then
      S := FillChr + S
    else
      Insert(FillChr, S, 2);

  R2S := S;
end;

{- pchar tüüpi funktsioonid -}

function PasStr(S: string): PChar;
var
  Txt: Cstring;
begin
  Move(S[1], Txt, Length(S));
  Txt[Length(S)] := #0;
  PasStr := Txt;
end;

function I2C(Nr: Integer; Len: Byte): PChar;
var
  S: string;
  I: Byte;
begin
  Str(Nr, S);
  if Len > 0 then
    while (Length(S) < Len) do
      if (S[1] <> '-') and (S[1] <> '+') then
        S := FillChr + S
      else
        Insert(FillChr, S, 2);
  I2C := PasStr(S);
end;

function M2C(Nr: Double; Len: Byte): PChar;
var
  S: string;
begin
  Str(Nr: 0: 2, S);
  if Len > 0 then
    while (Length(S) < Len) do
      if (S[1] <> '-') and (S[1] <> '+') then
        S := FillChr + S
      else
        Insert(FillChr, S, 2);
  M2C := PasStr(S);
end;

function L2C(Nr: LongInt; Len: Byte): PChar;
var
  S: string;
begin
  Str(Nr: Len, S);
  if Len > 0 then
    while (Length(S) < Len) do
      if (S[1] <> '-') and (S[1] <> '+') then
        S := FillChr + S
      else
        Insert(FillChr, S, 2);
  L2C := PasStr(S);
end;

function R2C(Nr: Real; Len: Byte): PChar;
var
  S: string;
begin
  Str(Nr: 0: 2, S);
  if Len > 0 then
    while (Length(S) < Len) do
      if (S[1] <> '-') and (S[1] <> '+') then
        S := FillChr + S
      else
        Insert(FillChr, S, 2);
  R2C := PasStr(S);
end;

function S2I(Txt: string): Integer;
var
  i, c: Integer;
begin
  Val(Txt, i, c);
  s2i := i;
end;

function S2M(Txt: string): real;
var
  i: Real;
  c: Integer;
begin

  Val(Txt, i, c);
  s2m := i;
end;

function S2L(Txt: string): Longint;
var
  i: LongInt;
  c: Integer;
begin
  Val(Txt, i, c);
  s2l := i;
end;

function S2R(Txt: string): Real;
var
  C: Integer;
  I: Real;
begin
  Val(Txt, I, C);
  S2R := I;
end;


function set_koma(Nr: longint): string;
var
  Txt: string;
  i, j: Integer;
begin
  str(Nr, Txt);
  i := 1; j := Length(Txt);
  while (i < j) do
  begin
    if i mod 3 = 0 then
      insert(',', Txt, j - i + 1);
    inc(i)
  end;
  set_koma := Txt;
end;

function setstr(count, ascii: Byte): string;
var
  Txt: string;
  i: Byte;
begin
  Txt := '';
  for i := 1 to count do
    Txt := Txt + chr(ascii);
  setstr := Txt;
end;

function getstr(mida: string; var kust: string): Byte;
begin
  getstr := 0;
  while True do begin
    if pos(mida, kust) = 0 then
      exit;
    getstr := pos(mida, kust);
    delete(kust, pos(mida, kust), Length(mida));
  end;
end;

function getfmask(param: string): string;
var
  j: Byte;
begin
  j := pos('*', param);
  if j = 0 then
    j := pos('?', param);
  if j = 0 then begin
    j := pos('.', param);
    if j = 0 then
      param := param + '*.*'
    else begin
      if j = Length(param) then
        param := param + '*';
      if j = 1 then
        param := '*' + param;
    end;
  end;

  for j := 1 to Length(param) do
    if param[j] = #$20 then
      delete(param, j, 1);

  getfmask := param;
end;

function IsAlpha(Ch: Char): Boolean;
begin
  if (Ch in ['A'..'Z']) or (Ch in ['a'..'z']) then
    IsAlpha := True
  else
    IsAlpha := False;
end;

function isnumeric(Txt: string): Boolean;
var
  Nr, c: Integer;
begin
  Val(Txt, Nr, c);
  if c = 0 then IsNumeric := True
  else IsNumeric := False;
end;

function KillStr(Txt, What: string): string;
var
  I: Byte;
begin
  I := 1;
  while (Length(Txt) > 0) and (I > 0) do begin
    I := Pos(What, Txt);
    if I > 0 then
      Delete(Txt, I, Length(What));
  end;
  KillStr := Txt;
end;

procedure HexStr(S: PCHAR; N: Longint; pos: Integer);
var
  i,
    slen: Integer;
begin
  slen := StrLen(S);
  if (pos > 0) and (pos < 9) then
  begin
    for i := pos - 1 downto 0 do
    begin
      S[slen + i] := HexNum[N and 15];
      N := N shr 4;
    end;
    S[slen + pos] := #0;
  end;
end;

function Hex2W;
var
  i,
    W: Word;
  C: Char;
begin
  W := 0;
  for i := 1 to 4 do
  begin
    C := Hex[i];
    W := W shl 4;
    case C of
      '0'..'9': W := W or (ord(C) - $30);
      'a'..'f': W := W or (ord(C) - ord('a') + 10);
      'A'..'F': W := W or (ord(C) - ord('A') + 10);
    end;
    Hex2W := W;
  end;
end;


end.

