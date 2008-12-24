(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

Unit UNAVR;

Interface

Uses
  AVRCore,
  CompDef,
  Common;

Function Disasm_AVR_Code(Code: Cardinal):String;

Implementation

Function Disasm_AVR_Code;
Begin
//  core.ip := ip;
  result := core.Disasm(@code);  //fix 32 bit  m,jg426672
End;

End.