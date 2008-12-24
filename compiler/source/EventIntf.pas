(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit EventIntf;

interface

uses
  Windows, Dialogs; // We need "Dialogs" for TMsgDlgType

//procedure SendBoolean(const Identifier: string; const Value: Boolean);
//procedure SendDateTime(const Identifier: string; const Value: TDateTime);
//procedure SendDebugEx(const Msg: string; MType: TMsgDlgType);
//procedure Sendnew(const Msg: string; src: string; Ctg: string; Evt: string; MType: TMsgDlgType);
procedure DebugWrite(const Msg: string);

{procedure SendDebug(const Msg: string);
procedure SendInteger(const Identifier: string; const Value: Integer);
procedure SendMethodEnter(const MethodName: string);
procedure SendMethodExit(const MethodName: string);
procedure SendSeparator;}
function StartDebugWin: hWnd;


// Global Debug Mode...

var
  DebugMode: integer;

implementation

uses
  Messages,
  SysUtils; 

threadvar
  MsgPrefix: AnsiString;

function StartDebugWin: hWnd;
begin
end;

{procedure SendDebugEx(const Msg: string; MType: TMsgDlgType);
begin
end;}

procedure DebugWrite(const Msg: string);
begin
end;

//procedure SendNew(const Msg: string; src: string; Ctg: string; Evt: string; MType: TMsgDlgType);
//begin
//end;

{procedure SendDebug(const Msg: string);
begin
end;

const
  Indentation = '    ';

procedure SendMethodEnter(const MethodName: string);
begin
  MsgPrefix := MsgPrefix + Indentation;
  SendDebugEx('Entering ' + MethodName, mtInformation);
end;

procedure SendMethodExit(const MethodName: string);
begin
  SendDebugEx('Exiting ' + MethodName, mtInformation);

  Delete(MsgPrefix, 1, Length(Indentation));
end;

procedure SendSeparator;
const
  SeparatorString = '------------------------------';
begin
  SendDebugEx(SeparatorString, mtInformation);
end;

procedure SendBoolean(const Identifier: string; const Value: Boolean);
begin
  // Note: We deliberately leave "True" and "False" as
  // hard-coded string constants, since these are
  // technical terminology which should not be localised.
  if Value then
    SendDebugEx(Identifier + '= True', mtInformation)
  else
    SendDebugEx(Identifier + '= False', mtInformation);
end;

procedure SendInteger(const Identifier: string; const Value: Integer);
begin
  SendDebugEx(Format('%s = %d', [Identifier, Value]), mtInformation);
end;

procedure SendDateTime(const Identifier: string; const Value: TDateTime);
begin
  SendDebugEx(Identifier + '=' + DateTimeToStr(Value), mtInformation);
end;}

initialization
  DebugMode := 1; // No Debug...

end.

