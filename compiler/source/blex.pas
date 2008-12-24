(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit blex;

interface

uses
  ToolStd,
  ToolSrv,

  CompDef,
  NodePool,
  LstFile,
  prefer,
  emit,
  MStrings,
  SysUtils;

{ Imitate FLEX Lexer... }

function b_yylex: Integer;

procedure ProcessCompilerDirective(Directive: string);

implementation

procedure ProcessCompilerDirective(Directive: string);
var
  Ch: Char;
begin
  //
//  WriteStdOutput('DIR:' + Directive+':');
  if Length (Directive) < 2 then exit;
  Ch := UpCase(Directive[1]);
  case Ch of
    'L': begin
      if Directive[2] = '+' then p_lstfile := true;
      if Directive[2] = '-' then p_lstfile := false;
    end;
  end;


end;



function b_yylex;
label
  yyexit, yy_var, yy_token, yy_math, yy_const;
var
  Ch: Char;
  err,
    idlen,
    I, J: Integer;
  Flag: Boolean;
  mantissa,
    yval: Integer;
  fl4: Single;
  directive: string;
begin

  while yytext < yyBufSize do begin
    yyeof := False;

    case yyState of
      yySTRING: begin
          case Buf[yytext] of
            #10,
              #13: begin
                yyState := yyINITIAL; { Cancel String Mode }
                inc(linenum);
                { error String Constant exceed Line'!
                          emit_lst_comment;
                          }
              end;
            {'''',}
            #$22: begin
                yyState := yyINITIAL; { Cancel String Mode }
              end else begin
              if yyComma = 1 then begin
                yyComma := 0;
                yval := T_COMMA;
                goto yyexit;
              end else begin
                yyComma := 1;
                yyintval := Ord(Buf[yytext]);
                inc(yytext);
                goto yy_const;
              end;
            end;
          end;
        end;
      yyINITIAL: begin
          Ch := UpCase(Buf[yytext]);
          case Ch of
            #0: begin
                yyeof := True;
                yval := T_EOF;
                goto yyexit;
              end;
            #$22: begin
                yyState := yySTRING;
                yyComma := 1; { Need Comma }
                inc(yytext); {skip "}
                yyintval := Ord(Buf[yytext]); {ret first char}
                inc(yytext); {point to next char or EOS}
                goto yy_const;
              end;
            ':': begin
                yval := T_COLON;
                inc(yytext);
                if (Buf[yytext] = '=') then begin
                  inc(yytext);
                  yval := T_EQUAL;
                end;
                goto yyexit;
              end;
            ' ', #9: begin inc(yytext); Continue; end; { SKIP WhiteSpace }
            { Reached end Of Line }
            #10: begin
                if (Buf[yytext] <> #0) then inc(yytext);
                Continue;
              end;
            #13: begin
                {emit_lst_comment;
                              }
                if (Buf[yytext] <> #0) then inc(yytext);
                yval := T_NEWLINE;
                goto yyexit;
              end;
            ';': begin
                if (Buf[yytext] <> #0) then inc(yytext);
                yval := T_NEWLINE;
                goto yyexit;
              end;
            ',': begin
                inc(yytext);
                yval := T_COMMA;
                goto yyexit;
              end;
            '@': begin
                inc(yytext);
                yval := T_AT;
                goto yyexit;
              end;
            '.': begin
                inc(yytext);
                yval := T_DOT;
                goto yyexit;
              end;
            '(': begin
                inc(yytext);
                yval := T_LBRACKET;
                goto yyexit;
              end;
            '[': begin
                inc(yytext);
                yval := T_LBRACKET2;
                goto yyexit;
              end;
            ')': begin
                inc(yytext);
                yval := T_RBRACKET;
                goto yyexit;
              end;
            ']': begin
                inc(yytext);
                yval := T_RBRACKET2;
                goto yyexit;
              end;
            '!': begin
                inc(yytext);
                yval := T_NOT;
                goto yyexit;
              end;
            '=': begin
                inc(yytext);
                yval := T_EQUAL;
                yyintval := 100;
                goto yyexit;
              end;
            '-': begin
                inc(yytext);
                if Buf[yytext] = '-' then begin
                  inc(yytext);
                  yval := T_DECDEC;
                  goto yyexit;
                end else begin
                  yyintval := 2;
                  goto yy_math;
                end;
              end;
            '+': begin
                inc(yytext);
                if Buf[yytext] = '+' then begin
                  inc(yytext);
                  yval := T_INCINC;
                  goto yyexit;
                end else begin
                  yyintval := 3;
                  goto yy_math;
                end;
              end;
            '*': begin
                inc(yytext);
                if Buf[yytext] = '*' then begin
                  inc(yytext);
                  yyintval := 5;
                end else yyintval := 4;
                goto yy_math;
              end;
            '{': begin
                {C/Delphi Style Comments..}
                inc(yytext); { }
                { look for Compiler Directives... }
                if (Buf[yytext] = '$') then
                begin
                  inc(yytext); { }
                  Directive := '';
                  while (Buf[yytext] <> '}') and (Buf[yytext] <> #0) do
                  begin
                    // Collect Compiler Directive...
                    //
                    Directive := Directive + Buf[yytext];
                    inc(yytext); { Skip to EOL... }
                  end;
                  ProcessCompilerDirective(Directive);
                end else begin
                  while (Buf[yytext] <> '}') and (Buf[yytext] <> #0) do
                  begin
                    inc(yytext); { Skip to EOL... }
                  end;
                end;
                yval := T_NEWLINE;
                goto yyexit;
              end;
            '/': begin
                inc(yytext);
                if Buf[yytext] = '/' then begin
                  {C/Delphi Style Comments..}
                  while (Buf[yytext] <> #10) and (Buf[yytext] <> #13) and (Buf[yytext] <> #0) do
                    inc(yytext); { Skip to EOL... }
                  yval := T_NEWLINE;
                  goto yyexit;
                end else yyintval := 7;
                goto yy_math;
              end;
            '''': begin
                inc(yytext);
                while (Buf[yytext] <> #10) and (Buf[yytext] <> #13) and (Buf[yytext] <> #0) do
                  inc(yytext); { Skip to EOL... }
                yval := T_NEWLINE;
                goto yyexit;
              end;
            '^': begin
                inc(yytext);
                if Buf[yytext] = '/' then begin
                  inc(yytext);
                  yyintval := 12;
                end else yyintval := 13;
                goto yy_math;
              end;
            '&': begin
                inc(yytext);
                if Buf[yytext] = '/' then begin
                  inc(yytext);
                  yyintval := 8;
                end else yyintval := 9;
                goto yy_math;
              end;
            '|': begin
                inc(yytext);
                if Buf[yytext] = '/' then begin
                  inc(yytext);
                  yyintval := 10;
                end else yyintval := 11;
                goto yy_math;
              end;
            '<': begin
                inc(yytext);
                case Buf[yytext] of
                  '<': begin
                      inc(yytext);
                      yval := T_SHL;
                      goto yyexit;
                    end;
                  '=': begin
                      inc(yytext);
                      yyintval := 5;
                    end;
                  '>': begin
                      inc(yytext);
                      yyintval := 3;
                    end else yyintval := 1;
                end;
                yval := T_LOG;
                goto yyexit;
              end;
            '>': begin
                inc(yytext);
                case Buf[yytext] of
                  '>': begin
                      inc(yytext);
                      yval := T_SHR;
                      goto yyexit;
                    end;
                  '=': begin
                      inc(yytext);
                      yyintval := 6;
                    end
                else yyintval := 2;
                end;
                yval := T_LOG;
                goto yyexit;
              end;
            {'''': Begin
              While (Buf[yytext]<>#10) and (Buf[yytext]<>#13) and (Buf[yytext]<>#0) Do
                               inc(yytext);
                yval := T_NEWLINE;
                             goto yyexit;
                        End;
                        }
            '#': begin
                inc(yytext);
                yval := T_23;
                goto yyexit;
              end;
            '0'..'9': begin { Decimal Const }
                yyintval := 0;
                I := 0;
                yyTmp.SubVal := 0; // 32 Integer Const!
                while (yytext < yyBufSize) and (I < 10) do begin
                  case Buf[yytext] of
                    '.': begin // Float Type!
                        mantissa := yyintval;
                        yyintval := 0;
                        yyTmp.SubVal := 1; // Float
                      end;
                    // Numeric
                    '0'..'9': yyintval := yyintval * 10 + (Ord(Buf[yytext]) - $30);
                  else begin
                      if yyTmp.subval <> 0 then
                      begin
                        val(IntToStr(mantissa) + '.' + IntToStr(yyintval), fl4, err);
                        yyintval := Single2I(fl4);
                      end;
                      StrCopy(yyTmp.Name, '* Immediate Constant Value *');
                      yval := T_CONST;
                      goto yy_const;
                    end;
                  end;
                  inc(I);
                  inc(yytext);
                end;
              end;
            '%': begin { Binary Const }
                yyintval := 0;
                I := 0;
                inc(yytext); { Skip '%' }
                while (yytext < yyBufSize) and (I < 33) do begin
                  case Buf[yytext] of
                    '0': yyintval := yyintval shl 1;
                    '1': yyintval := yyintval shl 1 + 1;
                    {
                            ' ', #9, #10, #13, ':', ',' , ')', '(': Begin
                             b_yylex := T_CONST;
                             goto yyexit;
                            End;}
                  else begin
                      StrCopy(yyTmp.Name, '* Immediate Constant Value *');
                      yval := T_CONST;
                      goto yy_const;
                    end;
                  end;
                  inc(I);
                  inc(yytext);
                end;
              end;
            '$': begin { Hex Const }
                yyintval := 0;
                I := 0;
                inc(yytext); { Skip '%' }
                while (yytext < yyBufSize) and (I < 9) do begin
                  case Buf[yytext] of
                    '0'..'9': yyintval := yyintval shl 4 + (Ord(Buf[yytext]) and 15);
                    'A'..'F', 'a'..'f': yyintval := yyintval shl 4 + (Ord(Buf[yytext]) and 15 + 9);
                  else begin
                      StrCopy(yyTmp.Name, '* Immediate Constant Value *');
                      yval := T_CONST;
                      goto yy_const;
                    end;
                  end;
                  inc(I);
                  inc(yytext);
                end;
              end;
            { Variable/Label Lookup }
            'A'..'Z', '_': begin
                ID[0] := Ch;
                idlen := 1;
                inc(yytext);
                Flag := True;
                { Collect Identifier }
                while (yytext < yyBufSize) and (idlen < 31) and Flag do begin
                  { Check for Separator... }
                  Ch := UpCase(Buf[yytext]);
                  case Ch of
                    '0'..'9',
                      'A'..'Z', '_', '$', '@': begin
                        ID[idlen] := Ch;
                        inc(idlen);
                        inc(yytext);
                      end
                  else Flag := False;
                  end;
                end;
                ID[idlen] := #0;
                dec(idlen);

                if locp <> 0 then begin { Search Local Vars first! }
                  if next_local_sym > 0 then
                    for J := next_local_sym - 1 downto 0 do begin
                      if StrComp(LocalSyms[J].Name, ID) = 0 then begin
                        yyTmp := LocalSyms[J];
                        if IsVariable(@LocalSyms[J]) then begin
                          yyintval := LocalSyms[J].Val;
                          goto yy_var;
                        end else begin
                          yyintval := LocalSyms[J].Val;
                          goto yy_const;
                        end;
                      end;
                    end;
                end;
                if next_sym > 0 then
                  for J := next_sym - 1 downto 0 do begin
                    if StrComp(Syms^[J].Name, ID) = 0 then begin
                      { Symbol Found! }
                      { Copy to Tmp! }
                      yyTmp := Syms^[J];
                      if IsVariable(@Syms^[J]) then begin
                        yyintval := Syms^[J].Val;
                        {DOT separator!}
                        if StrComp(ID, 'WREG') = 0 then
                        begin
                          Syms^[J].Val := wreg_def;
                          yyintval := Syms^[J].Val;
                        end;
                        goto yy_var;
                      end else begin
                        yyintval := Syms^[J].Val;
                        goto yy_const;
                      end;
                    end;
                  end;

                yval := T_LABEL;
                StrCopy(yyTmp.Name, ID);
                yyTmp.Val := -1;
                yyTmp.SubVal := 0;
                { UNDEF LABEL ? }

                { Filter out Tokens and Predefined Symbols }
                case ID[0] of
                  'A': begin { AND }
                      if StrComp(ID, 'ASR') = 0 then begin
                        yyintval := T_ASR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'AS') = 0 then begin
                        yval := T_AS;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'AT') = 0 then begin
                        yval := T_AT;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'ASSEMBLER') = 0 then begin
                        yval := T_ASSEMBLER;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'ADDR') = 0 then begin
                        yval := T_ADDR;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'ADD') = 0 then begin
                        yyintval := T_ADD;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ADC') = 0 then begin
                        yyintval := T_ADC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'AND') = 0 then begin
                        yyintval := T_AND;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ASM') = 0 then begin
                        yyintval := T_ASM;
                        goto yy_token;
                      end;

                    end;
                  'B': begin
                      if StrComp(ID, 'BEGIN') = 0 then begin
                        yval := T_BEGIN;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'BYTE') = 0 then begin
                        yval := T_TYPEDECL;
                        yyintval := sym_DEF; { BYTE }
                        goto yyexit;
                      end;
                      if StrComp(ID, 'BIT') = 0 then begin
                        yval := T_TYPEDECL;
                        yyintval := sym_BIT; { BYTE }
                        goto yyexit;
                      end;
                      if StrComp(ID, 'BREAK') = 0 then begin {?}
                        yval := T_BREAK;
                        goto yyexit;
                      end;
                    end;
                  'C': begin
                      if StrComp(ID, 'CONST') = 0 then begin
                        yval := T_CONDEF;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'CP') = 0 then begin
                        yyintval := T_CP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CPC') = 0 then begin
                        yyintval := T_CPC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'COM') = 0 then begin
                        yyintval := T_COM;
                        goto yy_token;
                      end;
                    end;
                  'D': begin { DEBUG DIRS }
                      if StrComp(ID, 'DIV') = 0 then begin
                        yyintval := T_DIV;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'DEC') = 0 then begin
                        yyintval := T_DEC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'DEFAULT') = 0 then begin
                        yval := T_DEFAULT;
                        yyintval := -1;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'DEBUGBREAK') = 0 then begin
                        yyintval := T_DEBUGBREAK;
                        goto yy_token
                      end;
                    end;
                  'E': begin { EEPROM END }
                      if StrComp(ID, 'EXTERNAL') = 0 then begin
                        yval := T_EXTERNAL;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'ELSE') = 0 then begin
                        yval := T_ELSE;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'END') = 0 then begin
                        //---
                        if Buf[yytext] = '.' then begin
                          yval := T_PROGEND;
                          inc(yytext);
                        end else
                          yval := T_END;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'EOR') = 0 then begin
                        yyintval := T_EOR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'EEPROM') = 0 then begin
                        yval := T_EEPROM;
                        goto yyexit;
                      end;
                    end;
                  'F': begin { FOR }
                      if StrComp(ID, 'FOR') = 0 then begin
                        yyintval := T_FOR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'FALSE') = 0 then begin
                        yval := T_CONST;
                        yyintval := 0;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'FUNCTION') = 0 then begin
                        yval := T_FUNCTION;
                        goto yyexit;
                      end;
                    end;
                  'G': begin { GOTO GOSUB }
                      if StrComp(ID, 'GOTO') = 0 then begin
                        yyintval := T_GOTO;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'GOSUB') = 0 then begin
                        yyintval := T_GOSUB;
                        goto yy_token;
                      end;
                    end;
                  'I': begin { IF INPUT }
                      if StrComp(ID, 'INC') = 0 then begin
                        yyintval := T_INC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'IF') = 0 then begin
                        yyintval := T_IFTHEN;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'INTERRUPT') = 0 then begin
                        yval := T_INTERRUPT;
                        goto yyexit;
                      end;
                    end;
                  'L': begin { LET LOOKUP LOOKDOWN LOW }
                      if StrComp(ID, 'LSR') = 0 then begin
                        yyintval := T_LSR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'LSL') = 0 then begin
                        yyintval := T_LSL;
                        goto yy_token;
                      end;
                    end;
                  'M': begin { MIN MAX }
                      if StrComp(ID, 'MUL') = 0 then begin
                        yyintval := T_MUL;
                        goto yy_token;
                      end;
                    end;
                  'O': begin { OR OUTPUT }
                      if StrComp(ID, 'OBJECT') = 0 then begin
                        yval := T_OBJECT;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'OR') = 0 then begin {?}
                        yyintval := T_OR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ORG') = 0 then begin {?}
                        yyintval := T_ORG;
                        goto yy_token;
                      end;
                    end;

                  'N': begin { NAP NEXT }
                      if StrComp(ID, 'NOT') = 0 then begin
                        yval := T_NOT;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'NEG') = 0 then begin
                        yyintval := T_NEG;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'NOP') = 0 then begin
                        yyintval := T_NOP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'NEXT') = 0 then begin
                        yyintval := T_NEXT;
                        goto yy_token;
                      end;
                    end;
                  'P': begin { PAUSE PINxx PINS PORT POT PULSIN PULSOUT PWM }
                      if StrComp(ID, 'PUBLIC') = 0 then begin
                        yval := T_PUBLIC;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'POP') = 0 then begin
                        yyintval := T_POP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'PUSH') = 0 then begin
                        yyintval := T_PUSH;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'PROCEDURE') = 0 then begin
                        yval := T_PROCEDURE;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'PROGRAM') = 0 then begin
                        yval := T_PROGRAM;
                        goto yyexit;
                      end;
                    end;
                  'R': begin { RANDOM RETURN READ RETURN REVERSE }
                      if StrComp(ID, 'ROM') = 0 then begin
                        yval := T_ROM;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'RAM') = 0 then begin
                        yval := T_RAM;
                        yyintval := 0; { offset 0 }
                        goto yyexit;
                      end;
                      if StrComp(ID, 'REG') = 0 then begin
                        yval := T_REG;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'REGISTER') = 0 then begin
                        yval := T_REG;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'ROR') = 0 then begin
                        yyintval := T_ROR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ROL') = 0 then begin
                        yyintval := T_ROL;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'RL') = 0 then begin
                        yyintval := T_RL;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'RR') = 0 then begin
                        yyintval := T_RR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'RETURN') = 0 then begin
                        yyintval := T_RETURN;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'REPEAT') = 0 then begin
                        yyintval := T_REPEAT;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'RETI') = 0 then begin
                        yyintval := T_RETI;
                        goto yy_token;
                      end;
                      {
                      if StrComp(ID, 'RETNMI') = 0 then begin
                        yyintval := T_RETNMI;
                        goto yy_token;
                      end;
                      }
                      if StrComp(ID, 'READ') = 0 then begin
                        yyintval := T_READ;
                        goto yy_token;
                      end;
                    end;
                  'S': begin { SYMBOL SERIN SEROUT SLEEP STEP SOUND }
                      if StrComp(ID, 'SHR') = 0 then begin
                        yval := T_SHR;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'SHL') = 0 then begin
                        yval := T_SHL;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'SINGLE') = 0 then begin
                        yval := T_TYPEDECL;
                        yyintval := sym_SINGLE; { BYTE }
                        goto yyexit;
                      end;
                      if StrComp(ID, 'SWAP') = 0 then begin
                        yyintval := T_SWAP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SUB') = 0 then begin
                        yyintval := T_SUB;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBC') = 0 then begin
                        yyintval := T_SBC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SWITCH') = 0 then begin {?}
                        yval := T_SWITCH;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'SKIP') = 0 then begin
                        yval := T_SKIP;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'SYMBOL') = 0 then begin
                        yval := T_SYMBOL;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'STEP') = 0 then begin
                        yval := T_STEP;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'SEGMENT') = 0 then begin
                        yval := T_SEGMENT;
                        goto yyexit;
                      end;
                    end;
                  'U': begin { }
                      if StrComp(ID, 'USES') = 0 then begin
                        yval := T_USES;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'USE') = 0 then begin
                        yval := T_USE;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'UNTIL') = 0 then begin
                        yyintval := T_UNTIL;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'UNIT') = 0 then begin
                        yval := T_LIBRARY;
                        goto yyexit;
                      end;
                    end;
                  'T': begin { THEN TO TOGGLE }
                      if StrComp(ID, 'THEN') = 0 then begin
                        yval := T_THEN;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'TO') = 0 then begin
                        yval := T_TO;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'TRUE') = 0 then begin
                        yval := T_CONST;
                        yyintval := $FFFF;
                        goto yyexit;
                      end;
                    end;
                  'X': begin
                      if StrComp(ID, 'XOR') = 0 then begin
                        yyintval := T_EOR;
                        goto yy_token;
                      end;
                    end;
                  'V': begin
                      if StrComp(ID, 'VAR') = 0 then begin
                        yval := T_VARDEF;
                        goto yyexit;
                      end;
                    end;
                  'W': begin { W0..W6 WRITE }
                      if StrComp(ID, 'WORD24') = 0 then begin
                        yval := T_TYPEDECL;
                        yyintval := sym_WORD24;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'WORD32') = 0 then begin
                        yval := T_TYPEDECL;
                        yyintval := sym_WORD32;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'WORD') = 0 then begin
                        yval := T_TYPEDECL;
                        yyintval := sym_WORD;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'WHILE') = 0 then begin
                        yyintval := T_WHILE;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'WAIT') = 0 then begin
                        yyintval := T_WAIT;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'WRITE') = 0 then begin
                        yyintval := T_WRITE;
                        goto yy_token;
                      end;
                    end;
                end; { Case id[0] Of }

                { Return what ever it was... }

                goto yyexit;
              end; { Case A..Z }
          end; { Case ch... }
        end; { Of INITIAL }
    end; { Case yystate... }
    { MOVE TO NEXT CHAR... }
    inc(yytext);
  end; { While }

  { We Reached EOF... }
  yval := T_EOF;
  yyeof := True;
  goto yyexit;

  yy_math:
    yval := T_MATH;
  yyTmp.yylex := T_MATH;
  yyTmp.Val := yyintval;
  goto yyexit;

  yy_token:
    StrCopy(yyTmp.Name, ID);
  yval := T_TOKEN;
  yyTmp.Val := yyintval;
  goto yyexit;

  yy_var:
    yyTmp.yylex := T_VAR;
  yval := T_VAR;
  goto yyexit;

  yy_const:
    yval := T_CONST;
  yyTmp.yylex := T_CONST;
  yyTmp.Typ := sym_Const;
  yyTmp.Val := yyintval;
  goto yyexit;

  yyexit:
    b_yylex := yval;
  yyTmp.Val := yyintval;

  yyn := NewNode;
  if yyn <> nil then
    with yyn^ do begin
      yylex := yval;
      Val := yyTmp.Val;
      SubVal := yyTmp.SubVal;
      Typ := yyTmp.Typ;
      StrLCopy(Name, yyTmp.Name, 32);
    end;

end;




begin
end. { Of Unit }

