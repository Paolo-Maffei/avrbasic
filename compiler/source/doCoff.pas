(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit docoff;

interface

uses
//  CompDef,//  prefer,//  Common,

  ToolSrv,
  SysUtils,
  Classes,
  Coff;

type

  T_LNUM = record
    l_paddr: Integer;
    l_lnno: Integer;
  end;

  T_MP_LNUM = record
    res1: Integer;
    l_lnno: Word;
    l_paddr: Word;
    res2: Integer;
    res3: Integer;
  end;

  T_AUX_BF = record
    reserved1: Integer;
    line: Word;
    res1: Word;
    res2: Integer;
    next: Integer;
    reserved2: Word;
  end;

  T_AUX_FILE = record
    tag: Integer;
    size: Integer;
    lnnoptr: Integer;
    next: Integer;
    reserved2: Word;
  end;

  T_MP_OPT_HDR = record
    res1: Integer;
    mp_type: Integer;
    res2,
      res3: Integer;
  end;

const
  f_pic = 1;
  f_avr = 2;
  f_cop8 = 3;
  f_i51 = 4;

type
  TSegment = class(TComponent)
  private
    FName: string; // Name of this Segment
    FPC: cardinal; // PC' Program Counter?
  public
    procedure emit(Data: byte); overload;
    procedure emit(Data: word); overload;

  end;

  TCustomCoffImage = class(TMemoryImage)
  private
    FCurrentSegment: TSegment;
    procedure SetCurrentSegment(const Value: TSegment);
  public
    property CurrentSegment: TSegment read FCurrentSegment write SetCurrentSegment;

  end;


  TCoffImage = class(TCustomCoffImage)
  private
    FFileName: string;
    FStrSize: cardinal;
    procedure SetFileName(const Value: string);
  protected
    memStream: TMemoryStream;
    symStream: TMemoryStream;

    COFF_nsyms: Integer;
    COFF_nlnno: Integer;
    COFF_lnum: T_LNUM;
    MP_lnum: T_MP_LNUM;
    AVR_lnum: T_AVR_LNUM;

  public
    ifamily: integer;
    procedure CreateEx(s: string);
    procedure Close;
    procedure Open;
    property FileName: string read FFileName write SetFileName;
    procedure SaveToFile(Filename: string); override;

    procedure AddSymbol(n: string; value: Integer; typ, sclass: Word);
    procedure AddLineNum(Line: Cardinal; Addr: Cardinal);
    procedure AddFileName(Name: string);
    procedure AddString(Name: string);
    procedure AddFun(Name: string; Typ: string);
    procedure Add_bf;
    procedure Add_ef;
  end;

var
  oCOFF_FileHeader: T_FILHDR;
  oCOFF_SectionHeader: T_SCNHDR;
  oCOFF_SymbolEntry: T_SYMENT;
  oCOFF_AuxEntry: array[0..17] of Byte;
  oCOFF_Reloc: T_RELOC;
  oCOFF_Stream: TFileStream;

  COFF_MEM_Stream: TMemoryStream;
  COFF_sym_stream: TMemoryStream; // Symbols...
  COFF_ln_stream: TMemoryStream; // LineNums...
  COFF_str_stream: TMemoryStream; // Strings...


//  coff_filename: string;
  coff_c_file_ofs: Integer; // Where to padd

  COFF_AUX_BF: T_AUX_BF;
  COFF_AUX_FILE: T_AUX_FILE;
  // MPLAB
  MP_OPT_HDR: T_MP_OPT_HDR;

  bbf: T_BBF;
  ebf: T_EBF;

  //
  //family: integer;








var
  mCoff: TCoffImage;

implementation












{ TCoff }

procedure TCoffImage.AddFileName(Name: string);
var
  s: string;
  i: Integer;
  nstr: Integer;
begin
  FillChar(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry), 0);
  StrCopy(oCOFF_SymbolEntry.e.e_name, '.file');
  oCOFF_SymbolEntry.e_sclass := 103; // C_FILE
  oCOFF_SymbolEntry.e_numaux := 1; //
  oCOFF_SymbolEntry.e_scnum := -2; //
  //
  coff_c_file_ofs := COFF_sym_stream.Position; // Save Position
  //
  COFF_sym_stream.Write(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry));
  Inc(COFF_nsyms);
  //
  FillChar(COFF_AuxEntry, SizeOf(oCOFF_SymbolEntry), 0);
  if iFamily = f_avr then
  begin
    s := name;
    for i := 1 to Length(s) do COFF_AuxEntry[i - 1] := ord(s[i]);
  end;
  if iFamily = f_pic then
  begin
    COFF_AuxEntry[0] := COFF_str_Stream.Position;
    AddString(name);
  end;

  COFF_sym_stream.Write(COFF_AuxEntry, SizeOf(oCOFF_SymbolEntry));
  Inc(COFF_nsyms);

end;

