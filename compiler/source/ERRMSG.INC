(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)


Const
  err_Unknown = 0;
  err_base = 10;

  err_Undefined_Label            = err_base+1;
  err_Undefined_Symbol           = err_base+2;
  err_Double_Label               = err_base+3;
  err_Next_Without_For           = err_base+4;
  err_Too_Many_For_Next_Nestings = err_base+5;
  err_Until_Without_Repeat       = err_base+6;
  err_Too_Many_Repeat_Nestings   = err_base+7;
  err_Error_In_Symbol_Definition = err_base+8;
  err_For_Variable_Type          = err_base+9;
  err_For_Next_Syntax            = err_base+10;
  err_branch_out_of_range        = err_base+11;
  err_open_repeat                = err_base+13;
  err_open_for                   = err_base+14;
  err_cannot_open_include        = err_base+15;
  err_trash                      = err_base+16;
  err_jmp_optimize_failed        = err_base+17;
  err_syntax                     = err_base+18;
  err_var_type                   = err_base+19;
  err_var_required               = err_base+20;
  err_else_without_if            = err_base+21;

  err_Unimplemented              = err_base+100;
  err_Demo_Limit                 = 9999;

{$IFDEF WIN32}

Resourcestring
  rcTrash = 'Trash at end of line';
  rcUndefLabel = 'Undefined Label';
  rcUndefSymbol = 'Undefined Symbol';
  rcDoubleLabel = 'Double defined Label';
  rcNextWithoutFor = 'NEXT without FOR';
  rcIncludeNotFound = 'Include File not found';
  rcJmpOptimizeFailed = 'Branch Optimization Failed';
  rcSyntax            = 'Syntax Error';
  rcBadVarTyp = 'Variable Type not supported';
  rcVarRequired = 'Variable required';

  rcDemoLimit = 'Demo Limit Exceeded!';

{$ENDIF}

