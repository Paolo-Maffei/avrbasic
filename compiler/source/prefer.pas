(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit prefer;

interface

uses
   SysUtils;

Var
  p_coff,
  p_syntax,
  p_test,
  p_errfile,
  p_lstfile,
  p_xrfile,
  p_hexfile,
  p_hexfile2,
  p_objfile: Boolean;

  has_vec2,
  DoInitStack,
  userstackok,
  stackneeded: Boolean;

  RootDir: String;


implementation

begin
  p_objfile := True;
  p_hexfile := True;
  p_lstfile := True;
  p_syntax := false;
  //
  p_coff := false;
  //
 // RootDir := ExtractFilePath(Application.Exename);
  RootDir := '';

  //Delete(RootDir, length(Rootdir)-7,7);

end.