procedure TCoffImage.AddFun(Name: string; Typ: string);
var
  s: string;
  i: Integer;
begin
  // Add Function Name
  AddSymbol(Name, 0, 4, 2);

  //
  FillChar(COFF_AUX_File, SizeOf(oCOFF_SymbolEntry), 0);
  Inc(COFF_nsyms);

  COFF_AUX_File.Size := 4;              // Size of Function?
  COFF_AUX_File.lnnoptr := 84;          // Offset to Line...
  COFF_AUX_File.Next := COFF_nsyms;     // ??

  COFF_sym_stream.Write(COFF_AUX_File, SizeOf(oCOFF_SymbolEntry));

end;

procedure TCoffImage.AddLineNum(Line, Addr: Cardinal);
begin
  if Line < 0 then Exit;
  Inc(COFF_nlnno);

  // Sucks !
  if iFamily = f_avr then
  begin
    COFF_lnum.l_paddr := Addr;
    COFF_lnum.l_lnno := Line;
    COFF_ln_Stream.Write(COFF_lnum, SizeOf(AVR_lnum));
  end;
  // WORKS !
  if iFamily = f_pic then
  begin
    MP_lnum.l_paddr := Addr;
    MP_lnum.l_lnno := Line;
    COFF_ln_Stream.Write(MP_lnum, SizeOf(MP_lnum));
  end;

end;


procedure TCoffImage.AddString(Name: string);
var a: array[0..259] of Char;
begin
  StrPCopy(A, name);
  COFF_str_Stream.Write(A, Length(name) + 1);
  FStrSize := FStrSize + Length(name) + 1;
end;

procedure TCoffImage.AddSymbol(n: string; value: Integer; typ,
  sclass: Word);
var
  s: string;
  i: Integer;
begin
  FillChar(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry), 0);
  s := Copy(n, 1, 8);
  for i := 1 to Length(s) do oCOFF_SymbolEntry.e.e_name[i - 1] := s[i];
  oCOFF_SymbolEntry.e_value := value;
  oCOFF_SymbolEntry.e_type := typ;
  oCOFF_SymbolEntry.e_sclass := sclass;
  oCOFF_SymbolEntry.e_scnum := 1; // Absolute ??

  // Write to Memory Stream
  COFF_sym_stream.Write(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry));
  Inc(COFF_nsyms);

end;

procedure TCoffImage.Add_bf;
begin
  FillChar(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry), 0);
  StrCopy(oCOFF_SymbolEntry.e.e_name, '.bf');
  oCOFF_SymbolEntry.e_sclass := 101; // C_FILE
  oCOFF_SymbolEntry.e_numaux := 1; //
  oCOFF_SymbolEntry.e_scnum := 1; //

  COFF_sym_stream.Write(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry));
  Inc(COFF_nsyms);

  FillChar(COFF_AUX_BF, SizeOf(oCOFF_SymbolEntry), 0);
  Inc(COFF_nsyms);

  COFF_AUX_BF.Line := 1;
//  COFF_AUX_BF.Next := COFF_nsyms + 2; // ??

  COFF_sym_stream.Write(COFF_AUX_BF, SizeOf(oCOFF_SymbolEntry));

end;

procedure TCoffImage.Add_ef;
begin
  FillChar(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry), 0);
  StrCopy(oCOFF_SymbolEntry.e.e_name, '.ef');
  oCOFF_SymbolEntry.e_sclass := 101; // C_FILE
  oCOFF_SymbolEntry.e_numaux := 1; //
  oCOFF_SymbolEntry.e_scnum := 1; //
  oCOFF_SymbolEntry.e_value := 0; // ??

  COFF_sym_stream.Write(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry));
  Inc(COFF_nsyms);

  FillChar(COFF_AUX_BF, SizeOf(oCOFF_SymbolEntry), 0);
  COFF_AUX_BF.Line := linenum; // oops

  COFF_sym_stream.Write(COFF_AUX_BF, SizeOf(oCOFF_SymbolEntry));
  Inc(COFF_nsyms);

end;

procedure TCoffImage.Close;
begin
  SaveToFile(Filename);

  COFF_MEM_Stream.Free; // Close File
  COFF_sym_stream.Free;
  COFF_ln_stream.Free;
  COFF_str_stream.Free;

end;

