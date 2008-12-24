(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit CustomCore;

interface

uses
  CompDef, Common,
	Windows, Messages, SysUtils, Classes; 
	//Graphics, 
	//Controls, 
	//Forms, Dialogs;

{$I AVRLEX.INC}
  
type
  PNode = PSym;
  TNode = TSym;


  TCustomCore = class(TComponent)
  private
    FFamily: string;
    FDevice: string;
    procedure SetDevice(const Value: string);
    procedure SetFamily(const Value: string);

    { Private declarations }
  protected
    { Protected declarations }
    constructor create(AOwner: TComponent); override;
  public
    { Public declarations }
    sfrStrings: TStringList;
    vecStrings: TStringList;

    function Disasm(value: Pointer): string; virtual;

    { CPU Instructions }
    procedure add(Dest,Op1,Op2: PNode); virtual; abstract;
    procedure adc(Dest,Op1,Op2: PNode); virtual; abstract;

    procedure decr(Dest,Src: PNode); virtual; abstract;
    procedure di; virtual; abstract;
    procedure divide(Dest,Op1,Op2: PNode); virtual; abstract;

    procedure ei; virtual; abstract;

    procedure incr(Dest,Src: PNode); virtual; abstract;

    procedure move(Dest,Src: PNode); virtual; abstract;
    procedure mul(Dest,Op1,Op2: PNode); virtual; abstract;

    procedure nop; virtual; abstract;

    procedure sub(Dest,Op1,Op2: PNode); virtual; abstract;
    procedure sbc(Dest,Op1,Op2: PNode); virtual; abstract;





  published
    { Published declarations }
    property Family: string read FFamily write SetFamily;
    property Device: string read FDevice write SetDevice;



  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('SiStudio', [TCustomCore]);
end;

{ TCustomCore }

constructor TCustomCore.create(AOwner: TComponent);
begin
  sfrStrings := TStringList.Create;
  vecStrings := TStringList.Create;

end;

function TCustomCore.Disasm(value: Pointer): string;
var
  b: Byte;
begin
  b := 0;
  if value <> nil then
    b := byte(value^);
  result := inttohex(ip, 4) + ' ' + inttohex(b, 2);
end;

procedure TCustomCore.SetDevice(const Value: string);
begin
  FDevice := Value;
end;

procedure TCustomCore.SetFamily(const Value: string);
begin
  FFamily := Value;
end;



end.

