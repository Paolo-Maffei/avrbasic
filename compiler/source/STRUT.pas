(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit strut;

interface

uses

  SysUtils;

function RemoveQuote(param: string): string;
function RemoveExt(param: string): string;

function Hex2B(Hex: string): Word;

implementation


// Two hex chars into byte

function Hex2B;
var
  i,
    W: Word;
  C: Char;
begin
  W := 0;
  for i := 1 to 2 do
  begin
    C := Hex[i];
    W := W shl 4;
    case C of
      '0'..'9': W := W or (ord(C) - $30);
      'a'..'f': W := W or (ord(C) - ord('a') + 10);
      'A'..'F': W := W or (ord(C) - ord('A') + 10);
    end;
    Hex2B := W;
  end;
end;


function RemoveQuoteNoCheck(param: string): string;
begin
  // Remove leader and trailer
  result := Copy(param, 2, length(param) - 2);
end;

function RemoveQuote(param: string): string;
begin
  if param[1] = '<' then
    if param[length(param)] = '>' then begin
      result := RemoveQuoteNoCheck(param);
      exit;
    end;
  if param[1] = '"' then
    if param[length(param)] = '"' then begin
      result := RemoveQuoteNoCheck(param);
      exit;
    end;
  if param[1] = '''' then
    if param[length(param)] = '''' then begin
      result := RemoveQuoteNoCheck(param);
      exit;
    end;
end;

function RemoveExt(param: string): string;
begin

end;

end.

