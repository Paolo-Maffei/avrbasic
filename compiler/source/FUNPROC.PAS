(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit Funproc;

interface

uses
  SysUtils,
  EFile,
  CompUt,
  CompDef,
  Common,
  NodePool,
  bs1lex;


function AddProcedure(Node: PSym): PSym; { Add New Procedure Name }
function GetFunction(Node: PSym): PSym;

procedure Init_Proc;

implementation

procedure Init_Proc;
var
  cur, next: PSym;
begin
  if ProcPool = nil then Exit;
  cur := ProcPool;
  repeat
    next := cur^.right;

    {FreeNode(cur);}

    cur := next;
  until cur = nil;

  ProcPool := nil;
end;


function AddProcedure;
var
  P, R, N,
    Param, Res,
    First, Last: PSym;
  fp: Integer;



  procedure Funtype;
  var
    v, subv, typ: integer;
  begin
    N := DropNode(N); {  Drop : }
    subv := 0;
    case N^.val of
      sym_WORD: begin
          v := 30;
          typ := sym_WORD;
        end;
      sym_DEF: begin
          v := WREG.val;
          typ := sym_DEF;
        end;
      sym_BIT: begin
          v := $3F;
          subv := 6;
          typ := sym_ioBit;
        end;
    end;
    N := DropNode(N); {  Drop type }
    if IfL(N, T_AT) then
    begin
      N := DropNode(N); {  Drop @ }
      if IfL(N, T_VAR) then
      begin
        // function @
        v := N^.Val;
        subv := N^.SubVal;
        typ := N^.Typ;
      end else begin
        error(48);
      end;
    end;
    //
    DefineSymbol('RESULT', v, subv, typ); { Z }
    if P^.mid = nil then
      P^.mid := AllocNode;
    res := AllocNode;
    res.yylex := T_VAR;
    res.typ := typ;
    res.val := v;
    res.SubVal := subv;
    P^.mid^.left := res;
  end;

begin
  P := AllocNode; { Get Node}
  if P = nil then
  begin
    Exit; { Cant get node }
  end;

  fp := 1;
  if node^.yylex = T_FUNCTION then fp := 2;

  N := DropNode(node); { Drop Fun/Proc}

  if ProcPool = nil then
  begin
    ProcPool := P; { Point to First Proc;}
  end else begin
    R := ProcPool;
    while R^.Right <> nil do { Seek For Tail}
    begin
      R := R^.Right;
    end;
    R^.Right := P; { Insert New Procedure!}
  end;

  if IfL(N^.right, T_DOT) then
  begin
    N^.right := DropNode(N^.right); { Drop Proc name }
    strcat(N^.name, '$');
    strcat(N^.name, N^.right^.Name);
    DropNode(N^.right); { Drop Proc name }
  end;

  // Set Procedure Function Params.
  with P^ do
  begin
    mid := nil; { Nothing!}
    StrCopy(name, N^.name);
    val := ip;
    yylex := T_LABEL;
    typ := fp; { Procedure ?}
  end;
  //
  DefineLabel(N, nil, 1); // Label at?
  N := DropNode(N); { Drop Proc name }
  //
  if N^.yylex = T_LBRACKET then
  begin
    // Define Function Params...
    N := DropNode(N); {  Drop ( }
    P^.mid := AllocNode; { We Have Params! }
    Param := AllocNode; { 1st Parameter }
    P^.mid^.right := Param; { Place to Param Tree }

    { Procedure ProcName(ident: Type; ident: type);  }

    { Process Formal Paramaters }
    while N^.yylex = T_LABEL do
    begin
      StrCopy(Param^.name, N^.name);
      First := Param; {First Param of same kind }
      Last := Param;
      { Process}
      N := DropNode(N); { Drop Name }
      while N^.yylex = T_COMMA do
      begin
        N := DropNode(N); { Drop , }
        if N^.yylex = T_LABEL then
        begin
          Param := AllocNode;
          StrCopy(Param^.name, N^.name);

          Last^.right := Param;
          Last := Param;

          N := DropNode(N); { Drop Name }
        end else begin
          { error }
        end;
      end;
    end;
    // Process TYPE
    // i:byte @ ;
    if N^.yylex = T_COLON then
    begin
      N := DropNode(N); // Drop Colon
      //----------
      case N^.val of
        sym_DEF: begin
            repeat
              N := DropNode(N); { Drop TYPE SPECIFIER }
              with First^ do
              begin
                val := wreg_def;
                subval := 0;
                yylex := T_VAR;
                typ := sym_DEF;
              end;
              if IfL(N, T_AT) then
              begin
                N := DropNode(N); { Drop @ }
                First^.val := N^.Val;
                N := DropNode(N); { Drop .. }
              end;
              DefineSymbol(First^.name, First^.val, 0, sym_DEF);
              First := First^.right;
            until First = nil;
          end;

        sym_WORD: begin
            repeat
              N := DropNode(N); { Drop TYPE SPECIFIER }
              with First^ do
              begin
                val := 30;
                subval := 0;
                yylex := T_VAR;
                typ := sym_WORD;
              end;
              if IfL(N, T_AT) then
              begin
                N := DropNode(N); { Drop @ }
                First^.val := N^.Val;
                N := DropNode(N); { Drop .. }
              end;
              DefineSymbol(First^.name, First^.val, 0, sym_WORD);
              First := First^.right;
            until First = nil;
          end;

        sym_BIT: begin
            repeat
              N := DropNode(N); { Drop TYPE SPECIFIER }
              with First^ do
              begin
                val := $3F; subval := 6;
                yylex := T_VAR; typ := sym_ioBit;
              end;
              if IfL(N, T_AT) then
              begin
                N := DropNode(N); { Drop @ }
                First^.val := N^.Val;
                First^.subval := N^.subVal;
                First^.typ := N^.typ;
                N := DropNode(N); { Drop .. }
              end;
              DefineSymbol(First^.name, First^.val, First^.subval, First^.typ); { SREG.6 }
              First := First^.right;
            until First = nil;
            N := DropNode(N); { Drop TYPE SPECIFIER }
          end;
      end;

      //---------------
      if N.yylex = T_RBRACKET then
      begin
        N := DropNode(N); {  Drop : }
        // Check for Function Type
        if N^.yylex = T_COLON then
          Funtype;
      end;
    end;
  end else
  begin
    // Check for function with no params!
    if N^.yylex = T_COLON then
      Funtype;
  end;
end;

{
  Get Pointer to Function/Proc
}

function GetFunction(Node: PSym): PSym;
var
  N: PSym;
begin
  GetFunction := nil;
  N := ProcPool;
  if N = nil then Exit;

  while N <> nil do
  begin
    if se(N^.Name, Node^.Name) then
    begin
      GetFunction := N;
      Exit;
    end;
    N := N^.right;
  end;
end;

begin
  ProcPool := nil;
end.

