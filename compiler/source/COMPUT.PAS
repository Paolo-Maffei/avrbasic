(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

Unit CompUt;

Interface

Uses
  EventIntf,
  AVRCore,
  
  Classes, IniFiles, Dialogs,
  prefer,
  MStrings,
  CompDef,
  SysUtils, Windows; //, FileCtrl;

Function se(l, r: PCHAR): Boolean;
Function ShortPathName(PathName: String): String;
Procedure LoadSFRs(dev: String);

Function IsLibCallNeeded(n: String): Boolean;
Procedure AddLibCall(n: String);
Procedure ClearLibCalls;

Implementation

Procedure ClearLibCalls;
Begin
  sNeedLibCalls := '';
End;

Procedure AddLibCall(n: String);
Begin
  If Not IsLibCallNeeded(n) Then
   sNeedLibCalls := sNeedLibCalls + '|' + n;
End;

Function IsLibCallNeeded;
Begin
  Result := Pos(n, sNeedLibCalls) <> 0;
End;



Procedure LoadSFRs(dev: String);
Var
  Ini: TIniFile;
  s, s2: String;
  v: Integer;
Begin
  if dev = devloaded then Exit; // Already Loaded
  //
  core.sfrStrings.Clear;
  core.vecStrings.Clear;

  // Open Device IniFile

  core.family := 'AVR';
  core.Device := dev;

  s := RootDir + 'CONFIG\DEVICE\'+ core.Family +'\'+ core.Device + '.INI';

  If Not FileExists(s) Then
  begin
    //ShowMessage('ERROR: Device Specific Config File not found!');
  { TODO :  }
    DebugWrite('ERROR: Device File '+s+ ' not found!');

    sram_bottom := 0;
    sram_top    := 0;
    sram_size   := 0;

    rom_size    := 512;
    ee_size     := 0;

    exit;
  end;

  devloaded := dev;

  Ini := TIniFile.Create(s);
  // Read SFR Names

  // Get SRAM/ROM/EEPROM
  sram_bottom := Ini.ReadInteger('MEM','SRAM.BOTTOM',  0);
  sram_top    := Ini.ReadInteger('MEM','SRAM.TOP',     0);
  sram_size   := Ini.ReadInteger('MEM','SRAM.SIZE',    0);

  rom_size    := Ini.ReadInteger('MEM','ROM.SIZE',   512); // Demo Limit!
  ee_size     := Ini.ReadInteger('MEM','EEPROM.SIZE',  0);

  has_lpm     := Ini.ReadBool('CPU', 'LPM', true);
  has_spm     := Ini.ReadBool('CPU', 'SPM', true);
  has_mul     := Ini.ReadBool('CPU', 'MUL', true);

  has_adiw    := Ini.ReadBool('CPU', 'ADIW', true);
  has_vec2    := Ini.ReadBool('CPU', 'LONGVECTOR', false);
  Ini.Free;

End;


Function ShortPathName;
var
  a, b: Array[0..259] of char;
begin
  StrPCopy(a, PathName);
  GetShortPathName(a, b, SizeOf(b) );
  Result := StrPas(b);
end;

Function se;
Begin
  se := StrComp(l, r) = 0;
End;


Begin
End.