(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit Emit_Avr;

interface

uses
  ToolSrv,
  AVRCore,

  StrUt,
  funcs,

  SysUtils,
  MStrings,
  AsmSub,
  CompDef,
  Common,
  CompUt,
  NodePool,
  FunProc,
  LstFile,
  EFile,
  prefer,
  emit;

const
  a_EEAR: Word = $1E;
  a_EEDR: Word = $1D;
  a_EECR: Word = $1C;
  {reg}
  a_IX = $1E; { ZL    }

var
  wdprescaler: Integer;
  prim, sec,
    primLo, primHi,
    secLo, secHi,
    Y, Z: TSym;


procedure expect(d: PSYM; l,err: integer);
//added
function emit_jmp_byname(n: string): integer;
function emit_call_byname(n: string): integer;
function FindAddr(n: string): integer;

procedure emit_brbs(bit: integer; lab: PSym);
procedure emit_brbc(bit: integer; lab: PSym);


procedure AVR_Libcalls;
procedure LibCall(n: string);

procedure EvalDotTree(Tree: PSym);
procedure EvalBR2Tree(Tree: PSym);

procedure emit_init;
procedure emit_device;

procedure IntrCode(n: Integer; bReg: Boolean);

function emit_ee_wr(D, S: Psym; ps: string): Psym;
function emit_ee_rd(D, S: Psym; ps: string): Psym;

//Function emit_wait(O: PSym): PSym;

function emit_plus(D, S, O: PSym): PSym;
function emit_minus(D, S, O: PSym): PSym;
function emit_binary_and(D, S, O: PSym): PSym;
function emit_swap(D, S: Psym): PSym;
function emit_com(D, S: Psym): PSym;

function emit_eval2(D, S: Psym): Psym;
function emit_assign(D, S: Psym): Psym; { D := S (simple) }
function emit_asm(T, D, S: Psym): Psym; { Asm Style Tokens }

function emit_dobit(D, S: Psym): Psym; { bitvar = ... }
{}
function emit_jmp(addr: Integer): Boolean;
function emit_call(addr: Integer): Boolean;
{}
function emit_beq(Op1, Op2, Lab: PSym; addr: Integer): Boolean;
function emit_bne(Op1, Op2, Lab: PSym; addr: Integer): Boolean;

function emit_blt(Op1, Op2, Lab: PSym; addr: Integer): Boolean;
function emit_ble(Op1, Op2, Lab: PSym; addr: Integer): Boolean;
function emit_bgt(Op1, Op2, Lab: PSym; addr: Integer): Boolean;
function emit_bge(Op1, Op2, Lab: PSym; addr: Integer): Boolean;

function emit_ei: Boolean;
function emit_di: Boolean;


{ Native AVR Emit}
function emitn_ldd(D, S, Ofs: PSym): Boolean;
function emitn_std(D, S, Ofs: PSym): Boolean;

function emitn_adiw(D, val: PSym): Boolean;
function emitn_sbiw(D, val: PSym): Boolean;

function emitn_ldp(D, S: PSym): Boolean;
function emitn_lpmp(D, S: PSym): Boolean;

function emitn_ldm(D, S: PSym): Boolean;

function emitn_stp(D, S: PSym): Boolean;
function emitn_stm(D, S: PSym): Boolean;

function emitn_lds(D, S: PSym): Boolean;
function emitn_sts(D, S: PSym): Boolean;

function emit_push(D: PSym): Boolean;
function emit_pop(D: PSym): Boolean;

{}

function emit_djnz(S: TSym; addr: Integer): Boolean;
function emit_ijnz(S: TSym; addr: Integer): Boolean;

function emit_ror(S: TSym): Boolean;

function emit_bitmove(D, S: TSym): Boolean;
function emit_ret: Boolean;
function emit_reti: Boolean;
function emit_retconst(S: Tsym): Boolean;

function emit_Typ(Code: Word): Boolean;
function emit_Typ0(S: TSym; Lit, Code: Word): Boolean;
function emit_Typ1(S: TSym; Code: Word): Boolean;
function emit_Typ1x(S: TSym; Code, O: Word): Boolean;

function emit_Typ1a(S: TSym; Code: Word): Boolean;
function emit_Typ2(D, S: TSym; Code: Word): Boolean;
function emit_Typ2a(D, S: TSym; Code: Word): Boolean;
function emit_Typ3(S: TSym; Code: Word): Boolean;

function emit_sbrc(S: TSym): Boolean;
function emit_sbrs(S: TSym): Boolean;

function emit_cbi(S: TSym): Boolean;
function emit_sbi(S: TSym): Boolean;
function emit_sbic(S: TSym): Boolean;
function emit_sbis(S: TSym): Boolean;

function emit_in(D, S: TSym): Boolean;
function emit_out(D, S: TSym): Boolean;

function emit_ldi(S: TSym; Lit: Word): Boolean;
function emit_andi(S: TSym; Lit: Word): Boolean;
function emit_subi(S: TSym; Lit: Word): Boolean;
function emit_sbci(S: TSym; Lit: Word): Boolean;
function emit_ori(S: TSym; Lit: Word): Boolean;

function emitn_mul(D, S: TSym): Boolean;

function emit_mul(D, S: TSym): Boolean;
function emit_div(D, S: TSym): Boolean;

function emit_mov(D, S: TSym): Boolean;
function emit_movw(D, S: TSym): Boolean;

function emit_cp(D, S: TSym): Boolean;
function emit_cpc(D, S: TSym): Boolean;
function emit_add(D, S: TSym): Boolean;
function emit_adc(D, S: TSym): Boolean;
function emit_sub(D, S: TSym): Boolean;
function emit_sbc(D, S: TSym): Boolean;
function emit_and(D, S: TSym): Boolean;
function emit_or(D, S: TSym): Boolean;
function emit_eor(D, S: TSym): Boolean;

function emit_dec(S: TSym): Boolean;
function emit_inc(S: TSym): Boolean;
function emit_ld(S: TSym): Boolean;
function emit_st(S: TSym): Boolean;

function emit_bld(S: TSym): Boolean;
function emit_bst(S: TSym): Boolean;

function is_branchok(line: Integer): Boolean;
procedure fix1(x: Word; fixnum: Integer);
function emit_fixup(T: TSym; x: Word): Boolean;


procedure nreg(D: PSYM);

var
  TC,
    TR: TSYM;

function REG(v: Integer): PSYM;
function CON(v: Integer): PSYM;

implementation

procedure expect;
begin
  if D = nil then
  begin
    error(116);
    exit;
  end;
  if D^.yylex <> l then
  begin
    error(err);
  end;



end;

procedure nreg(D: PSYM);
begin
  if D^.typ <> sym_DEF then error(114);
end;

function REG(v: Integer): PSYM;
begin
  TR.yylex := T_VAR;
  TR.typ := sym_DEF;
  TR.Val := v;
  Result := @TR;
end;

function CON(v: Integer): PSYM;
begin
  TC.yylex := T_CONST;
  TC.typ := sym_Const;
  TC.subval := 0;
  TC.Val := v;
  Result := @TC;
end;

procedure LibCall(n: string);
begin
  stackneeded := True;
  AddLibCall(n);
  StrPCopy(SwLab.Name, n);
  emit_call(FindLabelAddr(SwLab));
end;

function emit_jmp_byname;
var a: integer;
begin
  StrPCopy(SwLab.Name, n);
  a := FindLabelAddr(SwLab);
  if a = 0 then error(err_Undefined_Label);
  emit_jmp(a);
end;

function emit_call_byname;
var a: integer;
begin
  StrPCopy(SwLab.Name, n);
  a := FindLabelAddr(SwLab);
  if a = 0 then error(err_Undefined_Label);
  emit_call(a);
end;

function FindAddr;
begin
  StrPCopy(SwLab.Name, n);
  result := FindLabelAddr(SwLab);
end;


procedure emit_brbc(bit: integer; lab: PSym);
var
  addr: integer;
begin
  addr := FindLabelAddr(lab^);
  if (abs(addr - ip - 1) < $40) and (addr <> 0) then
  begin
    emit_rec(ip, $F400 or (((addr - ip - 1) and $7F) shl 3) or (bit and 7), linenum, 1);
    inc(ip);
  end else
  begin
    error(60);
  end;
end;

procedure emit_brbs(bit: integer; lab: PSym);
var
  addr: integer;

begin
  addr := FindLabelAddr(lab^);
  if (abs(addr - ip - 1) < $40) and (addr <> 0) then
  begin
    emit_rec(ip, $F000 or (((addr - ip - 1) and $7F) shl 3) or (bit and 7), linenum, 1);
    inc(ip);
  end else
  begin
    error(60);
  end;

end;


function emit_jmp;
begin
  core.jump_addr(addr);
end;

function emit_call;
begin
  assume_none;
  core.call_addr(addr);
end;

function emit_djnz;
begin
  emit_dec(S);
  if abs(addr - ip - 1) < $40 then
  begin
    emit_rec(ip, $F401 or (((addr - ip - 1) and $7F) shl 3), linenum, 1); inc(ip);
  end else begin
    emit_typ($F009);
    emit_rec(ip, $C000 + ((addr - ip - 1) and $FFF), linenum, 1); inc(ip);
  end;
end;

function emit_ijnz;
begin
  emit_inc(S);
  if abs(addr - ip - 1) < $40 then
  begin
    emit_rec(ip, $F401 or (((addr - ip - 1) and $7F) shl 3), linenum, 1); inc(ip);
  end else begin
    emit_typ($F009);
    emit_rec(ip, $C000 + ((addr - ip - 1) and $FFF), linenum, 1); inc(ip);
  end;
end;


function emit_Typ;
begin
  emit_rec(ip, code, linenum, 1);
  inc(ip);
end;

function emit_Typ0;
begin
  emit_rec(ip, code + (S.Val shl 4 and $0F0) + (Lit shl 4 and $F00) + (Lit and $F), linenum, 1);
  inc(ip);
end;

function emit_Typ1(S: TSym; Code: Word): Boolean;
begin
  emit_rec(ip, code + (S.Val shl 4 and $1F0) + (S.SubVal and 7), linenum, 1);
  inc(ip);
end;

function emit_Typ1x;
begin
  emit_rec2(ip, code + (S.Val shl 4 and $1F0) + (S.SubVal and 7) + (O shl 16), linenum, 1);
  inc(ip);
  inc(ip);
end;

function emit_Typ1a(S: TSym; Code: Word): Boolean; begin
  emit_rec(ip, code + (S.Val shl 3 and $0F8) + (S.SubVal and 7), linenum, 1);
  inc(ip);
end;

function emit_Typ2; begin
  // assume_none
  emit_rec(ip, code + (D.Val shl 4 and $1F0) + (S.Val and $0F) + (S.Val shl 5 and $0600), linenum, 1);
  inc(ip);
end;

function emit_Typ2a; begin
  // assume_none ?
  emit_rec(ip, code + (D.Val shl 4 and $1F0) + (S.Val and $0F) + (S.Val shl 5 and $0200), linenum, 1);
  inc(ip);
end;

function emit_Typ3; begin
  // assume_none ?

  emit_rec(ip, code + (S.Val shl 4 and $1F0), linenum, 1);
  inc(ip);
end;


function emit_sbrc;
begin
  emit_Typ1(S, $FC00);
end;

function emit_sbrs;
begin
  emit_Typ1(S, $FE00);
end;

function emit_cbi;
begin
  emit_Typ1a(S, $9800);
end;

function emit_sbi;
begin
  emit_Typ1a(S, $9A00);
end;

function emit_sbic;
begin
  emit_Typ1a(S, $9900);
end;

function emit_sbis;
begin
  emit_Typ1a(S, $9B00);
end;

function emit_in;
begin
  emit_Typ2(D, S, $B000);
end;

function emit_out;
begin
  emit_Typ2(S, D, $B800);

  if not userstackok then
    if has_sram and (not DoInitStack) then
    begin
      if (D.Val = $3E) or (D.Val = $3D) then
      begin
        userstackok := True;
      end;
    end;
end;

function emit_ldi;
begin
  case S.Typ of
    sym_DEF: begin
        if S.val = WREG.val then begin
          if (wreg_val = -1) or ((wreg_val xor Lit and 255) <> 0) then
          begin
            emit_Typ0(S, Lit, $E000);
            wreg_val := lit and 255;
          end;
        end else emit_Typ0(S, Lit, $E000);
      end;
    sym_WORD: begin
        emit_Typ0(S, Lit, $E000);
        TempSym.Val := S.Val + 1;
        emit_Typ0(TempSym, Lit shr 8, $E000);
      end;
    sym_WORD32: begin
        emit_Typ0(S, Lit, $E000);
        TempSym.Val := S.Val + 1;
        emit_Typ0(TempSym, Lit shr 8, $E000);
        TempSym.Val := S.Val + 2;
        emit_Typ0(TempSym, Lit shr 16, $E000);
        TempSym.Val := S.Val + 3;
        emit_Typ0(TempSym, Lit shr 24, $E000);
      end;


    sym_SINGLE: begin
        {
           if Lit^.subval = 0 then
              i32 := Single2I( Lit^.val * 1.0)
           else
              i32 := Lit^.val;

           emit_ldi(REG(S.val+0)^, i32);
           emit_ldi(REG(S.val+1)^, i32 shr 8);
           emit_ldi(REG(S.val+2)^, i32 shr 16);
           emit_ldi(REG(S.val+3)^, i32 shr 24);
        }
      end;
  end;
end;

function emit_andi;
begin
  if S.Val > 15 then
    emit_Typ0(S, Lit, $7000)
  else begin
    emit_ldi(WREG, Lit);
    emit_and(S, WREG);
  end;
end;

function emit_subi;
begin
  if S.Val > 15 then
    emit_Typ0(S, Lit, $5000)
  else begin
    emit_ldi(WREG, Lit);
    emit_sub(S, WREG);
  end;
end;

function emit_sbci;
begin
  if S.Val > 15 then
    emit_Typ0(S, Lit, $4000)
  else begin
    emit_ldi(WREG, Lit);
    emit_sbc(S, WREG);
  end;
end;

function emit_ori;
begin
  case s.typ of
    sym_bit,
      sym_DEF:
      begin
        if S.Val > 15 then
          emit_Typ0(S, Lit, $6000)
        else begin
          emit_ldi(WREG, Lit);
          emit_or(S, WREG);
        end;
      end;
    sym_IO:
      begin
        emit_in(WREG, S);
        emit_ori(WREG, Lit);
        emit_out(S, WREG);
      end;
  end;
end;

//
// MOV Rd,Rs
//
function emit_mov;
begin
  if (D.val and $1F) <> S.val then // no need to move r0,r0
    emit_Typ2a(D, S, $2C00);
  //- - - - - - - - - - - - - - - - - - - - -

  //- - - - - - - - - - - - - - - - - - - - -
end;

function emit_movw;
begin
  if (D.val and $1F) <> S.val then // no need to move r0,r0
  begin
    if ((D.Val or S.Val) and 1) = 0 then
    begin
      // assume none
      emit_Typ($0100 or (D.Val shl 3 and $F0) or (S.Val shr 1 and $0F) );
    end else
    begin
      // wrong operands
      error(9876);
    end;
  end;



end;

{ Accepts cpi Lit Const }

function emit_cp;
begin
  if D.typ = sym_SINGLE then
  begin
    emit_ldi(ZL, D.val); LibCall('FP_LD_A');
    emit_ldi(ZL, S.val); LibCall('FP_LD_B');
    LibCall('FP_CMP');
    Exit;
  end;

  case S.Typ of
    sym_Const: begin
        case D.typ of
          sym_lDEF: begin
              emitn_ldd(@primLo, @Y, @D);
              emit_Typ0(primLo, S.val, $3000);
            end;
          sym_DEF: begin
              if D.Val > 15 then
                { cp regH, Lit}
                emit_Typ0(D, S.Val, $3000)
              else begin
                emit_ldi(WREG, S.Val);
                emit_Typ2a(D, WREG, T_CP); { cp }
              end;
            end;
          sym_word: begin
              if D.Val > 15 then
              begin { cp regH, Lit}
                emit_Typ0(D, S.Val, $3000);
              end else begin
                emit_ldi(WREG, S.Val);
                emit_Typ2a(D, WREG, T_CP); { cp }
              end;
              emit_ldi(WREG, S.Val shr 8);
              Tmp := D;
              Tmp.val := Tmp.val + 1;
              emit_Typ2a(Tmp, WREG, T_CPC); { cp }
            end;
        end;
      end else begin
      { CP reg, reg }
      case D.typ of
        sym_sDEF: begin
            emitn_lds(@WREG, @S);
            emit_Typ2a(D, WREG, T_CP); { cp }
          end;
        sym_lDEF: begin
            emitn_ldd(@primLo, @Y, @D); // Get Primary
            emitn_ldd(@secLo, @Y, @S); // Get Secondary
            emit_Typ2a(primLo, secLo, T_CP); // Compare
          end;
        sym_DEF: begin
            emit_Typ2a(D, S, T_CP); { cp }
          end;
        sym_Word: begin
            emit_Typ2a(D, S, T_CP); { cp }
            Tmp1 := D; Tmp1.val := Tmp1.val + 1;
            Tmp2 := S; Tmp2.val := Tmp2.val + 1;
            emit_Typ2a(Tmp1, Tmp2, T_CPC); { cp }
          end;
      end;
    end;
  end;
end;

function emit_cpc;
begin
  // emit_Typ2a(D,S,T_CPC);
  case S.Typ of
    sym_Const: begin
        case D.typ of
          sym_lDEF: begin
              emitn_ldd(@primLo, @Y, @D);
              emit_Typ2a(primLo, S, T_CPC);
            end;
          sym_DEF: begin
              emit_ldi(WREG, S.Val);
              emit_Typ2a(D, WREG, T_CPC); { cp }
            end;
          sym_word: begin
              emit_ldi(WREG, S.Val);
              emit_Typ2a(D, WREG, T_CPC); { cp }
              emit_ldi(WREG, S.Val shr 8);
              Tmp := D;
              Tmp.val := Tmp.val + 1;
              emit_Typ2a(Tmp, WREG, T_CPC); { cp }
            end;
        end;
      end else begin
      { CP reg, reg }
      case D.typ of
        sym_sDEF: begin
            emitn_lds(@WREG, @S);
            emit_Typ2a(D, WREG, T_CPC); { cp }
          end;
        sym_lDEF: begin
            emitn_ldd(@primLo, @Y, @D); // Get Primary
            emitn_ldd(@secLo, @Y, @S); // Get Secondary
            emit_Typ2a(primLo, secLo, T_CPC); // Compare
          end;
        sym_DEF: begin
            emit_Typ2a(D, S, T_CPC); { cp }
          end;
        sym_Word: begin
            emit_Typ2a(D, S, T_CPC); { cp }
            Tmp1 := D; Tmp1.val := Tmp1.val + 1;
            Tmp2 := S; Tmp2.val := Tmp2.val + 1;
            emit_Typ2a(Tmp1, Tmp2, T_CPC); { cp }
          end;
      end;
    end;
  end;
end;



function emitn_mul;
begin
  //
  emit_Typ2a(D, S, $9C00);

end;


function emit_mul;
begin
  if D.typ = sym_SINGLE then
  begin
    if S.Typ = sym_CONST then
    begin
      emit_ldi(ZL, D.val); LibCall('FP_LD_A');
      if S.subval = 0 then
        i32 := Single2I(S.val * 1.0)
      else
        i32 := S.val;
      emit_ldi(REG(20)^, i32);
      emit_ldi(REG(21)^, i32 shr 8);
      emit_ldi(REG(22)^, i32 shr 16);
      emit_ldi(REG(23)^, i32 shr 24);
    end else begin
      emit_ldi(ZL, D.val); LibCall('FP_LD_A');
      emit_ldi(ZL, S.val); LibCall('FP_LD_B');
    end;

    StrPCopy(SwLab.Name, 'FP_MUL');
    emit_call(FindLabelAddr(SwLab));

    // Store Result
    emit_ldi(ZL, D.val);
    LibCall('FP_ST_A');
    Exit;
  end;

  if D.typ = sym_WORD then
  begin
    if S.Typ = sym_CONST then
    begin
      emit_ldi(ZL, D.val);
      emit_ldi(REG(20)^, i32);

      error(1111);
    end else
    begin
      error(1112);
      emit_ldi(ZL, D.val);
      emit_ldi(ZL, S.val);
    end;

    // Store Result
    //emit_ldi(ZL, D.val);
    LibCall('US16_MUL');
    Exit;
  end;
  //
  if D.typ = sym_DEF then
  begin
    // MUL REG, REG
  end;


end;

function emit_div;
begin
  if D.typ = sym_SINGLE then
  begin
    if S.Typ = sym_CONST then
    begin
      emit_ldi(ZL, D.val); LibCall('FP_LD_A');
      if S.subval = 0 then
        i32 := Single2I(S.val * 1.0)
      else
        i32 := S.val;
      emit_ldi(REG(20)^, i32);
      emit_ldi(REG(21)^, i32 shr 8);
      emit_ldi(REG(22)^, i32 shr 16);
      emit_ldi(REG(23)^, i32 shr 24);
    end else begin
      emit_ldi(ZL, D.val); LibCall('FP_LD_A');
      emit_ldi(ZL, S.val); LibCall('FP_LD_B');
    end;

    LibCall('FP_DIV');
    // Store Result
    emit_ldi(ZL, D.val);
    LibCall('FP_ST_A');
    Exit;
  end;
end;


function emit_add;
begin
  if D.typ = sym_SINGLE then
  begin
    if S.Typ = sym_CONST then
    begin
      emit_ldi(ZL, D.val); LibCall('FP_LD_A');
      if S.subval = 0 then
        i32 := Single2I(S.val * 1.0)
      else
        i32 := S.val;
      emit_ldi(REG(20)^, i32);
      emit_ldi(REG(21)^, i32 shr 8);
      emit_ldi(REG(22)^, i32 shr 16);
      emit_ldi(REG(23)^, i32 shr 24);
    end else begin
      emit_ldi(ZL, D.val); LibCall('FP_LD_A');
      emit_ldi(ZL, S.val); LibCall('FP_LD_B');
    end;

    StrPCopy(SwLab.Name, 'FP_ADD');
    emit_call(FindLabelAddr(SwLab));

    // Store Result
    emit_ldi(ZL, D.val);
    LibCall('FP_ST_A');
    Exit;
  end;

  if (S.Typ = sym_DEF) and (S.Typ = sym_DEF) then
  begin
    emit_Typ2a(D, S, T_ADD);
    exit;
  end;

  if S.Typ = sym_Const then
  begin
    if D.Typ = sym_WORD32 then { OOPS! }
    begin
      D.typ := sym_DEF;
      emit_subi(D, -S.val);
      S.val := (-S.val) shr 8; D.val := D.val + 1; emit_sbc(D, S);
      S.val := (S.val) shr 8; D.val := D.val + 1; emit_sbc(D, S);
      S.val := (S.val) shr 8; D.val := D.val + 1; emit_sbc(D, S);
      exit;
    end;

    if D.Typ = sym_WORD then { OOPS! }
    begin
      if has_adiw then
      begin { adiw ? }
        if (D.Val in [24, 26, 28, 30]) and (S.val < 64) and (S.val >= 0) then
        begin
          emit_typ($9600 + (D.val shl 3 and $30) + (S.val and 15) + (S.val shl 2 and $C0));
        end else begin
          emit_subi(D, -S.val);
          S.val := (-S.val) shr 8;
          D.typ := sym_DEF;
          D.val := D.val + 1;
          emit_sbc(D, S);
          exit;
        end;
      end else
      begin
        emit_subi(D, -S.val);
        S.val := (-S.val) shr 8;
        D.typ := sym_DEF;
        D.val := D.val + 1;
        emit_sbc(D, S);
        exit;
      end;
    end;
    if D.Typ = sym_DEF then
      if D.Val > 15 then emit_subi(D, -S.val) else
      begin
        emit_ldi(WREG, S.Val);
        emit_Typ2a(D, WREG, T_ADD)
      end;
    exit;
  end;
  // word32, word23
  if D.typ = sym_WORD32 then
  begin
    D.typ := sym_DEF;
    S.typ := sym_DEF;
    emit_sub(D, S);
    S.val := S.val + 1; D.val := D.val + 1; emit_sbc(D, S);
    S.val := S.val + 1; D.val := D.val + 1; emit_sbc(D, S);
    S.val := S.val + 1; D.val := D.val + 1; emit_sbc(D, S);
    exit;
  end;

end;

function emit_adc;
begin
  if (S.Typ = sym_DEF) and (S.Typ = sym_DEF) then
  begin
    emit_Typ2a(D, S, T_ADC);
    exit;
  end;

  if S.Typ = sym_Const then
  begin
    if D.Val > 15 then emit_sbci(D, -S.val) else
    begin
      emit_ldi(WREG, S.Val);
      emit_Typ2a(D, WREG, T_ADC)
    end;
  end;
end;

function emit_sub;
begin
  if D.typ = sym_SINGLE then
  begin
    if S.Typ = sym_CONST then
    begin
      emit_ldi(ZL, D.val); LibCall('FP_LD_A');
      if S.subval = 0 then
        i32 := Single2I(S.val * 1.0)
      else
        i32 := S.val;
      emit_ldi(REG(20)^, i32);
      emit_ldi(REG(21)^, i32 shr 8);
      emit_ldi(REG(22)^, i32 shr 16);
      emit_ldi(REG(23)^, i32 shr 24);
    end else begin
      emit_ldi(ZL, D.val); LibCall('FP_LD_A');
      emit_ldi(ZL, S.val); LibCall('FP_LD_B');
    end;

    StrPCopy(SwLab.Name, 'FP_SUB');
    emit_call(FindLabelAddr(SwLab));

    // Store Result
    emit_ldi(ZL, D.val);
    LibCall('FP_ST_A');
    Exit;
  end;

  if S.Typ = sym_Const then
  begin
    if D.Typ = sym_WORD32 then { OOPS! }
    begin
      D.typ := sym_DEF;
      emit_subi(D, S.val);
      S.val := (S.val) shr 8; D.val := D.val + 1; emit_sbc(D, S);
      S.val := (S.val) shr 8; D.val := D.val + 1; emit_sbc(D, S);
      S.val := (S.val) shr 8; D.val := D.val + 1; emit_sbc(D, S);
      exit;
    end;

    if D.Typ = sym_WORD then { OOPS! }
    begin
      if has_adiw then
      begin { adiw ? }
        if (D.Val in [24, 26, 28, 30]) and (S.val < 64) and (S.val >= 0) then
        begin
          emit_typ($9700 + (D.val shl 3 and $30) + (S.val and 15) + (S.val shl 2 and $C0));
        end else begin
          emit_subi(D, S.val);
          S.val := (S.val) shr 8;
          D.typ := sym_DEF;
          D.val := D.val + 1;
          emit_sbc(D, S);
          exit;
        end;
      end else
      begin
        emit_subi(D, S.val);
        S.val := (S.val) shr 8;
        D.typ := sym_DEF;
        D.val := D.val + 1;
        emit_sbc(D, S);
        exit;
      end;
    end;

    if D.Typ = sym_DEF then
      emit_subi(D, S.val);
    Exit;
  end; // Const

  // word32, word23
  if D.typ = sym_WORD32 then
  begin
    D.typ := sym_DEF;
    S.typ := sym_DEF;
    emit_sub(D, S);
    S.val := S.val + 1; D.val := D.val + 1; emit_sbc(D, S);
    S.val := S.val + 1; D.val := D.val + 1; emit_sbc(D, S);
    S.val := S.val + 1; D.val := D.val + 1; emit_sbc(D, S);
    exit;
  end;

  if S.Typ = sym_DEF then emit_Typ2a(D, S, T_SUB);
end;

function emit_sbc;
begin
  if S.Typ = sym_DEF then emit_Typ2a(D, S, T_SBC);
  if S.Typ = sym_Const then
  begin
    if D.Val > 15 then emit_sbci(D, S.val) else
    begin
      emit_ldi(WREG, S.Val);
      emit_Typ2a(D, WREG, T_SBC)
    end;
  end;
end;

function emit_and;
begin
  if D.Typ = sym_IO then
  begin
    if S.Typ = sym_DEF then
    begin
      emit_in(WREG, D);
      emit_Typ2a(WREG, S, T_AND);
      emit_out(D, WREG);
    end;
    if S.Typ = sym_Const then
    begin
      { OOPS! No EORI }
      emit_in(WREG, D);
      emit_andi(WREG, S.val);
      emit_out(D, WREG);
    end;
    Exit;
  end;
  if S.Typ = sym_DEF then emit_Typ2a(D, S, T_AND);
  if S.Typ = sym_Const then emit_andi(D, S.val);
end;

function emit_or;
begin
  if D.Typ = sym_IO then
  begin
    if S.Typ = sym_DEF then
    begin
      emit_in(WREG, D);
      emit_Typ2a(WREG, S, T_OR);
      emit_out(D, WREG);
    end;
    if S.Typ = sym_Const then
    begin
      { OOPS! No EORI }
      emit_in(WREG, D);
      emit_ori(WREG, S.val);
      emit_out(D, WREG);
    end;
    Exit;
  end;

  if S.Typ = sym_DEF then emit_Typ2a(D, S, T_OR);
  if S.Typ = sym_Const then emit_ori(D, S.val);
end;

function emit_eor;
begin
  if D.Typ = sym_DEF then
  begin
    if S.Typ = sym_DEF then emit_Typ2a(D, S, T_EOR);
    if S.Typ = sym_Const then
    begin
      if D.val = WREG.val then
      begin
        Warning(1011);
        emit_ldi(ZL, S.Val);
        emit_Typ2a(D, ZL, T_EOR);
      end else
      begin
        emit_ldi(WREG, S.Val);
        emit_Typ2a(D, WREG, T_EOR);
      end;
    end;
  end;
  if D.Typ = sym_IO then
  begin
    if S.Typ = sym_DEF then
    begin
      emit_in(WREG, D);
      emit_Typ2a(WREG, S, T_EOR);
      emit_out(D, WREG);
    end;
    if S.Typ = sym_Const then
    begin
      { OOPS! No EORI }
//      Warning(1011);
      emit_ldi(WREG, S.Val);
      emit_in(ZL, D);
      emit_Typ2a(ZL, WREG, T_EOR);
      emit_out(D, ZL);
    end;
  end;

end;

function emit_dec;
begin
  case S.typ of
    sym_lWORD: begin
        emitn_ldd(@primLo, @Y, @S); S.Val := S.val + 1;
        emitn_ldd(@primHi, @Y, @S);

        tcon.val := 1;
        emitn_sbiw(@prim, @tcon);

        emitn_std(@primHi, @Y, @S); S.Val := S.val - 1;
        emitn_std(@primLo, @Y, @S);
      end;
    sym_lDEF: begin
        emitn_ldd(@WREG, @Y, @S);
        emit_Typ3(WREG, $940A);
        emitn_std(@WREG, @Y, @S);
      end;
    sym_sDEF: begin
        emitn_lds(@WREG, @S);
        emit_Typ3(WREG, $940A);
        emitn_sts(@WREG, @S);
      end;
    sym_DEF: begin
        emit_Typ3(S, $940A);
        if S.Val = wreg_def then assume_none; //##
      end;
    sym_IO: begin
        emit_in(WREG, S);
        emit_Typ3(WREG, $940A);
        emit_out(S, WREG);
      end;
    sym_Word: begin
        emit_subi(S, 1);
        Tmp := S;
        Tmp.Val := Tmp.Val + 1;
        emit_sbci(Tmp, 0);
      end;
  end;
end;

function emit_inc;
begin
  case S.typ of
    sym_lWORD: begin
        emitn_ldd(@primLo, @Y, @S); S.Val := S.val + 1;
        emitn_ldd(@primHi, @Y, @S);

        tcon.val := 1;
        emitn_adiw(@prim, @tcon);

        emitn_std(@primHi, @Y, @S); S.Val := S.val - 1;
        emitn_std(@primLo, @Y, @S);
      end;
    sym_lDEF: begin
        emitn_ldd(@WREG, @Y, @S);
        emit_Typ3(WREG, $9403);
        emitn_std(@WREG, @Y, @S);
      end;
    sym_sDEF: begin
        emitn_lds(@WREG, @S);
        emit_Typ3(WREG, $9403);
        emitn_sts(@WREG, @S);
      end;
    sym_DEF: begin
        emit_Typ3(S, $9403);
        if S.Val = wreg_def then assume_none; //##
      end;
    sym_IO: begin
        emit_in(WREG, S);
        emit_Typ3(WREG, $9403);
        emit_out(S, WREG);
      end;
    sym_Word: begin
//        emit_add(S, CON(1)^);
        emit_subi(S, 255);
        Tmp := S;
        Tmp.Val := Tmp.Val + 1;
        emit_sbci(Tmp, 255);
      end;
  end;
end;

function emit_ld;
begin
  //
  if S.Val = WREG.val then
    assume_none;
  emit_Typ3(S, $8000);
end;

function emit_st;
begin
  emit_Typ3(S, $8200);
end;

function emit_bld;
begin
  emit_typ($F800 + (S.Val shl 4 and $1F0) + (S.SubVal and 7));
end;

function emit_bst;
begin
  emit_typ($FA00 + (S.Val shl 4 and $1F0) + (S.SubVal and 7));
end;


{ Emit rjmp/rcall/brbx immed or fixup record! }

function is_branchok(line: Integer): Boolean;
var
  j: Integer;
begin
  is_branchok := True;
  Exit;
  {
  If last_branch_out = 0 Then Exit;
  For j := 0 to last_branch_out-1 Do
  Begin
    If line = branchout[j] Then
    Begin
      is_branchok := False;
      Exit;
    End;
  End;
  }
end;

procedure fix1(x: Word; fixnum: Integer);
begin
  wreg_val := -1;

  if pass >= 10 then begin
    WrLstLine(L2HEX(ip, 4) + ':????');
    Error(err_Undefined_Label);
  end;

  inc(next_fix);
  inc(ip);
end;

function emit_fixup(T: TSym; x: Word): Boolean;
var
  i: Integer;
begin
  wreg_val := -1;
  //
  // Process SKIP
  //
  if T.yylex = T_SKIP then
  begin
    if (x = 0) or (x = 1) then
    begin
      Error(1015);
    end else
      emit_typ(x or 8); {!}
    Exit;
  end;
  //
  //
  //
  i := 0;
  while i < next_lab do
  begin
    //
    // Find label to JUMP...
    //
    if StrComp(T.Name, Labels[i].Name) = 0 then
    begin
      //
      // Process Label...
      //
      if Labels[i].addr <> undeflab then
      begin
        if (Labels[i].typ = 1) and (x = 0) and (not bGoto) then x := 1;
        { Label defined, do}
        case x of
          0: begin
            core.jump_addr(Labels[i].addr);
//              emit_rec(ip, $C000 or ((Labels[i].addr - ip - 1) and $FFF), linenum, 1);
//              inc(ip);
            end;
          1: begin
              core.call_addr(Labels[i].addr);
//              emit_rec(ip, $D000 or ((Labels[i].addr - ip - 1) and $FFF), linenum, 1);
//              inc(ip);
            end else
          begin
            if abs(Labels[i].addr - ip - 1) < $40 then
            begin
              {We Try Short Branch First! }
              emit_rec(ip, x or (((Labels[i].addr - ip - 1) and $7F) shl 3), linenum, 1);
              inc(ip);
            end else
            begin
              {branch to Long..}
              emit_rec(ip, (x or 8) xor $0400, linenum, 1);
              inc(ip);
              emit_rec(ip, $C000 or ((Labels[i].addr - ip - 1) and $FFF), linenum, 1);
              inc(ip);
            end;
          end;
        end;
        Exit;
      end else begin
        { Lab exists, but undef, make fixup }
        if x > 1 then
        begin
          if is_branchok(linenum) then
          begin
            fix1(x, i);
          end else begin
            emit_rec(ip, x or $08 xor $0400, linenum, 1);
            inc(ip);
            fix1(0, i);
            {
            emit_rec(ip,$C000 or ((Labels[i].addr-ip-1) and $FFF), linenum,1);
            inc(ip);
            }
          end;
        end else begin
          {rjmp/rcall}
          fix1(x, i);
        end;
        Exit;
      end;
    end;
    Inc(i);
  end;
  { Define a undef Lab }
  StrCopy(Labels[next_lab].Name, id);
  Labels[next_lab].addr := undeflab;

  if x > 1 then
  begin
    if is_branchok(linenum) then
    begin
      fix1(x, next_lab);
    end else begin
      emit_rec(ip, x or $08 xor $0400, linenum, 1);
      inc(ip);
      fix1(0, next_lab);
    end;
  end else begin
    {rjmp/rcall}
    fix1(x, next_lab);
  end;
end;

procedure emit_init;
var
  i: Integer;
begin
  cpuclock := 1000000;

  wdprescaler := 7; { Max }
  mode := 0; { user }
  {yyemit_init}
  next_free := 0;
  next_sym := 0; { Clear Symbols ? }
  next_gosub := 0;
  next_for := 0;
  next_repeat := 0;
  next_cnt := 0;
  next_ee := 0; used_ee := 0;

  next_sram := $60; // Fixed ??

  next_h_reg := $1D; { Below ZL }
  next_l_reg := 0;

  next_eeh_reg := 63; { EE Top   }
  next_eel_reg := 0;

  if pass = 0 then begin
    for i := 0 to yyMaxLabels do
      Labels[i].addr := undefined;
    next_lab := 0;
  end;
  next_fix := 0;

  yyemit_errors := 0;
  yystate := yyINITIAL;

  for i := 0 to 255 do
    MEM[i] := 0; //??
end;

{}

function emit_ret;
begin
  stackneeded := True;
  assume_none;
  emit_typ($9508);
end;

function emit_reti;
begin
  stackneeded := True;
  assume_none;
  emit_typ($9518);
end;

function emit_retconst;
begin
  stackneeded := True;
end;

function emit_bitmove;
begin
  emit_bst(S);
  emit_bld(D);
end;

{ D = S + O }

function emit_plus;
begin
  if O^.Typ = sym_DEF then emit_Typ2a(D^, O^, T_ADD);
  if O^.Typ = sym_Const then
  begin
    if D^.Val > 15 then emit_subi(D^, -O^.val) else
    begin
      emit_ldi(WREG, O^.Val);
      emit_Typ2a(D^, WREG, T_ADD)
    end;
  end;
end;
{ D = S - O }

function emit_minus;
begin
  if O^.Typ = sym_DEF then emit_Typ2a(D^, O^, T_SUB);
  if O^.Typ = sym_Const then
  begin
    if D^.Val > 15 then emit_subi(D^, O^.val) else
    begin
      emit_ldi(WREG, O^.Val);
      emit_Typ2a(D^, WREG, T_SUB)
    end;
  end;
end;

function emit_binary_and(D, S, O: PSym): PSym;
begin
  if O^.Typ = sym_DEF then emit_Typ2a(D^, O^, T_AND);
  if O^.Typ = sym_Const then
  begin
    if D^.Val > 15 then emit_andi(D^, O^.val) else
    begin
      emit_ldi(WREG, O^.Val);
      emit_Typ2a(D^, WREG, T_AND)
    end;
  end;
end;

function emit_ror;
begin
  emit_Typ3(S, word(T_ROR));
end;
(*

Function emit_wait;
Begin
  bnot := False;
  If O^.yylex = T_NOT Then
  Begin
    bnot := True;
    O := DropNode(O);
  End;

  Case O^.yylex of
    T_EEPROM: Begin
      emit_typ($99E1); { sbic eecr, 0 }
      emit_jmp(ip-1);  { ?? }
    End;
    //
    //
    //
    T_VAR: Begin
      Case O^.Typ Of
        sym_ioBit: Begin
          if O^.val = $3F Then
          Begin
            if bnot Then emit_typ($F7F8 + (O^.subval and 7))
            else emit_typ($F7F8 + (O^.subval and 7));
          End else Begin
           if O^.val < $20 Then
           Begin
             if bnot Then emit_sbic(O^)
             else emit_sbis(O^);
             emit_jmp(ip-1); { ?? }
           End else Begin
             emit_in(WREG, O^);
             WREG.subval := O^.subval;
             if bnot Then emit_sbrc(WREG)
             else emit_sbrs(WREG);
             WREG.subval := 0;
             emit_jmp(ip-2); { ?? }
           End;
          End;
        End;
        sym_Bit: Begin
          if bnot Then emit_sbrc(O^)
          else emit_sbrs(O^);
          emit_jmp(ip-1); { ?? }
        End;
        sym_DEF: Begin
          emit_and(O^, O^);

          if bnot Then emit_typ($F7F1)
          else emit_typ($F3F1);

        End;
      End;
    End;
    T_CONST: Begin
      Case O^.val of
        0: Begin
        End;
        1: Begin
          emit_typ(0); { NOP }
        End;
        2: Begin
          emit_typ($C000); { rjmp +00 }
        End;
        3: Begin
          emit_typ($C000); { rjmp +00 }
          emit_typ(0); { NOP }
        End;
        4: Begin
          emit_typ($C000); { rjmp +00 }
          emit_typ($C000); { rjmp +00 }
        End;
        5: Begin
          emit_typ($C000); { rjmp +00 }
          emit_typ($C000); { rjmp +00 }
          emit_typ(0); { NOP }
          End;
        6: Begin
          emit_typ($C000); { rjmp +00 }
          emit_typ($C000); { rjmp +00 }
          emit_typ($C000); { rjmp +00 }
        end;
        7..255*3: Begin
          // if not RC!
          If ((O^.val) mod 3) = 2 Then emit_typ(0);     { NOP }
          If ((O^.val) mod 3) = 3 Then emit_typ($C000); { NOP }
          //
          emit_ldi(WREG, (O^.val) div 3);  // 1
          //-----------------------------------
          emit_dec(WREG);                  // 1
          emit_typ($F7F1);                 // 2 Loop
        End else Begin
          Error(1987);
        End;
      End;
    End;
  End
End;
      *)
//
//
//

procedure emit_reg;
var i: Integer;
begin
  for i := 0 to 31 do DefineSymbol('R' + IntToStr(i), i, 0, sym_DEF);
  for i := 0 to 15 do DefineSymbol('W' + IntToStr(i * 2), i * 2, 0, sym_WORD);

  SREG.yylex := T_VAR; SREG.val := $3F; SREG.typ := sym_IO;
  INT_SREG.yylex := T_VAR; INT_SREG.typ := sym_DEF; INT_SREG.val := 0;
  INT_WREG.yylex := T_VAR; INT_WREG.typ := sym_DEF; INT_WREG.val := 29;

  WBIT.yylex := T_VAR; WBIT.Typ := sym_ioBIT;
  WBIT.Val := $3F; WBIT.subVal := 6;

  WREG.yylex := T_VAR; WREG.Typ := sym_DEF;
  WREG.Val := wreg_def; {r31 is Work1}

  ZL.yylex := T_VAR; ZL.Typ := sym_DEF; ZL.Val := a_IX; {r30 is ZL}
  ZH.yylex := T_VAR; ZH.Typ := sym_DEF; ZH.Val := 31; {r31 is ZH}
end;

procedure emit_1200; { 1200 Standard IO }
begin
  emit_reg;
  DefineSymbol('WREG', wreg_def, 0, sym_DEF); { WREG }
  DefineSymbol('WBIT', $3F, 6, sym_ioBit); { WBIT }
end;


procedure emit_device;
var
  v,
    i: Integer;
  s, s2: string;
begin
  // Default CPU?
  cpu := 1200;
  // Parse Device String..
  s := uppercase(devstr);
  if Pos('ATMEGA', s) <> 0 then Delete(s,1,6); // Remove 'ATMEGA'
  if Pos('AT90S', s) <> 0 then Delete(s,1,5);  // Remove 'AT90S'
  if Pos('90S', s) <> 0 then Delete(s,1,3);    // Remove '90S'
  if Pos('S', s) <> 0 then Delete(s,1,1);      // Remove 'S'
  s2 := '';
  i := 1;
  while (i <= length(s)) and (s[i] in ['0'..'9']) do
  begin
    s2 := s2 + s[i];
    inc(i);
  end;
  // s2 <> ''
  // Convert to numeric CPU Value
  try
    cpu := strtoint(s2);
  except
    cpu := 1200;
  end;
  //

  // Create Device String!
  Str(cpu, devstr);

  // Load SFRs ! Inits mem...
  LoadSFRs(devstr);
  has_sram := sram_size <> 0;

  // Define Device I/O Symbols!
  for i := 0 to core.sfrStrings.Count - 1 do
  begin
    s := core.sfrStrings.Names[i];
    s2 := core.sfrStrings.Values[s]; Delete(s2, 1, 1);
    v := Hex2B(s2);
    DefineSymbol(s, v, 0, sym_IO);
  end;

  //----
  mode := 1200; //?
  if sram_size <> 0 then  model := 8515;
  demo := sram_size <> 0;
  emit_1200;
  //
  if has_lpm then
    next_l_reg := 1;

  if sram_size <> 0 then
  begin
    INT_WREG.val := 28; INT_SREG.val := 1;
    next_h_reg := 28;
    wreg_def := 29;
    WREG.val := wreg_def;
  end;

  last_predef := next_sym;

  XR.yylex := T_VAR; XR.Typ := sym_DEF; XR.Val := 26;
  YR.yylex := T_VAR; YR.Typ := sym_DEF; YR.Val := 28;

  if bIntUsesSREG then begin
    INT_SREG.val := next_l_reg;
    inc(next_l_reg);
  end;
  if bIntUsesWREG then begin
    INT_WREG.val := next_h_reg;
    Dec(next_h_reg);
  end;

end;


function emit_ee_wr;
begin
  if (D = nil) or (S = nil) then
  begin
    // Write Sequnce, data/addr set ok

    // if EEMWE Supported then set it
    if not (core.ChkPortStr('EEMWE') = '-') then
      emit_sbi(sym(Tmp, T_VAR, $1C, 2, sym_ioBit, 0, '')^);
    // Set EEWE
    emit_sbi(sym(Tmp, T_VAR, $1C, 1, sym_ioBit, 0, '')^);
    // Wait til ready .. always?
    if use_eewait then
      emit_wait(sym(Tmp, T_EEPROM, 0, 0, 0, 0, ''));
  end;
end;

function emit_ee_rd;
begin
  if (D = nil) or (S = nil) then
  begin
    { Write Sequnce, data/addr set ok }
    emit_sbi(sym(Tmp, T_VAR, $1C, 0, sym_ioBit, 0, '')^);
  end;
end;


{ Branch on Equal }

function emit_beq;
begin
  if (Op1 = nil) or (Op2 = nil) then
  begin
    Exit;
  end;
  { If def = Then }
  case Op1^.typ of
    Sym_sDEF: begin
        case Op2^.typ of
          sym_Const: begin
              if Op2^.val = 0 then
              begin
                emitn_lds(@WREG, Op1);
                emit_and(WREG, WREG);
                emit_fixup(Lab^, $F001); {breq}
              end else begin
                emitn_lds(@WREG, Op1);
                emit_cp(WREG, Op2^);
                emit_fixup(Lab^, $F001); {breq}
              end;
            end;
          Sym_DEF: begin
              emitn_lds(@WREG, Op1);
              emit_cp(WREG, Op2^);
              emit_fixup(Lab^, $F001); {breq}
            end;
        end;
      end;
    { Reg = XX }
    Sym_Word: begin
        case Op2^.typ of
          sym_Const: begin
              if Op2^.val = 0 then
              begin
                emit_mov(WREG, Op1^);
                Tmp := Op1^; Tmp.val := Tmp.val + 1;
                Tmp.typ := sym_def;
                emit_or(WREG, Tmp);
                emit_fixup(Lab^, $F001); {breq}
              end else begin
                emit_cp(Op1^, Op2^);
                emit_fixup(Lab^, $F001); {breq}
              end;
            end;
          Sym_Word: begin
              emit_cp(Op1^, Op2^);
              emit_fixup(Lab^, $F001); {breq}
            end;
        end;
      end;
    Sym_DEF: begin
        case Op2^.typ of
          sym_Const: begin
              if Op2^.val = 0 then
              begin
                emit_and(Op1^, Op1^);
                emit_fixup(Lab^, $F001); {breq}
              end else begin
                emit_cp(Op1^, Op2^);
                emit_fixup(Lab^, $F001); {breq}
              end;
            end;
          Sym_DEF: begin
              if Lab^.yylex = T_SKIP then
              begin
                emit_Typ2a(Op1^, Op2^, T_CPSE);
              end else
              begin
                emit_cp(Op1^, Op2^);
                emit_fixup(Lab^, $F001); {breq}
              end;
            end;
        end;
      end;
    sym_ioBit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbic(Op1^);
          end else begin
            emit_sbis(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbis(Op1^);
          end else begin
            emit_sbic(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
    sym_Bit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrc(Op1^);
          end else begin
            emit_sbrs(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrs(Op1^);
          end else begin
            emit_sbrc(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
  end;
end;

{ Branch on Equal }

function emit_bne;
begin
  if (Op1 = nil) or (Op2 = nil) then
  begin
    Exit;
  end;
  { If def = Then }
  case Op1^.typ of
    Sym_Word: begin
        case Op2^.typ of
          sym_Const: begin
              if Op2^.val = 0 then
              begin
                emit_mov(WREG, Op1^);
                Tmp := Op1^; Tmp.val := Tmp.val + 1;
                Tmp.typ := sym_def;
                emit_or(WREG, Tmp);
                emit_fixup(Lab^, $F401); {breq}
              end else begin
                emit_cp(Op1^, Op2^);
                emit_fixup(Lab^, $F401); {breq}
              end;
            end;
          sym_Word: begin
              emit_cp(Op1^, Op2^);
              emit_fixup(Lab^, $F401); {breq}
            end;
        end;
      end;
    { Reg = XX }
    Sym_DEF: begin
        case Op2^.typ of
          sym_Const: begin
              if Op2^.val = 0 then
              begin
                emit_and(Op1^, Op1^);
                emit_fixup(Lab^, $F401); {breq}
              end else begin
                emit_cp(Op1^, Op2^);
                emit_fixup(Lab^, $F401); {breq}
              end;
            end;
          Sym_sDEF: begin
              emitn_lds(@WREG, Op2);
              emit_cp(WREG, Op1^);
              emit_fixup(Lab^, $F401); {breq}
            end;
          Sym_DEF: begin
              emit_cp(Op1^, Op2^);
              emit_fixup(Lab^, $F401); {breq}
            end;
        end;
      end;
    Sym_sDEF: begin
        case Op2^.typ of
          sym_Const: begin
              if Op2^.val = 0 then
              begin
                emit_and(Op1^, Op1^);
                emit_fixup(Lab^, $F401); {breq}
              end else begin
                emit_cp(Op1^, Op2^);
                emit_fixup(Lab^, $F401); {breq}
              end;
            end;
          Sym_DEF: begin
              emitn_lds(@WREG, Op1);
              emit_cp(WREG, Op2^);
              emit_fixup(Lab^, $F401); {breq}
            end;
        end;
      end;
    //
    // high bank and SREG
    //
    sym_ioBit: begin
        if Op2^.val = 0 then
        begin
          if Op1^.val < $20 then
          begin
            // low IO bank
            if Lab^.yylex = T_SKIP then
            begin
              emit_sbis(Op1^);
            end else begin
              emit_sbic(Op1^);
              emit_fixup(Lab^, 0);
            end;
          end else begin
            if Op1^.val = $3F then
            begin
              emit_fixup(Lab^, $F000 + (Op1^.subval and 7));
            end else begin
              Error(1234);
            end;
          end;
          // = 1
        end else begin
          if Op1^.val < $20 then
          begin
            // low IO bank
            if Lab^.yylex = T_SKIP then
            begin
              emit_sbic(Op1^);
            end else begin
              emit_sbis(Op1^);
              emit_fixup(Lab^, 0);
            end;
          end else begin
            if Op1^.val = $3F then
            begin
              emit_fixup(Lab^, $F400 + (Op1^.subval and 7));
            end else begin
              Error(1234);
            end;
          end;
        end;
      end;
    sym_Bit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrs(Op1^);
          end else begin
            emit_sbrc(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrc(Op1^);
          end else begin
            emit_sbrs(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
  end;
end;


{ Branch on Less Than < }

function emit_blt;
begin
  { If def = Then }
  case Op1^.typ of
    Sym_Const: begin
        emit_bgt(Op2, Op1, Lab, 0);
      end;
    { Reg < const_or_var }
    Sym_Word,
      Sym_DEF: begin
        case Op2^.typ of
          sym_Word,
            sym_DEF,
            sym_Const: begin
              emit_cp(Op1^, Op2^);
              if Lab^.yylex = T_SKIP then
                emit_typ($F008) { brcs+1}
              else
                emit_fixup(Lab^, $F000); {brcs}
            end;
        end;
      end;
  end;
end;

{ Branch on Less or Equal }

function emit_ble;
begin
  { If def = Then }
  case Op1^.typ of
    Sym_Const: begin
        emit_bge(Op2, Op1, Lab, 0);
      end;
    Sym_WORD: begin
        case Op2^.typ of
          sym_Const: begin
              Inc(Op2^.val);
              emit_blt(Op1, Op2, Lab, 0);
              Dec(Op2^.val);
            end;
        end;
      end;
    { Reg = XX }
    Sym_DEF: begin
        case Op2^.typ of
          sym_WORD,
            sym_DEF:
            begin
              emit_cp(Op2^, Op1^);
              if Lab^.yylex = T_SKIP then
                emit_typ($F408) { brcs+1}
              else
                emit_fixup(Lab^, $F400); {brcs}
            end;
          sym_Const:
            begin
              if Op1^.val < 16 then
              begin
                emit_ldi(WREG, Op2^.val);
                emit_cp(WREG, Op1^);
                if Lab^.yylex = T_SKIP then
                  emit_typ($F408) { brcs+1}
                else
                  emit_fixup(Lab^, $F400); {brcs}
              end else
              begin
                { regH > Const }
                inc(Op2^.val);
                emit_cp(Op1^, Op2^);
                if Lab^.yylex = T_SKIP then
                begin
                  emit_typ($F408); { brcc+1}
                end else begin
                  emit_fixup(Lab^, $F000); {brcs}
                end;
              end;
            end;
        end;
      end;
    sym_ioBit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbis(Op1^);
          end else begin
            emit_sbic(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbic(Op1^);
          end else begin
            emit_sbis(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
    sym_Bit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrs(Op1^);
          end else begin
            emit_sbrc(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrc(Op1^);
          end else begin
            emit_sbrs(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
  end;
end;

{ Branch on Greater }

function emit_bgt;
begin
  { If def = Then }
  case Op1^.typ of
    Sym_WORD: begin
        case Op2^.typ of
          sym_Const: begin
              Inc(Op2^.val);
              emit_bge(Op1, Op2, Lab, 0);
              Dec(Op2^.val);
            end;
        end;
      end;
    { Reg = XX }
    Sym_DEF: begin
        case Op2^.typ of
          sym_Const: begin
              if Op1^.val < 16 then
              begin
                emit_ldi(WREG, Op2^.val); // ??
                emit_cp(WREG, Op1^);
                if Lab^.yylex = T_SKIP then
                  emit_typ($F008) { brcs+1}
                else
                  emit_fixup(Lab^, $F000); {brcs}
              end else
              begin
                { regH > Const }
                inc(Op2^.val);
                emit_cp(Op1^, Op2^);
                if Lab^.yylex = T_SKIP then
                begin
                  emit_typ($F008); { brcs+1}
                end else
                begin
                  emit_fixup(Lab^, $F400); {brcs}
                end;
              end;

            end;
          Sym_DEF: begin
              emit_cp(Op1^, Op2^);
              emit_fixup(Lab^, $F401); {breq}
            end;
        end;
      end;
    sym_ioBit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbis(Op1^);
          end else begin
            emit_sbic(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbic(Op1^);
          end else begin
            emit_sbis(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
    sym_Bit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrs(Op1^);
          end else begin
            emit_sbrc(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrc(Op1^);
          end else begin
            emit_sbrs(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
  end;
end;

{ Branch on Greater or Equal }

function emit_bge;
begin
  { If def = Then }
  case Op1^.typ of
    sym_Const: begin
        emit_ble(Op2, Op1, Lab, 0);
      end;
    { Reg = XX }
    Sym_WORD,
      Sym_DEF: begin
        case Op2^.typ of
          sym_Word,
            sym_DEF,
            sym_Const: begin
              emit_cp(Op1^, Op2^);
              if Lab^.yylex = T_SKIP then
                emit_typ($F408) { brcs+1}
              else
                emit_fixup(Lab^, $F400); {brcs}
            end;
        end;
        (*
              Case Op2^.typ of
                sym_Const: Begin
                  If Op2^.val = 0 Then
                  Begin
                    emit_and(Op1^,Op1^);
                    emit_fixup(Lab^, $F401); {breq}
                  end else Begin
                    emit_cp(Op1^,Op2^);
                    emit_fixup(Lab^, $F400); {brcc}
                  End;
                End;
                Sym_DEF: Begin
                    emit_cp(Op1^,Op2^);
                    emit_fixup(Lab^, $F400); {brcc}
                End;
              End;
        *)
      end;
    sym_ioBit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbis(Op1^);
          end else begin
            emit_sbic(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbic(Op1^);
          end else begin
            emit_sbis(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
    sym_Bit: begin
        if Op2^.val = 0 then
        begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrs(Op1^);
          end else begin
            emit_sbrc(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end else begin
          if Lab^.yylex = T_SKIP then
          begin
            emit_sbrc(Op1^);
          end else begin
            emit_sbrs(Op1^);
            emit_fixup(Lab^, 0);
          end;
        end;
      end;
  end;
end;

function emitn_ldd(D, S, Ofs: PSym): Boolean;
var
  w: Word;
begin

  if D^.val = WREG.val then assume_none;

  { 10o0 oo0d dddd sooo }
  w := $8000 or (D^.val shl 4 and $01F0);
  case S^.Val of
    30: ;
    28: w := w or $0008;
    26: begin
        w := w or $100C;
        if Ofs^.val <> 0 then begin
          error(991);
        end;
      end
  else begin
      { Error: Z or Y allowed! }
      error(992);
    end;
  end;
  if Ofs^.val < 64 then
  begin
    w := w or (Ofs^.val and 7) or (Ofs^.val shl 7 and $0C00) or (Ofs^.val shl 8 and $2000);
  end else begin
    { Error Offset > 63 }
    error(993);
  end;

  emit_typ(w);
end;

function emitn_lpmp;
var
  w: Word;
begin
  { 10o0 oo0d dddd sooo }
  if D^.val = WREG.val then assume_none;

  w := $9005 or (D^.val shl 4 and $01F0);
  (*
  case S^.Val of
    30: w := w or $0000; {z+}
    28: w := w or $0008; {y+}
    26: w := w or $000C; {x+}
  else begin
      { Error: Z or Y allowed! }
    end;
  end;
  *)
  emit_typ(w);
end;


function emitn_ldp;
var
  w: Word;
begin
  { 10o0 oo0d dddd sooo }
  if D^.val = WREG.val then assume_none;

  w := $9001 or (D^.val shl 4 and $01F0);
  case S^.Val of
    30: w := w or $0000; {z+}
    28: w := w or $0008; {y+}
    26: w := w or $000C; {x+}
  else begin
      { Error: Z or Y allowed! }
    end;
  end;
  emit_typ(w);
end;

function emitn_ldm;
var
  w: Word;
begin
  { 10o1 oo0d dddd sooo }
  if D^.val = WREG.val then assume_none;

  w := $9002 or (D^.val shl 4 and $01F0);
  case S^.Val of
    30: w := w or $0000; {z+}
    28: w := w or $0008; {y+}
    26: w := w or $000C; {x+}
  else begin
      { Error: Z or Y allowed! }
    end;
  end;
  emit_typ(w);
end;

function emitn_lds;
var
  w: Word;
begin
  { 10o0 oo0d dddd sooo }
  if not has_sram then exit;

  if D^.val = WREG.val then assume_none;

  nreg(D);
  emit_typ1x(D^, $9000, S^.val);

end;

function emitn_sts;
var
  w: Word;
begin
  { 10o0 oo0d dddd sooo }
  if not has_sram then exit;
  nreg(D);
  emit_typ1x(D^, $9200, S^.val);
end;


function emitn_stm;
var
  w: Word;
begin
  { 10o0 oo0d dddd sooo }
  w := $9202 or (D^.val shl 4 and $01F0);
  case S^.Val of
    30: w := w or $0000; {z+}
    28: w := w or $0008; {y+}
    26: w := w or $000C; {x+}
  else begin
      { Error: Z or Y allowed! }
    end;
  end;
  emit_typ(w);
end;

function emitn_stp;
var
  w: Word;
begin
  { 10o0 oo0d dddd sooo }
  w := $9201 or (D^.val shl 4 and $01F0);
  case S^.Val of
    30: w := w or $0000; {z+}
    28: w := w or $0008; {y+}
    26: w := w or $000C; {x+}
  else begin
      { Error: Z or Y allowed! }
    end;
  end;
  emit_typ(w);
end;

function emitn_std;
var
  w: Word;
begin
  { 10o0 oo0d dddd sooo }
  w := $8200 or (D^.val shl 4 and $01F0);
  case S^.Val of
    30: ;
    28: w := w or $0008;
    26: w := w or $100C;
  else begin
      { Error: Z or Y allowed! }
    end;
  end;
  if Ofs^.val < 64 then
  begin
    w := w or (Ofs^.val and 7) or (Ofs^.val shl 7 and $0C00) or (Ofs^.val shl 8 and $2000);
  end else begin
    { Error Offset > 63 }
  end;
  emit_typ(w);
end;

function emitn_adiw(D, val: PSym): Boolean;
var
  w: Word;
begin
  w := $9600;
  case D^.val of
    24: w := $9600;
    26: w := $9610;
    28: w := $9620;
    30: w := $9630;
  end;
  w := w or (val^.val and 15) or (val^.val shl 2 and $00C0);
  emit_typ(w);
end;

function emitn_sbiw(D, val: PSym): Boolean;
var
  w: Word;
begin
  w := $9700;
  case D^.val of
    24: w := $9700;
    26: w := $9710;
    28: w := $9720;
    30: w := $9730;
  end;
  w := w or (val^.val and 15) or (val^.val shl 2 and $00C0);
  emit_typ(w);
end;

function emit_swap;
begin
  emit_Typ3(D^, word(T_SWAP));
end;

function emit_eval2(D, S: Psym): Psym;
var
  IX2,
    Source,
    Fun, Param, Res,
    Dest: Psym;
  V: Word;
begin
  emit_eval2 := S; { by Default }
  Dest := D;
  if D = nil then
  begin
    Dest := @WREG; { If no Destination, return WREG! }
  end;

  case S^.yylex of
    T_EEPROM: begin
        DropNode(S^.right); { [ }
        Source := emit_eval2(nil, S^.right); { Evaluate Index! }
        case Source^.typ of
          sym_DEF: begin
              TempSym.Val := a_EEAR; {EEAR}
              emit_out(TempSym, Source^);
              TempSym.Val := a_EECR; {EECR}
              TempSym.subval := 0; {EERE}
              emit_sbi(TempSym);
              TempSym.Val := a_EEDR; {EEDR}
              emit_in(Dest^, TempSym);
            end;
          sym_Const: begin
              TempSym.Val := a_EEAR; {EEAR}
              emit_ldi(WREG, Source^.val);
              emit_out(TempSym, WREG);
              TempSym.Val := a_EECR; {EECR}
              TempSym.subval := 0; {EERE}
              emit_sbi(TempSym);
              TempSym.Val := a_EEDR; {EEDR}
              emit_in(Dest^, TempSym);
            end;
        end;
        DropNode(S^.right); { index }
        DropNode(S^.right); { ] }

        emit_eval2 := Dest;
        Exit; { Return EE }
      end;
    T_RAM: begin
        bpre := 0;
        TCon.val := 0;
        DropNode(S^.right); { [ }
        if S^.right^.yylex = T_DECDEC then
        begin
          bpre := 2;
          DropNode(S^.right); { [ }
        end;

        if S^.right^.right^.yylex = T_INCINC then begin
          DropNode(S^.right^.right); { Drop ++ }
          bpre := 1; { post-incre }
        end;

        IX2 := @ZL;
        if ((S^.right^.typ = sym_DEF) or (S^.right^.typ = sym_WORD)) and
          (S^.right^.yylex = T_VAR) and
          ((S^.right^.val = 26) or (S^.right^.val = 28) or (S^.right^.val = 30)) then
        begin
          if ((S^.right^.val = 28) or (S^.right^.val = 30)) and (S^.right^.right^.yylex = T_MATH)
            and (S^.right^.right^.right^.yylex = T_CONST) then
          begin
            if (S^.right^.right^.right^.val < 64) and ((S^.right^.right^.val = 2) or (S^.right^.right^.val = 3)) then
            begin
              TCon.val := S^.right^.right^.right^.val;
              DropNode(S^.right^.right);
              DropNode(S^.right^.right);
            end;
          end;

          Source := S^.right; { X, Y }
          IX2 := Source;
        end else
        begin
          Source := emit_eval2(IX2, S^.right); { Evaluate Index! }
        end;

        case Source^.typ of
          sym_WORD,
            Sym_DEF: begin
              if Source^.val <> IX2^.val then
                emit_mov(IX2^, Source^);
              if S^.val <> 0 then begin
                emit_subi(IX2^, -S^.val);
              end;
            end;
        end;
        DropNode(S^.right); { index }
        DropNode(S^.right); { ] }


        if bpre = 0 then emitn_ldd(Dest, IX2, @TCon);
        if bpre = 1 then begin
          case Dest^.typ of
            sym_DEF: emitn_ldp(Dest, IX2);
            sym_WORD: begin
                emitn_ldp(Dest, IX2);
                Dest^.val := Dest^.val + 1;
                emitn_ldp(Dest, IX2);
                Dest^.val := Dest^.val - 1;
              end;
          end;
        end;
        if bpre = 2 then begin
          emitn_ldm(Dest, IX2);
        end;

        emit_eval2 := Dest;
        Exit; { Return RAM }
      end;
    T_VAR: begin
        case S^.typ of
          sym_EE: begin
              TempSym.Val := a_EEAR; {EEAR}
              V := S^.val; { EEVAR Address! }
              if S^.right^.yylex = T_LBRACKET2 then
              begin
                DropNode(S^.right); { [ }
                Source := emit_eval2(@WREG, S^.right); { Eval Index! }
                case Source^.typ of
                  sym_DEF: begin
                      if V = 0 then emit_out(TempSym, Source^)
                      else begin
                        emit_assign(@WREG, Source);
                        emit_subi(WREG, -V);
                        emit_out(TempSym, WREG);
                      end;
                    end;
                  sym_Const: begin
                      emit_ldi(WREG, V + Source^.val);
                      emit_out(TempSym, WREG);
                    end;
                end;
                DropNode(S^.right); { index }
                DropNode(S^.right); { ] }
              end else begin
                emit_ldi(WREG, V);
                emit_out(TempSym, WREG);
              end;
              TempSym.Val := a_EECR; {EECR}
              TempSym.subval := 0; {EERE}
              emit_sbi(TempSym);
              TempSym.Val := a_EEDR; {EEDR}
              emit_in(Dest^, TempSym); {!}
              emit_eval2 := Dest;
              Exit; { Return EEVAR }
            end;
          sym_DEF: begin


            end;
          sym_sDEF: begin
              if Dest^.typ = sym_DEF then
              begin
                emitn_lds(Dest, S);
                emit_eval2 := Dest;
              end else begin
                emitn_lds(@WREG, S);
                emit_eval2 := @WREG;
              end;

              Exit; { Return I/O }
            end;
          sym_lDEF: begin
              emitn_ldd(Dest, @Y, S);
              emit_eval2 := Dest;
              Exit; { Return I/O }
            end;
          sym_IO: begin
              if D^.typ = sym_DEF then
              begin
                emit_in(Dest^, S^);
                emit_eval2 := Dest;
              end else begin
                emit_in(WREG, S^);
                emit_eval2 := @WREG;
              end;
              Exit; { Return I/O }
            end;
        end;
      end;
    T_LABEL: begin { Function Call! }
        if S^.right <> nil then begin
          if S^.right^.yylex = T_LBRACKET then
          begin
            DropNode(S^.right); { ( }
            Fun := GetFunction(S); { Pointer to Function}

            Param := nil;
            Res := nil;
            if Fun <> nil then
              if Fun^.mid <> nil then
              begin
                Param := Fun^.mid^.right;
                Res := Fun^.mid^.left;
              end;
            if Param = nil then
              Param := @WREG; { Default }
            if res <> nil then
            begin
              if res^.typ = sym_BIT then
              begin
                Dest := @WBIT; // Result in working Bit!
              end;
            end;

            if S^.right <> nil then
            begin
              if S^.right^.yylex <> T_RBRACKET then { Void () ? }
              begin { Evaluate Parameters! }

                Source := emit_eval2(Param, S^.right);
                emit_assign(Param, Source);

                DropNode(S^.right); { Param }
              end;
              DropNode(S^.right); { ) }
            end;
          end else begin
            // no Params
            Fun := GetFunction(S); { Pointer to Function}

            Res := nil;
            if Fun <> nil then
              if Fun^.mid <> nil then
              begin
                Res := Fun^.mid^.left;
              end;
            if res <> nil then
            begin
              Dest := res;
            end;
          end;
        end;
        emit_fixup(S^, 1);
        {??
        Case IsFunction(S) Of
          0,1,2: Begin
            If Dest^.val <> WREG.val then
              emit_mov(Dest^, WREG);
          End;
          3: Begin
            Dest := @WBIT;
          End;
        End;
        }
        emit_eval2 := Dest;
      end;
  end;
end;

function emit_assign;
begin
  case D^.typ of
    sym_Bit,
      sym_ioBIT: begin
        emit_dobit(D, S);
      end;
    sym_lDEF: begin
        case S^.typ of
          sym_lDEF: begin
              if D^.val <> S^.Val then
              begin

              end;
            end;
          sym_DEF: begin
              emitn_std(S, @Y, D);
            end;
          sym_Const: begin
              emit_ldi(WREG, S^.val);
              emitn_std(@WREG, @Y, D);
            end;
        end;
      end;
    sym_DEF: begin
        case S^.typ of
          sym_sDEF: begin
             emitn_lds(D, S);
            end;
          sym_DEF: begin
              if D^.val <> S^.Val then
                emit_mov(D^, S^);
            end;
          sym_Const: begin
              if D^.val > 15 then emit_ldi(D^, S^.val)
              else begin
                if S^.val = 0 then emit_eor(D^, D^)
                else begin
                  emit_ldi(WREG, S^.val);
                  emit_mov(D^, S^);
                end;
              end;
            end;
        end;
      end;
    sym_Word: begin
        case S^.typ of
          // word := word
          sym_Word: begin
              if S^.val <> D^.val then
              begin
                { TODO : MOVW }
                //
                emit_mov(D^, S^); inc(D^.val); inc(S^.val);
                emit_mov(D^, S^); dec(D^.val); dec(S^.val);
              end;
            end;
          sym_DEF: begin
              if D^.val <> S^.Val then
                emit_mov(D^, S^);
              D^.typ := sym_DEF;
              inc(D^.val);
              emit_eor(D^, D^);
              dec(D^.val);
              D^.typ := sym_WORD;
            end;
          sym_Const: begin
              emit_ldi(D^, S^.val);
            end;
        end;
      end;
  end;
end;


//
// Asm Style Command
//
function emit_asm;
begin
  if D^.yylex <> T_VAR then Error(err_Var_Required);

  case T^.yylex of
    T_TOKEN: begin
        case T^.val of
          //
          //
          //
          T_SPM: begin
              emit_typ($95E8);
          end;
          T_MUL: begin
              emit_mul(D^, S^);
            end;
          T_DIV: begin
              emit_div(D^, S^);
            end;
          T_ASR: begin
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_DEF: begin
                      emit_Typ3(D^, word(T_ASR));
                    end;
                  sym_WORD: begin
                      D^.val := D^.val + 1;
                      emit_Typ3(D^, word(T_ASR));
                      D^.val := D^.val - 1;
                      emit_Typ3(D^, word(T_ROR));
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_Typ3(WREG, word(T_ASR));
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_ROR: begin
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_DEF: begin
                      emit_Typ3(D^, word(T_ROR));
                    end;
                  sym_WORD: begin
                      D^.val := D^.val + 1;
                      emit_Typ3(D^, word(T_ROR));
                      D^.val := D^.val - 1;
                      emit_Typ3(D^, word(T_ROR));
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_Typ3(WREG, word(T_ROR));
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_ROL: begin
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_DEF: begin
                      emit_adc(D^, D^);
                    end;
                  sym_WORD: begin
                      D^.typ := sym_def;
                      emit_adc(D^, D^);
                      D^.val := D^.val + 1;
                      emit_adc(D^, D^);
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_adc(WREG, WREG);
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_LSL: begin
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_DEF: begin
                      emit_add(D^, D^);
                    end;
                  sym_WORD: begin
                      D^.typ := sym_def;
                      emit_add(D^, D^);
                      D^.val := D^.val + 1;
                      emit_adc(D^, D^);
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_add(WREG, WREG);
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_COM: begin
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_WORD: begin
                      emit_Typ3(D^, word(T_COM));
                      D^.val := D^.val + 1;
                      emit_Typ3(D^, word(T_COM));
                    end;
                  sym_DEF: begin
                      emit_Typ3(D^, word(T_COM));
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_Typ3(WREG, word(T_COM));
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_NEG: begin
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_WORD: begin
                      emit_Typ3(D^, word(T_NEG)); { negate low byte }
                      emit_ldi(WREG, 0);
                      inc(D^.val);
                      D^.typ := sym_DEF;
                      emit_sub(WREG, D^);
                      emit_mov(D^, WREG);
                    end;
                  sym_DEF: begin
                      emit_Typ3(D^, word(T_NEG));
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_Typ3(WREG, word(T_NEG));
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_LSR: begin
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_DEF: begin
                      emit_Typ3(D^, word(T_LSR));
                    end;
                  sym_WORD: begin
                      D^.val := D^.val + 1;
                      emit_Typ3(D^, word(T_LSR));
                      D^.val := D^.val - 1;
                      emit_Typ3(D^, word(T_ROR));
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_Typ3(WREG, word(T_LSR));
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_SWAP: begin
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_DEF: begin
                      emit_swap(D, nil);
                    end;
                  sym_sDEF: begin
                      emitn_lds(@WREG, D);
                      emit_swap(@WREG, nil);
                      emitn_sts(@WREG, D);
                    end;

                  sym_WORD: begin
                      D^.typ := sym_DEF;
                      TempSym := D^;
                      emit_mov(WREG, D^); { wreg := low }
                      inc(D^.val);
                      emit_mov(TempSym, D^); { low := high }
                      emit_mov(D^, WREG); { high := wreg }
                    end;

                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_swap(@WREG, nil);
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_DEC: begin
              if D^.yylex = T_RAM then
              begin
                Tmp.Val := 0;
                emitn_ldd(@WREG, D^.right^.right, @Tmp);
                emit_dec(WREG);
                emitn_std(@WREG, D^.right^.right, @Tmp);
              end;
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_sDEF,
                    sym_WORD,
                    sym_lWORD,
                    sym_lDEF,
                    sym_DEF: begin
                      emit_dec(D^);
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_dec(WREG);
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_INC: begin
              if D^.yylex = T_RAM then
              begin
                Tmp.Val := 0;
                emitn_ldd(@WREG, D^.right^.right, @Tmp);
                emit_inc(WREG);
                emitn_std(@WREG, D^.right^.right, @Tmp);
              end;
              if D^.yylex = T_VAR then
              begin
                case D^.Typ of
                  sym_sDEF,
                    sym_lWORD,
                    sym_WORD,
                    sym_lDEF,
                    sym_DEF: begin
                      emit_inc(D^);
                    end;
                  sym_IO: begin
                      emit_in(WREG, D^);
                      emit_inc(WREG);
                      emit_out(D^, WREG);
                    end;
                end;
              end;
            end;
          T_CP: begin
              emit_cp(D^, S^);
            end;
          T_CPC: begin
              emit_cpc(D^, S^);
            end;
          T_ADD: begin
              emit_add(D^, S^);
            end;
          T_ADC: begin
              emit_adc(D^, S^);
            end;
          T_SUB: begin
              emit_sub(D^, S^);
            end;
          T_SBC: begin
              emit_sbc(D^, S^);
            end;
          T_AND: begin
              emit_and(D^, S^);
            end;
          T_EOR: begin
              emit_eor(D^, S^);
            end;
          T_OR: begin
              emit_or(D^, S^);
            end;
        end;
      end else begin
      Error(err_syntax);
    end;
  end;
end;

procedure EvalDotTree;
var
  C, L, R, O: PSym;
begin
  {PARANOIA Safety}
  if Tree = nil then Exit;
  {start here}
  C := Tree;
  {*we are done*}
  if C^.Right = nil then Exit;
  if C^.yylex = T_NEWLINE then Exit;
  L := C;

  repeat
    O := L^.Right; if O = nil then Exit;
    R := O^.Right; if R = nil then Exit;

    if (O^.yylex = T_DOT) and (L^.yylex = T_EEPROM) then
    begin
      if se(R^.name, 'DATA') then
      begin
        L^.yylex := T_VAR; L^.Typ := sym_IO; L^.val := a_EEDR;
        StrCopy(L^.name, 'EEPROM@DATA');
        DropNode(L^.right); DropNode(L^.right);
      end;
      if se(R^.name, 'ADDR') then
      begin
        L^.yylex := T_VAR; L^.Typ := sym_IO; L^.val := a_EEAR;
        StrCopy(L^.name, 'EEPROM@ADDRESS');
        DropNode(L^.right); DropNode(L^.right);
      end;
    end;
    O := L^.Right; if O = nil then Exit;
    R := O^.Right; if R = nil then Exit;

    // .lo etc
    if (O^.yylex = T_DOT) and (L^.yylex = T_VAR) then
    begin
      if se(R^.name, 'OUT') then
      begin
        L^.val := (L^.val - 16) div 3 * 3 + 16 + 2;
        DropNode(L^.right); DropNode(L^.right);
      end;
      if se(R^.name, 'DIR') then
      begin
        L^.val := (L^.val - 16) div 3 * 3 + 16 + 1;
        DropNode(L^.right); DropNode(L^.right);
      end;
      if se(R^.name, 'INP') then
      begin
        L^.val := (L^.val - 16) div 3 * 3 + 16;
        DropNode(L^.right); DropNode(L^.right);
      end;
      if se(R^.name, 'LO') then
      begin
        //        L^.val := L^.val and $FFFE; // lo
        if L^.Typ = sym_WORD then L^.Typ := sym_DEF;
        DropNode(L^.right); DropNode(L^.right);
      end;
      if se(R^.name, 'HI') then
      begin
        //        L^.val := L^.val or 1; // hi
        L^.val := L^.val + 1; // hi
        if L^.Typ = sym_WORD then L^.Typ := sym_DEF;
        DropNode(L^.right); DropNode(L^.right);
      end;
    end;


    if (O^.yylex = T_DOT) and (L^.yylex = T_LABEL) then
    begin
      { Constants! ie dot's not followed by := }
      if not IfL(R^.right, T_EQUAL) then
      begin { }
        if se(L^.name, 'CPU') then
        begin
          if se(R^.name, 'CLOCK') then
          begin
            L^.yylex := T_CONST; L^.Typ := sym_Const; L^.val := cpuclock;
            StrCopy(L^.name, 'CPU@CLOCK');
            DropNode(L^.right); DropNode(L^.right);
          end;
        end;
      end;

      if se(L^.name, 'CPU') then
      begin
        if se(R^.name, 'CARRY') then
        begin
          L^.yylex := T_VAR; L^.Typ := sym_IObit; L^.val := $3F;
          L^.subval := 0;
          StrCopy(L^.name, 'CPU@CARRY');
          DropNode(L^.right); DropNode(L^.right);
        end;
        if se(R^.name, 'HALFCARRY') then
        begin
          L^.yylex := T_VAR; L^.Typ := sym_IObit; L^.val := $3F;
          L^.subval := 5;
          StrCopy(L^.name, 'CPU@HALFCARRY');
          DropNode(L^.right); DropNode(L^.right);
        end;
        if se(R^.name, 'NEGATIVE') then
        begin
          L^.yylex := T_VAR; L^.Typ := sym_IObit; L^.val := $3F;
          L^.subval := 2;
          StrCopy(L^.name, 'CPU@NEGATIVE');
          DropNode(L^.right); DropNode(L^.right);
        end;
        if se(R^.name, 'ZERO') then
        begin
          L^.yylex := T_VAR; L^.Typ := sym_IObit; L^.val := $3F;
          L^.subval := 1;
          StrCopy(L^.name, 'CPU@ZERO');
          DropNode(L^.right); DropNode(L^.right);
        end;
      end;


      if se(L^.name, 'SRAM') then
      begin
        if se(R^.name, 'TOP') then
        begin
          L^.yylex := T_CONST; L^.Typ := sym_Const;
          L^.val := sram_top;
          StrCopy(L^.name, 'SRAM@TOP');
          DropNode(L^.right); DropNode(L^.right);
        end;
        if se(R^.name, 'BOTTOM') then
        begin
          L^.yylex := T_CONST; L^.Typ := sym_Const;
          L^.val := sram_bottom;
          StrCopy(L^.name, 'SRAM@BOTTOM');
          DropNode(L^.right); DropNode(L^.right);
        end;
        if se(R^.name, 'SIZE') then
        begin
          L^.yylex := T_CONST; L^.Typ := sym_Const;
          L^.val := sram_size;
          StrCopy(L^.name, 'SRAM@SIZE');
          DropNode(L^.right); DropNode(L^.right);
        end;
      end;

      if se(L^.name, 'TIMER') then
      begin
        if se(R^.name, 'OVERFLOW') then
        begin
          L^.yylex := T_VAR; L^.Typ := sym_ioBit;
          L^.val := $33; L^.subval := 3; { TIFR }
          StrCopy(L^.name, 'TIMER@OVERFLOW');
          DropNode(L^.right); DropNode(L^.right);
        end;
        if se(R^.name, 'INPUT') then
        begin
          L^.yylex := T_VAR; L^.Typ := sym_ioBit;
          L^.val := $12; L^.subval := 2; { PINB.2 }

          StrCopy(L^.name, 'TIMER@INPUT');
          DropNode(L^.right); DropNode(L^.right);
        end;
        if se(R^.name, 'COUNT') then
        begin
          L^.yylex := T_VAR; L^.Typ := sym_IO;
          L^.val := $32;

          StrCopy(L^.name, 'TIMER@COUNTER');
          DropNode(L^.right); DropNode(L^.right);
        end;
      end;
    end;

    {}

    { We have: L O R }
    if (O^.yylex = T_DOT) and (R^.yylex = T_CONST) then
    begin
      if (R^.val >= 0) then begin
        L^.subval := R^.val and 7;
        if L^.typ = sym_IO then L^.Typ := sym_ioBit;
        if L^.typ = sym_DEF then L^.Typ := sym_Bit;
        if L^.typ = sym_Word then
        begin
          L^.Typ := sym_Bit;
          if R^.val > 7 then L^.val := L^.val + 1;
        end;
      end else begin
        if (R^.val = -1) then begin // Highbit
          L^.subval := 7;
          if L^.typ = sym_IO then L^.Typ := sym_ioBit;
          if L^.typ = sym_DEF then L^.Typ := sym_Bit;
          if L^.typ = sym_Word then
          begin
            L^.Typ := sym_Bit;
            L^.val := L^.val + 1;
          end;
        end;
      end;

      DropNode(L^.right);
      DropNode(L^.right);
    end;
    L := L^.right; { Advance to Next.. }

  until L = nil;
end;


function emit_dobit(D, S: Psym): Psym;
var
  V: Word;
begin
  if D = nil then Exit;
  if S = nil then Exit;

  case D^.typ of
    sym_BIT: begin
        case S^.typ of
          sym_Bit: begin
              emit_bitmove(D^, S^); { ok! }
            end;
          sym_ioBit: begin
              if S^.Val < $20 then
              begin
                if D^.val < 16 then
                begin
                  { low bank = io.bit}
                  Error(99);
                end else
                begin
                  emit_ori(D^, (1 shl D^.subval));
                  emit_sbis(S^);
                  emit_andi(D^, (1 shl D^.subval) xor 255);
                end;
              end else begin
                if S^.Val = $3F then
                begin
                  if S^.Subval = 6 then
                  begin
                    { reg.bit = SREG.6 }
                    emit_bld(D^);
                  end else begin
                    if D^.val < 16 then
                    begin
                      Error(99);
                    end else begin
                      emit_ori(D^, (1 shl D^.subval));
                      emit_typ($F008 + (S^.subval and 7));
                      emit_andi(D^, (1 shl D^.subval) xor 255);
                    end;
                  end;
                end else begin // bit := high io bit


                end;
              end;
            end;
          sym_Const: begin
              if S^.val = 0 then
              begin
                if D^.Val > 15 then
                begin
                  emit_andi(D^, (1 shl (D^.SubVal and 7)) xor $FF);
                end else
                begin
                  emit_typ($94E8); { clt }
                  emit_bld(D^);
                end;
              end else
              begin
                if D^.Val > 15 then
                begin
                  emit_ori(D^, 1 shl (D^.Subval and 7));
                end else
                begin
                  emit_typ($9468); { set }
                  emit_bld(D^);
                end;
              end;
            end;
        end;
      end;
    sym_ioBIT: begin
        case S^.typ of
          sym_Bit: begin
              { iobit = bit }
              if D^.val < $20 then
              begin
                if not bnot then {bug}
                begin
                  emit_sbrc(S^); emit_sbi(D^);
                  emit_sbrs(S^); emit_cbi(D^);
                end else
                begin
                  emit_sbrs(S^); emit_sbi(D^);
                  emit_sbrc(S^); emit_cbi(D^);
                end;
              end else begin
                if D^.val = $3F then begin
                  if D^.subval = 6 then begin
                    emit_bst(S^);
                  end;
                end else begin // High IO Bit := bit



                end;
              end;
            end;
          sym_ioBit: begin
              if D^.Val < $20 then
              begin
                if S^.val <> $3F then
                begin
                  { iobit = iobit }
                  if (S^.val = D^.val) and (S^.subval = D^.subval) then
                  begin
                    if bnot then
                    begin
                      emit_in(WREG, D^);
                      emit_ldi(ZL, 1 shl D^.subval);
                      emit_eor(WREG, ZL); { set Bit }
                      emit_out(D^, WREG);
                      Warning(1011);
                    end;
                  end else
                  begin
                    if not bnot then begin
                      emit_sbic(S^); emit_sbi(D^);
                      emit_sbis(S^); emit_cbi(D^);
                    end else begin
                      emit_sbis(S^); emit_sbi(D^);
                      emit_sbic(S^); emit_cbi(D^);
                    end;
                  end;
                end else begin
                  { io bit = sreg bit }
                  V := 0; if bnot then V := $0400;
                  emit_typ($F408 + (S^.subval and 7) xor V);
                  emit_sbi(D^);
                  emit_typ($F008 + (S^.subval and 7) xor V);
                  emit_cbi(D^);
                end;
              end else begin
                { SREG. = iobit }
                if (S^.val = D^.val) and (S^.subval = D^.subval) then
                begin

                end else
                begin
                  emit_typ($9408 or (D^.SubVal shl 4 and $070));
                  if bnot then
                    emit_sbic(S^) else
                    emit_sbis(S^);
                  emit_typ($9488 or (D^.SubVal shl 4 and $070));
                end;
              end;
            end;
          sym_Const: begin { ioBit := Const }
              if S^.val = 0 then // := 0;
              begin
                if (D^.Val and $FF) > 31 then
                begin
                  if (D^.Val and $FF) = $3F then
                  begin
                    emit_typ($9488 or (D^.SubVal shl 4 and $070));
                  end else
                  begin
                    V := (1 shl (D^.SubVal and 7)) xor $FF;
                    emit_in(WREG, D^);
                    emit_andi(WREG, V);
                    emit_out(D^, WREG);
                  end;
                end else
                begin
                  { Clear 0..1F }
                  emit_cbi(D^)
                end;
              end else begin // := 1;
                if (D^.Val and $FF) > 31 then
                begin
                  if (D^.Val and $FF) = $3F then
                  begin
                    emit_typ($9408 or (D^.SubVal shl 4 and $070));
                  end else
                  begin
                    V := (1 shl (D^.SubVal and 7));
                    emit_in(WREG, D^);
                    emit_ori(WREG, V);
                    emit_out(D^, WREG);
                  end;
                end else
                begin
                  emit_sbi(D^)
                end;
              end;
            end;
        end;
      end;
  end;
end;

function emit_ei;
begin
  core.ei;
end;

function emit_di;
begin
  core.di;
end;

procedure EvalBR2Tree(Tree: PSym);
var
  LL, C, L, R, O: PSym;
begin
  {PARANOIA Safety}
  if Tree = nil then Exit;
  {start here}
  C := Tree;
  {*we are done*}
  if C^.Right = nil then Exit;
  if C^.yylex = T_NEWLINE then Exit;
  L := C;

  repeat
    if L^.yylex = T_RAM then
    begin
      if (L^.right <> nil) and (L^.right^.right <> nil) and
        (L^.right^.right^.right <> nil) then
      begin
        if (L^.right^.yylex = T_LBRACKET2) and (L^.right^.right^.right^.yylex = T_RBRACKET2) then
        begin
          if (L^.right^.right^.yylex = T_CONST) then
          begin
            if L^.right^.right^.val < 32 then
            begin
              DropNode(L^.right); { [ }
              L^.val := L^.right^.val;
              L^.yylex := T_VAR;
              L^.typ := sym_DEF;
              DropNode(L^.right); { value }
              DropNode(L^.right); { ] }
            end else begin
              DropNode(L^.right); { [ }
              L^.val := L^.right^.val;
              L^.yylex := T_VAR;
              L^.typ := sym_sDEF; { static DEF }
              DropNode(L^.right); { value }
              DropNode(L^.right); { ] }
            end;
          end else begin

          end;
        end;
      end;
    end;

    if L^.yylex = T_EEPROM then
    begin
      if (L^.right <> nil) and (L^.right^.right <> nil) and
        (L^.right^.right^.right <> nil) then
      begin
        if (L^.right^.yylex = T_LBRACKET2) and (L^.right^.right^.right^.yylex = T_RBRACKET2) then
        begin
          if (L^.right^.right^.yylex = T_CONST) then
          begin
            if L^.right^.right^.val < 64 then
            begin
              DropNode(L^.right); { [ }
              L^.val := L^.right^.val;
              L^.yylex := T_VAR;
              L^.typ := sym_EE;
              DropNode(L^.right); { value }
              DropNode(L^.right); { ] }
            end else begin
              error(987);
            end;
          end else begin

          end;
        end;
      end;
    end;

    if (L^.yylex = T_VAR) and (L^.typ = sym_DEF) then
    begin
      if (L^.right <> nil) and (L^.right^.right <> nil) and
        (L^.right^.right^.right <> nil) then
      begin
        if (L^.right^.yylex = T_LBRACKET2) and (L^.right^.right^.right^.yylex = T_RBRACKET2) then
        begin
          if L^.right^.right^.yylex = T_CONST then
          begin
            if (L^.right^.right^.val + L^.val) < 32 then
            begin
              DropNode(L^.right); { [ }
              L^.val := L^.val + L^.right^.val;
              L^.yylex := T_VAR; L^.typ := sym_DEF;
              DropNode(L^.right); { value }
              DropNode(L^.right); { ] }
            end else
            begin
              DropNode(L^.right); { [ }
              L^.val := L^.val + L^.right^.val;
              L^.yylex := T_VAR; L^.typ := sym_sDEF;
              DropNode(L^.right); { value }
              DropNode(L^.right); { ] }
            end;
          end else
          begin
            L^.yylex := T_RAM; { oops! }
          end;
        end;
      end;
    end;

    if (L^.yylex = T_VAR) and (L^.typ = sym_EE) then
    begin
      if (L^.right <> nil) and (L^.right^.right <> nil) and
        (L^.right^.right^.right <> nil) then
      begin
        if (L^.right^.yylex = T_LBRACKET2) and (L^.right^.right^.right^.yylex = T_RBRACKET2) then
        begin
          if L^.right^.right^.yylex = T_CONST then
          begin
            if (L^.right^.right^.val + L^.val) < 64 then
            begin
              DropNode(L^.right); { [ }
              L^.val := L^.val + L^.right^.val;
              L^.yylex := T_VAR; L^.typ := sym_EE;
              DropNode(L^.right); { value }
              DropNode(L^.right); { ] }
            end;
          end;
        end;
      end;
    end;


    L := L^.right;
  until L = nil;
end;

procedure IntrCode;
begin
  case n of
    0: begin
        if not has_sram then
        begin
          emit_in(INT_SREG, SREG);
          WREG.val := INT_WREG.val;
        end else
        begin
          if bReg then
          begin
            emit_in(INT_SREG, SREG);
            WREG.val := INT_WREG.val;
          end else
          begin
            emit_push(@WREG);
            emit_in(WREG, SREG);
            emit_push(@WREG);
          end;

        end;
      end;
    1: begin
        if not has_sram then
        begin
          emit_out(SREG, INT_SREG);
          WREG.val := wreg_def;
        end else begin
          if bReg then
          begin
            emit_out(SREG, INT_SREG);
            WREG.val := wreg_def;
          end else
          begin
            emit_pop(@WREG);
            emit_out(SREG, WREG);
            emit_pop(@WREG);
          end;
        end;
      end;
  end;
end;

{ ??? }

function emit_com;
begin

end;

function emit_pop;
begin
  if not has_sram then begin
    error(299);
    exit;
  end;
  stackneeded := True;

  case D^.yylex of
    T_VAR: begin
        case D^.typ of
          sym_DEF: begin
              emit_typ1(D^, $900F);
            end;
          sym_IO: begin
              emit_typ1(WREG, $900F);
              emit_out(D^, WREG);
            end;
          sym_WORD: begin
              emit_typ1(D^, $900F);
              D^.val := D^.val + 1;
              emit_typ1(D^, $900F);
            end;
        end;
      end;
  end;
end;

function emit_push; {920f}
begin
  if not has_sram then begin
    error(299);
    exit;
  end;
  stackneeded := True;

  case D^.yylex of
    T_VAR: begin
        case D^.typ of
          sym_DEF: begin
              emit_typ1(D^, $920F);
            end;
          sym_IO: begin
              emit_in(WREG, D^);
              emit_typ1(WREG, $920F);
            end;
          sym_WORD: begin
              D^.val := D^.val + 1;
              emit_typ1(D^, $920F);
              D^.val := D^.val - 1;
              emit_typ1(D^, $920F);
            end;
        end;
      end;
    T_CONST: begin
        emit_ldi(WREG, D^.val);
        emit_typ1(WREG, $920F);
      end;
  end;
end;
//
//
//

procedure AVR_Libcalls;
begin
  {
  If IsLibCallNeeded('FP_ST_A') Then
  Begin
    InsertLabel('FP_ST_A', 0);
    emitn_std(REG(16),@ZL, CON(0));
    emitn_std(REG(17),@ZL, CON(1));
    emitn_std(REG(18),@ZL, CON(2));
    emitn_std(REG(19),@ZL, CON(3));
    emit_ret; //
  end;
  If IsLibCallNeeded('FP_LD_A') Then
  Begin
    InsertLabel('FP_LD_A', 0);
    emitn_ldd(REG(16),@ZL, CON(0));
    emitn_ldd(REG(17),@ZL, CON(1));
    emitn_ldd(REG(18),@ZL, CON(2));
    emitn_ldd(REG(19),@ZL, CON(3));
    emit_ret; //
  End;
  If IsLibCallNeeded('FP_LD_B') Then
  Begin
    InsertLabel('FP_LD_B', 0);
    emitn_ldd(REG(20),@ZL, CON(0));
    emitn_ldd(REG(21),@ZL, CON(1));
    emitn_ldd(REG(22),@ZL, CON(2));
    emitn_ldd(REG(23),@ZL, CON(3));
    emit_ret; //
  End;
  }
end;

begin
  TCon.typ := sym_const;
  TCon.yylex := T_CONST;
  TCon.val := 0;
  // Base Pointer
  Y.Val := 28;
  Y.yylex := T_VAR;
  Y.typ := sym_DEF;

  Z.Val := 30;
  Z.yylex := T_VAR;
  Z.typ := sym_WORD;
  //
  prim.Val := 26;
  prim.yylex := T_VAR;
  prim.typ := sym_WORD;

  primLo.Val := 26;
  primLo.yylex := T_VAR;
  primLo.typ := sym_DEF;
  primHi.Val := 27;
  primHi.yylex := T_VAR;
  primHi.typ := sym_DEF;
  //
  sec.Val := 24;
  sec.yylex := T_VAR;
  sec.typ := sym_WORD;
  secLo.Val := 24;
  secLo.yylex := T_VAR;
  secLo.typ := sym_WORD;
  secHi.Val := 25;
  secHi.yylex := T_VAR;
  secHi.typ := sym_WORD;


end.

