(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit AVRCore;

interface

uses
  ToolSrv,

  prefer,
  CompDef, Common,
  CustomCore,
  EventIntf,
  strut,
  MStrings,
	Windows, Messages, SysUtils, Classes, 
	//Graphics, Controls, Forms, Dialogs,
  IniFiles;


type
  PLineNum = ^TLineNum;
  TLineNum = packed record
    addr: cardinal; // physical address
    ln: word; // line number
    fn: byte; // file number
    seg: byte; // segment
  end;

  TAVRCore = class(TCustomCore)
  private
    FFamily: string;
    FDevice: string;
    FMaxVector: integer;
    procedure SetFamily(const Value: string);
    procedure SetDevice(const Value: string);
    procedure SetMaxVector(const Value: integer);
    { Private declarations }
  protected
    { Protected declarations }
    Config: TIniFile;
    bLongVector: Boolean; // Has LONG Vectors ?
  public
    { Public declarations }
    constructor create(AOwner: TComponent); override;
    destructor destroy; override;

    procedure emit_word(value: word); //override;
    function Disasm(value: Pointer): string; override;
    function sfrToStr(value: cardinal): string; //override;
    function ChkPortStr(value: string): string; //override;
    function VecToAddr(value: string): cardinal; //override;

    procedure add(Dest, Op1, Op2: PNode); override;
    procedure adc(Dest, Op1, Op2: PNode); override;

    procedure di; override;
    procedure ei; override;

    procedure divide(Dest, Op1, Op2: PNode); override;

    procedure incr(Dest, Src: PNode); override;
    procedure decr(Dest, Src: PNode); override;

    procedure move(Dest, Src: PNode); override;
    procedure mul(Dest, Op1, Op2: PNode); override;

    procedure nop; override;

    procedure sub(Dest, Op1, Op2: PNode); override;
    procedure sbc(Dest, Op1, Op2: PNode); override;

    procedure jump_addr(addr: cardinal);
    procedure call_addr(addr: cardinal);

    procedure emit_typ3(S: PNode; code: word);

    // native...

    procedure lds(Dest, Src: PNode);
    procedure sts(Dest, Src: PNode);

    procedure inp(Dest, Src: PNode);
    procedure outp(Dest, Src: PNode);

  published
    { Published declarations }

    property Family: string read FFamily write SetFamily;
    property Device: string read FDevice write SetDevice;

    property MaxVector: integer read FMaxVector write SetMaxVector;
  end;

var
  Core: TAVRCore;

procedure Register;

implementation

uses
  emit;

procedure Register;
begin
  RegisterComponents('Case2000', [TAVRCore]);
end;

{ TAVRCore }

procedure TAVRCore.adc(Dest, Op1, Op2: PNode);
begin

end;

procedure TAVRCore.add(Dest, Op1, Op2: PNode);
begin

end;

procedure TAVRCore.decr(Dest, Src: PNode);
begin
  case Dest^.typ of
    sym_lWORD: begin
    {
        emitn_ldd(@primLo, @Y, @S); S.Val := S.val + 1;
        emitn_ldd(@primHi, @Y, @S);

        tcon.val := 1;
        emitn_sbiw(@prim, @tcon);

        emitn_std(@primHi, @Y, @S); S.Val := S.val - 1;
        emitn_std(@primLo, @Y, @S);
        }
      end;
    sym_lDEF: begin
        {emitn_ldd(@WREG, @Y, @S);
        emit_Typ3(WREG, $940A);
        emitn_std(@WREG, @Y, @S);
        }
      end;
    sym_sDEF: begin lds(@WREG, Dest); decr(@WREG, nil); sts(@WREG, Dest); end;
    sym_DEF: begin emit_Typ3(Dest, $940A); end;
    sym_IO: begin inp(@WREG, Dest); decr(@WREG, nil); outp(Dest, @WREG); end;
    sym_Word: begin
        {emit_subi(S, 1);
        Tmp := S;
        Tmp.Val := Tmp.Val + 1;
        emit_sbci(Tmp, 0);
        }
      end;
  end;

end;

procedure TAVRCore.divide(Dest, Op1, Op2: PNode);
begin

end;

procedure TAVRCore.incr(Dest, Src: PNode);
begin
  case Dest^.typ of
    sym_lWORD: begin
    {
        emitn_ldd(@primLo, @Y, @S); S.Val := S.val + 1;
        emitn_ldd(@primHi, @Y, @S);
        tcon.val := 1;
        emitn_adiw(@prim, @tcon);
        emitn_std(@primHi, @Y, @S); S.Val := S.val - 1;
        emitn_std(@primLo, @Y, @S);        }
      end;
    sym_lDEF: begin
        {emitn_ldd(@WREG, @Y, @S);
        emit_Typ3(WREG, $9403);
        emitn_std(@WREG, @Y, @S);
        }
      end;
    sym_sDEF: begin lds(@WREG, Dest); incr(@WREG, nil); sts(@WREG, Dest); end;
    sym_DEF: begin emit_Typ3(Dest, $9403); end;
    sym_IO: begin inp(@WREG, Dest); incr(@WREG, nil); outp(Dest, @WREG); end;
    sym_Word: begin
    {        emit_subi(S, 255);
        Tmp := S;
        Tmp.Val := Tmp.Val + 1;
        emit_sbci(Tmp, 255);
        }
      end;
  end;

end;

procedure TAVRCore.di;
begin
  emit_word($94F8);
end;

procedure TAVRCore.ei;
begin
  emit_word($9478);
end;

procedure TAVRCore.mul(Dest, Op1, Op2: PNode);
begin
 //
end;

procedure TAVRCore.nop;
begin
  emit_word(0);
end;

procedure TAVRCore.sbc(Dest, Op1, Op2: PNode);
begin

end;

procedure TAVRCore.sub(Dest, Op1, Op2: PNode);
begin

end;

procedure TAVRCore.SetFamily(const Value: string);
begin
  FFamily := value;
end;

procedure TAVRCore.SetDevice(const Value: string);
begin
  FDevice := Value;
  // Create INI File Object
  Config := TIniFile.Create(RootDir + 'CONFIG\DEVICE\' + FFamily + '\' + FDevice + '.ini');
  // Read SFR's and Vectors
  Config.ReadSectionValues('SFR', sfrStrings);
  Config.ReadSectionValues('Vector', vecStrings);
  MaxVector := Config.ReadInteger('CPU', 'Vectors', 0);
  //
  bLongVector := Config.ReadBool('CPU', 'LONGVECTOR', false);

end;

procedure TAVRCore.emit_word(value: word);
begin
  emit.emit_word(value);
end;

function TAVRCore.Disasm(value: Pointer): string;
var
  code: word;
  code32: cardinal;
  sx: string;
  S: string[255];
  L: Longint;
  C: Char;
begin
  result := '';
  code := word(value^);
  C := FillChr;
//D6 FillChr := '0';
  // if disasmtyp = 0 then Sx := '0x' else       Sx := 'L';
  Sx := '0x';
  S := '';
  //
  case Code of
    $0400..$2FFF: begin
        case Code of
          $0C00..$0FFF: S := 'ADD '; $1C00..$1FFF: S := 'ADC ';
          $0400..$07FF: S := 'CPC '; $1400..$17FF: S := 'CP  ';
          $0800..$0BFF: S := 'SBC ';
          $1000..$13FF: S := 'CPSE '; $2C00..$2FFF: S := 'MOV ';
          $2400..$27FF: S := 'EOR '; $2800..$2BFF: S := 'OR  ';
          $1800..$1BFF: S := 'SUB '; $2000..$23FF: S := 'AND ';
        end;
        S := S + 'R' + I2S(Code shr 4 and $1F, 0) + ',' + 'R' + I2S(Code and $0F + (Code shr 5 and $10), 0);
      end;
    $B800..$BFFF: begin
        S := 'OUT ' + sfrToStr(Code) + ',R' + I2S(Code shr 4 and $1F, 0);
      end;
    $B000..$B7FF: begin
        S := 'IN ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',' + sfrToStr(Code);
      end;
    $F000..$F7FF: begin
        case (Code and $0407) of
          $0400: S := 'BRCC '; $0001: S := 'BREQ ';
          $0401: S := 'BRNE '; $0000: S := 'BRCS ';
          $0404: S := 'BRGE '; $0004: S := 'BRLT ';
          $0405: S := 'BRHC '; $0005: S := 'BRHS ';
          $0407: S := 'BRID '; $0007: S := 'BRIE ';
          $0402: S := 'BRPL '; $0002: S := 'BRMI ';
          $0406: S := 'BRTC '; $0006: S := 'BRTS ';
          $0403: S := 'BRVC '; $0003: S := 'BRVS ';
        end;
        L := (Code shr 3 and $7F);
        if (L and $40) <> 0 then begin
          L := L or $FFFFFF80;
          //L := -L;
          //L := L and $3F;
        end;
        S := S + Sx + L2HEX(ip + 1 + L, 4);
      end;
    $9800..$9BFF: begin
        case Code of
          $9800..$98FF: S := 'CBI '; $9A00..$9AFF: S := 'SBI ';
          $9900..$99FF: S := 'SBIC '; $9B00..$9BFF: S := 'SBIS ';
        end;
        S := S + '0x' + L2HEX(Code shr 3 and $1F, 2) + ',' + L2HEX(Code and 7, 1);
      end;
    $F800..$FFFF: begin
        case Code of
          $F800..$F9FF: S := 'BLD ';
          $FA00..$FBFF: S := 'BST ';
          $FC00..$FDFF: S := 'SBRC ';
          $FE00..$FFFF: S := 'SBRS ';
        end;
        S := S + 'R' + I2S(Code shr 4 and $1F, 0) + ',' + L2HEX(Code and 7, 1);
      end;
    $E000..$EFFF,
      $3000..$7FFF: begin
        case Code of
          $E000..$EFFF: S := 'LDI ';
          $4000..$4FFF: S := 'SBCI ';
          $5000..$5FFF: S := 'SUBI ';
          $6000..$6FFF: S := 'ORI ';
          $3000..$3FFF: S := 'CPI ';
          $7000..$7FFF: S := 'ANDI ';
        end;
        S := S + 'R' + I2S(Code shr 4 and $F + 16, 0) + ',0x' + L2HEX((Code shr 4 and $F0) + (Code and $F), 2);
      end;

    $9488: S := 'CLC'; $9408: S := 'SEC';
    $94D8: S := 'CLH'; $9458: S := 'SEH'; {CLH FIX 0.26}
    $94F8: S := 'CLI'; $9478: S := 'SEI';
    $94A8: S := 'CLN'; $9428: S := 'SEN';
    $94C8: S := 'CLS'; $9448: S := 'SES';
    $94E8: S := 'CLT'; $9468: S := 'SET';
    $94B8: S := 'CLV'; $9438: S := 'SEV';
    $9498: S := 'CLZ'; $9418: S := 'SEZ';
    $9509: S := 'ICALL'; $9409: S := 'IJMP';
    $95C8: S := 'LPM';
    $95E8: S := 'SPM';

    $9588: S := 'SLEEP';
    $9598: S := 'DEBUGBREAK';
    $95A8, $95B8: S := 'WDR';
    $9508, $9528, $9548, $9568: S := 'RET';
    $9518, $9538, $9558, $9578: S := 'RETI';

    {adiw}
    $9600..$96FF: begin
        S := 'ADIW R' + I2S((Code shr 4 and $3 + 12) * 2, 2) + ',0x' + L2HEX((Code shr 2 and $30) + (Code and $F), 2);
      end;
    {sbiw}
    $9700..$97FF: begin
        S := 'SBIW R' + I2S((Code shr 4 and $3 + 12) * 2, 2) + ',0x' + L2HEX((Code shr 2 and $30) + (Code and $F), 2);
      end;
    {rjmp/rcall}
    $C000..$DFFF: begin
        if Code >= $D000 then S := 'RCALL ' else S := 'RJMP ';
        L := (Code and $FFF);
        if (Code and $800) <> 0 then begin
          {S := S + '-';}
          L := L or $FFFFF000;
          //L := -L;
        end;
        S := S + Sx + L2HEX(ip + 1 + L, 4)
      end;
    $0001: begin
        S := 'RETNMI';
      end;
    $0000: begin
        S := 'NOP';
      end else begin
      if (Code and $D208) = $8000 then
      begin { ld r y+n}
        S := 'LDD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',Z+' +
          I2S(((Code and 7) or (Code shr 7 and $18) or (Code shr 8 and $20)), 0);
        result := S;
      end;
      if (Code and $D208) = $8008 then
      begin { ld r y+n}
        S := 'LDD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',Y+' +
          I2S(((Code and 7) or (Code shr 7 and $18) or (Code shr 8 and $20)), 0);
        result := S;
      end;
      if (Code and $D208) = $8200 then
      begin { ld r y+n}
        S := 'STD Z+' + I2S(((Code and 7) or (Code shr 7 and $18) or (Code shr 8 and $20)), 0)
          + ',R' + I2S(Code shr 4 and $1F, 0);
        result := S;
      end;
      if (Code and $D208) = $8208 then
      begin { ld r y+n}
        S := 'STD Y+' + I2S(((Code and 7) or (Code shr 7 and $18) or (Code shr 8 and $20)), 0)
          + ',R' + I2S(Code shr 4 and $1F, 0);
        result := S;
      end;

      case (Code and $FE0F) of
        $8000: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',Z ';
        $9001: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',Z+ ';
        $9002: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',-Z ';
        $8200: S := 'ST ' + 'Z,R' + I2S(Code shr 4 and $1F, 0);
        $9201: S := 'ST ' + 'Z+,R' + I2S(Code shr 4 and $1F, 0);
        $9202: S := 'ST ' + '-Z,R' + I2S(Code shr 4 and $1F, 0);

        $8008: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',Y ';
        $9009: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',Y+ ';
        $900A: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',-Y ';
        $8208: S := 'ST ' + 'Y,R' + I2S(Code shr 4 and $1F, 0);
        $9209: S := 'ST ' + 'Y+,R' + I2S(Code shr 4 and $1F, 0);
        $920A: S := 'ST ' + '-Y,R' + I2S(Code shr 4 and $1F, 0);

        $900C: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',X ';
        $900D: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',X+ ';
        $900E: S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',-X ';
        $920C: S := 'ST ' + 'X,R' + I2S(Code shr 4 and $1F, 0);
        $920D: S := 'ST ' + 'X+,R' + I2S(Code shr 4 and $1F, 0);
        $920E: S := 'ST ' + '-X,R' + I2S(Code shr 4 and $1F, 0);

        $9200: begin
            code32 := cardinal(value^);
            S := 'STS ' + '[0x' + L2HEX(code32 shr 16, 4) + '],R' + I2S(Code shr 4 and $1F, 0);
          end;
        $9000: begin
            code32 := cardinal(value^);
            S := 'LDS R' + I2S(Code shr 4 and $1F, 0) + ',[0x' + L2HEX(code32 shr 16, 4) + ']';
          end;
        $900F: S := 'POP R' + I2S(Code shr 4 and $1F, 0); {fix 0.26}
        $920F: S := 'PUSH R' + I2S(Code shr 4 and $1F, 0); {fix 0.26}

        $9400: S := 'COM R' + I2S(Code shr 4 and $1F, 0); {fix 0.26}
        $9401: S := 'NEG R' + I2S(Code shr 4 and $1F, 0); {fix 0.26}
        $9405: S := 'ASR R' + I2S(Code shr 4 and $1F, 0);
        $9406: S := 'LSR R' + I2S(Code shr 4 and $1F, 0);
        $940A: S := 'DEC R' + I2S(Code shr 4 and $1F, 0);
        $940C: begin
            code32 := cardinal(value^);
            S := 'JMP 0x' + L2HEX(code32 shr 16, 4);
          end;
        $940E: begin
            code32 := cardinal(value^);
            S := 'CALL 0x' + L2HEX(code32 shr 16, 4);
          end;

        $9403: S := 'INC R' + I2S(Code shr 4 and $1F, 0);
        $9407: S := 'ROR R' + I2S(Code shr 4 and $1F, 0);
        $9402: S := 'SWAP R' + I2S(Code shr 4 and $1F, 0);
      else begin
          S := 'Undefined Opcode: ' + L2HEX(Code, 4);
          { ? }
          // #todo1 LDD disasm?
          //LDD  { 10o0 oo0d dddd sooo }
          //STD  { 10o0 oo1d dddd sooo }


          // +Inttostr((code and 7) +(code shr 7 and $18)+(code shr 8 and $20))+
          if (code and $D208) = $8000 then
          begin
            //ldd r,z+k
            S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',Z+' + Inttostr((code and 7) + (code shr 7 and $18) + (code shr 8 and $20));
          end;
          if (code and $D208) = $8008 then
          begin
            S := 'LD ' + 'R' + I2S(Code shr 4 and $1F, 0) + ',Y+' + Inttostr((code and 7) + (code shr 7 and $18) + (code shr 8 and $20));
          end;

          if (code and $D208) = $8200 then
          begin
            S := 'ST ' + 'Z+' + Inttostr((code and 7) + (code shr 7 and $18) + (code shr 8 and $20)) + ',R' + I2S(Code shr 4 and $1F, 0);
          end;
          if (code and $D208) = $8208 then
          begin
            S := 'ST ' + 'Y+' + Inttostr((code and 7) + (code shr 7 and $18) + (code shr 8 and $20)) + ',R' + I2S(Code shr 4 and $1F, 0);
          end;

          if (code and $FF00) = $0100 then
          begin
            S := 'MOVW R' + inttostr(code shr 3 and $1E) + ', R' + inttostr(code shl 1 and $1E);
          end;

//D6          FillChr := C;
          result := S;
        end;
      end;
    end;
  end;
//D6  FillChr := C;
  result := s;

end;

constructor TAVRCore.create;
begin
  inherited create(AOwner);
  Family := 'AVR';
  Device := '1200'; // Creates Config INI File!
end;

destructor TAVRCore.destroy;
begin
  Config.Free;
  inherited destroy;
end;



function TAVRCore.sfrToStr(value: cardinal): string;
var
  S, S2: string;
  i, j, v: Integer;
begin
  i := value and $0F + (value shr 5 and $30);
  S := '0x' + L2HEX(i, 2);

  //
  // Find SFR's!
  //
  if sfrStrings <> nil then
    if sfrStrings.Count > 0 then
    begin
      j := 0;
      v := -1;
      repeat
        S2 := sfrStrings.Values[sfrStrings.names[j]];
        if S2 <> '' then
        begin
          Delete(S2, 1, 1);
          v := Hex2B(S2);
        end;
        inc(j);
      until (j >= sfrStrings.Count) or (v = i);
      if v = i then
      begin
        dec(j);
        S := sfrStrings.names[j];
      end;
    end;
  result := S;
end;


function TAVRCore.ChkPortStr(value: string): string;
begin
  Result := Config.ReadString('SFRB', value, '-');
  // Check other stuff
end;


function TAVRCore.VecToAddr(value: string): cardinal;
var
  s: string;
begin
  result := $FFFFFFFF; // none
  if vecStrings.Count = 0 then exit;
  s := vecStrings.Values[value]; // get On.. value
  if s <> '' then
  begin
    // Translate
    try
      result := StrToInt(s);
    except
      result := $FFFFFFFF; // none
    end;
  end;
end;

procedure TAVRCore.SetMaxVector(const Value: integer);
begin
  FMaxVector := Value;
end;

procedure TAVRCore.move(Dest, Src: PNode);
begin

  // move Word := Word
//  emit_mov(D^, S^); inc(D^.val); inc(S^.val);
//  emit_mov(D^, S^); dec(D^.val); dec(S^.val);

end;

procedure TAVRCore.jump_addr(addr: cardinal);
begin
  if bLongVector then
  begin
    // Check if in Range...
    if Abs(ip - addr) > 2000 then
    begin
       // JMP (long JMP)
      emit_rec2(ip, $940C + (addr shl 16), linenum, 1);
      inc(ip, 2);
    end else
    begin
      // RJMP always...
      emit_rec(ip, $C000 + ((addr - ip - 1) and $FFF), linenum, 1);
      inc(ip);
    end;
  end else
  begin
    // RJMP always...
    emit_rec(ip, $C000 + ((addr - ip - 1) and $FFF), linenum, 1);
    inc(ip);
  end;

end;

procedure TAVRCore.emit_typ3(S: PNode; code: word);
begin
  if S^.Val = wreg_def then assume_none; //##
  //
  emit_rec(ip, code + (S^.Val shl 4 and $1F0), linenum, 1);
  inc(ip);
end;

procedure TAVRCore.call_addr(addr: cardinal);
begin
  stackneeded := True;

  if bLongVector then
  begin
    // Check if in Range...
    if Abs(ip - addr) > 2000 then
    begin
       // CALL (long CALL)
      emit_rec2(ip, $940E + (addr shl 16), linenum, 1);
      inc(ip, 2);
    end else
    begin
      // RJMP always...
      emit_rec(ip, $D000 + ((addr - ip - 1) and $FFF), linenum, 1);
      inc(ip);
    end;
  end else
  begin
    // RJMP always...
    emit_rec(ip, $D000 + ((addr - ip - 1) and $FFF), linenum, 1);
    inc(ip);
  end;
end;

procedure TAVRCore.lds(Dest, Src: PNode);
begin

end;

procedure TAVRCore.sts(Dest, Src: PNode);
begin

end;

procedure TAVRCore.inp(Dest, Src: PNode);
begin

end;

procedure TAVRCore.outp(Dest, Src: PNode);
begin

end;

end.

