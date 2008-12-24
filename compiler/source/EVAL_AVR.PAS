(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit eval_AVR;

interface

uses
  SysUtils,
  CompDef,
  NodePool,
  Emit_AVR,
  EFile;

function evaluate(Dest, Tree: PSym): PSym;

implementation


function evaluate;
begin
  { BitVariable := }

  { if Destination is Bit Variable... }
  if IsBitVariable(Dest) then
  begin
    DropNode(yy0^.right); { Drop = }
    bnot := False;
    if yy0^.right^.yylex = T_NOT then
    begin
      bnot := True;
      DropNode(yy0^.right);
    end;
    yys := yy0^.right;
    yys := emit_eval2(nil, yys);
    emit_dobit(Dest, yys);
    Exit;
  end;

  if yy0^.right^.yylex = T_LBRACKET2 then
  begin
    DropNode(yy0^.right); { Drop [ }
    { eevar[] := }
    if Dest^.typ = sym_EE then
    begin
      { eevar[] = }
      TempSym.Val := a_EEAR; {EEAR}
      case yy0^.right^.yylex of
        T_VAR: begin
            emit_mov(WREG, yy0^.right^);
            if Dest^.val <> 0 then
            begin
              yy0^.right^.typ := sym_const;
              emit_add(WREG, yy0^.right^);
            end;
          end;
        T_CONST: begin
            emit_ldi(WREG, Dest^.val + yy0^.right^.val);
          end;
      end;
      emit_out(TempSym, WREG);
      TempSym.Val := a_EEDR; {EEDR}

      case yy0^.right^.yylex of
        T_VAR, T_CONST: begin
            case yy0^.right^.Typ of
              sym_DEF: begin
                  emit_out(TempSym, yy0^.right^);
                end;
              sym_Const: begin
                  emit_ldi(WREG, yy0^.right^.val);
                  emit_out(TempSym, WREG);
                end;
            end;
            emit_out(TempSym, WREG);
          end;

        { eevarp[] = EEPROM[] }
        T_EEPROM: begin
            {???}

              { ERROR... }
            error(err_unimplemented);
          end;
      end; { case 5}
      { Values are set write/wait if flag }
      emit_ee_wr(nil, nil, '');
    end; { eevar[] }

    Exit;
  end;
  { variable = ... }
  if yy0^.right^.yylex = T_EQUAL then
  begin
    DropNode(yy0^.right); { Drop = }
    bnot := False;

    if yy0^.right^.yylex = T_NOT then
    begin
      bnot := True;
      DropNode(yy0^.right);
    end;

    yy1 := yy0^.right; // save first Operand
    yys := yy1; // source := first
    { #todo1 check eval2
    if (Dest^.typ <> sym_Bit) and
      (Dest^.typ <> sym_Word) and
      (Dest^.typ <> sym_ioBit) then
    begin
      if Dest^.typ = sym_DEF then
        yys := emit_eval2(Dest, yys) else
        yys := emit_eval2(nil, yys);
    end;
    }
    yys := emit_eval2(Dest, yys);

    case yys^.yylex of
      T_ROM: begin
          if yys^.right^.yylex = T_LBRACKET2 then
          begin
            emit_assign(@Z, yys^.right^.right);
            emit_typ($95C8); { LPM? }
            if Dest^.val <> 0 then
            begin
              Tmp.yylex := T_VAR;
              Tmp.typ := sym_DEF;
              Tmp.val := 0;
              emit_mov(Dest^, Tmp);
            end;
          end else begin

          end;
        end;
      T_TOKEN: begin
          case yys^.val of
            T_SWAP: begin
                emit_swap(Dest, yy1^.right);
                Exit;
              end;
            T_COM: begin
                emit_com(Dest, yy1^.right);
                Exit;
              end;
          end;
        end;
      { 0   1 2    34     5 6.. }
      { var = Func (Param1,...) }
      T_LABEL: begin
          {funcall}
          case Dest^.typ of
            sym_ioBit: begin
                emit_fixup(yys^, 1); { Gosub }
              end;
            sym_bit: begin
                emit_fixup(yys^, 1); { Gosub }
                emit_bld(Dest^);
              end;
            sym_WORD: begin
                if yys^.subval <> 0 then
                begin
                  Tmp := Dest^;
                  Tmp.Val := Tmp.val + 1;
                  emit_fixup(yys^, 1); emit_mov(Tmp, WREG);
                  emit_fixup(yys^, 1); emit_mov(Dest^, WREG);
                end else begin
                  yys^.Val := FindLabelAddr(yys^);
                  Tmp := Dest^;
                  Tmp.Typ := sym_DEF;
                  emit_ldi(Tmp, yys^.val);
                  Tmp.Val := Tmp.val + 1;
                  emit_ldi(Tmp, yys^.val shr 8);
                end;
              end;
            sym_DEF: begin
                if yys^.yylex = T_CONST then
                  if yys^.typ = sym_Const then
                    emit_ldi(WREG, yys^.val);
                if yys^.yylex = T_VAR then
                  if yys^.typ = sym_DEF then
                    if yys^.val <> WREG.Val then
                      emit_mov(WREG, yys^);
                { GoSub }
                emit_fixup(yys^, 1); { Gosub }
                emit_assign(Dest, @WREG);
              end;
          end;
        end;
      T_VAR: begin
          { Var = Var }
          case Dest^.Typ of
            // Single := ?1
            sym_Single: begin
                case yys^.Typ of
                  sym_Single: begin
                      error(99);

                    end;
                  sym_WORD: begin
                      // Load ACCA with Word
                      emit_mov(REG(16)^, yys^);
                      Tmp := yys^;
                      Tmp.Val := Tmp.Val + 1;
                      Tmp.Typ := sym_DEF;
                      emit_mov(REG(17)^, Tmp);
                      emit_ldi(REG(18)^, 0);
                      emit_ldi(REG(19)^, 0);
                      //
                      LibCall('SL2F_L04'); // Convert
                      emit_ldi(ZL, Dest^.val);
                      LibCall('FP_ST_A'); // Store
                    end;
                end;
              end;
            { first OP= I/O }
            sym_IO: begin
                case yys^.Typ of
                  { iovar = var ??? }
                  sym_DEF: begin
                      emit_out(Dest^, yys^);
                    end;
                end;
              end;
            sym_sDEF: begin
                case yys^.Typ of
                  { sDEF = var }
                  sym_DEF: begin
                      emitn_sts(yys, Dest);
                    end;
                end;
              end;
            { first OP = word }
            sym_WORD: begin
                case yys^.Typ of
                  // Word := Single
                  sym_SINGLE: begin
                      // Load
                      emit_ldi(ZL, yys^.val);
                      LibCall('FP_LD_A');
                      // Convert
                      LibCall('F2L_L04');
                      // Store Result...
                      Tmp := Dest^;
                      Tmp.Typ := sym_DEF;
                      emit_mov(Tmp, REG(16)^);
                      Tmp.Val := Tmp.Val + 1;
                      emit_mov(Tmp, REG(17)^);
                    end;
                  sym_DEF: begin
                      if Dest^.val = yys^.val then
                      begin
                        Tmp := Dest^;
                        Tmp.Val := Tmp.Val + 1;
                        Tmp.Typ := sym_DEF;
                        emit_eor(Tmp, Tmp); { Clear}
                      end else
                      begin
                        emit_mov(Dest^, yys^); { low Byte}
                        Tmp := Dest^; Tmp.Val := Tmp.Val + 1; Tmp.Typ := sym_DEF;
                        emit_eor(Tmp, Tmp); { Clear}
                      end
                    end;
                  sym_WORD: begin
                      if Dest^.val <> yys^.val then
                      begin
                        emit_mov(Dest^, yys^);
                        Tmp2 := yys^; Tmp2.Val := Tmp2.Val + 1; Tmp2.Typ := sym_DEF;
                        Tmp := Dest^; Tmp.Val := Tmp.Val + 1; Tmp.Typ := sym_DEF;
                        emit_mov(Tmp, Tmp2);
                      end;
                    end;
                end;
              end;
            { 0     1 2}
            { eevar = var }
            sym_EE: begin
                TempSym.Val := a_EEAR; {EEAR}
                emit_ldi(WREG, Dest^.val);
                emit_out(TempSym, WREG);

                TempSym.Val := a_EEDR; {EEDR}
                case yys^.Typ of
                  sym_DEF: begin
                      emit_out(TempSym, yys^);
                    end;
                  sym_Const: begin
                      emit_ldi(WREG, yys^.val);
                      emit_out(TempSym, WREG);
                    end;
                end;
                emit_ee_wr(nil, nil, '');
              end;
            { first OP = Reg }
            sym_DEF: begin
                case yys^.Typ of
                  { var = iovar }
                  sym_IO: begin
                      emit_in(Dest^, yys^);
                    end;
                  { var = var | var16 }
                  sym_DEF,
                    sym_WORD: begin
                      if Dest^.val <> yys^.val then
                        emit_mov(Dest^, yys^);
                    end;
                end;
              end;
          end;
        end;
      { 0   1 2  34    5  }
      { Var = Const }
      T_CONST: begin
          case Dest^.Typ of
            sym_Bit,
              sym_ioBit: begin
                emit_dobit(Dest, yys);
                Exit;
              end;

            { reg := Const }
            sym_EE: begin
                TempSym.Val := a_EEAR; {EEAR}
                emit_ldi(WREG, yy0^.val);
                emit_out(TempSym, WREG);

                TempSym.Val := a_EEDR; {EEDR}
                case yys^.Typ of
                  sym_DEF: begin
                      emit_out(TempSym, yys^);
                    end;
                  sym_Const: begin
                      emit_ldi(WREG, yys^.val);
                      emit_out(TempSym, WREG);
                    end;
                end;
                emit_ee_wr(nil, nil, '');
              end;
            sym_sDEF: begin
                emit_ldi(WREG, yys^.val);
                emitn_sts(@WREG, Dest);
              end;
            sym_lDEF: begin
                emit_ldi(WREG, yys^.val);
                emitn_std(@WREG, @Y, Dest);
              end;
            // var = const_single
            sym_SINGLE: begin
                // Type Conversion
                // Integer -> Float
                if yys^.subval = 0 then
                  i32 := Single2I(yys^.val * 1.0)
                else
                  i32 := yys^.val;
                // Load FP_A
                emit_ldi(REG(16)^, i32);
                emit_ldi(REG(17)^, i32 shr 8);
                emit_ldi(REG(18)^, i32 shr 16);
                emit_ldi(REG(19)^, i32 shr 24);
                // SRAM Address
                emit_ldi(ZL, Dest^.val);
                // Store to STATIC
                LibCall('FP_ST_A');
              end;
            sym_DEF: begin
                {
                If ispic then
                  emit_ldi(Dest^, yys^.val) else
                  }
                begin
                  if Dest^.val > 15 then
                  begin {high bank= ldi}
                    emit_ldi(Dest^, yys^.val);
                  end else
                  begin {low bank= ldi w  / mov}
                    if yys^.val = 0 then
                    begin
                      emit_eor(Dest^, Dest^);
                    end else begin
                      emit_ldi(WREG, yys^.val);
                      emit_mov(Dest^, WREG);
                    end;
                  end;
                end;
              end;

            sym_WORD: begin
                if Dest^.val > 15 then
                begin {high bank= ldi OK}
                  emit_ldi(Dest^, yys^.val);
                end else
                begin {low bank= ldi w  / mov}
                  case yys^.val of
                    0: begin
                        Dest^.typ := sym_DEF;
                        emit_eor(Dest^, Dest^);
                        Dest^.Val := Dest^.Val + 1; {h byte}
                        emit_eor(Dest^, Dest^);
                      end;
                    1..255: begin
                        emit_ldi(WREG, yys^.val);
                        emit_mov(Dest^, WREG);
                        Dest^.typ := sym_DEF;
                        Dest^.Val := Dest^.Val + 1; {h byte}
                        emit_eor(Dest^, Dest^);
                      end else begin
                      if (yys^.val and $00FF) = 0 then
                      begin
                        Dest^.typ := sym_DEF;
                        emit_eor(Dest^, Dest^);
                        Dest^.Val := Dest^.Val + 1; {h byte}
                        emit_ldi(WREG, yys^.val shr 8);
                        emit_mov(Dest^, WREG);
                      end else
                      begin
                        emit_ldi(WREG, yys^.val);
                        emit_mov(Dest^, WREG);
                        if ((yys^.val and 255) = (yys^.val shr 8)) then
                        begin
                          Tmp := Dest^;
                          Tmp.val := Tmp.val + 1;
                          emit_mov(Tmp, Dest^);
                        end else begin
                          Dest^.Val := Dest^.Val + 1; {h byte}
                          emit_ldi(WREG, yys^.val shr 8);
                          emit_mov(Dest^, WREG);
                        end;
                      end;
                    end;
                  end;
                end;
              end;

            sym_WORD32: begin
                if Dest^.val > 15 then
                begin {high bank= ldi OK}
                  emit_ldi(Dest^, yys^.val);
                end else
                begin {low bank= ldi w  / mov}
                  case yys^.val of
                    0: begin
                        Dest^.typ := sym_DEF; emit_eor(Dest^, Dest^);
                        Dest^.Val := Dest^.Val + 1; emit_eor(Dest^, Dest^);
                        Dest^.Val := Dest^.Val + 1; emit_eor(Dest^, Dest^);
                        Dest^.Val := Dest^.Val + 1; emit_eor(Dest^, Dest^);
                      end
                  else begin
                      Dest^.typ := sym_DEF;
                      emit_ldi(WREG, yys^.val); emit_mov(Dest^, WREG);
                      Dest^.Val := Dest^.Val + 1;
                      emit_ldi(WREG, yys^.val shr 8); emit_mov(Dest^, WREG);
                      Dest^.Val := Dest^.Val + 1;
                      emit_ldi(WREG, yys^.val shr 16); emit_mov(Dest^, WREG);
                      Dest^.Val := Dest^.Val + 1;
                      emit_ldi(WREG, yys^.val shr 24); emit_mov(Dest^, WREG);
                    end;
                  end;
                end;
              end;

            { IO := Const }
            sym_IO: begin
                emit_assign(@WREG, yys);
                emit_out(Dest^, WREG);
              end;
          end;
        end;
      T_RAM: begin
          //
          emit_eval2(Dest, yys);

          Exit;
        end
    else begin
        Error(342);
        Exit;
      end;
    end;

    { 0   1 2      3      4      }
    { var = VarCon T_MATH VarCon }
{tr(yy1);}
    yy2 := yy1^.right;
    yy3 := yy2^.right; { Operand }

    while IsBinaryOperation(yy2) do
    begin
      { word = x .. y }
      yy4 := emit_eval2(nil, yy3); { Eval Operand! }

      // WORD MATH
      if Dest^.typ = sym_WORD then
      begin
        Tmp := Dest^; Tmp.Typ := sym_DEF;
        Tmp2 := Dest^; Tmp2.Val := Tmp2.Val + 1; Tmp2.Typ := sym_DEF;
        Op1 := yy4^; Op1.Typ := sym_DEF;
        Op2 := yy4^; Op2.Val := Op2.Val + 1; Op2.Typ := sym_DEF;

        case yy2^.val of
          T_AND: begin
              case yy3^.typ of
                sym_WORD: begin
                    emit_binary_and(@Tmp, @Tmp, @Op1);
                    emit_binary_and(@Tmp2, @Tmp2, @Op2);
                    {
                    emit_and(Tmp, Op1);
                    emit_and(Tmp2, Op2);
                    }
                  end;
                sym_CONST: begin
                    case yy4^.val of
                      0: begin
                          emit_eor(Tmp, Tmp);
                          emit_eor(Tmp2, Tmp2);
                        end;
                      1..$FE: begin
                          emit_eor(Tmp2, Tmp2);
                          emit_andi(Tmp, yy4^.val and 255);
                        end;
                      $FF: begin
                          emit_eor(Tmp2, Tmp2);
                        end;
                      Integer($FFFF): begin { Nothing }
                        end;
                      Integer($FF00): begin
                          emit_eor(Tmp, Tmp);
                        end else begin
                        if (yy4^.val and 255) <> 255 then
                          emit_andi(Tmp, yy4^.val and 255);
                        emit_andi(Tmp2, yy4^.val shr 8 and 255);
                      end;
                    end;
                  end;
              end;
            end;
          T_OR: begin
              case yy4^.typ of
                sym_WORD: begin
                    emit_or(Tmp, Op1);
                    emit_or(Tmp2, Op2);
                  end;
                sym_CONST: begin
                    case yy4^.val of
                      0: begin { Nothing }
                        end;
                      1..$FE: begin
                          emit_ori(Tmp, yy4^.val and 255);
                        end;
                      $FF: begin
                          emit_ldi(Tmp, 255);
                        end;
                      Integer($FF00): begin
                          emit_ldi(Tmp2, 255);
                        end else begin
                        if (yy4^.val and 255) <> 0 then
                          emit_ori(Tmp, yy4^.val and 255);
                        emit_ori(Tmp2, yy4^.val shr 8 and 255);
                      end;
                    end;
                  end;
              end;
            end;
          T_EOR: begin
              case yy4^.typ of
                sym_WORD: begin
                    emit_eor(Tmp, Op1);
                    emit_eor(Tmp2, Op2);
                  end;
                sym_CONST: begin
                    case yy4^.val of
                      0: begin { Nothing }
                        end;
                      1..$FF: begin
                          emit_eor(Tmp, yy4^);
                        end else begin
                        if (yy4^.val and $FF) <> 0 then
                          emit_eor(Tmp, yy4^);
                        yy4^.val := yy4^.val shr 8;
                        emit_eor(Tmp2, yy4^);
                      end;
                    end;
                  end;
              end;
            end;
          { + }
          3: begin
              case yy4^.typ of
                sym_DEF: begin
                    {emit_add(Tmp, Op1);
                    emit_ldi(WREG, 0);
                    emit_adc(Tmp2, WREG);
                    }
                    emit_add(Tmp, Op1);
                    emit_typ($F408);
                    emit_inc(Tmp2);
                  end;
                sym_WORD: begin
                    emit_add(Tmp, Op1);
                    emit_adc(Tmp2, Op2);
                  end;
                sym_CONST: begin
                    case yy4^.Val of
                      0: begin { nop }
                          {??}
                        end;
                      1: begin { inc word (word = word+1 ) }
                          if Tmp.val < 16 then
                          begin
                            emit_inc(Tmp); { skip}
                            emit_typ($F409); { bneq+1}
                            emit_inc(Tmp2);
                          end else begin
                            emit_add(Dest^, yy4^);
                            {emit_add(Tmp, yy4^);
                            yy4^.Val := (-yy4^.Val) shr 8;
                            emit_sbc(Tmp2, yy4^);
                            }
                          end;
                        end;
                      $100: begin { inc hi }
                          emit_inc(Tmp2);
                        end;
                      Integer($FF00): begin { dec hi }
                          emit_dec(Tmp2);
                        end else begin
                        if (yy4^.Val and $00FF) = 0 then
                        begin
                          yy4^.Val := yy4^.Val shr 8;
                          emit_add(Tmp2, yy4^);
                        end else
                        begin
                          if has_adiw and (Dest^.val in [24, 26, 28, 30]) and (yy4^.val < 64) then
                            emit_add(Dest^, yy4^)
                          else begin
                            emit_add(Tmp, yy4^);
                            yy4^.Val := (-yy4^.Val) shr 8;
                            emit_sbc(Tmp2, yy4^);
                          end;

                        end;
                      end;
                    end;
                  end; {const}
              end;
            end;
          { -}
          2: begin
              case yy4^.typ of
                sym_DEF: begin
                    emit_sub(Tmp, Op1);
                    emit_ldi(WREG, 0); // ???????
                    emit_sbc(Tmp2, WREG);
                  end;
                sym_WORD: begin
                    emit_sub(Tmp, Op1);
                    emit_sbc(Tmp2, Op2);
                  end;
                sym_CONST: begin
                    case yy4^.Val of
                      0: begin { nop }
                        end;
                      1: begin { dec word}
                          {If ispic then emit_dec(Dest^)
                          else}
                          if Tmp.val < 16 then
                          begin
                            emit_dec(Tmp); { skip}
                            emit_typ($F409); { bneq+1}
                            emit_dec(Tmp2);
                          end else begin
                            emit_sub(Dest^, yy4^);
                            {
                            emit_sub(Tmp, yy4^);
                            yy4^.Val := yy4^.Val shr 8;
                            emit_sbc(Tmp2, yy4^);
                            }
                          end;
                        end;
                      $100: begin { inc hi }
                          emit_dec(Tmp2);
                        end;
                      Integer($FF00): begin { dec hi }
                          emit_inc(Tmp2);
                        end else begin
                        if (yy4^.Val and $00FF) = 0 then
                        begin
                          yy4^.Val := yy4^.Val shr 8;
                          emit_sub(Tmp2, yy4^);
                        end else
                        begin
                          if has_adiw and (Dest^.val in [24, 26, 28, 30]) and (yy4^.val < 64) then
                            emit_sub(Dest^, yy4^)
                          else begin
                            emit_sub(Tmp, yy4^);
                            yy4^.Val := yy4^.Val shr 8;
                            emit_sbc(Tmp2, yy4^);
                          end;
                        end;
                      end;
                    end;
                  end; {const}
              end;
            end;

          { mul }
          4: begin
              { word = byte * byte }
              if yy4^.typ = sym_DEF then
              begin
                Tmp := Dest^; Tmp.Val := Tmp.Val + 1; Tmp.Typ := sym_DEF;
                Op1 := Dest^; Op1.Subval := 0;
                {emit_eor(Tmp, Tmp);} emit_ldi(WREG, 8);
                emit_sbrc(Op1); emit_add(Tmp, yy4^);
                emit_Typ3(Tmp, word(T_LSR));
                emit_Typ3(Dest^, Word(T_ROR));
                emit_Typ3(WREG, Word(T_DEC));
                emit_typ($F7D1);
              end;
              { word = byte * const }
              if yy4^.typ = sym_Const then
              begin
                case yy4^.Val of
                  0: begin
                      emit_ldi(Dest^, 0);
                    end;
                  1: begin { Nothing }
                    end;
                  2: begin { shl 1 }
                      Tmp2 := Dest^; Tmp2.Val := Tmp2.Val + 1; Tmp2.Typ := sym_DEF;
                      Tmp := Dest^; Tmp.Typ := sym_DEF;
                      emit_add(Tmp, Tmp);
                      emit_adc(Tmp2, Tmp2);
                    end;
                  4: begin
                      Tmp2 := Dest^; Tmp2.Val := Tmp2.Val + 1; Tmp2.Typ := sym_DEF;
                      Tmp := Dest^; Tmp.Typ := sym_DEF;
                      emit_add(Tmp, Tmp);
                      emit_adc(Tmp2, Tmp2);
                      emit_add(Tmp, Tmp);
                      emit_adc(Tmp2, Tmp2);
                    end;
                  8: begin { shl 3 }
                      Tmp2 := Dest^; Tmp2.Val := Tmp2.Val + 1; Tmp2.Typ := sym_DEF;
                      Tmp := Dest^; Tmp.Typ := sym_DEF;
                      emit_add(Tmp, Tmp); emit_adc(Tmp2, Tmp2);
                      emit_add(Tmp, Tmp); emit_adc(Tmp2, Tmp2);
                      emit_add(Tmp, Tmp); emit_adc(Tmp2, Tmp2);
                    end;
                  16: begin { shl 4 }
                      Tmp := Dest^; Tmp.Val := Tmp.Val + 1; Tmp.Typ := sym_DEF;
                      emit_typ3(Dest^, Word(T_SWAP));
                      emit_typ3(Tmp, Word(T_SWAP));
                      emit_andi(Tmp, $F0);
                      emit_mov(WREG, Dest^);
                      emit_andi(Dest^, $F0);
                      emit_andi(WREG, $0F);
                      emit_or(Tmp, WREG);
                    end;
                  256: begin { shl 8 }
                      Tmp2 := Dest^; Tmp2.Val := Tmp2.Val + 1; Tmp2.Typ := sym_DEF;
                      Tmp := Dest^; Tmp.Typ := sym_DEF;
                      emit_mov(Tmp2, Tmp);
                      emit_eor(Tmp, Tmp);
                    end else begin
                    Tmp := Dest^; Tmp.Val := Tmp.Val + 1; Tmp.Typ := sym_DEF;
                    Op1 := Dest^; Op1.Subval := 0;
                    {emit_eor(Tmp, Tmp);} emit_ldi(WREG, 8);
                    emit_sbrc(Op1); emit_add(Tmp, yy4^);
                    emit_Typ3(Tmp, word(T_LSR));
                    emit_Typ3(Dest^, Word(T_ROR));
                    emit_Typ3(WREG, Word(T_DEC));
                    emit_typ($F7D1);
                  end;
                end;
              end;
            end;

          { div ??}
          7: begin
              error(99);
            end;
        end;
      end;

      { Byte = x .. y }
      // Eval BYTE Dest
      if Dest^.typ = sym_DEF then
      begin
        case yy2^.val of
          T_AND: begin
              emit_binary_and(Dest, Dest, yy3);
            end;
          T_OR: begin
              emit_or(Dest^, yy3^);
            end;
          T_EOR: begin
              emit_eor(Dest^, yy3^);
            end;
          {/ }
          7: begin
              if yy3^.typ = sym_Const then
              begin
                case yy3^.val of
                  2: begin
                      emit_typ1(Dest^, Word(T_LSR));
                    end;
                  4: begin
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_typ1(Dest^, Word(T_LSR));
                    end;
                  8: begin
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_typ1(Dest^, Word(T_LSR));
                    end;
                  16: begin
                      emit_typ1(Dest^, Word(T_SWAP));
                      emit_andi(Dest^, $0F);
                    end;
                  32: begin
                      emit_typ1(Dest^, Word(T_SWAP));
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_andi(Dest^, $07);
                    end;
                  64: begin
                      emit_typ1(Dest^, Word(T_SWAP));
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_andi(Dest^, $03);
                    end;
                  128: begin
                      emit_adc(Dest^, Dest^); // c := d7
                      emit_adc(Dest^, Dest^); // d0 := d7
                      emit_andi(Dest^, $01);
                    end
                else begin
                    if yy3^.val >= 256 then
                    begin
                      emit_eor(Dest^, Dest^);
                      Warning(1001); // Result is Always 0
                    end else begin
                      emit_ldi(ZL, yy4^.val);
                      emit_ldi(WREG, 255); // k := 0
                      emit_inc(WREG);
                      emit_sub(Dest^, ZL);
                      emit_typ($F7E8);
                      emit_mov(Dest^, WREG);

                    end;
                  end;
                end;
              end else
              begin

                //  WREG := i		// Make Copy
                //  k := 0		// Clear Dest
                //  Repeat
                //   inc k
                //   sub WREG,j 		// Sub
                //  Until CPU.Carry;	// Repeat Until
                //  dec k			// Adjust

                emit_ldi(WREG, 255); // k := 0
                emit_inc(WREG);
                emit_sub(Dest^, yy4^);
                emit_typ($F7E8);
                emit_mov(Dest^, WREG);
              end;
            end;

          {* }
          4: begin
              // byte = byte * byte
              if yy3^.typ = sym_Const then
              begin
                case yy3^.val of
                  2: begin
                      emit_Add(Dest^, Dest^);
                    end;
                  4: begin
                      emit_Add(Dest^, Dest^);
                      emit_Add(Dest^, Dest^);
                    end;
                  8: begin
                      emit_Add(Dest^, Dest^);
                      emit_Add(Dest^, Dest^);
                      emit_Add(Dest^, Dest^);
                    end;
                  16: begin
                      emit_typ1(Dest^, Word(T_SWAP));
                      emit_andi(Dest^, $F0);
                    end;
                  32: begin
                      emit_typ1(Dest^, Word(T_SWAP));
                      emit_Add(Dest^, Dest^);
                      emit_andi(Dest^, $E0);
                    end;
                  64: begin
                      emit_typ1(Dest^, Word(T_SWAP));
                      emit_Add(Dest^, Dest^);
                      emit_Add(Dest^, Dest^);
                      emit_andi(Dest^, $C0);
                    end;
                  128: begin
                      emit_ror(Dest^);
                      emit_ror(Dest^);
                      emit_andi(Dest^, $80);
                    end
                else begin
                    if yy3^.val >= 256 then
                    begin
                      emit_eor(Dest^, Dest^);
                      Warning(1002); // Result is Always 0
                    end else begin
                      emit_ldi(ZL, yy3^.val); // wreg = k
                      emit_mov(WREG, yys^); // wreg = k
                      emit_subi(WREG, 1);
                      emit_typ($F011); // if zero
                      emit_add(Dest^, ZL); // ?
                      emit_typ($CFFC); // goto
                    end;
                  end;
                end;
              end else
              begin
                // i := j  done Already !
                if Dest^.val <> yys^.val then
                begin
                  emit_mov(WREG, yy3^); // wreg = k
                  emit_subi(WREG, 1);
                  emit_typ($F011); // if zero
                  emit_add(Dest^, yys^); // ?
                  emit_typ($CFFC); // goto
                end else begin
                  emit_mov(ZL, yys^); // wreg = k
                  emit_mov(WREG, yy3^); // wreg = k
                  emit_subi(WREG, 1);
                  emit_typ($F011); // if zero
                  emit_add(Dest^, ZL); // ?
                  emit_typ($CFFC); // goto
                end;
              end;
            end;


          {+}
          3: begin
              if yy3^.typ = sym_Const then
              begin
                case yy3^.val of
                  1: begin
                      emit_inc(Dest^);
                    end;
                else
                  {emit_add(yy[0], yy[i+1]);}
                  emit_plus(Dest, Dest, yy3);
                end;
              end else begin
                {emit_add(yy[0], yy[i+1]);}
                emit_plus(Dest, Dest, yy4);
              end;
            end;
          {-}
          2: begin
              if yy3^.typ = sym_Const then
              begin
                case yy3^.val of
                  1: begin
                      emit_dec(Dest^);
                    end;
                else {emit_sub(yy[0], yy[i+1]);}
                  {??}
                  emit_minus(Dest, Dest, yy3);
                end;
              end else begin
                {emit_sub(yy[0], yy[i+1]);}
                emit_minus(Dest, Dest, yy3);
              end;
            end;
        end;
      end;

      { io Byte = x .. y }
      if Dest^.typ = sym_IO then
      begin
        {tr(yy2);}
        case yy2^.val of
          T_AND: begin
              emit_binary_and(Dest, Dest, yy3);
            end;
          T_OR: begin
              emit_or(WREG, yy3^);
            end;
          T_EOR: begin
              emit_eor(Dest^, yy3^);
            end;
          {/ }
          7: begin
              if yy3^.typ = sym_Const then
              begin
                case yy3^.val of
                  2: begin
                      emit_typ1(Dest^, Word(T_LSR));
                    end;
                  4: begin
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_typ1(Dest^, Word(T_LSR));
                    end;
                  8: begin
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_typ1(Dest^, Word(T_LSR));
                      emit_typ1(Dest^, Word(T_LSR));
                    end;
                  16: begin
                      emit_typ1(Dest^, Word(T_SWAP));
                    end;
                else begin
                    emit_plus(Dest, Dest, yy3);
                  end;
                end;
              end else begin
                emit_plus(Dest, Dest, yy4);
              end;
            end;


          {+}
          3: begin
              if yy3^.typ = sym_Const then
              begin
                case yy3^.val of
                  1: begin
                      emit_inc(Dest^);
                    end;
                else
                  {emit_add(yy[0], yy[i+1]);}
                  emit_plus(Dest, Dest, yy3);
                end;
              end else begin
                {emit_add(yy[0], yy[i+1]);}
                emit_plus(Dest, Dest, yy4);
              end;
            end;
          {-}
          2: begin
              if yy3^.typ = sym_Const then
              begin
                case yy3^.val of
                  1: begin
                      emit_dec(Dest^);
                    end;
                else {emit_sub(yy[0], yy[i+1]);}
                  {??}
                  emit_minus(Dest, Dest, yy3);
                end;
              end else begin
                {emit_sub(yy[0], yy[i+1]);}
                emit_minus(Dest, Dest, yy3);
              end;
            end;
        end;
      end;


      yy2 := DropNode(yy2);
      yy2 := DropNode(yy2);
      yy3 := yy2^.right; { Operand }
    end; { BinaryOp }
    if not IfL(yy2, T_NEWLINE) then
      if not IfL(yy2, T_LBRACKET2)
        then Error(err_trash);

  end; { error var= }

end;



begin
end.

