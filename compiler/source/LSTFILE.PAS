(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

Unit LstFile;

Interface

Uses
  Streams,
  AsmSub,
  CompDef,
  Common,
  emit,
  prefer,
  SysUtils,
  MStrings;

Procedure Write_Lab(n: Integer);
Procedure Write_Sym(Syms: Tsym);

Procedure tc(com: String);
Procedure c(com: String);
Procedure emit_comment(com: String);
Procedure emit_trace(n: Integer; s: String; a,b,c,d,f: TSym);

Procedure OpenLstFile;
Procedure CloseLstFile;

Implementation

Var
  LineBuf: Array[0..255] Of Char;

Procedure OpenLstFile;
Begin
  ClearListOutput;
End;


Procedure CloseLstFile;
Var
  i: Integer;
Begin
    if not p_lstfile then exit;

    WrLstLine('');
    WrLstLine('* SYMBOL TABLE *');

    For i:= last_predef To next_sym-1 do Write_Sym(Syms^[i]);

    WrLstLine('');
    WrLstLine('* LABELS *');

    For i:= 0 To next_lab-1 do Write_Lab(i);

    WrLstLine('');
    WrLstLine('Program Memory used : ' + IntToStr(ip) + ' words');
    WrLstLine('Internal EEPROM used: ' + IntToStr(used_ee) +  ' bytes');
    WrLstLine('Errors: ' + IntToStr(yyemit_errors));

//    WrLstLine('Symbols: ', next_sym - last_predef, ', Max = ', yyMaxSyms);
//    WrLstLine('Labels: ',  next_lab, ', Max = ', yyMaxLabels);

    WrLstLine('');
End;

Procedure Write_Sym(Syms: Tsym);
Var
  s: String;
Begin
{
      StrLCopy(LineBuf, Syms.Name,32);
      StrCat(LineBuf, '                                        ');
      LineBuf[32] := #0;

      Case Syms.yylex of
        T_NEWLINE: Begin
          Write(ofile, '<NEW LINE>  ');
        End;
        T_TOKEN: Begin
          Write(ofile, LineBuf, '  ');
          Write(ofile, 'TOKEN       ');
        End;
        T_LABEL: Begin
          Write(ofile, LineBuf, '  ');
          Write(ofile, 'LABEL       ', L2HEX( Syms. val, 4) );
        End;
        T_23: Begin
          Write(ofile,  '#');
        End;
        T_COLON: Begin
          Write(ofile,  ':');
        End;
        T_EQUAL: Begin
          Write(ofile,  '=');
        End;
        T_EEPROM: Begin
          Write(ofile,  'EEPROM');
        End;
        T_SYMBOL: Begin
          Write(ofile,  'Symbol      ');
        End;
        T_LBRACKET: Begin
          Write(ofile,  '(');
        End;
        T_RBRACKET: Begin
          Write(ofile,  ')');
        End;
        T_LBRACKET2: Begin
          Write(ofile,  '[');
        End;
        T_RBRACKET2: Begin
          Write(ofile,  ']');
        End;
        T_TYPEDECL: Begin
            Write(ofile, 'TYPE DECLARATION ' + I2S(Syms.Val,2) );
        End;
        T_MATH: Begin
          Case Syms.Val Of
            2: Write(ofile, '-');
            3: Write(ofile, '+');
            4: Write(ofile, '*');
            6: Write(ofile, '/');
          End;
        End;
        T_VAR,
        T_CONST: Begin
          Write(ofile, LineBuf, '  ');
          Case Syms.Typ Of
            sym_Const: Write(ofile,  'CONST       ');
            sym_DEF:   Write(ofile,  'REG VAR     ');
            sym_sDEF:  Write(ofile,  'SRAM BYTE   ');
            sym_BIT:   Write(ofile,  'REG VAR BIT ');
            sym_IO:    Write(ofile,  'I/O REG     ');
            sym_ioBIT: Write(ofile,  'I/O REG BIT ');
            sym_EE:    Write(ofile,  'EEPROM VAR  ');
            sym_WORD:  Write(ofile,  'WORD VAR    ');
            sym_ROM:   Write(ofile,  'ROM CONST   ');
          End;
          Write(ofile, L2HEX(Word(Syms.Val),4));
          Case Syms.Typ Of
            sym_DEF: Begin
              If Syms.SubVal > 1 Then
                Write(ofile,  '['+ I2S(Syms.SubVal,2) + ']');
            End;
            sym_BIT,
            sym_ioBIT: Write(ofile,  '.',L2HEX(Syms.SubVal,1));
          End;
        End else begin
          Write(ofile,  '? ', Syms.Name, ' ', Syms.Typ, ' ', Syms.Val, ' ', Syms.SubVal);
        end;
      End;

      Writeln(ofile);
     }
End;

Procedure Write_Lab(n: Integer);
Begin
  StrLCopy(LineBuf, Labels[n].Name,32);
  StrCat(LineBuf, '                                        ');
  LineBuf[32] := #0;
  WrLstLine(StrPas(LineBuf) +  '  ' + L2HEX(Labels[n].Addr,4) + ' ' + I2S(Labels[n].typ,2) );
End;

{ Trace }

Procedure emit_trace;
Begin
  if pass<10 then Exit;
{
  Writeln(ofile, '********************************************************************');
  Writeln(ofile, 'Trace: ', s);
  Write_Sym(a);
  if n>1 then Write_Sym(b);
  if n>2 then Write_Sym(c);
  Writeln(ofile, '********************************************************************');
}
End;

{ Copy Source to .LST }

Procedure emit_comment; begin
  if Pass<10 Then Exit;
   WrLstLine(com);
end;

Procedure c;
begin
  WrLstLine(com + ' ' + I2S(pass,2) );
end;

Procedure tc;
begin
  If pass<10 then exit;
  if p_lstfile then
     WrLstLine( com );
end;

Begin
End.

