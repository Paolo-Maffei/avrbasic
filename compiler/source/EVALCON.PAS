(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

Unit EvalCon;

Interface

Uses
  CompDef,
  NodePool,
  EFile,
  LstFile,
  Sysutils;

Procedure EvalConstTree(Tree: PSym);
Function EvalConstExpr(Expr: PSym): PSym;

Implementation

Function EvalConstExpr;
Var
  LB, RB,
  L, R, O: PSym;
Begin
   L := Expr;
   O := Expr^.right;
   R := O^.right;
      { Operation? }
      Case O^.yylex Of
        T_TOKEN: Begin
          Case O^.val Of
            T_AND: Begin {*}
              L^.val := L^.val and R^.val;
              StrCopy(L^.name, 'EXPR');
              DropNode(Expr^.right); DropNode(Expr^.right);
            End;
            T_OR: Begin {*}
              L^.val := L^.val or R^.val;
              StrCopy(L^.name, 'EXPR');
              DropNode(Expr^.right); DropNode(Expr^.right);
            End;
            T_EOR: Begin {*}
              L^.val := L^.val xor R^.val;
              StrCopy(L^.name, 'EXPR');
              DropNode(Expr^.right); DropNode(Expr^.right);
            End;
          End;
        End;
        T_SHR: Begin
            L^.val := L^.val shr R^.val;
            StrCopy(L^.name, 'EXPR');
            DropNode(Expr^.right); DropNode(Expr^.right);
        End;
        T_SHL: Begin
            L^.val := L^.val shl R^.val;
            StrCopy(L^.name, 'EXPR');
            DropNode(Expr^.right); DropNode(Expr^.right);
        End;
        T_MATH: Begin
          Case O^.val Of
            4: Begin {*}
              L^.val := L^.val * R^.val;
              StrCopy(L^.name, 'EXPR');
              DropNode(Expr^.right); DropNode(Expr^.right);
            End;
            7: Begin {/}
              Expr^.val := Expr^.val div Expr^.right^.right^.val;
              StrCopy(Expr^.name, 'EXPR');
              DropNode(Expr^.right); DropNode(Expr^.right);
            End;
            2: Begin {-}
              Expr^.val := Expr^.val - Expr^.right^.right^.val;
              StrCopy(Expr^.name, 'EXPR');
              DropNode(Expr^.right); DropNode(Expr^.right);
            End;
            3: Begin {+}
              Expr^.val := Expr^.val + Expr^.right^.right^.val;
              StrCopy(Expr^.name, 'EXPR');
              DropNode(Expr^.right); DropNode(Expr^.right);
            End else Begin
              Error(1033);
              DropNode(Expr^.right); DropNode(Expr^.right);
            End;
          End;
        End;
        T_LOG: Begin

        End;
      End;
      {  }

      LB := L^.left;
      RB := L^.right;

      If (LB^.yylex = T_LBRACKET) and (RB^.yylex = T_RBRACKET) Then
      Begin
        If (LB^.left^.yylex = T_EQUAL) or
           (LB^.left^.yylex = T_LBRACKET) or
           (LB^.left^.yylex = T_LBRACKET2) or
           IsBinaryOperation(LB^.left) or
           (LB^.left^.yylex = T_COMMA) Then
           Begin
             DropNode(LB); DropNode(RB);
           End;
      End;

  EvalConstExpr := L; { Return Evaluation Result! }
End;

Procedure EvalConstTree(Tree: PSym);
Var
  LL, C, L, R, O: PSym;
Begin
  {PARANOIA Safety}
  If Tree = Nil Then Exit;
  {start here}
  C := Tree;
  {*we are done*}
  If C^.Right = Nil Then Exit;
  If C^.yylex = T_NEWLINE Then Exit;
  L := C;

  Repeat
    If (L^.yylex = T_ADDR) Then
    Begin

      If (L^.right^.yylex = T_VAR) or (L^.right^.yylex = T_LABEL) Then
      Begin
        L := DropNode(L);
        If L^.yylex = T_LABEL Then L^.Val := FindLabelAddr(L^);
        If (L^.yylex = T_VAR) and ((L^.typ = sym_IO) or (L^.typ = sym_IOBit))
          then L^.val := L^.val + $20;
        L^.yylex := T_CONST;
        L^.typ := sym_CONST;
        StrCat(L^.name, '@');
        If (L^.left <> Nil) and (L^.right <> Nil) Then
        Begin
          If (L^.left^.yylex = T_LBRACKET) and (L^.right^.yylex = T_RBRACKET) Then
          Begin
            DropNode(L^.left);
            DropNode(L^.right);
          End;
        End;
      End;


    End;
    L := L^.right;
  Until L=Nil;

  L := C;
  Repeat
    LL := L^.left;
    If LL<>Nil Then
    Begin
      If (LL^.yylex = T_EQUAL) or (LL^.yylex = T_LBRACKET) or
         (LL^.yylex = T_LBRACKET2) or (LL^.yylex = T_COMMA) then
        Begin
          If L^.right = Nil Then Exit; { No Op Code }         O := L^.Right;
          If O^.right = Nil Then Exit; { No Right Operand! }  R := O^.Right;
          If R^.yylex = T_LBRACKET Then R := EvalConstExpr(R^.right);

          { We have: L O R }
          If (L^.yylex = T_CONST) and (R^.yylex = T_CONST) and
              IsBinaryOperation(O) and IsDelimitr(L^.left, 0) Then
          Begin
            EvalConstExpr(L);
          End else
            L := L^.right; { Advance to Next.. }
        End else L := L^.right; { Advance to Next.. };
    End else L := L^.right; { Advance to Next.. };
  Until L=Nil;
End;

Begin
End.