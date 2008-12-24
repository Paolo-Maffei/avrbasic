(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit common;

interface

//Uses
//  StdCtrls,
//  Buttons;


Const
  last_pass = 10;
  max_opt_passes = 8;
Var
  jmp_opt_failed: Boolean;  
  Breaks: Array[0..1023] Of Integer;
  mode: integer;

Type
  TWARRAY16 = ^WARRAY16;
  WARRAY16 = ARRAY[0..65535] Of Word;
  TWORD16 = ^WORD;

  TWARRAY8 = ^WARRAY8;
  WARRAY8 = ARRAY[0..65535] Of Byte;
  TWORD8 = ^BYTE;

Var
  ROM: Array[0..65535] Of Byte;
  ROM16: TWARRAY16;
  ROM8: TWARRAY8;

  RAM1: Array[0..65535] Of Byte;
  RAM: TWARRAY8;

  RAM2: Array[0..65535] Of Byte;
  IO: TWARRAY8;

  RAM3: Array[0..65535] Of Byte;
  EEPROM: TWARRAY8;

Var
  ip, lastip: Word;
  clock: Longint;
  running: Boolean;

  bit_free,
  bit_vaddr,
  bit_vars: Integer;
  disasmtyp: Integer;


implementation

Begin
  ROM16  := @ROM;
  ROM8   := @ROM;
  RAM    := @RAM1;
  IO     := @RAM2;
  EEPROM := @RAM3;

  running := False;
  disasmtyp := 0;
  mode := 0;
end.