procedure TCoffImage.CreateEx(s: string);
begin

  COFF_nlnno := 0;
  // Clear File Header
  FillChar(COFF_FileHeader, SizeOf(COFF_FileHeader), 0);
  COFF_FileHeader.f_magic := $0A12; // AVR COFF
  COFF_FileHeader.f_flags := $000B; // Stripped reloc, ext local

  //$00FF
  COFF_FileHeader.f_flags := $00FF; // Stripped reloc, ext local

  //
  COFF_FileHeader.f_nscns := 1;
  //
  FillChar(COFF_SectionHeader, SizeOf(COFF_SectionHeader), 0);
  StrCopy(COFF_SectionHeader.s_name, '.text');
  if iFamily = f_pic then
    StrCopy(COFF_SectionHeader.s_name, '.code');
  COFF_SectionHeader.s_flags := $0020;
  //

  mCoff.filename := s;
  Open;

  COFF_str_stream.Seek(4, 0); // Make Room

  COFF_nsyms := 0;
  if iFamily = f_pic then
  begin
    COFF_FileHeader.f_magic := $1234; // PIC COFF
    COFF_FileHeader.f_opthdr := SizeOf(MP_OPT_HDR);
    MP_OPT_HDR.mp_type := $6C84; // PIC16C54
    MP_OPT_HDR.res1 := $15678; // ?
    MP_OPT_HDR.res2 := $0C; // ?
    MP_OPT_HDR.res3 := 08; // ?
  end;
  COFF_MEM_Stream.Write(COFF_FileHeader, SizeOf(COFF_FileHeader));

  if iFamily = f_pic then
  begin
    COFF_MEM_Stream.Write(MP_OPT_HDR, SizeOf(MP_OPT_HDR));
  end;

  COFF_MEM_Stream.Write(COFF_SectionHeader, SizeOf(COFF_SectionHeader));

end;

procedure TCoffImage.Open;
begin
  COFF_MEM_Stream := TMemoryStream.Create;
  COFF_ln_Stream := TMemoryStream.Create;
  COFF_sym_stream := TMemoryStream.Create;
  COFF_str_stream := TMemoryStream.Create;
  FStrSize := 4; // Initial Size of Strings.

  iFamily := f_avr;
end;

procedure TCoffImage.SaveToFile(Filename: string);
var
  nstr,
    i: Integer;
  p, raw: CARDINAL;
begin
  raw := COFF_MEM_Stream.Position;
  {
  if family <> f_i51 then
    COFF_MEM_Stream.Write(ROM16^, lastip * 2)
  else
    COFF_MEM_Stream.Write(ROM8^, lastip);
    }

  COFF_MEM_Stream.Write(MI.FROM, MI.LastPC * 2);

  //
  if COFF_ln_Stream.Size <> 0 then
  begin
    // Set File Pointer
    COFF_SectionHeader.s_lnnoptr := COFF_MEM_Stream.Position;
    COFF_SectionHeader.s_nlnno := COFF_nlnno;
    // Save to output Stream
    COFF_ln_Stream.SaveToStream(COFF_MEM_Stream);
  end;

  //
  COFF_FileHeader.f_nsyms := COFF_nsyms;
  COFF_FileHeader.f_symptr := COFF_MEM_Stream.Position;
  // Copy Symbols..
  COFF_sym_stream.Seek(0, soFromBeginning);
  if COFF_nsyms <> 0 then begin
    for i := 0 to COFF_nsyms - 1 do
    begin
      COFF_sym_stream.Read(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry));
      COFF_MEM_Stream.Write(oCOFF_SymbolEntry, SizeOf(oCOFF_SymbolEntry));
    end;
  end;
  // String Table

  nstr := COFF_str_Stream.position;
  p := COFF_str_Stream.size;
  COFF_str_Stream.Seek(0, 0);
  COFF_str_Stream.Write(p, 4); // Size of Strings
  COFF_str_Stream.Seek(nstr, soFromBeginning);
  COFF_str_Stream.SaveToStream(COFF_MEM_Stream);

  p := COFF_MEM_Stream.Position; // Save

  COFF_MEM_Stream.Seek(0, soFromBeginning);
  COFF_MEM_Stream.Write(COFF_FileHeader, SizeOf(COFF_FileHeader));
  if iFamily = f_pic then
  begin
    COFF_MEM_Stream.Write(MP_OPT_HDR, SizeOf(MP_OPT_HDR));
  end;
  {
  if family = f_i51 then
  begin
    COFF_SectionHeader.s_size := lastip
  end else
    COFF_SectionHeader.s_size := lastip * 2;
  }

  COFF_SectionHeader.s_size := MI.LastPC * 2;
  COFF_SectionHeader.s_scnptr := raw;

  COFF_MEM_Stream.Write(COFF_SectionHeader, SizeOf(COFF_SectionHeader));

  COFF_MEM_Stream.Seek(p, soFromBeginning);
//  if p_coff then

  COFF_MEM_Stream.SaveToFile(Filename);



end;

procedure TCoffImage.SetFileName(const Value: string);
begin
  FFileName := Value;
end;

{ TSegment }

procedure TSegment.emit(Data: byte);
begin
  //
end;

procedure TSegment.emit(Data: word);
begin
  //
end;

{ TCustomCoffImage }

procedure TCustomCoffImage.SetCurrentSegment(const Value: TSegment);
begin
  FCurrentSegment := Value;
end;

initialization
  mCoff := TCoffImage.Create(nil);

end.

