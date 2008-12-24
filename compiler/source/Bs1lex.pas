(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit bs1lex;

interface

Uses
    CompDef,
    NodePool,
    LstFile,
    emit,
    prefer,
    AsmSub,
    MStrings,
    SysUtils,
    blex;

Type TPROC = Procedure;
Var Parse: TPROC;

Type
  tyylex = Function : Integer;
var
  yylex: tyylex;

Procedure emit_lst_comment;

implementation

Procedure emit_lst_comment;
Var
  i, j, k: Integer;
Begin
  if pass<10 then Exit;

  StrCopy(LineBuf, '');
  i := yytext-2;
  if i<0 then i := 0;

  j := 0;
  while (i>0) and (j<250) and (Buf[i] <> #13) Do
  Begin
    dec(i); inc(j);
  End;
  inc(i);
  if i = 1 then i := 0;

  j := 0;
  If Buf[i] = #10 Then Inc(i);
  while (j<250) and (Buf[i] <> #13) Do
  Begin
    LineBuf[j] := Buf[i];
    inc(i); inc(j);
  End;
  LineBuf[j] := #0;
            
  if p_lstfile then
    WrLstLine('      ' + LineBuf);
  LastLstLine := StrPas(LineBuf);
End;



begin
  yylex := b_yylex;


end.{ Of Unit }
