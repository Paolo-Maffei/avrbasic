(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit streams;

interface

Uses
  Classes;
//
// Very common Things!
//
Var
  HexStream,
  ObjectStream,
  ListStream: TMemoryStream;

Procedure ClearListOutput;
Procedure ClearObjectOutput;
Procedure ClearHexOutput;

implementation

Procedure ClearListOutput;
Begin
  If ListStream = Nil then ListStream := TMemoryStream.Create;
  ListStream.Clear;
  ListStream.Seek(0,0);
End;

Procedure ClearObjectOutput;
Begin
  If ObjectStream = Nil then ObjectStream := TMemoryStream.Create;
  ObjectStream.Clear;
  ObjectStream.Seek(0,0);
End;

Procedure ClearHexOutput;
Begin
  If HexStream = Nil then HexStream := TMemoryStream.Create;
  HexStream.Clear;
  HexStream.Seek(0,0);
End;


end.
