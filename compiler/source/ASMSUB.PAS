(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit asmsub;

interface

uses
  streams,
  sysutils;

// faker

procedure WrLstLine(val:string);
procedure Killsuffix(val:string);
procedure Addsuffix(val: string; suf:string);

implementation

procedure WrLstLine(val:string);
var
  line: Array[0..255] of char;
begin
  StrPCopy(line, val+#13);
  ListStream.Write(line, length(val)+1);
end;

procedure Killsuffix;
begin
  if pos('.', val) <> 0 then
    Delete(val, pos('.', val), 4);
end;

procedure Addsuffix;
begin
  val := val + suf;
end;


end.
