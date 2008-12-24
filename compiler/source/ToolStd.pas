(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit ToolStd;

// Copyright 2000 Case2000
// Generic Services for Tool Output Processing.
// Must compile/link under Delphi/FPC and run in console/gui mode.

interface

uses
  EventIntf,
  C2Types;

var
  WriteStdOutput: TWriteStringProc;
  WriteStdError: TWriteStringProc;

  GetErrorLineNumber: TGetErrorLineNumberProc;
  GetErrorFileName: TGetErrorFileNameProc;

  ClearErrorOutput: TClearErrorOutput;

procedure AbstractStringWrite(line: string);
procedure AbstractClearErrorOutput;

implementation

// Raise exception ?

procedure AbstractClearErrorOutput;
begin
//  raise EAbstractError.Create('Abstract Error[ClearErrorOutput]');
  DebugWrite('AbstractClearErrorOutput');
end;

procedure AbstractStringWrite(line: string);
begin
//  raise EAbstractError.Create('Abstract Error[StringWrite]');
  DebugWrite('AbstractStringWrite '+line);
end;

// Return unknown line number always

function AbstractGetErrorLineNumber(str: string): integer;
begin
  result := -1;
end;

initialization
  WriteStdOutput := @AbstractStringWrite;
  WriteStdError := @AbstractStringWrite;
  ClearErrorOutput := @AbstractClearErrorOutput;

finalization

end.
