(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

Unit CompDef;

Interface

Uses
//  AVRCore,
  Classes;

Const undefined = $7FFF;

{$I AVRLEX.INC}

Const
  avr = 1; i51 = 2; pic = 3; m6805 = 4; cop = 5;
  z8 = 6; holtek = 7; st62 = 8; sx = 9; fm = 10; z80 = 11;

  _ext_hex: String = 'ROM';

Var
  has_spm,
  has_mul,
  has_lpm,
  has_sram,
  has_adiw,
  has_ljmp,
  segfix: Boolean;

  segment,
  gran,
  i32: Integer;
  s4: Single;

  basic,
  doLibrary: Boolean;
  avd_id,
  cpux,
  family: Integer;
  devloaded,
  devstr: String;
  mainfile,
  sNeedLibCalls: String;

  srclinenum,
  mainfiletype: Integer;
  uselinenuminfo: Boolean;
  nooptpasses: Boolean;

Const
    yyMaxLabelChars     = 32;
    yyMaxLabels 	= 1500;
    yyMaxSyms	 	= 1500;
    yyMaxLocalSyms 	= 20;
    yyBufSize 		= 500000;
//    yyMaxFixups	        = 60;
    max_fors            = 8;
    max_repeat          = 20;
    max_while           = 8;
    max_sw              = 8;
    max_if              = 8;
    maxtok              = 300;   { ?! }

var
   cpuclock: Longint;    { 1MHz }
   clocktype: Byte;
   defasm: Integer;


Type
    TRec = Array[0..8] Of Byte;

    PSym = ^TSym;
    TSym = Record
        Val: Longint;          // 4 Byte Value
        SubVal,
        Typ,
        Size,
        Storage: ShortInt;
        yylex: Integer;       // SmallInt
        left, mid, right: PSym;
        Name: Array[0..yyMaxLabelChars] of Char;
    End;
    PLab = ^TLab;
    TLab = Record
    	addr: Word;
        typ: Byte;
        Name: Array[0..yyMaxLabelChars] of Char;
    End;
    TLabFix = Record
    	addr: Word;			{ Address where to fix 	}
    	num: Integer;	    { Index in Labels		}
        rec: Trec;
    End;
    TLabOpt = Record
	ofs: Integer;       { Offset }
        yytext: Integer;    { Where in the Text }
    End;
    TRepeat = Record
	addr	: Word;		{ addr of FOR statement }
        n: Byte;
    End;
    TWhile = Record
	addr	: Word;		{ addr of FOR statement }
    End;
    TSwitch = Record
        V: TSym;
        n: Integer;
        addr	: Word;		{ addr of FOR statement }
    End;
    TIF = Record
        num,
        typ: Integer;
    End;
    TBEND = Record
        typ,
        n: Integer;
    	addr	: Word;		{ addr of FOR statement }
    End;

    TFor = Record
    	addr	: Word;		{ addr of FOR statement }
    	V	: Integer;
        Nam     : Array[0..31] Of Char;
    	StartVal: Word;
        EndVal  : Word;
        StepVal	: Integer;
    	StartIsV: Boolean;
    	EndIsV	: Boolean;
    	StepIsV	: Boolean;
    	StepUp	: Boolean;
        Loop, Start, Fin, Step: Tsym;
    End;

    TLocalDef = Record
      HiUsed,
      LoUsed,
      LocalUsed,
      LastSym: Integer;
      bInterrupt: Boolean;
      bAssembler: Boolean;
      bRegister: Boolean;
    End;

Var
    next_sym,
    next_local_sym,
    next_lab,
    next_fix: Integer;
    EdFileNum: Integer;
    docmode: Integer;

    ShortFile,
    filen: String;
    errfile,
    codefile: File;
    dodislisting: Boolean;
//    fip,
    savedip: Integer;

Var
    TokensProcessed: Longint;
    textPC: Integer;            { points to TOKEN being read }

Const
    yyInitial = 0;              { Initial State     }
    yyString = 1; 	            { In String State   }

Var
    yytext: Integer;            { pointer into Buf  }
    yystate: Integer;           {                   }
    yycomma: Integer;
    yyintval: Longint;          { Where integer values are returned ??? }
    yyeof: Boolean;
    yytest: Integer;
    yylast: Integer;

Var
    PLineBuf: PChar;
    LineBuf:Array[0..255] Of Char;
    id: Array[0..yyMaxLabelChars] Of Char;      { where we collect...   }
    isWord: Boolean;
    Buf: PCHAR;

Type
    PSymsArray = ^TSymsArray;
    TSymsArray = Array[0..0] Of TSym;
Var
    Syms: PSymsArray;

Var
    Labels: Array[0..yyMaxLabels] of TLab;  	{ Labels	}
    LocalSyms: Array[0..yyMaxLocalSyms] of TSym; 		{ Symbols	}

    Op1, Op2,
    Tmp, Tmp1, Tmp2,
    yyTmp,
    TempSym: TSym;

    rom_top, rom_bottom, rom_size,
    ee_top, ee_bottom, ee_size,
    sram_top, sram_bottom, sram_size: Integer;

    next_h_reg,      next_l_reg,
    next_h_reg_loc,  next_l_reg_loc,
    next_eeh_reg,    next_eel_reg: Integer;

    next_sram: Integer;

    msgFileOK,
    demo,
    bIntUsesSREG,
    bIntUsesWREG: Boolean;

{--belongs not here--}

Var
    next_for,
    next_cnt    : Word;
    ForStack 	: Array[0..max_fors-1] Of TFor;

    next_repeat,
    repeat_cnt  : Word;
    RepStack 	: Array[0..max_repeat-1] Of TRepeat;

    next_while,
    while_cnt  : Word;
    WhileStack 	: Array[0..max_repeat-1] Of TWhile;


    next_sw,
    sw_cnt  : Word;
    SWStack 	: Array[0..max_sw] Of TSwitch;

    next_if, if_cnt  : Word;
    IFStack: Array[0..max_if] Of TIF;

    bep  : Word;
    BEStack 	: Array[0..max_sw] Of TBEND;

    inobject: Boolean;

    cend: Integer;                  { Current End }
    e2: Array[0..32] Of Integer;    { End To Much Array }
    e2m: Integer;

    vectors: Array[0..255] Of cardinal;
    aaa:array[0..1000] of integer;

    be,
    locp: Integer;
    LocalDef: Array[0..7] Of TLocalDef;

Var
    last_line,
    last_error,
    yyemit_errors: Integer;

    szStartup,
    szTokenLib,
    szUserLib: Array[0..32] Of Char;

Const
    max_gosubs	= 16;
Var
    next_gosub	: Integer;
    Gosubs	: Array[0..max_gosubs-1] Of Integer;
    blst,

    bgoto,
    bgosub,
    bnot,
    bnif: Boolean;
    breduce: Boolean;

    bpre,
    bpost: Integer; {?}

Const
    max_files = 256;

Var
    par,  fname: String;
    szHexFile: Array[0..259] Of Char;
    mode, { 0 user, 1 optimzing linker }

    saved, push,
    next_free: Word;				{ Pointer to next free	}
    MEM: Array[0..255] of Byte;    { our EEPROM MEM		}

    LastIncFile,
    incfilenum, filenum, cfilenum,
    save_linenum: Integer;
    pass : Integer;
    basfile: String;

    sobjfile: String;
    files: Array[0..max_files] Of String;

    hextyp: Integer;
    next_branch_out,
    last_branch_out,
    used_ee,
    next_ee: Word;
    nlines: Integer;
    last_predef: Integer;

Const
    undeflab = $7FFF;


var
    wreg_def: longint; { AT90S1200}
    wreg_val: Integer;
    lcl: Integer;        // Last Code Lenght
    csz: Integer;        // Word!
    rambank: Integer;

{ usage maps }

var
 use_eewait: boolean;
 use_watchdog: boolean;


Var
  model,
  cpu: Integer;
  rtlpath: String;

  symlab,
  SREG,
  INT_SREG, INT_WREG,
  WREG, WBIT,
  TCon,
  XR, YR, ZR,
  ZH, ZL: TSym;
  IX,
  Src,Dst,Op: PSym;

Var
  TempRec: TRec;
  {CODEMEM: Array[0..4096] Of Word;}
  EEMEM: Array[0..$FFF] Of Word;

Const
  max_coderec = 65535;

Type
  TCodeRec = Record
    addr: Word;        { Addr            }
    code,
    c2: Word;          { Code emitted    }
    size,              { code Size}
    tag: Byte;         {                 }
    fn: byte;          { Filenum         }
    ln: Word;          { LineNum         }
  End;

Var
  next_code: Integer;
  CodeRecords: Array[0..max_coderec] of TCodeRec;

Function Single2I(s: Single): Integer;

Implementation

Var
  ss: Single;
  ii: Integer absolute ss;

Function Single2I;
Begin
  ss := s;
  Result := ii;
End;

Begin
  Family := avr;    { Set Default Family }
  basic := True;

  devloaded := '';
  GetMem(Syms, SizeOf(Tsym) * yyMaxSyms); { 100 Symbols! }
  GetMem(Buf, yyBufSize+1);

  segfix := True;

  aaa[1] := 1;

  wreg_def:= $1F; { AT90S1200}
    wreg_val:=-1;
    rambank:= 0;
    lcl:= 1;        // Last Code Lenght
    csz:= 2;        // Word!
   cpuclock:= 1000000;    { 1MHz }

 use_eewait:= true;
 use_watchdog:= false;
   clocktype:= 0;
   defasm:= 0;


End.