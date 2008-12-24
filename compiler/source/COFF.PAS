(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit coff;

interface

Uses
  Classes;

{$A-}

Type
  T_FILHDR = Record        // COFF File Header
    f_magic: WORD;         //* magic number             */
    f_nscns: WORD;         //* number of sections       */
    f_timdat: CARDINAL;    //* time & date stamp        */
    f_symptr: CARDINAL;    //* file pointer to symtab   */
    f_nsyms: CARDINAL;     //* number of symtab entries */
    f_opthdr: WORD;        //* sizeof(optional hdr)     */
    f_flags: WORD;         //* flags                    */
  End;

Const
  F_RELFLG = $0001;
  F_EXEC   = $0002;
  F_LNNO   = $0004;
  F_LSYMS  = $0008;
  F_AR32WR = $0100;

Type
  T_SCNHDR = Record
    s_name: Array[0..7] Of Char;  //* section name                     */
    s_paddr: CARDINAL;            //* physical address, aliased s_nlib */
    s_vaddr: CARDINAL;            //* virtual address                  */
    s_size: CARDINAL;             //* section size                     */
    s_scnptr: CARDINAL;           //* file ptr to raw data for section */
    s_relptr: CARDINAL;           //* file ptr to relocation           */
    s_lnnoptr: CARDINAL;          //* file ptr to line numbers         */
    s_nreloc: WORD;               //* number of relocation entries     */
    s_nlnno: WORD;                //* number of line number entries    */
    s_flags: CARDINAL;            //* flags                            */
  End;

Const
  STYP_TEXT = $0020;
  STYP_DATA = $0040;
  STYP_BSS  = $0080;

Type
  T_SYM_NAM = Record
    Case integer of
      0: (e_zeroes, e_offset: CARDINAL);
      1: (e_name: Array[0..7] Of Char);
  End;

  T_SYMENT = Record
    e: T_SYM_NAM;       // ??
    e_value: CARDINAL;
    e_scnum: SmallInt;  // 16 Bit Int
    e_type: Word;
    e_sclass: Byte;
    e_numaux: Byte;
  End;

  T_RELOC = Record
    r_vaddr,
    r_symndx: CARDINAL;
    r_type: WORD;
    r_etype: WORD;  // FAKE For MPASM !
  End;

  T_BBF = Record
     res1: Cardinal;
     snum: Word;
     res2,
     res3: Cardinal;
     next: Word;
     res4: Word;
  End;

  T_EBF = Record
     res1: Cardinal;
     snum: Word;
     res2,
     res3,
     res4: Cardinal;
  End;

  T_AVR_LNUM = Record
    l_paddr: Cardinal;
    l_lnno: Word;
  End;

//
// My Stuff
//

Type
  PCOFF_LdSymbol = ^TCOFF_LdSymbol;
  TCOFF_LdSymbol = Record
    e_name: String;     // Loaded from String Table if Reguired
    e_rvalue,           // Adjusted Value
    // T_SYMENT
    e_value: CARDINAL;
    e_scnum: SmallInt;  // 16 Bit Int
    e_type: Word;
    e_sclass: Byte;
    e_numaux: Byte;
  End;


Var
  COFF_FileHeader: T_FILHDR;
  COFF_SectionHeader: T_SCNHDR;
  COFF_SymbolEntry: T_SYMENT;
  COFF_AuxEntry: Array[0..17] Of Byte;
  COFF_Reloc: T_RELOC;
  //
  COFF_Stream: TFileStream;
  //
  COFF_LdSymbol: PCOFF_LdSymbol;
  COFF_SymList: TList;       // List of  TCOFF_LdSymbol


implementation

end.
