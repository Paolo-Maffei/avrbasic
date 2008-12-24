(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

const
  T_EOF = -1;

  T_CONST = 1;
  T_VAR = 2;
  T_LABEL = 3;
  T_TOKEN = 4;
  T_STRING = 5;
  { one char }
  T_COMMA = 6; { , }
  T_LBRACKET = 7; { ( }
  T_RBRACKET = 8; { ) }
  T_EQUAL = 9; { = }
  T_MATH = 11;
  T_LOG = 12;
  T_NEWLINE = 13;
  T_LBRACKET2 = 14; { [ }
  T_RBRACKET2 = 15; { ] }
  T_NOT = 16;
  T_DOT = 79;

  T_23 = 10; { # }

  t_BASE = $20;

  { PBASIC Tokens}
const
  T_HIGH = t_BASE + 0;
  T_LOW = t_BASE + 1;
  T_INPUT = t_BASE + 2;
  T_OUTPUT = t_BASE + 3;
  T_TOGGLE = t_BASE + 4;
  T_REVERSE = t_BASE + 5;
  T_PWM = t_BASE + 6;
  T_POT = t_BASE + 7;
  T_PULSOUT = t_BASE + 8;
  T_PULSIN = t_BASE + 9;
  T_FOR = t_BASE + 10;
  T_READ = t_BASE + 11;
  T_WRITE = t_BASE + 12;
  T_LOOKDOWN = t_BASE + 13;
  T_GOSUB = t_BASE + 14;

  T_CBR = t_BASE + 16;
  T_SER = t_BASE + 19;

  T_IN = t_BASE + 20;
  T_OUT = t_BASE + 21;

  T_LOOKUP = t_BASE + 22;
  T_NEXT = t_BASE + 23;
  T_IFTHEN = t_BASE + 24;
  T_GOTO = t_BASE + 25;
  T_BRANCH = t_BASE + 26;
  T_NAP = t_BASE + 28;
  T_DEBUG = t_BASE + 30;
  T_END = t_BASE + 31;

  { PBASIC Secondary Tokens }
  T_SYMBOL = t_BASE + 32;
  T_BSAVE = t_BASE + 33;
  T_TO = t_BASE + 34;
  T_STEP = t_BASE + 35;
  T_EEPROM = t_BASE + 36;
  T_REM = t_BASE + 37;
  T_ANDOR = t_BASE + 38;
  T_THEN = t_BASE + 39;
  T_RETURN = t_BASE + 27;

  t_avrbase = 1000;

  {AVR Asm mnemo }
  T_ASR = Integer($9405);
  T_COM = Integer($9400);
  T_NEG = Integer($9401);
  T_DEC = Integer($940A);
  T_LSR = Integer($9406);
  T_ROR = Integer($9407);
  T_INC = Integer($9403);
  T_SWAP = Integer($9402);

  T_WDR = Integer($95A8);
  T_SLEEP = Integer($9588);

  T_AND = Integer($2000);
  T_OR = Integer($2800);
  T_ADD = Integer($0C00);
  T_ADC = Integer($1C00);
  T_SUB = Integer($1800);
  T_SBC = Integer($0800);
  T_EOR = Integer($2400);
  T_CP = Integer($1400);
  T_CPC = Integer($0400);
  T_CPSE = Integer($1000);

  T_BRBC = t_avrbase + 3;
  T_BRBS = t_avrbase + 4;

  T_BREQ = Integer($F001);
  T_BRLO = Integer($F000);
  T_BRNE = Integer($F401);

  T_RETI = t_avrbase + 5;
  T_WATCHDOG = t_avrbase + 30;
  T_NOP = t_avrbase + 31;

  T_REPEAT = t_avrbase + 32;
  T_UNTIL = t_avrbase + 33;
  T_WHILE = t_avrbase + 34;
  T_WEND = t_avrbase + 35;

  T_DEFAULT = t_avrbase + 36;
  T_USE = t_avrbase + 37;
  T_AS = t_avrbase + 38;
  T_PROCEDURE = t_avrbase + 39;

  T_LSL = t_avrbase + 40;
  T_ROL = t_avrbase + 41;

  T_WAIT = t_BASE + 40;
  T_SKIP = t_BASE + 41;
  T_EXIT = t_BASE + 42;
  T_ON = t_BASE + 43;
  T_OFF = t_BASE + 44;

  T_INT0 = t_BASE + 45;
  T_TIMER0 = t_BASE + 46;
  T_ANACOMP = t_BASE + 47;
  T_RESET = t_BASE + 48;
  T_RAM = t_BASE + 49;
  T_COLON = t_BASE + 50;

  T_VARDEF = t_BASE + 51;
  T_CONDEF = t_BASE + 52;
  T_BYTE = t_BASE + 53;
  T_WORD = t_BASE + 54;
  T_REG = t_BASE + 55;
  T_BIT = t_BASE + 56;

  T_AT = t_BASE + 57;
  T_ADDR = t_BASE + 58;

  T_ROM = t_BASE + 59;
  T_PORT = t_BASE + 60;

  T_SIZE = t_BASE + 61;
  T_DEVICE = t_BASE + 62;

  T_INCINC = t_BASE + 63;
  T_DECDEC = t_BASE + 64;

  T_PUSH = t_BASE + 65;
  T_POP = t_BASE + 66;

  T_BEGIN = t_BASE + 67;
  T_INTERRUPT = t_BASE + 68;
  T_PROGRAM = t_BASE + 69;
  T_CPU = t_BASE + 70;

  T_TRUE = t_BASE + 71;
  T_FALSE = t_BASE + 72;

  T_TIMER = t_BASE + 73;
  T_EXTINT = t_BASE + 74;
  T_ASSEMBLER = t_BASE + 75;
  T_FUNCTION = t_avrbase + 76;

  T_TYPEDECL = t_avrbase + 77;

  T_SHR = t_avrbase + 78;
  T_SHL = t_avrbase + 79;

  T_ORG = t_avrbase + 80;

  T_SWITCH = t_avrbase + 81;
  T_BREAK = t_avrbase + 82;

  T_ELSE = t_avrbase + 83;

  T_FAMILY = t_avrbase + 84;

  T_RL = t_avrbase + 85;
  T_RR = t_avrbase + 86;

  T_OBJECT = t_avrbase + 87;

  T_MUL = t_avrbase + 88;
  T_DIV = t_avrbase + 89;

  T_Library = t_avrbase + 91;
  T_Public = t_avrbase + 92;
  T_External = t_avrbase + 93;
  T_USES = t_avrbase + 94;

  T_RETNMI = t_avrbase + 95;
  T_WORD24 = t_BASE + 96;
  T_WORD32 = t_BASE + 97;

  T_DUP = t_BASE + 98;
  T_DROP = t_BASE + 99;

  T_LOAD = t_BASE + 100;
  T_STORE = t_BASE + 101;


  T_DO = t_BASE + 102;
  T_LOOP = t_BASE + 103;
  T_LOOPP = t_BASE + 104;
  T_I = t_BASE + 105;
  T_J = t_BASE + 106;
  T_K = t_BASE + 107;

  T_SEGMENT = t_BASE + 108;
  T_ASM = t_BASE + 109;
  T_ASMEND = t_BASE + 110;
  T_PROGEND = t_BASE + 111;

  // asm
  T_LPM = t_BASE + 112;
  T_ELPM = t_BASE + 113;

  T_LD = t_BASE + 114;
  T_LDI = t_BASE + 115;
  T_LDS = t_BASE + 116;
  T_LDD = t_BASE + 117;
  T_ST = t_BASE + 118;
  T_STS = t_BASE + 119;
  T_STD = t_BASE + 120;
  T_MOV = t_BASE + 121;

  T_ORI = t_BASE + 122;
  T_ADIW = t_BASE + 124;
  T_SBIW = t_BASE + 125;

  T_IJMP = t_BASE + 126;
  T_ICALL = t_BASE + 127;

  T_SUBI = t_BASE + 128;
  T_ANDI = t_BASE + 129;
  T_CLR = t_BASE + 130;
  T_SBR = t_BASE + 132;
  T_SBCI = t_BASE + 133;

  T_TST = t_BASE + 135;

  T_CPI = t_BASE + 136;


  T_SBRC = t_BASE + 137;
  T_SBRS = t_BASE + 138;
  T_SBIC = t_BASE + 139;
  T_SBIS = t_BASE + 140;
  T_BRCS = t_BASE + 145;
  T_BRCC = t_BASE + 146;
  T_BRSH = t_BASE + 147;
  T_BRMI = t_BASE + 149;
  T_BRPL = t_BASE + 150;
  T_BRGE = t_BASE + 151;
  T_BRLT = t_BASE + 152;
  T_BRHS = t_BASE + 153;
  T_BRHC = t_BASE + 154;
  T_BRTS = t_BASE + 155;
  T_BRTC = t_BASE + 156;
  T_BRVS = t_BASE + 157;
  T_BRVC = t_BASE + 158;
  T_BRIE = t_BASE + 159;
  T_BRID = t_BASE + 160;

  T_BSET = t_BASE + 161;
  T_BCLR = t_BASE + 162;
  T_BST = t_BASE + 163;
  T_BLD = t_BASE + 164;
  T_SEC = t_BASE + 165;
  T_CLC = t_BASE + 166;
  T_SEN = t_BASE + 167;
  T_CLN = t_BASE + 168;
  T_SEZ = t_BASE + 169;
  T_CLZ = t_BASE + 170;
  T_SEI = t_BASE + 171;
  T_CLI = t_BASE + 172;
  T_SES = t_BASE + 173;
  T_CLS = t_BASE + 174;
  T_SEV = t_BASE + 175;
  T_CLV = t_BASE + 176;
  T_SET = t_BASE + 177;
  T_CLT = t_BASE + 178;
  T_SEH = t_BASE + 179;
  T_CLH = t_BASE + 180;

  T_CBI = t_BASE + 181;
  T_SBI = t_BASE + 182;

  T_SPM = t_BASE + 183;
  T_MOVW = t_BASE + 184;

  T_DEBUGBREAK = t_avrbase + 185;
  //
  T_ERROR = 1003;

  sym_DEF = 0; { Default }
  sym_BIT = 1; { BIT     }
  sym_ioBIT = 2; { I/O BIT }
  sym_IO = 4; { I/O     }
  sym_EE = 5; { EEPROM  }
  sym_WORD = 6; { Word Variables }
  sym_Const = 7;
  sym_ROM = 8; { Rom Constant }

  sym_sDEF = 9; {Static SRAM BYTE }
  sym_lDEF = 10; {local BYTE}

  sym_sWORD = 11;
  sym_lWORD = 12;

  sym_SINGLE = 14;
  sym_WORD24 = 15;
  sym_WORD32 = 16;

  {
io_ofs    = $0000;
word_ofs  = $0000;
   }

