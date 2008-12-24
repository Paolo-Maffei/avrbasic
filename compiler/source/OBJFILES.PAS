(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit objfiles;

interface

uses
  SysUtils,
  CompDef,
  Common,
  prefer,
  Streams,
  //  AsmDef,
  ToolSrv,
  Asmsub,
  HexFil4;

procedure CloseObjFile;
procedure OpenObjFile;
procedure CheckSrcFileInObj(src: string);
procedure AddSrcFileInObj(src: string);

implementation

procedure CheckSrcFileInObj(src: string);
var i: integer;
begin
  for i := 1 to lastincfile do
  begin
    if ansicomparetext(Files[i], src) = 0 then cFileNum := i;
  end;
end;

procedure AddSrcFileInObj(src: string);
var i: integer;
begin
  i := 1;
  // if not full path, then expand
  if ExtractFilePath(src) = '' then src := Files[0] + src;

  while i <= lastincfile do
  begin
    if ansicomparetext(Files[i], src) = 0 then begin
      cFileNum := i;
      exit;
    end;
    inc(i);
  end;
  if lastincfile < 32 then
  begin
    inc(lastincfile);
    Files[lastincfile] := src;
    cFileNum := lastincfile;
  end;

end;


procedure wrl(L: Longint);
begin
  //  BlockWrite(avdfile, L, 4);
end;

procedure wrb1;
begin
  wrl($0000002C); wrl(0); wrl(1); wrl(-1); wrl(-1); wrl(-1); wrl(-1);
end;

procedure OpenObjFile;
var
  ll: Longint;
  i: Integer;
  S: array[0..1000] of Char;
  fn: string;
begin
  if p_syntax then Exit;

  for i := 0 to 2047 do {CODEMEM}  ROM16^[i] := $FFFF;
  for i := 0 to 511 do EEMEM[i] := $FFFF;

  if p_objfile and (family = avr) then begin

    fn := Files[1]; KillSuffix(fn); AddSuffix(fn, '.obj');
    {
    Assign(ObjFile, fn);
    rewrite(ObjFile, 1);
    }
    {
    ll := 0;                        BlockWrite(ObjFile, ll, 4);
    ll := $1A000000;                BlockWrite(ObjFile, ll, 4);
    ll := $0109;                    BlockWrite(ObjFile, ll, 2);
    StrCopy(S, 'AVR Object File');  BlockWrite(ObjFile, S, StrLen(S) + 1);
    }
    ll := 0; ObjectStream.Write(ll, 4);
    ll := $1A000000; ObjectStream.Write(ll, 4);
    ll := $0109; ObjectStream.Write(ll, 2);
    StrCopy(S, 'AVR Object File'); ObjectStream.Write(S, StrLen(S) + 1);

  end;

  (*
    If p_avdfile and (family=avr) Then
    Begin
      fn := Files[1]; KillSuffix(fn); AddSuffix(fn, AvdSuffix);
      Assign(avdFile, fn);
      rewrite(avdFile, 1);

      rewrite(avdfile, 1);
      ll := 0; BlockWrite(avdfile, ll, 4); { TimeStamp }
      wrb1;

      wrl($00000016); wrl($00000016);
      wrl($000002E4); wrl($000001FD);
      wrl($00000001);
      StrCopy(S, #11'ASourceView');
      BlockWrite(avdfile, S, StrLen(S));

      fn := Files[1]; KillSuffix(fn); AddSuffix(fn, '.obj');

      StrPCopy(S, fn + ' ' + fn);
      ll := StrLen(S); BlockWrite(avdfile, ll, 1);
      BlockWrite(avdfile, S, StrLen(S));
      wrb1; // FF..FF
    End;
    *)
end;

procedure CloseObjFile;
var
  I: Integer;
  typ1,
    l1, l2: Longint;
  S: array[0..259] of Char;
  S1: string;
begin
 if p_syntax then Exit;

  if family = avr then
  begin
    if p_objfile then 
    begin
      l1 := ObjectStream.Position; { Save File Pos! }
      l2 := 0;
      ObjectStream.Seek(0, 0); { Seek(0) }
      ObjectStream.Write(l2, 2); { ? }

      l2 := l1 shr 8;
      ObjectStream.Write(l2, 1);
      ObjectStream.Write(l1, 1);

      l2 := 8; ObjectStream.Seek(l2, 0); { Seek(8) }
      l2 := (LastIncFile shl 8) + $09; ObjectStream.Write(l2, 2);

      ObjectStream.Seek(l1, 0);
      StrPCopy(S, Files[1]);
      ObjectStream.Write(S, Length(Files[1]) + 1);

      if LastIncFile > 1 then begin
        for I := 2 to LastIncFile do begin
          StrPCopy(S, Files[I]);
          ObjectStream.Write(S, Length(Files[I]) + 1);
        end;
      end;
      l2 := 0; ObjectStream.Write(l2, 1);
      //CLOSE(ObjFile);
    end;
    { AVD }

    // 3F
    // --
    (*
    If p_avdfile and (family=avr) Then
    Begin

     wrl($00000000); wrl($00000000);
     wrl($00000254); wrl($00000117);
     wrl($00000000);

     // Break Point Records ??
 {
     wrl(1);
     wrl(0);

     S1 := Files[1];
     KillSuffix(S1);
     AddSuffix(S1, '.obj');

     StrPCopy(S, ' ' + S1);
     l1 := Length(S1);
     S[0] := chr(l1);
     BlockWrite(avdfile, S, l1+1);

     wrl($64);
 }
     // Proceed..

     wrl($00000000);
     wrl($00000000); wrl($F0000000);

     l1 := $3F; BlockWrite(avdfile, l1, 1); // !!!
     typ1 := avd_id;

     Case cpu Of
       1200: begin
         wrl($00000001); wrl($00000001);  wrl($42520003);
         wrl($00000001); wrl(rom_size);
         wrl($00000001); wrl($00000020); { RAM End }

         wrl($00000001); wrl(ee_size);
         wrl($00000001); wrl($00000000);
         wrl(64); { io_size }
         wrl($00000001); wrl($00000000);
         wrl($00000001); wrl($00000001);
         wrl($00000000);
       end;
     Else
       wrl($00000000); wrl($00000001); wrl($00000003);
       wrl($00000001); wrl(rom_size);
       wrl($00000001); wrl(sram_size + $60);

       wrl($00000001); wrl(ee_size);
       wrl($00000001); wrl($00000000);
       wrl(64); { io_size }
       wrl($00000001); wrl($00000001);
       wrl($00000001); wrl(typ1);
       wrl($00000000);
     End;
     CLOSE(avdfile);
    End;
   *)


  end;

  p_hexfile := true;

  WriteToolOutput('L before hexwrite');

  if p_hexfile then 
  begin
    hextyp := 1;

    S1 := Files[1];
    s1 := ChangeFileExt(S1, '.rom');
    StrPCopy(S, S1);
    
    if hextyp = 1 then
    begin
      WritePicHEX(S, hft_INHX8, True, True, False, 0, 0, nil, nil, @EEMEM, PCHAR(ROM16), 0, ip, 64);

      WriteToolOutput('L after writepic');
{
      s1 := ChangeFileExt(S1, '.eep');
      StrPCopy(S, S1);
      if ee_size <> 0 then
        WriteINHX8(S, hft_INHX8,
          True, True, False, 0, 0, nil, nil,
          @EEMEM, @EEMEM, 0, ee_size);
}
      WriteToolOutput('L after write EE');
    end;
    
  end;
end;

{}
begin
  rom_size := 512;
  ee_size := 64;
end.

