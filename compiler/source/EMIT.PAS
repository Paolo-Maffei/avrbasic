(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit emit;

interface

uses
  ToolSrv,

  SysUtils,
  MStrings,
  Streams,
  AsmSub,
  DoCoff,
  CompDef,
  Common,
  prefer;

{$WRITEABLECONST ON} 

const
  ipmask: Word = $FF;

var

  LastLstLine: string;

  oddflag: Boolean;
  oddip, odddata: Integer;

procedure emit_rec(ad: WORD; code: CARDINAL; lin, m: WORD);
procedure emit_rec2(ad: WORD; code: CARDINAL; lin, m: WORD);

function emit_word(Code: Word): Boolean;
function emit_byte(Code: Word): Boolean;
function emit2(C1, C2: Word): Boolean;
function emit3(C1, C2, C3: Word): Boolean;

procedure assume_none;

{ Return Tempsym }
function sym(var s: TSym; yylex: Integer;
  Val: Longint; Subval, Typ, Size: Integer;
  Name: string): PSym;

function GetCode(ln, fn: Integer): Integer;
function GetLine(addr, fn: Integer): Integer;
function GetFile(addr: Integer): Integer;

implementation

uses
  UnAVR;

function GetLine;
var
  i: Integer;
begin
  Result := -1;
  if next_code > max_coderec then Exit;
  if next_code = 0 then Exit;

  i := 0;
  while (i < next_code) do
  begin
    if (Coderecords[i].fn = fn) and (Coderecords[i].addr = addr) then
    begin
      Result := Coderecords[i].ln;
      Exit;
    end;
    inc(i);
  end;
end;

function GetFile;
var
  i: Integer;
begin
  Result := -1;
  if next_code > max_coderec then Exit;
  if next_code = 0 then Exit;

  i := 0;
  while (i < next_code) do
  begin
    if (Coderecords[i].addr = addr) then
    begin
      Result := Coderecords[i].fn;
      Exit;
    end;
    inc(i);
  end;
end;


function GetCode;
var
  i: Integer;
begin
  Result := -1;
  if next_code > max_coderec then Exit;
  if next_code = 0 then Exit;

  i := 0;
  while (i < next_code) do
  begin
    if (Coderecords[i].ln = ln) and (Coderecords[i].fn = fn) then
    begin
      Result := i;
      Exit;
    end;
    inc(i);
  end;
end;


function sym;
var
  PS: PSym;
begin
  PS := @S;
  PS^.yylex := yylex;
  PS^.val := val;
  PS^.subval := subval;
  PS^.typ := typ;
  PS^.Size := size;
  StrPCopy(PS^.Name, Name);
  sym := PS;
end;

procedure assume_none;
begin
  wreg_val := -1;
end;

function emit_word;
begin
  emit_rec(ip, code, linenum, 1);
  inc(ip);

  MI.emit(code);
end;

function emit_byte;
begin
  if oddflag then begin
    odddata := (odddata and $FF) or (code shl 8);
    emit_rec(oddip, odddata, linenum, 1);
    oddflag := false;
    inc(ip);
  end else begin
    // Save location!
    oddip := ip;
    odddata := code;
    oddflag := true;
  end;
end;

function emit2; begin
  csz := 2;
  emit_rec(ip, c1, linenum, 1);
  inc(ip, 2);
end;

function emit3; begin
  csz := 3;
  emit_rec(ip, c1, linenum, 1);
  inc(ip, 3);
end;

procedure emit_rec;
var
  A: array[0..9] of Byte;
  lnum: Integer;
begin
  if Pass < 10 then Exit;

  mCOFF.AddLineNum(linenum - 1, ip);

  if next_code > max_coderec then begin
    Exit;
  end;

  CodeRecords[next_code].Addr := ad;
  CodeRecords[next_code].Code := code;
  CodeRecords[next_code].fn := CFileNum;
  CodeRecords[next_code].ln := lin;
  CodeRecords[next_code].tag := 0;

  if p_syntax then Exit; // Syntax Check only..

  //

  MI.PC := ad;
  MI.Emit(word(code));
  
  A[0] := 0; A[1] := ad shr 8; A[2] := ad;
  A[3] := code shr 8; A[4] := code;
  A[5] := cFilenum - 1; { filenum }
  if uselinenuminfo then
  begin
    CodeRecords[next_code].ln := srclinenum + 1;
    lnum := srclinenum;
  end else
    lnum := lin - 1;
  begin
    if lnum <= 0 then lnum := 1;
    A[6] := lnum shr 8;
    A[7] := lnum;
  end;
  A[8] := m and 1;
  ObjectStream.Write(A, 9);

  ad := ad and $FFFF; // 64K Limit
  ROM16^[ad] := code;

  if p_lstfile and dodislisting then
    WrLstLine(L2HEX(ad, 4) + ':' + L2HEX(code, 4) + ' ' + Disasm_AVR_Code(code));

  Inc(next_code);
end;

procedure emit_rec2;
var
  A: array[0..9] of Byte;
  lnum: Integer;
begin
  if Pass < 10 then Exit;

  mCOFF.AddLineNum(linenum - 1, ip);

  if next_code > max_coderec then begin
    Exit;
  end;

  CodeRecords[next_code].Addr := ad;
  CodeRecords[next_code].Code := code;
  CodeRecords[next_code].fn := CFileNum;
  CodeRecords[next_code].ln := lin;
  CodeRecords[next_code].tag := 0;
  // Syntax Check only..
//  if p_syntax then Exit;
  //
  A[0] := 0;
  A[1] := ad shr 8;
  A[2] := ad;
  A[3] := code shr 8; A[4] := code;
  A[5] := cFilenum - 1; { filenum }
  if uselinenuminfo then
  begin
    CodeRecords[next_code].ln := srclinenum + 1;
    lnum := srclinenum;
  end else
    lnum := lin - 1;

  if lnum <= 0 then lnum := 1;
  A[6] := lnum shr 8;
  A[7] := lnum;
  A[8] := m and 1;
  ObjectStream.Write(A, 9);

  ad := ad and $FFFF; // 64K Limit
  ROM16^[ad] := code;

  // second byte
  inc(ad);
  CodeRecords[next_code+1].Addr := ad;
  CodeRecords[next_code+1].Code := code shr 16;
  CodeRecords[next_code+1].fn := CFileNum;
  CodeRecords[next_code+1].ln := lin;
  CodeRecords[next_code+1].tag := 0;
  // Syntax Check only..
  if p_syntax then Exit;
  //
  A[0] := 0;
  A[1] := ad shr 8;
  A[2] := ad;
  A[3] := code shr 24;
  A[4] := code shr 16;
  A[5] := cFilenum - 1; { filenum }

  CodeRecords[next_code+1].ln := CodeRecords[next_code].ln;

  if lnum <= 0 then lnum := 1;
  A[6] := lnum shr 8;
  A[7] := lnum;
  A[8] := m and 1;
  ObjectStream.Write(A, 9);

  ad := ad and $FFFF; // 64K Limit
  ROM16^[ad] := code shr 16;

  if p_lstfile and dodislisting then
    WrLstLine(L2HEX(ad-1, 4) + ':' + L2HEX(code, 4) + ' ' + Disasm_AVR_Code(code));

  Inc(next_code);
  Inc(next_code);
end;


begin
  oddflag := false;
  rtlpath := '';
  next_code := 0;
  gran := 1;



end.

