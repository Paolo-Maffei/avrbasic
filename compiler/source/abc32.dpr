(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

program abc32;
{$APPTYPE CONSOLE}
uses
  SysUtils,
  uCompile;

begin
  if ParamCount <> 1 then
  begin
    Writeln('AVR Basic Compiler (Beta 1.0.1)');
    Writeln('http://www.trioflex.com');
    Writeln('Copyright 1997-2002 Silicon Studio Ltd.');
    Writeln('Copyright 2008 Trioflex OY');

    Writeln;
    Writeln('Usage avrcomp filename.bas');
    exit;
  end;
  CompileFile(ParamStr(1));

  Writeln('done');
  halt(0);

end. 