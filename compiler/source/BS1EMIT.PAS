(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit BS1Emit;

interface

uses
  AVRCore,
  ToolSrv,
  SysUtils,
  MStrings,
  CompUt,
  CompDef, { Compiler Definitions           }
  NodePool, { Symbol Nodes/Handling          }
  FunProc,
  //  VisCo, { Visual Components              }
  ObjFiles, { Object File Generation         }
  LstFile, { Listing File Generation        }
  EFile, { Error Report/Handling          }
  emit,
  prefer,
  Common,
  Pars_AVR,

  blex, alex,
  BS1Lex;

procedure CompileBS1;


implementation


procedure CompileBS1;
label
  next_error;
var
  I, J, K: Integer;
  l1, l2: Longint;
  F: Integer;
  op, X1, X2,
    V, V1, V2: Word;
  Null: Tsym;
  S: string;
  strV: array[0..100] of Char;
  yylex_i: integer;

begin
  yytext := 0;
  PLineBuf := Buf;
  dodislisting := true;
  basic := True;

  yylex := b_yylex;
  mode := 0; // basic mode
  Parse := Parse_AVR;

  if pass = -1 then
  begin
    ClearLibCalls; // Clear Required Lib Calls!

    DoInitStack := False;
    userstackok := False;
    stackneeded := False;

    Demo := True;
    doLibrary := False;

    uselinenuminfo := false;
    repeat
      yylex_i := yylex; 
      case yylex_i of
        ord(T_LIBRARY): begin
            doLibrary := True;
          end;
        // Process Uses Clauses!
      end;
    until yyeof;
    // ?
    Demo := False;

    last_branch_out := 0;
    for I := 0 to 31 do vectors[I] := $FFFFFFFF;

    bIntUsesSREG := False;
    bIntUsesWREG := False;

    Exit;
  end;

  mode := 0; // basic mode
  for i:=0 to yyMaxSyms-1 do syms^[i].name := '';
  cpu := 1200;
  assume_none;
  use_eewait := True;
  next_branch_out := 0;

  bit_free := 0;
  bit_vars := 0;

  be := 0;
  last_line := 0;
  last_error := 0;
  locp := 0; { we are in Main }

  next_code := 0;

  filenum := 1;
  IncFilenum := 1;
  cFileNum := 1;

  ip := 0;

  next_repeat := 0; repeat_cnt := 0;
  next_sw := 0; sw_cnt := 0;
  next_if := 0; if_cnt := 0;
  bep := 0;
  cend := 0;
  e2[cend] := 0;
  e2m := 0;
  inobject := False;

  Init_Proc; // Init Ptocedure Handlers!

  { Init on Each Pass! }

  case Family of
    AVR: Init_AVR;

  else begin
      Error(300);
    end;
  end;

  last_predef := next_sym;
  segment := 0;

  linenum := 1;
  blst := True;

  yyl := @Null; yyl^.Right := nil; yyl^.Left := nil;

  { Process Lines... }
  repeat
    last_line := linenum;
//    if not LimitOK then Exit;

// todo limit

    InitNodes;
    { Left Marker }
    yyc := yyl;
    breduce := False;
    K := 0;
    repeat
      yylast := yylex; { LEXER Is HERE! }

      { insert yyn to tree! }
      yyc^.Right := yyn; yyn^.Left := yyc;
      yyn^.Right := nil; yyc := yyn;

      if (yylast = T_SKIP) or ((yylast = T_TOKEN) and (yyn^.val = T_REPEAT)) then
      begin
        yyn := Newnode;
        if yyn <> nil then
        begin
          yyn^.yylex := T_NEWLINE;
          yyn^.Left := yyc; yyn^.Right := nil;
          yyc^.Right := yyn; yyc := yyn;
          yylast := T_NEWLINE;
        end;
      end;

    until yyeof or {(yylast = T_COLON) or}
    (yylast = T_NEWLINE) or (K > (maxtok - 1));

    bGoto := True;
    bpre := 0; bpost := 0;

    if yylast = T_NEWLINE then
    begin
      if blst then
      begin
        emit_lst_comment;
        inc(linenum);
        blst := False;
      end;
      if Buf[yytext - 1] = #13 then
      begin
        blst := True;
      end;
    end;

    yy0 := yyl^.Right;
    Parse;

    next_error:
      { ### Skip to next Statement Error(err_Unknown); }
  until yyeof; { Until Buf Done }
  Exit_Pass_AVR;


  if pass >= 0 then Link_AVR;

  { Blah, finished }
  { Fixup Records.. }
  if pass = 0 then last_branch_out := next_branch_out;

  if pass = last_pass then
  begin

  WriteToolOutput('L P');

    linenum := 0;
{
    if next_for <> 0 then
    begin 
      Error(err_open_for); 
    end;
    if next_repeat <> 0 then
    begin 
      Error(err_open_repeat); 
    end;
    if be<>0 then Error(9996);
}
  WriteToolOutput('L P1');

//    tc(#13#10 + '* PROCEDURES *'#13#10);
//    tr(ProcPool);

    case Family of
      AVR: begin
try
       Exit_AVR;
except
  WriteToolOutput('Excep');
end;

  WriteToolOutput('L P1a');

      end; 
      // PIC: Exit_PIC;
    end;

  WriteToolOutput('Exit done');

{$IFDEF WIN32}
    {
    For I := 0 To 4095 Do
    Begin
      ROM16^[I] := CODEMEM[I];
    End;
    }
{$ENDIF}

    lastip := ip;
    ip := 0;

  end; { Pass = last_pass }
end;

begin
  Core := TAVRCore.Create(Nil);
  
  used_ee := 0;
  ip := 0;
  nlines := 0;
  hextyp := 1;

  Parse := Parse_AVR;
end.

