(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit ToolSrv;
{***************************************************************
 Generic Services for Tool Output Processing.
 Must compile/link under Delphi/FPC and run in console/gui mode.
****************************************************************}

interface

uses
  ToolStd,
  IniFiles,
  Classes,
  SysUtils;

type
  EAbstractError = class(Exception);
  TWriteStringProc = procedure(str: string);

  //
  // Generic Memory Image...
  // All Code Generation should call some Descendants of..
  //
  TMemoryImage = class(TComponent)
  private
    FPC: Cardinal;
    FLastPC: Cardinal;
    procedure SetPC(const Value: Cardinal);
    procedure SetLastPC(const Value: Cardinal);
  public
    FROM: Array[0..$FFFF] of WORD;

    procedure LoadFromFile(FileName: string); virtual; abstract;
    procedure SaveToFile(FileName: string); virtual; abstract;

    procedure emit(Data: byte); overload; virtual; abstract;
    procedure emit(Data: word); overload; virtual; abstract;
  published
    property PC: Cardinal read FPC write SetPC;
    property LastPC: Cardinal read FLastPC write SetLastPC;
  end;

  TDumbMemoryImage = class(TMemoryImage)
  private

  public
    procedure LoadFromFile(FileName: string); override;
    procedure SaveToFile(FileName: string); override;

    procedure emit(Data: byte); override;
    procedure emit(Data: word); override;

  published
  end;


var
  InstallDir: string;
  TemplateDir: string;

  // Global Memory Image..
  MI: TMemoryImage;

  linenum: integer; // BAD BAD..

procedure WriteToolOutput(line: string);
function MsgByNum(Num: Integer): string;  // Retrieve Common Messages

implementation

var
  MsgIni: TIniFile;
  InternalMsgList: TStringList; // We hold Messages here

procedure WriteToolOutput(line: string);
begin
  WriteStdOutput(line);
end;

function MsgByNum(Num: Integer): string;
begin
  //
  if not Assigned(InternalMsgList) then
  begin
    Exit;
  end;
  // Get Message...
  Result := InternalMsgList.Values[IntToStr(Num)];

end;


{ TMemoryImage }

procedure TMemoryImage.SetLastPC(const Value: Cardinal);
begin
  FLastPC := Value;
end;

procedure TMemoryImage.SetPC(const Value: Cardinal);
begin
  FPC := Value;
end;

{ TDumbMemoryImage }

procedure TDumbMemoryImage.emit(Data: byte);
begin
   FPC := FPC and $FFFF;
   FROM[FPC] := Data; // Low Byte?

   //
   Inc(FPC);
   if FPC>FLastPC then FLastPC := FPC;
end;

procedure TDumbMemoryImage.emit(Data: word);
begin
   FPC := FPC and $FFFF;
   FROM[FPC] := Data; // Low Byte?

   //
   Inc(FPC);
   if FPC>FLastPC then FLastPC := FPC;

end;

procedure TDumbMemoryImage.LoadFromFile(FileName: string);
begin
 //

end;

procedure TDumbMemoryImage.SaveToFile(FileName: string);
begin
  //

end;

initialization
  // Load Messages...
  MsgIni := TIniFile.Create('C:\c2\common.txt');

  InternalMsgList := TStringList.Create;
  // Read Messages...

  MI := TDumbMemoryImage.Create(nil);

finalization
  //InternalMsgList.Free ?

end.
