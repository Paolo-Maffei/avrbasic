(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit EFile;

interface

uses
  ToolSrv,
  ToolStd,
  asmsub,

  prefer,
  IniFiles,
  Classes,
  SysUtils,
  //StdCtrls,
  MStrings,
  CompDef;

var
  EList: TStringList;
  forcederr: Boolean;


function ErrorMsg(num: Integer): string;
procedure ForcedError(ERR: Integer);
procedure Error(ERR: Integer);
procedure Warning(num: Integer);
procedure emit_error(ERR, lin, pass: Integer);

{ *.ERR File Parsing Function's }

function getErrLineNum(Line: string): Integer;
function getErrFile(Line: string): string;


procedure ClearErrors;

{$I ERRMSG.INC}

implementation

//
// Clear Error Messages.
//
procedure ClearErrors;
begin
  if EList <> nil then Elist.Clear;
end;

function getErrLineNum;
var
  N, P1, P2: Integer;
  S, R: string;
begin
  N := -1; { not applicable }
  P1 := Pos('(', Line);
  if P1 <> 0 then begin
    P1 := P1 + 1;
    S := Copy(Line, P1, Length(Line) - P1);
    P2 := Pos(')', S);
    if P2 <> 0 then begin
      R := Copy(S, 1, P2 - 1);
      N := StrToInt(R);
    end;
  end;
  getErrLineNum := N;
end;

function getErrFile;
var
  L1,
    N, P1, P2: Integer;
  S, R: string;
begin
  L1 := 8;
  Result := '';
  if Line[1] = 'E' then L1 := 8;
  if Line[1] = 'W' then L1 := 10;

  P1 := Pos('(', Line);
  if P1 <> 0 then begin
    Result := Copy(Line, L1, P1 - L1);
  end;
end;

var es: string;

function ErrorMsg;
begin
  Result := MsgByNum(num); // ToolSrv
end;

procedure Warning;
var
  C: Char;
  WMsg: string;
begin
  if pass < 10 then Exit; { No Before here }
  C := FillChr; 
//d6 writeableconst
//FillChr := '0';

  { Error[num] Filename linenum : Text }
  es := Files[filenum - 1];
  if filenum = 1 then es := es + '.BAS' else es := es + '.INC';
  {
  Writeln(errfile, 'Warning[',num,'] ', es ,' ',linenum-1,' : ', WMsg );
  Writeln(ofile, '***** WARNING: '+ WMsg );
  }
//d6 writeableconst
//  FillChr := C;
end;

procedure ForcedError(ERR: Integer);
begin
  last_error := ERR;
  forcederr := True;
  inc(yyemit_errors);
  emit_error(ERR, linenum, pass);
end;

procedure Error(ERR: Integer);
begin
  last_error := ERR;
  forcederr := False;
  inc(yyemit_errors);
  emit_error(ERR, linenum, pass);
end;

procedure emit_error;
var
  S: string;
begin
  if (pass <> 10) and (not forcederr) then
    Exit; { No Before here }

  { Error[num] Filename linenum : Text }
  es := Files[filenum - 1];
  if filenum = 1 then es := es + '.BAS' else es := es + '.INC';

  S := 'Error: ';
  // Add FileName
  if filenum < max_files then
  begin
    S := S + Files[filenum];
  end;
  // Add Line number...
  S := S + '(' + IntToStr(lin - 1) + '): ' + ErrorMsg(ERR);

  //  Writeln(errfile, );
  //  Writeln(ofile, '***** ERROR: ' + ErrorMsg(ERR));

  WriteStdError( 'Error[' + inttostr(ERR) + '] ' + es + ' ' + inttostr(lin - 1) + ' : ' + ErrorMsg(ERR) );

//  WriteToolOutput( S );
  WrLstLine( S );
  //

end;

initialization
  EList := TStringList.Create;


finalization

end.

