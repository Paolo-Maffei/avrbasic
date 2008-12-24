(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit alex;

interface

uses
  ToolSrv,
  
  CompDef,
  NodePool,
  LstFile,
  emit,
  MStrings,
  SysUtils;

{ Imitate FLEX Lexer... }

function a_yylex: Integer;

implementation

function a_yylex;
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
            {
            ';': begin
                if (Buf[yytext] <> #0) then inc(yytext);
                yval := T_NEWLINE;
                goto yyexit;
              end;
            }
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
                while (Buf[yytext] <> '}') and (Buf[yytext] <> #0) do
                  inc(yytext); { Skip to EOL... }
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
            ';': begin
                {C/Delphi Style Comments..}
                while (Buf[yytext] <> #10) and (Buf[yytext] <> #13) and (Buf[yytext] <> #0) do
                  inc(yytext); { Skip to EOL... }
                yval := T_NEWLINE;
                goto yyexit;
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
                             a_yylex := T_CONST;
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
                      'A'..'Z', '_': begin
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
                      if StrComp(ID, 'ADIW') = 0 then begin
                        yyintval := T_ADIW;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ANDI') = 0 then begin
                        yyintval := T_ANDI;
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
                      if StrComp(ID, 'BRBS') = 0 then begin
                        yyintval := T_BRBS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRBC') = 0 then begin
                        yyintval := T_BRBC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRCS') = 0 then begin
                        yyintval := T_BRCS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRCC') = 0 then begin
                        yyintval := T_BRCC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRSH') = 0 then begin
                        yyintval := T_BRCC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRLO') = 0 then begin
                        yyintval := T_BRCS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRMI') = 0 then begin
                        yyintval := T_BRMI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRPL') = 0 then begin
                        yyintval := T_BRPL;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRGE') = 0 then begin
                        yyintval := T_BRGE;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRLT') = 0 then begin
                        yyintval := T_BRLT;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRHS') = 0 then begin
                        yyintval := T_BRHS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRHC') = 0 then begin
                        yyintval := T_BRHC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRTS') = 0 then begin
                        yyintval := T_BRTS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRTC') = 0 then begin
                        yyintval := T_BRTC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRVS') = 0 then begin
                        yyintval := T_BRVS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRVC') = 0 then begin
                        yyintval := T_BRVC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRIE') = 0 then begin
                        yyintval := T_BRIE;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRID') = 0 then begin
                        yyintval := T_BRID;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BREQ') = 0 then begin
                        yyintval := T_BREQ;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BRNE') = 0 then begin
                        yyintval := T_BRNE;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BSET') = 0 then begin
                        yyintval := T_BSET;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BCLR') = 0 then begin
                        yyintval := T_BCLR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BST') = 0 then begin
                        yyintval := T_BST;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'BLD') = 0 then begin
                        yyintval := T_BLD;
                        goto yy_token;
                      end;

                    end;
                  'C': begin
                      if StrComp(ID, 'CONST') = 0 then begin
                        yval := T_CONDEF;
                        goto yyexit;
                      end;
                      if StrComp(ID, 'CALL') = 0 then begin
                        yyintval := T_GOSUB;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CP') = 0 then begin
                        yyintval := T_CP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CPC') = 0 then begin
                        yyintval := T_CPC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CPI') = 0 then begin
                        yyintval := T_CPI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CPSE') = 0 then begin
                        yyintval := T_CPSE;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'COM') = 0 then begin
                        yyintval := T_COM;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLC') = 0 then begin
                        yyintval := T_CLC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLI') = 0 then begin
                        yyintval := T_CLI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLZ') = 0 then begin
                        yyintval := T_CLZ;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLT') = 0 then begin
                        yyintval := T_CLT;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLH') = 0 then begin
                        yyintval := T_CLH;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLV') = 0 then begin
                        yyintval := T_CLV;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLN') = 0 then begin
                        yyintval := T_CLN;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLS') = 0 then begin
                        yyintval := T_CLS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CBI') = 0 then begin
                        yyintval := T_CBI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CBR') = 0 then begin
                        yyintval := T_CBR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'CLR') = 0 then begin
                        yyintval := T_CLR;
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
                    end;
                  'E': begin { EEPROM END }
                      if StrComp(ID, 'END') = 0 then begin
                        yyintval := T_ASMEND;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'EOR') = 0 then begin
                        yyintval := T_EOR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ELPM') = 0 then begin
                        yyintval := T_ELPM;
                        goto yy_token;
                      end;
                    end;
                  'F': begin { FOR }
                    end;
                  'G': begin { GOTO GOSUB }


                    end;
                  'H': begin { HIGH }

                    end;
                  'I': begin { IF INPUT }
                      if StrComp(ID, 'INC') = 0 then begin
                        yyintval := T_INC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'IJMP') = 0 then begin
                        yyintval := T_IJMP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ICALL') = 0 then begin
                        yyintval := T_ICALL;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'IN') = 0 then begin
                        yyintval := T_IN;
                        goto yy_token;
                      end;
                    end;
                  'J': begin { JMP }
                      if StrComp(ID, 'JMP') = 0 then begin
                        yyintval := T_GOTO; //..
                        goto yy_token;
                      end;
                  end;
                  'L': begin
                      if StrComp(ID, 'LSR') = 0 then begin
                        yyintval := T_LSR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'LSL') = 0 then begin
                        yyintval := T_LSL;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'LPM') = 0 then begin
                        yyintval := T_LPM;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'LD') = 0 then begin
                        yyintval := T_LD;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'LDI') = 0 then begin
                        yyintval := T_LDI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'LDS') = 0 then begin
                        yyintval := T_LDS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'LDD') = 0 then begin
                        yyintval := T_LDD;
                        goto yy_token;
                      end;

                    end;
                  'M': begin
                      if StrComp(ID, 'MUL') = 0 then begin
                        yyintval := T_MUL;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'MOV') = 0 then begin
                        yyintval := T_MOV;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'MOVW') = 0 then begin
                        yyintval := T_MOVW;
                        goto yy_token;
                      end;
                    end;
                  'O': begin { OR OUTPUT }
                      if StrComp(ID, 'OR') = 0 then begin {?}
                        yyintval := T_OR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ORG') = 0 then begin {?}
                        yyintval := T_ORG;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'OUT') = 0 then begin
                        yyintval := T_OUT;
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
                    end;
                  'P': begin { PAUSE PINxx PINS PORT POT PULSIN PULSOUT PWM }
                      if StrComp(ID, 'POP') = 0 then begin
                        yyintval := T_POP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'PUSH') = 0 then begin
                        yyintval := T_PUSH;
                        goto yy_token;
                      end;
                    end;
                  'R': begin
                      if StrComp(ID, 'RJMP') = 0 then begin
                        yyintval := T_GOTO;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'RCALL') = 0 then begin
                        yyintval := T_GOSUB;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ROR') = 0 then begin
                        yyintval := T_ROR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'ROL') = 0 then begin
                        yyintval := T_ROL;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'RET') = 0 then begin
                        yyintval := T_RETURN;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'RETI') = 0 then begin
                        yyintval := T_RETI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'RETNMI') = 0 then begin
                        yyintval := T_RETNMI;
                        goto yy_token;
                      end;
                    end;
                  'S': begin { SYMBOL SERIN SEROUT SLEEP STEP SOUND }
                      if StrComp(ID, 'ST') = 0 then begin
                        yyintval := T_ST;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'STD') = 0 then begin
                        yyintval := T_STD;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'STS') = 0 then begin
                        yyintval := T_STS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SPM') = 0 then begin
                        yyintval := T_SPM;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SLEEP') = 0 then begin
                        yyintval := T_SLEEP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SWAP') = 0 then begin
                        yyintval := T_SWAP;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SUB') = 0 then begin
                        yyintval := T_SUB;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SUBI') = 0 then begin
                        yyintval := T_SUBI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBIW') = 0 then begin
                        yyintval := T_SBIW;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBC') = 0 then begin
                        yyintval := T_SBC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SEI') = 0 then begin
                        yyintval := T_SEI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SEC') = 0 then begin
                        yyintval := T_SEC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SEH') = 0 then begin
                        yyintval := T_SEH;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SEZ') = 0 then begin
                        yyintval := T_SEZ;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SET') = 0 then begin
                        yyintval := T_SET;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SEV') = 0 then begin
                        yyintval := T_SEV;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SEN') = 0 then begin
                        yyintval := T_SEN;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SES') = 0 then begin
                        yyintval := T_SES;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBI') = 0 then begin
                        yyintval := T_SBI;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBIC') = 0 then begin
                        yyintval := T_SBIC;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBIS') = 0 then begin
                        yyintval := T_SBIS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBR') = 0 then begin
                        yyintval := T_SBR;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SER') = 0 then begin
                        yyintval := T_SER;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBRS') = 0 then begin
                        yyintval := T_SBRS;
                        goto yy_token;
                      end;
                      if StrComp(ID, 'SBRC') = 0 then begin
                        yyintval := T_SBRC;
                        goto yy_token;
                      end;


                    end;
                  'U': begin { }

                    end;
                  'T': begin { THEN TO TOGGLE }
                      if StrComp(ID, 'TST') = 0 then begin
                        yyintval := T_TST;
                        goto yy_token;
                      end;
                    end;
                  'X': begin
                      if StrComp(ID, 'XOR') = 0 then begin
                        yyintval := T_EOR;
                        goto yy_token;
                      end;
                    end;
                  'V': begin

                    end;
                  'W': begin
                      if StrComp(ID, 'WDR') = 0 then begin
                        yyintval := T_WDR;
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
    a_yylex := yval;
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
end.

