(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

Unit NodePool;

Interface

Uses
  SysUtils,
  MStrings,
  CompDef,
  Common,
  CompUt,
  LstFile,
  EFile;

Var
  ProcPool,
  FreeHead,
  FreeTail: PSym;

Var
  Nodes: Array[0..maxtok] Of TSym;

Var
  yyn,yyc,
  yyl,yyr,
  yyd,yys,
  yy0,yy1,yy2,yy3, yy4: PSym;

  TmpLab: PLab;
  NoLab: TLab;                              // No Label, dummy }
  TmpIO,
  SwLab,                                    //
  NULL,                                     // NULL Always
  Z16,                                      // 8/16 Z Register
  Con: TSym;

{badf}
Function FindLabelAddr(T: TSym): Integer;

Function NewNode: PSym;                     { Get New Node }
Function DropNode(Node: PSym): Psym;        { Drop Node    }

Function AllocNode: PSym;                   { Alloc New Node }
Procedure FreeNode(Node: PSym);             { Free Node  (Single) }

Procedure InitNodes;                        { Init Free Node Pool }

Function IsVariable(Node: PSym): Boolean;
Function IsBitVariable(Node: PSym): Boolean;
Function IsBinaryOperation(Node: PSym): Boolean;
Function IsDelimitr(Node: PSym; Typ: Integer): Boolean;
Function IsFunction(Node: Psym): Integer;
Function IsW(Node: PSym): Boolean;
Function IfL(Node: PSym; v: Integer): Boolean;

Procedure MakeConst(T: PSym; Value: Integer);
Procedure tr(N: PSym);

Procedure DefineSymbol(name: String; Value: Integer; SubVal, Typ: Word);
Procedure DefineLocalSymbol(name: String; Value: Integer; SubVal, Typ: Word);

Procedure DefineLabel(Lab: Psym; Addr: PSym; typ: Byte);
Procedure InsertLabel(Name: String; typ: Integer);

Function FindLabel(T: PSym): PLab;

Function nstr(Node: PSym): String;

Implementation

{ vale koht! }
Procedure Assume_None;
Begin

  rambank := -1;
  wreg_val := -1;

End;

Function NewNode;
{$IFNDEF WIN32}
Var Result: PSym;
{$ENDIF}
Begin
  If FreeTail = Nil Then
  Begin
    NewNode := @NULL;
    NULL.right := @NULL;
    NULL.right := @NULL;
    Exit;
  End;
  Result := FreeTail;
  If FreeTail^.Left = Nil Then
  Begin
    NewNode := Result;
    Exit;
  End;

  FreeTail := FreeTail^.Left;
  FreeTail^.Right := Nil;
  { Not Connected }
  Result^.Left := Nil;
  Result^.Right := Nil;

{$IFNDEF WIN32}
  NewNode := Result;
{$ENDIF}


End;

Function DropNode;
Begin
  If Node = Nil Then Exit;
  { We cant Drop Nil! }
  With Node^ Do Begin
    If Left <> Nil Then Left^.Right := Right;
    If Right  <> Nil Then Right^.Left := Left;
    DropNode := Right;
    Left := FreeTail;
    Right := Nil;
  End;
  FreeTail^.Right := Node;          { Link as to the last node      }
  FreeTail := Node;
End;

Procedure InitNodes;
Var
  i: Integer;
Begin
  FreeHead := @Nodes[0];
  FreeHead^.Right := @Nodes[1];
  FreeHead^.Left := Nil;
  For i := 1 to maxtok-1 Do Begin
    Nodes[i].Left := @Nodes[i-1];
    Nodes[i].Right := @Nodes[i+1];
  End;
  FreeTail := @Nodes[maxtok];
  FreeTail^.Left := @Nodes[maxtok-1];
  FreeTail^.Right := Nil;
End;

{ }
Function IsVariable;
Begin
  IsVariable := False;
  If Node^.yylex = T_VAR Then IsVariable := True;
End;

Function IsBitVariable;
Begin
  IsBitVariable := False;
  If Node^.yylex = T_VAR Then Begin
    If Node^.typ = sym_Bit Then IsBitVariable := True;
    If Node^.typ = sym_ioBit Then IsBitVariable := True;
  End;
End;

Function IsDelimitr(Node: PSym; Typ: Integer): Boolean;
Begin
  IsDelimitr := False;
  If Node=Nil Then Exit;
  Case Typ Of
    0: Begin
     If Node^.yylex = T_EQUAL Then Begin IsDelimitr := True; Exit; End;
     If Node^.yylex = T_LBRACKET Then Begin IsDelimitr := True; Exit; End;
     If Node^.yylex = T_LBRACKET2 Then Begin IsDelimitr := True; Exit; End;
     If Node^.yylex = T_COMMA Then Begin IsDelimitr := True; Exit; End;
    End;
  End;

End;

Function IsBinaryOperation;
Begin
  IsBinaryOperation := False;
  If Node^.yylex = T_EQUAL Then Begin IsBinaryOperation := True; Exit; End;
  If Node^.yylex = T_MATH Then Begin IsBinaryOperation := True; Exit; End;
  If Node^.yylex = T_SHR Then Begin IsBinaryOperation := True; Exit; End;
  If Node^.yylex = T_SHL Then Begin IsBinaryOperation := True; Exit; End;
  If Node^.yylex = T_TOKEN Then
  Begin
    Case Node^.val Of
      T_AND, T_OR, T_EOR: IsBinaryOperation := True;
    End;
    Exit;
  End;
End;


Procedure tr;
Var
  T: PSym;
Begin
  If N = Nil Then Exit;
  If pass<last_pass Then Exit;
  {  If not cc_Trace_On then Exit;  }
  {  Exit;  }
  T := N;
  While T <> Nil Do
  Begin
    Write_Sym(T^);
    If T^.mid <> Nil Then
    Begin
      tr(T^.mid^.right);
    End;
    T := T^.right; { Get Next..}
  End;
End;

Procedure DefineSymbol;
var I: integer;
Begin
  If next_sym >= yyMaxSyms Then
  Begin
    Error(986);
    Exit;
  End;

  If locp <> 0 Then
  Begin
    DefineLocalSymbol(name, Value, SubVal, Typ);
    Exit;
  End;

{$R-}
  for i:=0 to next_sym do
    if Syms^[i].name = name then
     error(120);
    
  StrPCopy(Syms^[next_sym].Name, name);
  Syms^[next_sym].subval := subval;
  Syms^[next_sym].Typ := typ;
  Syms^[next_sym].val := value;
  Syms^[next_sym].yylex := T_VAR;

  if typ = sym_IO then Syms^[next_sym].val := (value and $FF);
  if typ = sym_ioBIT then Syms^[next_sym].val := (value and $FF);
  if typ = sym_WORD then Syms^[next_sym].val := (value and $FF);
  if typ = sym_CONST then Syms^[next_sym].yylex := T_CONST;

  Inc(next_sym);
End;

Procedure DefineLocalSymbol;
Begin
  StrPCopy(LocalSyms[next_local_sym].Name, name);
  LocalSyms[next_local_sym].subval := subval;
  LocalSyms[next_local_sym].Typ := typ;
  LocalSyms[next_local_sym].val := value;
  LocalSyms[next_local_sym].yylex := T_VAR;

  if typ = sym_IO then LocalSyms[next_local_sym].val := (value and $7F);
  if typ = sym_ioBIT then LocalSyms[next_local_sym].val := (value and $7F);
  if typ = sym_WORD then LocalSyms[next_local_sym].val := (value and $7F);
  if typ = sym_CONST then LocalSyms[next_local_sym].yylex := T_CONST;

  Inc(next_local_sym);
End;

Function FindLabel;
Var
    i: Integer;
Begin
    FindLabel := @NoLab;
    i := 0;
    While i<next_lab Do
    Begin
       If StrComp(Labels[i].Name, T^.Name) = 0 Then
       Begin
          FindLabel := @Labels[i];
          Break;
        End;
        Inc(i);
    End;
End;

Procedure InsertLabel;
Var
  i: Integer;
  a: Word;
  nn: Array[0..33] Of Char;
Begin
 StrPCopy(nn, name);
 if pass>0 then
 Begin
   i := 0;
   While i<next_lab Do
   Begin
	 If se(Labels[i].Name, nn) Then
     Begin
	   If Labels[i].addr = undefined Then
       Begin
         Error(err_Undefined_Label);
	   End else
       Begin
         Labels[i].addr := ip; Labels[i].typ := typ;
         assume_none; {??}
       End;
       Break;
     End;
     Inc(i);
   End;
   if i=next_lab Then
   Begin
     Error(err_Undefined_Label);
   End;
 End;

 if pass=0 then
 Begin
   i := 0;
   While i<next_lab Do Begin
     If StrComp(Labels[i].Name, nn) = 0 Then
     Begin
	   If Labels[i].addr = undefined Then
       Begin
		 Labels[i].addr := ip;
         Labels[i].typ := typ;

         assume_none; { ?? }
	   End else Begin
         Error(err_Double_Label);
       End;
       Break;
     End;
     Inc(i);
   End;

   { add label}
   if i=next_lab Then
   Begin
     StrCopy(Labels[next_lab].Name, nn);
	 Labels[next_lab].addr := ip;
     Labels[i].typ := typ;
	 inc(next_lab);
     {??}
     assume_none; { ?? }
     End;
   End;
End;



Procedure DefineLabel;
Var
  i: Integer;
  a: Word;
  ipfix: Integer;
Begin
 If Lab = Nil Then Exit;
 ipfix := ip;
 if segfix and (segment=1) then
   ipfix := ip * 2;

 //
 // Pass <> 0
 //
 if pass > 0 then
 Begin
   i := 0;
   While i<next_lab Do
   Begin
     If StrComp(Labels[i].Name, Lab^.Name) = 0 Then
     Begin
       If Labels[i].addr = undefined Then
       Begin
         Error(err_Undefined_Label);
       End else Begin
           if Labels[i].addr <> ipfix then
           begin
             jmp_opt_failed := True;
             If pass = last_pass then
             begin
               Error(err_jmp_optimize_failed);
             End;
           end;
         Labels[i].addr := ipfix;
         Labels[i].typ := typ;
         assume_none;
       End;
       Break;
     End;
     Inc(i);
   End;
   if i=next_lab Then
   Begin
     Error(err_Undefined_Label);
   End;

   Exit;
 End;
 //
 // pass = 0
 //
 if pass = 0 then
 Begin
   i := 0;
   While i<next_lab Do Begin
     If StrComp(Labels[i].Name, Lab^.Name) = 0 Then
     Begin
       If Labels[i].addr = undefined Then
       Begin
         Labels[i].addr := ipfix;
         Labels[i].typ := typ;
         assume_none; { ?? }
       End else Begin
         nooptpasses := True;
         ForcedError(err_Double_Label);
         Exit; // !!
       End;
       Break;
     End;
     Inc(i);
   End;

   { add label}
   if i=next_lab Then
   Begin
     StrCopy(Labels[next_lab].Name, Lab^.Name);
     Labels[next_lab].addr := ipfix;
     Labels[i].typ := typ;
     inc(next_lab);
     {??}
     assume_none; { ?? }
   End else begin
      Error(1235);
   end;
 End;

End;

Function IsFunction(Node: Psym): Integer;
Var
  i: Integer;
  N: PSym;
Begin
  IsFunction := -1;

  i := 0;
  While i<next_lab Do
  Begin
    If StrComp(Labels[i].Name, Node^.Name) = 0 Then
    Begin
      If (Labels[i].typ = 2) or (Labels[i].typ = 3) Then
      Begin
        IsFunction := Labels[i].typ;
        Exit;
      End;
    End;
    Inc(i);
  End;

  N := ProcPool;
  If N = nil Then Exit;

  While N^.right <> Nil Do
  Begin
    If se(N^.Name, Node^.Name) Then
    Begin
      IsFunction := N^.Typ;
      Exit;
    End;
    N := N^.right;
  End;
End;



Function FindLabelAddr(T: TSym): Integer;
Var
  i: Integer;
Begin
    FindLabelAddr := 0;
    i := 0;
    While i<next_lab Do
    Begin
	   If StrComp(Labels[i].Name, T.Name) = 0 Then
       Begin
          FindLabelAddr := Labels[i].addr;
          Break;
        End;
        Inc(i);
    End;
End;

Procedure MakeConst;
Begin
  With T^ Do
  Begin
    yylex := T_CONST;
    typ := sym_Const;
    val := value;
  End;
End;

Function IsW;
Begin
  IsW := False;
  If Node = Nil Then Exit;
  If (Node^.val = wreg_def) and (Node^.yylex = T_VAR) Then IsW := True;
End;

Function IfL;
Begin
  IfL := False;
  If Node = Nil Then Exit;
  If Node^.yylex = v Then IfL := True;
End;

Function AllocNode;
{$IFNDEF WIN32}
Var Result: PSym;
{$ENDIF}

Begin
  GetMem(Result, SizeOf(TSym));
  Result^.left := Nil;
  Result^.mid := Nil;
  Result^.right := Nil;
  AllocNode := Result;
End;

Procedure FreeNode;
Begin
  FreeMem(Node, SizeOf(TSym));
End;

Function nstr(Node: PSym): String;
Var N: PSym;
Begin
  Result := '';
  If Node = Nil Then Exit;

  N := Node;
  Result := Result + Chr(N^.val and $FF);
  N := DropNode(N);
  While IfL(N, T_COMMA) Do
  Begin
    N := DropNode(N);             { Drop Comma }
    Result := Result + Chr(N^.val and $FF); { Append     }
    N := DropNode(N);             { Drop Value }
  End;
End;



Begin
  NoLab.Addr := undefined;
  NoLab.Typ := 0;

  SwLab.yylex := T_LABEL;
  SwLab.Typ := 0;

  Con.yylex := T_CONST;
  Con.Typ := sym_Const;
  Con.val := 0;
  Con.subval := 0;

  TmpIO.yylex := T_VAR;
  TmpIO.val := 0;
  TmpIO.typ := sym_IO;

  Z16.yylex := T_VAR;
  Z16.Typ := sym_WORD;
  Z16.Val := 30;      // ZL
  Z16.SubVal := 0;




End.