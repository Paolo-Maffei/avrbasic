(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

{ $I DEF.INC}
unit HexFil4;

interface

uses

{$IFDEF ver100}
  SysUtils;
//Type
//	PByte			= ^Byte;
//	PWord			= ^Word;

{$ELSE}
  SysUtils;
{$ENDIF}



type
  PByte = ^Byte;
  PWord = ^Word;


type
  THexFileType = (hft_INHX8, hft_INHX8S,
    hft_INHX8M, hft_INHX16, hft_INHX32, hft_RAWBIN);

const
  HexNum: PCHAR = '0123456789ABCDEF';

function OpenHexFile(Name, Options: PCHAR; mode: Integer): Integer;
function CloseHexFile(var fhex: Text): Integer;
function WriteHexFile(var fhex: Text; buffer: PCHAR; start, bytes: Integer): Integer;

function WriteHexRec(var fhex: Text; FileType: THexFileType;
  buffer: PCHAR; bufloc, start, bytes: Integer): Integer;

function ReadPICHex(Name: PCHAR;
  FileType: THexFileType;
  Fuse_Loc,
  ID_Loc: Word;
  FUSES,
  ID,
  EEPROM,
  Buffer: PCHAR;
  start, bytes, eebytes: Integer): Integer;


function WritePICHex(Name: string;
  FileType: THexFileType;
  IncludeFuses, IncludeID,
  IncludeEEPROM: Boolean;
  Fuse_Loc,
  ID_Loc: Word;
  FUSES,
  ID,
  EEPROM,
  Buffer: PCHAR;
  start, bytes, eebytes: Integer): Integer;

function WriteINHX8(Name: PCHAR;
  FileType: THexFileType;
  IncludeFuses,
  IncludeID,
  IncludeEEPROM: Boolean;
  Fuse_Loc,
  ID_Loc: Word;
  FUSES,
  ID,
  EEPROM,
  Buffer: PCHAR;
  start, bytes: Integer): Integer;

function ReadINHX8(Name: PCHAR;
  FileType: THexFileType;
  Fuse_Loc,
  ID_Loc: Word;
  FUSES,
  ID,
  EEPROM,
  Buffer: PCHAR;
  start, bytes: Integer): Integer;




procedure HexStr(S: PCHAR; N: Longint; pos: Integer);




implementation


function OpenHexFile(Name, Options: PCHAR; mode: Integer): Integer;
begin
 {
  if mode = OF_READWRITE Then
 OpenHexFile := _lcreat (Name, 0)
  else
 OpenHexFile := _lopen (Name, mode);
  }
end;

function CloseHexFile(var fhex: Text): Integer;
begin
  system.close(fhex);
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

function WriteHexFile(var fhex: Text; Buffer: PCHAR; start, bytes: Integer): Integer;
var
  Buf: PBYTE;
  line: array[0..255] of char;
  addr: Word;
  i,
    BytesLeft: Integer;
  B,
    cks: Byte;
  done: Boolean;

begin
  BytesLeft := bytes;
  Addr := Start;

  while BytesLeft > 0 do
  begin
    cks := 0;
    StrCopy(line, ':'); { Separator  }
    if BytesLeft > 16 then { byte count > max Record length	}
    begin
      cks := cks - 16;
      HexStr(line, 16, 2); { Record Length	= 16				}
    end else
    begin
      cks := cks - BytesLeft;
      HexStr(line, BytesLeft, 2);
    end;
    HexStr(line, addr, 4); { Record Start Address }
    HexStr(line, 0, 2); { Record Type: 00 }

    cks := cks - (addr and 255);
    cks := cks - (addr shr 8);
    if BytesLeft >= 16 then
    begin
      for i := 0 to 15 do
      begin
        B := ord(Buffer[addr]);
        cks := cks - B;
        HexStr(line, B, 2);
        inc(addr);
      end;
      BytesLeft := BytesLeft - 16;
    end else
    begin
      for i := 0 to BytesLeft - 1 do
      begin
        B := ord(Buffer[addr]);
        cks := cks - B;
        HexStr(line, B, 2);
        inc(addr);
      end;
      BytesLeft := 0;
    end;
 { 00 fe
   08 f6
   08 08 ec
 }
    HexStr(line, cks, 2); { checksum }
    writeLn(fhex, line);
  end;

  { Make End Record :00000001FF+CR+LF+EOF }
  StrCopy(line, ':');
  HexStr(line, 0, 2); { Zero Length }
  HexStr(line, 0, 4); { Addr 0 }
  HexStr(line, $01, 2); { Record Type: 01 }
  HexStr(line, $FF, 2); { Checksum }
  writeLn(fhex, line);
end;



function WriteHexRec(var fhex: Text;
  FileType: THexFileType;
  Buffer: PCHAR;
  BufLoc,
  start,
  bytes: Integer): Integer;

var
  Buf: PBYTE;
  line: array[0..255] of char;
  addr: Word;
  i,
    BytesLeft: Integer;
  B,
    cks: Byte;
  done: Boolean;

begin
  BytesLeft := bytes;
  Addr := Start;

  cks := 0;
  StrCopy(line, ':'); { Separator  }
  if BytesLeft > 16 then { byte count > max Record length	}
  begin
    cks := cks - 16;
    HexStr(line, 16, 2); { Record Length	= 16				}
  end else
  begin
    dec(cks, BytesLeft);
    HexStr(line, BytesLeft, 2);
  end;
  HexStr(line, addr, 4); { Record Start Address }
  HexStr(line, 0, 2); { Record Type: 00 }

  dec(cks, (addr and 255));
  Dec(cks, (addr shr 8));
  if BytesLeft >= 16 then
  begin
    for i := 0 to 15 do
    begin
      B := ord(Buffer[BufLoc]);
      Dec(cks, B);
      HexStr(line, B, 2);
      inc(addr);
      inc(BufLoc);
    end;
    Dec(BytesLeft, 16);
  end else
  begin
    for i := 0 to BytesLeft - 1 do
    begin
      B := ord(Buffer[BufLoc]);
      dec(cks, B);
      HexStr(line, B, 2);
      inc(addr);
      inc(BufLoc);
    end;
    BytesLeft := 0;
  end;

  HexStr(line, cks, 2);
  writeLn(fhex, line);
end;

function WritePICHex;
var
  Buf: PBYTE;
  line: array[0..255] of char;
  p: Pchar;
  addr: Word;
  i,
    BytesLeft: Integer;
  B, cks: Byte;
  done: Boolean;
  fhex: TextFile;
begin
  WritePICHex := -1;

  if Name = '' then Exit;

  if bytes <> 0 then
  begin
//	AssignFile (fhex,'AAA');

    AssignFile(fhex, Name);


    ReWrite(fhex);
    if (IOResult <> 0) then Exit;

    if FileType = hft_INHX32 then
    begin
      StrCopy(line, ':020000040000FA');
      writeLn(fhex, line);
    end;

    BytesLeft := bytes * 2;
    Addr := Start;

    while BytesLeft > 0 do
    begin
      cks := 0;
      StrCopy(line, ':'); { Separator  }
      if BytesLeft > 16 then { byte count > max Record length	}
      begin
        Dec(cks, 16);
        HexStr(line, 16, 2); { Record Length	= 16				}
      end else
      begin
        dec(cks, BytesLeft);
        HexStr(line, BytesLeft, 2);
      end;
      HexStr(line, addr, 4); { Record Start Address }
      HexStr(line, 0, 2); { Record Type: 00 }

      Dec(cks, (addr and 255));
      Dec(cks, (addr shr 8));
      if BytesLeft >= 16 then
      begin
        for i := 0 to 15 do
        begin
          B := ord(Buffer[addr]);
          Dec(cks, B);
          HexStr(line, B, 2);
          inc(addr);
        end;
        Dec(BytesLeft, 16);
      end else
      begin
        for i := 0 to BytesLeft - 1 do
        begin
          B := ord(Buffer[addr]);
          Dec(cks, B);
          HexStr(line, B, 2);
          inc(addr);
        end;
        BytesLeft := 0;
      end;
      HexStr(line, cks, 2); { checksum }
      writeLn(fhex, line);
    end;

 { Make End Record :00000001FF+CR+LF+EOF }
    StrCopy(line, ':00000001FF');
    writeLn(fhex, line);
    CloseFile(fhex);
  end;

  WritePICHex := 0; { OK }

  if IncludeEEPROM then
  begin

    Name := ChangeFileExt(Name, '.eep');
    AssignFile(fhex, Name);
    ReWrite(fhex);

    for i := 0 to eebytes - 1 do
    begin
      StrCopy(Line, '');
      HexStr(line, i, 4);
      StrCat(line, ':');
      HexStr(line, Ord(EEPROM[i * 2]), 2);
      Writeln(fhex, line);
    end;

    CloseFile(fhex);
  end;


end;

function HexToWord(Hex: PCHAR; Pos: Word): Word;
var
  ii,
    W: Word;
  C: Char;
begin
  if Pos > 4 then Pos := 4;
  ii := Pos;
  W := 0;
  while ii > 0 do
  begin
    C := Hex[Pos - ii];
    W := W shl 4;
    case C of
      '0'..'9': W := W or (ord(C) - $30);
      'a'..'f': W := W or (ord(C) - ord('a') + 10);
      'A'..'F': W := W or (ord(C) - ord('A') + 10);
    end;
    Dec(ii);
  end;
  HexToWord := W;
end;

function ByteSwap(W: Word): Word;
begin
  ByteSwap := (W shl 8) or (W shr 8);
end;

function ReadPICHex;

var
  pfh: Text;
    {
    pfh: THandle;
    }
  Buf: PBYTE;
  WBuf: PWORD;
  line: array[0..255] of char;
  addr: Word;
  i, BytesLeft: Integer;
  BytesPerLine: Word;
  B, cks: Byte;
  done: Boolean;
  Ch: Char;
  p, P1, P2: PCHAR;
  HiAddr: Word;

  function gLine: Integer;
  var
    Txt: string;
    ii: Integer;
  begin
    ReadLn(pfh, Txt);
    StrPCopy(Line, Txt);

    ii := 0;
    Ch := ' ';
{	While (Not Eof (pfh)) And (Ch <> #13) Do Begin
  Read (pfh,Ch);
  If (ii<255) and (Ch<>#10) Then Begin
   Line[ii] := Ch;
   inc(ii);
  End;
 End;
 Line[ii] := #0;
    }
  end;

begin
  ReadPICHex := -1;
  if StrLen(Name) = 0 then Exit;
  Assign(pfh, Name);
  Reset(pfh);
  if (IOResult <> 0) then Exit;

  HiAddr := 0;
  repeat
    gLine; { Read Line }
    if Line[0] = ':' then
    begin
   { Check For Data Record }
      if StrLComp(Line + 7, '00', 2) = 0 then
      begin
        BytesPerLine := HexToWord(Line + 1, 2);
        addr := HexToWord(Line + 3, 4) div 2;
    { INHX32 Fixup }
        if (HiAddr and 1) <> 0 then addr := addr or $8000;
    { Check For Main Memory }

        if (BytesPerLine <= $40) and (BytesPerLine >= 2) then
        begin
          if (Addr + ((BytesPerLine div 2))) <= Bytes then
          begin
            WBuf := PWORD(Buffer + (Addr * 2));
            for i := 0 to (BytesPerLine div 2) - 1 do
            begin
              WBuf^ := ByteSwap(HexToWord(Line + 9 + (i * 4), 4));
              Inc(WBuf);
            end;
          end;

          if (Addr = ID_Loc) and (BytesPerLine = 8) then
          begin
            WBuf := PWORD(ID);
            for i := 0 to 3 do
            begin
              WBuf^ := ByteSwap(HexToWord(Line + 9 + (i * 4), 4));
              Inc(WBuf);
            end;
            Continue;
          end;

          if Addr = Fuse_Loc then
          begin
            WBuf := PWORD(Fuses);
            WBuf^ := ByteSwap(HexToWord(Line + 9, 4));
            Continue;
          end;

          if (Addr >= $2100) and ((Addr + ((BytesPerLine div 2))) < $2200) then
          begin
            WBuf := PWORD(EEPROM + ((Addr - $2100) and $3F * 2));
            for i := 0 to 7 do
            begin
              WBuf^ := ByteSwap(HexToWord(Line + 9 + (i * 4), 4));
              Inc(WBuf);
            end;
            Continue;
          end;
        end; { Valid Line }
      end;
   { Check Address Prefix Record }
      if StrLComp(Line + 7, '04', 2) = 0 then
      begin
        HiAddr := HexToWord(Line + 9, 4);
        Continue;
      end;

   { Check For End Record }
      if StrLComp(Line + 7, '01', 2) = 0 then
      begin
        BytesPerLine := HexToWord(Line + 1, 2);
        addr := HexToWord(Line + 3, 4);

        Line[0] := #0; { Break out }
        Continue;
      end;
    end;
  until Line[0] = #0; { End Of File }
  System.Close(pfh);
  ReadPICHex := 0; { OK }

  p := StrPos(Name, '.');
  if p <> nil then begin
    p[1] := 'E';
    p[2] := 'E';
    p[3] := 'P';
    Assign(pfh, Name);
    Reset(pfh);
    if (IOResult <> 0) then Exit;
       { Read EEP File!!! }

    repeat
      gLine; { Read Line }
      if Line[4] = ':' then
      begin
        Addr := HexToWord(Line, 4);
        if (Addr >= 0) and (Addr < eebytes) then EEPROM[addr * 2] := Chr(HexToWord(Line + 5, 2));
      end;
    until Line[0] = #0; { End Of File }

    System.Close(pfh);
  end;

end;


function WriteINHX8;

var
  BBuf: PBYTE;
  Buf: PWORD;
  p: PCHAR;
  line: array[0..255] of char;
  addr: Word;
  i,
    BytesLeft: Integer;
  B,
    B1, B2,
    cks: Byte;
  done: Boolean;

  fhex: Text;

begin
  WriteINHX8 := -1;
  if StrLen(Name) = 0 then Exit;

  Assign(fhex, Name);
  ReWrite(fhex);
  if (IOResult <> 0) then Exit;

    {
 fhex := _lcreat(Name, 0);
 if fhex <= 0 Then Exit;
    }{ Cant create File }

{--------------------------
 Process Raw Bin
---------------------------}
    {
 If FileType = hft_RAWBIN Then
 Begin
  _lwrite(fhex, Buffer, Bytes);
  _lclose(fhex);
  WriteINHX8 := 0;
  Exit;
 End;
    }
{--------------------------
 HEX Types Go Here...
---------------------------}

  BytesLeft := Bytes;
  Addr := Start;

  while BytesLeft > 0 do
  begin
    cks := 0;
    StrCopy(line, ':'); { Separator  }
    if BytesLeft > 16 then { byte count > max Record length	}
    begin
      cks := cks - 16;
      HexStr(line, 16, 2); { Record Length	=  Bytes }
    end else
    begin
      cks := cks - BytesLeft;
      HexStr(line, BytesLeft, 2);
    end;

    cks := cks - ((addr div 2) and 255);
    cks := cks - ((addr div 2) shr 8);
    HexStr(line, addr div 2, 4); { Record Start Address }
    HexStr(line, 0, 2); { Record Type: 00 }

    if BytesLeft >= 16 then
    begin
      for i := 0 to 15 do
      begin
        B1 := ord(Buffer[Addr]);
        cks := cks - B1;
        inc(addr);
        inc(addr);
        HexStr(line, B1, 2);
      end;
      BytesLeft := BytesLeft - 16;
    end else
    begin
      for i := 0 to BytesLeft - 1 do
      begin
        B1 := ord(Buffer[Addr]);
        cks := cks - B1;
        inc(addr);
        inc(addr);
        HexStr(line, B1, 2);
      end;
      BytesLeft := 0;
    end;

    HexStr(line, cks, 2); { checksum }
        {
  _lwrite(fhex, line, strlen(line));
  _lwrite(fhex, #13#10, 2);
        }
    WriteLn(fhex, line);
  end;

    { Make End Record :00000001FF+CR+LF+EOF }
  StrCopy(line, ':00000001FF');
  writeLn(fhex, line);
  system.close(fhex);
  WriteINHX8 := 0; { OK }
end;


function ReadINHX8(Name: PCHAR;
  FileType: THexFileType;
  Fuse_Loc,
  ID_Loc: Word;
  FUSES,
  ID,
  EEPROM,
  Buffer: PCHAR;
  Start,
  Bytes: Integer): Integer;
var
  Buf: PBYTE;
 {
 WBuf : PWORD;
 }
  line: array[0..255] of char;
  addr: Word;
  i,
    BytesLeft: Integer;
  BytesPerLine: Word;
  B,
    cks: Byte;
  done: Boolean;
  Ch: Char;

  pfh: Text;
  P1, P2: PCHAR;

  HiAddr: Word;

  TypeOK: Boolean; { Type Determined }
  CheckedType: THexFileType;

var
  Txt: string;
  ii: Integer;

  procedure gline;
  begin
    ii := 0;
    Ch := ' ';
    ReadLn(pfh, Txt);
    StrPCopy(Line, Txt);
{	While (Not Eof (pfh)) And (Ch <> #13) Do Begin
  Read (pfh,Ch);
  If (ii<255) and (Ch<>#10) Then Begin
   Line[ii] := Ch;
   inc(ii);
  End;
 End;
 Line[ii] := #0;}
  end;

begin
  ReadINHX8 := -1;
  if StrLen(Name) = 0 then Exit;

  Assign(pfh, Name);
  Reset(pfh);
  if (IOResult <> 0) then Exit;

{----------------------
 Process Raw Binary
-----------------------}
    {
 If FileType = hft_RAWBIN Then
 Begin
  mmioClose(pfh, 0);
  Exit;
 End;
    }
{----------------------
 Process Hex Files
-----------------------}
  TypeOK := False;
  Bytes := Bytes * 2;

  repeat
    gLine; { Read Line }
    if Line[0] = ':' then
    begin

      CheckedType := hft_INHX8M; { ??? }

   { Check For Data Record }
      if StrLComp(Line + 7, '00', 2) = 0 then
      begin
        BytesPerLine := HexToWord(Line + 1, 2);
        addr := HexToWord(Line + 3, 4);

        if (BytesPerLine <= $40) and (BytesPerLine >= 1) then
        begin
          if (Addr + BytesPerLine) <= Bytes then
          begin
            Buf := PBYTE(Buffer + (Addr * 2));
            for i := 0 to BytesPerLine - 1 do
            begin
              Buf^ := HexToWord(Line + 9 + (i * 2), 2);
              Inc(Buf);
              Inc(Buf);
            end;
          end;

        end; { Valid Line }
      end;

   { Check For End Record }
      if StrLComp(Line + 7, '01', 2) = 0 then
      begin
        BytesPerLine := HexToWord(Line + 1, 2);
        addr := HexToWord(Line + 3, 4);

        Line[0] := #0; { Break out }
        Continue;
      end;
    end;

  until Line[0] = #0; { End Of File }
    {
 mmioClose(pfh, 0);
    }
  System.Close(pfh);

  ReadINHX8 := 0; { OK }
end;


begin
end.
d.

