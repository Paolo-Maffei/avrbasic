(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit pars_avr;

interface

uses
  funcs,
  AVRCore,
  ToolSrv,

  Classes,
  Sysutils, { Strings }
  MStrings, { Myke's Strings }
  AsmSub,
  CompDef, { Comp Def's etc }
  CompUt,
  Common,
  prefer,
  NodePool, { Node Handling }
  Coff,
  Prep, { Preprocess.. }
  EvalCon,
  FunProc,
  doCOFF,
  ObjFiles,
  LstFile,
  EFile, { Error File }

  Eval_AVR, { Expression Evaluator }
  emit_AVR, { AVR Emitter }
  AVR_obj, { AVR Objects }
  HexFil4,
  BS1lex, blex, alex,
  emit; { Code Emitter }

procedure Parse_AVR;
procedure Init_AVR;
procedure Exit_AVR;
procedure Exit_Pass_AVR;

procedure Link_AVR;
procedure Link_AVR_Unit(name: string);


implementation
{$R-}

procedure Link_AVR_Unit(name: string);
var
  A8: array[0..8] of Char;
  nSyms,
    i, j, k: Integer;
  s: string;
  sect_ip: Integer;
  uname: string;

  code_snum,
    udata_snum,
    code_size,
    udata_loc,
    udata_size: Integer;

  relp,
    codeword: Word;
  code_stream: TMemoryStream;

begin

  udata_size := 0;
  code_size := 0;
  uname := name;

  uname := changefileext(uname, '.cof');
  sect_ip := ip;

  COFF_Stream := TFileStream.Create(uname, fmOpenRead);
  COFF_Stream.Read(COFF_FileHeader, SizeOf(COFF_FileHeader));
  // Skip Optional Header
  COFF_Stream.Seek(COFF_FileHeader.f_opthdr, soFromCurrent);

  for j := 1 to COFF_FileHeader.f_nscns do
  begin
    // Read Section Header
    COFF_Stream.Read(COFF_SectionHeader, SizeOf(COFF_SectionHeader));
    FillChar(A8, 9, 0);
    for i := 0 to 7 do A8[i] := COFF_SectionHeader.s_name[i];

    if StrComp(A8, '.udata') = 0 then begin
      // Add Variable Space
      udata_size := COFF_SectionHeader.s_size;
      udata_snum := j;
    end;
    if StrComp(A8, '.text') = 0 then begin
      code_size := COFF_SectionHeader.s_size;
      code_snum := j;
      //
      // Load Code Section Data
      //
    end;
    if pass = last_pass then
    begin
      code_stream := TMemoryStream.Create; // Create .code buffer
      code_stream.CopyFrom(COFF_Stream, code_size); // Copy
    end;
  end;

  // Seek to SYMTAB
  COFF_Stream.Seek(COFF_FileHeader.f_symptr, soFromBeginning);

  j := 1;
  while j <= COFF_FileHeader.f_nsyms do
  begin
    COFF_Stream.Read(COFF_SymbolEntry, SizeOf(COFF_SymbolEntry));
    FillChar(A8, 9, 0);
    if COFF_SymbolEntry.e.e_zeroes <> 0 then
      for i := 0 to 7 do A8[i] := COFF_SymbolEntry.e.e_name[i];

    case (COFF_SymbolEntry.e_sclass) of
      4: begin // REGISTER
          case COFF_SymbolEntry.e_type of
            $0C: begin // T_UCHAR
                DefineSymbol(StrPas(A8), COFF_SymbolEntry.e_value, 0, sym_DEF);
              end;
            $0D: begin // T_USHORT
                DefineSymbol(StrPas(A8), COFF_SymbolEntry.e_value, 0, sym_WORD);
              end;
          end;
        end;
      3: begin // STATIC
          case COFF_SymbolEntry.e_type of
            $06: begin // T_FLOAT
                DefineSymbol(StrPas(A8), COFF_SymbolEntry.e_value, 0, sym_SINGLE);
              end;
          end;
        end;
      2: begin // PUBLIC
          ip := sect_ip + COFF_SymbolEntry.e_value;
          InsertLabel(StrPas(A8), 0);
        end;
    end;

    Inc(j);
    // Skip Aux Entries!
    if COFF_SymbolEntry.e_numaux <> 0 then
    begin
      for k := 1 to COFF_SymbolEntry.e_numaux do
      begin
        COFF_Stream.Read(COFF_AuxEntry, SizeOf(COFF_AuxEntry));
        inc(j);
      end;
    end;
  end;
  COFF_Stream.Free;

  if pass = last_pass then
  begin
    ip := sect_ip; // IP
    code_stream.Seek(0, 0);

    if code_size <> 0 then
      for k := 0 to (code_size div 2) - 1 do
      begin
        code_stream.Read(codeword, 2);
        core.emit_word(codeword);
      end;
    code_stream.Free;
  end;


  // Fixup the Block
  ip := sect_ip + (COFF_SectionHeader.s_size div 2)

end;

procedure Link_AVR;
begin
  if doLibrary then Exit; // ??
  linenum := 1;

  // Floating Point Library
  if IsLibCallNeeded('FP_') then
  begin
    Link_AVR_Unit(RootDir + 'LIB\AVR\fplib.o');
    Exit;
  end;
  // Unsigned 16
  if IsLibCallNeeded('US16_') then
  begin
    Link_AVR_Unit(RootDir + 'LIB\AVR\us16lib.cof');
    Exit;
  end;
end;


procedure Exit_Pass_AVR;
begin
  AVR_Libcalls;
end;

procedure Parse_AVR;
label
  next_error;
var
  I, J, K: Integer;
  op: Word;
begin
// Dot Commands
//  if yy0^.yylex = T_DOT then begin
//    exit;
//  end;


  EvalConstTree(yy0); { Constant Expressions }
  EvalBR2Tree(yy0); { [] }
  EvalDotTree(yy0); { Dot Stuff, Object?   }
  EvalConstTree(yy0);
  EvalBR2Tree(yy0);
  if yy0 = nil then Exit;
  if inobject then Exit;

  if (yy0^.yylex = T_CONST) or (yy0^.yylex = T_DEFAULT) then begin
    if next_sw <= 0 then begin
      Error(91);
      goto next_error;
    end else begin
      InsertLabel('SWITCH@' + L2HEX(sw_cnt, 2) + '@' + L2HEX(SWStack[next_sw].N, 2), 0);
      inc(SWStack[next_sw].N);
      if yy0^.yylex = T_DEFAULT then begin
        //StrPCopy(SymLab.Name, 'SWITCH@' + L2HEX(sw_cnt, 2) + '@' + L2HEX(SWStack[next_sw].N, 2));
        //emit_fixup(SymLab, 0);
      end else begin
        StrPCopy(SwLab.Name, 'SWITCH@' + L2HEX(sw_cnt, 2) + '@' + L2HEX(SWStack[next_sw].N, 2));
        emit_bne(@SWStack[next_sw].V, yy0, @SwLab, 0);
      end;
    end;
    yy0 := DropNode(yy0); { Drop Const }
    yy0 := DropNode(yy0); { Drop: }
  end;

  if yy0^.Right = nil then Exit;

  if IfL(yy0^.Right, T_DOT) then
  begin
    EvalObjects(yy0);
    Exit;
  end;

  if (yy0^.yylex = T_LABEL) then begin
    if yy0^.Right^.yylex = T_COLON then
    begin
      DefineLabel(yy0, nil, 0);
      yy0 := DropNode(yy0);
      yy0 := DropNode(yy0);
    end else begin
      TmpLab := FindLabel(yy0); { Get Type }
      case TmpLab^.typ of
        0: begin
            if (yy0^.Right^.yylex = T_EQUAL) then begin
              Error(err_Undefined_Symbol);
            end else begin
              if (yy0^.Right^.yylex <> T_DOT) then
              begin
                // Define Labels without :
                //DefineLabel(yy0, Nil, 0);
                Error(err_Undefined_Label);
                Exit;
              end;
            end;
          end;
        1, 2, 3: begin
            if segment = 0 then
              emit_eval2(nil, yy0);
            Exit;
          end;
      end;
    end;
  end;

  if segment = 1 then
    case yy0^.yylex of
      T_23: begin
          doprep;
        end;
      T_EOF: begin //?

        end;
      //
      T_VARDEF: begin
          yy0 := DropNode(yy0); { Drop Var }
          yy1 := yy0; {}
          repeat
            yy1 := yy1^.Right;
          until (yy1^.Right = nil) or (yy1^.yylex = T_COLON) or (yy1^.yylex = T_NEWLINE);

          if yy1^.yylex = T_COLON then
          begin
            yy1 := yy1^.Right; { Get Type Declaration }
            if yy1^.yylex = T_TYPEDECL then
            begin
              { Type Declaration }
              expect(yy0, T_LABEL, 118);
              while (yy0^.yylex = T_LABEL) {or (yy0^.yylex = T_VAR)} do
              begin
                { Declare Variable! }
                case yy1^.val of
                  sym_SINGLE: begin
                      DefineSymbol(yy0^.Name, next_sram, 0, sym_SINGLE);
                      Inc(next_sram, 4);
                    end;
                  sym_BIT: begin
                      if IfL(yy1^.Right, T_AT) then
                      begin
                        { var i: Byte @ address }
                        if IfL(yy1^.Right^.Right, T_VAR) then begin
                          case yy1^.Right^.Right^.typ of
                            sym_DEF: begin
                                DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_DEF);
                              end;
                            sym_BIT: begin
                                DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val,
                                  yy1^.Right^.Right^.subval, sym_BIT);
                              end;
                            sym_ioBIT: begin
                                DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val,
                                  yy1^.Right^.Right^.subval, sym_ioBIT);
                              end;
                          end;
                        end;
                      end else begin
                        // auto allocated Bit Variables
                        if bit_free = 0 then begin
                          // Allocate a new Byte for Bit Variables
                          DefineSymbol('$BITVAR$' + IntToStr(bit_vars), next_h_reg, 0, sym_DEF);
                          bit_vaddr := next_h_reg; // Save Address
                          Dec(next_h_reg);
                          LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                          inc(bit_vars);
                          bit_free := 8;
                        end;
                        dec(bit_free);
                        DefineSymbol(yy0^.Name, bit_vaddr,
                          bit_free, sym_BIT);
                      end;
                    end;
                  sym_DEF: begin
                      if yy0^.Right^.yylex = T_LBRACKET2 then begin
                        { Var i[const]: Byte; }
                        DefineSymbol(yy0^.Name, next_h_reg - (yy0^.Right^.Right^.val - 1), yy0^.Right^.Right^.val, sym_DEF);
                        next_h_reg := next_h_reg - (yy0^.Right^.Right^.val);
                        LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                      end else begin
                        if IfL(yy1^.Right, T_AT) then begin
                          { var i: Byte @ address }
                          if IfL(yy1^.Right^.Right, T_VAR) then begin
                            case yy1^.Right^.Right^.typ of
                              sym_sDEF: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_sDEF);
                                end;
                              sym_EE: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_EE);
                                end;
                              sym_DEF: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_DEF);
                                end;
                              sym_IO: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_IO);
                                end;
                              sym_BIT: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_DEF);
                                end;
                              sym_ioBIT: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_IO);
                                end;
                            end;
                          end;
                        end else begin
                          { Define Byte/Char Variable }
                          { model                     }
                          if model = 1200 then
                          begin
                            DefineSymbol(yy0^.Name, next_h_reg, 0, sym_DEF);
                            Dec(next_h_reg);
                            LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                          end else begin
                            if locp = 0 then
                            begin
                              DefineSymbol(yy0^.Name, next_h_reg, 0, sym_DEF);
                              Dec(next_h_reg);
                              LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                            end else begin
                              DefineSymbol(yy0^.Name, LocalDef[locp].LocalUsed, 0, sym_lDEF);
                              LocalDef[locp].LocalUsed := LocalDef[locp].LocalUsed + 1;
                            end;
                          end;
                        end;
                      end;
                    end;

                  sym_Word: begin
                      if yy0^.Right^.yylex = T_LBRACKET2 then begin
                        DefineSymbol(yy0^.Name, next_h_reg - (yy0^.Right^.Right^.val - 1), yy0^.Right^.Right^.val, sym_Word);
                        next_h_reg := next_h_reg - (yy0^.Right^.Right^.val * 2);
                        LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 2;
                      end else begin
                        if IfL(yy1^.Right, T_AT) then begin
                          { var i: Byte @ address }
                          if IfL(yy1^.Right^.Right, T_VAR) then begin
                            case yy1^.Right^.Right^.typ of
                              sym_sDEF: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_Word);
                                end;
                              sym_Word,
                                sym_DEF: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_Word);
                                end;
                            end;
                          end;
                        end else begin
                          DefineSymbol(yy0^.Name, next_h_reg - 1, 0, sym_Word);
                          Dec(next_h_reg); Dec(next_h_reg);
                          LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 2;
                        end;
                      end;
                    end;

                  sym_Word32: begin
                      if yy0^.Right^.yylex = T_LBRACKET2 then begin
                        DefineSymbol(yy0^.Name, next_h_reg - (yy0^.Right^.Right^.val - 1), yy0^.Right^.Right^.val, sym_Word32);
                        next_h_reg := next_h_reg - (yy0^.Right^.Right^.val * 4);
                        LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 4;
                      end else begin
                        if IfL(yy1^.Right, T_AT) then begin
                          { var i: Byte @ address }
                          if IfL(yy1^.Right^.Right, T_VAR) then begin
                            case yy1^.Right^.Right^.typ of
                              sym_sDEF: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_Word32);
                                end;
                              sym_Word,
                                sym_DEF: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_Word32);
                                end;
                            end;
                          end;
                        end else begin
                          DefineSymbol(yy0^.Name, next_h_reg - 1, 0, sym_Word);
                          Dec(next_h_reg, 4);
                          LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 4;
                        end;
                      end;
                    end;
                end;
                yy0 := yy0^.Right;
                yy0 := yy0^.Right;
              end;
            end;
            Exit;
          end else begin
            error(118);
          end; //

          {? Var Ident [word] REG LOW }
          {!!!?
          isWord := False;
          if (yy0^.Right^.yylex = T_TYPEDECL) and (yy0^.Right^.val = sym_Word) then begin
            isWord := True;
            DropNode(yy0^.Right);
          end;
          }
        end;
      T_SEGMENT: begin
          yy0 := DropNode(yy0); { Drop Const }
          if IfL(yy0, T_LABEL) then
          begin
            if StrComp(yy0^.name, 'DATA') = 0 then
            begin
              segment := 1;
              gran := 1;
            end;
            if StrComp(yy0^.name, 'CODE') = 0 then
            begin
              if oddflag then
                emit_byte(0);
              gran := 2;
              segment := 0;
            end;
          end else begin

          end;
        end;
      T_NEWLINE: begin
          { Empty Line! }
        end;
      T_TYPEDECL: begin
          case yy0.val of
            sym_SINGLE: begin
              end;
            sym_DEF: begin
                yy0 := DropNode(yy0); // DROP WORD
                emit_byte(yy0^.val);
                yy0 := DropNode(yy0); // DROP 1st Value
                while IfL(yy0, T_COMMA) do
                begin
                  yy0 := DropNode(yy0); { DROP COMMA}
                  if yy0^.yylex = T_LABEL then yy0^.Val := FindLabelAddr(yy0^);
                  emit_byte(yy0^.val);
                  yy0 := DropNode(yy0); { Drop Data }
                end;
              end;
            sym_WORD:
              begin // BAD no WORD Align!
                if oddflag then
                  emit_byte(0);

                yy0 := DropNode(yy0); // DROP WORD
                if yy0^.yylex = T_LABEL then yy0^.Val := FindLabelAddr(yy0^);
                core.emit_word(yy0^.val);
                yy0 := DropNode(yy0); // DROP 1st Value
                while IfL(yy0, T_COMMA) do
                begin
                  yy0 := DropNode(yy0); { DROP COMMA}
                  if yy0^.yylex = T_LABEL then yy0^.Val := FindLabelAddr(yy0^);
                  core.emit_word(yy0^.val);
                  yy0 := DropNode(yy0); { Drop Data }
                end;
              end else begin
              Error(1011);
            end;
          end;
        end else begin
        Error(1009);
      end;
    end;

//************************************************************************

  { Action! }
  if segment = 0 then
    case yy0^.yylex of
      T_SEGMENT: begin
          yy0 := DropNode(yy0); { Drop Const }
          if IfL(yy0, T_LABEL) then
          begin
            if StrComp(yy0^.name, 'DATA') = 0 then
            begin
              segment := 1;
              gran := 1;
            end;
            if StrComp(yy0^.name, 'CODE') = 0 then
            begin
              gran := 2;
              segment := 0;
            end;
          end else begin

          end;
        end;
      T_NEWLINE: begin
          { Empty Line! }
        end;
      T_COLON: begin

        end;
      T_CONDEF: begin
          yy0 := DropNode(yy0); { Drop Const }
          if IfL(yy0, T_LABEL) then
          begin
            yy1 := yy0^.Right;
            case yy1^.yylex of
              T_EQUAL: begin
                  { Symbolic Const }
                  yy1 := DropNode(yy1); { Drop= }

                  case yy1^.yylex of
                    T_CONST: begin
                        { Define a new Const }
                        DefineSymbol(yy0^.Name, yy1^.val, 0, sym_Const);
                      end else begin
                      Error(err_Error_In_Symbol_Definition);
                      goto next_error;
                    end; { end case yy1}
                  end; { T_EQUAL}
                end;
              T_ROM: begin
                  J := ip * 2;
                  K := 0;
                  DefineSymbol(yy0^.Name, J, 0, sym_ROM);
                  DropNode(yy0^.Right); { ROM }
                  DropNode(yy0^.Right); { = }
                  yy1 := yy0^.Right; { First Value}

                  op := 0;
                  { first item }
                  if yy1^.yylex = T_CONST then begin
                    op := yy1^.val and 255;
                    yy1 := DropNode(yy1);
                  end else begin
                    Error(1999);
                  end;

                  K := 1;
                  while IfL(yy1, T_COMMA) do begin
                    if yy1^.Right^.yylex = T_CONST then begin
                      if (K and 1) = 0 then begin
                        op := yy1^.Right^.val and 255;
                        inc(K);
                      end else begin
                        op := op or (yy1^.Right^.val shl 8);
                        emit_typ(op);
                        K := 0;
                      end;
                    end;
                    yy1 := DropNode(yy1);
                    yy1 := DropNode(yy1);
                  end; {while}
                  { Emit if Odd byte left }
                  if (K and 1) <> 0 then begin
                    emit_typ(op);
                  end;
                end;
              { EEPROM String }
              T_EEPROM: begin
                  yy1 := DropNode(yy0^.Right); { Drop EEPROM }
                  J := next_ee;
                  if yy1^.yylex = T_AT then
                  begin
                    J := yy1^.Right^.val and $FFF;
                    I := 6;
                    DropNode(yy1^.Right); { Drop AT }
                    yy1 := DropNode(yy1); { Drop At }
                  end;
                  if yy1^.yylex = T_EQUAL then
                  begin
                    DefineSymbol(yy0^.Name, J, 0, sym_EE);

                    yy1 := DropNode(yy1);
                    { first item }
                    if yy1^.yylex = T_CONST then
                    begin
                      EEMEM[J] := yy1^.val and $FF;
                      inc(J);
                      inc(used_ee);
                    end;
                    yy1 := yy1^.Right;
                    while (yy1^.yylex = T_COMMA) do begin
                      yy1 := DropNode(yy1);
                      if yy1^.yylex = T_CONST then begin
                        EEMEM[J] := yy1^.val and $FF;
                        yy1 := DropNode(yy1);
                        inc(J);
                        inc(used_ee);
                      end; { end if }
                    end; { end while}
                  end; { if EQ }
                  next_ee := J;
                end;
            end;
          end;
        end;

      T_VARDEF: begin
          yy0 := DropNode(yy0); { Drop Var }
          yy1 := yy0;
          if yy1^.right <> nil then
          begin
            // Search for Colon
            repeat
              yy1 := yy1^.Right;
            until (yy1^.Right = nil) or (yy1^.yylex = T_COLON) or (yy1^.yylex = T_NEWLINE);

            if yy1^.yylex = T_COLON then
            begin
              yy1 := yy1^.Right; { Get Type Declaration }
              if yy1^.yylex = T_TYPEDECL then
              begin
                { Type Declaration }
                expect(yy0, T_LABEL, 118);
                while (yy0^.yylex = T_LABEL) do
                begin
                  { Declare Variable! }
                  case yy1^.val of
                    sym_SINGLE: begin
                        DefineSymbol(yy0^.Name, next_sram, 0, sym_SINGLE);
                        Inc(next_sram, 4);
                      end;
                    sym_BIT: begin
                        if IfL(yy1^.Right, T_AT) then
                        begin
                          { var i: Byte @ address }
                          if IfL(yy1^.Right^.Right, T_VAR) then begin
                            case yy1^.Right^.Right^.typ of
                              sym_DEF: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_DEF);
                                end;
                              sym_BIT: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val,
                                    yy1^.Right^.Right^.subval, sym_BIT);
                                end;
                              sym_ioBIT: begin
                                  DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val,
                                    yy1^.Right^.Right^.subval, sym_ioBIT);
                                end;
                            end;
                          end;
                        end else begin
                          // auto allocated Bit Variables
                          if bit_free = 0 then begin
                            // Allocate a new Byte for Bit Variables
                            DefineSymbol('$BITVAR$' + IntToStr(bit_vars), next_h_reg, 0, sym_DEF);
                            bit_vaddr := next_h_reg; // Save Address
                            Dec(next_h_reg);
                            LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                            inc(bit_vars);
                            bit_free := 8;
                          end;
                          dec(bit_free);
                          DefineSymbol(yy0^.Name, bit_vaddr,
                            bit_free, sym_BIT);

                        end;
                      end;
                    sym_DEF: begin
                        if yy0^.Right^.yylex = T_LBRACKET2 then
                        begin
                          { Var i[const]: Byte; }
                          DefineSymbol(yy0^.Name, next_h_reg - (yy0^.Right^.Right^.val - 1), yy0^.Right^.Right^.val, sym_DEF);
                          next_h_reg := next_h_reg - (yy0^.Right^.Right^.val);
                          LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                        end else begin
                          if IfL(yy1^.Right, T_AT) then begin
                            { var i: Byte @ address }
                            if IfL(yy1^.Right^.Right, T_VAR) then
                            begin
                              case yy1^.Right^.Right^.typ of
                                sym_sDEF: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_sDEF);
                                  end;
                                sym_EE: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_EE);
                                  end;
                                sym_DEF: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_DEF);
                                  end;
                                sym_IO: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_IO);
                                  end;
                                sym_BIT: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_DEF);
                                  end;
                                sym_ioBIT: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_IO);
                                  end;
                              end;
                            end else begin
                              Error(48);
                            end;
                          end else begin
                            { Define Byte/Char Variable }
                            { model                     }
                            if model = 1200 then
                            begin
                              DefineSymbol(yy0^.Name, next_h_reg, 0, sym_DEF);
                              Dec(next_h_reg);
                              LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                            end else begin
                              if locp = 0 then
                              begin
                                DefineSymbol(yy0^.Name, next_h_reg, 0, sym_DEF);
                                Dec(next_h_reg);
                                LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                              end else begin
                                DefineSymbol(yy0^.Name, LocalDef[locp].LocalUsed, 0, sym_lDEF);
                                LocalDef[locp].LocalUsed := LocalDef[locp].LocalUsed + 1;
                              end;
                            end;
                          end;
                        end;
                      end;

                    sym_Word: begin
                        if yy0^.Right^.yylex = T_LBRACKET2 then begin
                          DefineSymbol(yy0^.Name, next_h_reg - (yy0^.Right^.Right^.val - 1), yy0^.Right^.Right^.val, sym_Word);
                          next_h_reg := next_h_reg - (yy0^.Right^.Right^.val * 2);
                          LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 2;
                        end else begin
                          if IfL(yy1^.Right, T_AT) then
                          begin
                            { var i: Byte @ address }
                            if IfL(yy1^.Right^.Right, T_VAR) then
                            begin
                              case yy1^.Right^.Right^.typ of
                                sym_sDEF: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_Word);
                                  end;
                                sym_Word,
                                  sym_DEF: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_Word);
                                  end;
                              end;
                            end else begin
                              Error(48);
                            end;
                          end else begin
                            DefineSymbol(yy0^.Name, next_h_reg - 1, 0, sym_Word);
                            Dec(next_h_reg); Dec(next_h_reg);
                            LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 2;
                          end;
                        end;
                      end;

                    sym_Word32: begin
                        if yy0^.Right^.yylex = T_LBRACKET2 then begin
                          DefineSymbol(yy0^.Name, next_h_reg - (yy0^.Right^.Right^.val - 1), yy0^.Right^.Right^.val, sym_Word32);
                          next_h_reg := next_h_reg - (yy0^.Right^.Right^.val * 4);
                          LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 4;
                        end else begin
                          if IfL(yy1^.Right, T_AT) then begin
                            { var i: Byte @ address }
                            if IfL(yy1^.Right^.Right, T_VAR) then begin
                              case yy1^.Right^.Right^.typ of
                                sym_sDEF: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_Word32);
                                  end;
                                sym_Word,
                                  sym_DEF: begin
                                    DefineSymbol(yy0^.Name, yy1^.Right^.Right^.val, 0, sym_Word32);
                                  end;
                              end;
                            end;
                          end else begin
                            DefineSymbol(yy0^.Name, next_h_reg - 1, 0, sym_Word);
                            Dec(next_h_reg, 4);
                            LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 4;
                          end;
                        end;
                      end;

                  end;
                  yy0 := yy0^.Right; // Drop varname
                  yy0 := yy0^.Right; // Drop , or :
                end;
//                expect(yy0, T_TYPEDECL, 119);
              end else
              begin
                Error(47);
              end;
              Exit;
            end else
            begin
              Error(46);
            end; //
            { Var Ident [word] REG LOW }
            isWord := False;
            if (yy0^.Right^.yylex = T_TYPEDECL) and (yy0^.Right^.val = sym_Word) then begin
              isWord := True;
              DropNode(yy0^.Right); { drop word }
            end;

            case yy0^.Right^.yylex of
              T_REG: begin
                  DropNode(yy0^.Right); { drop reg }
                  if yy0^.Right^.yylex = T_LOW then begin
                    if isWord then begin
                      DefineSymbol(yy0^.Name, next_l_reg, 0, sym_Word);
                      inc(next_l_reg);
                      inc(next_l_reg);
                      LocalDef[locp].LoUsed := LocalDef[locp].LoUsed + 2;
                    end else begin
                      DefineSymbol(yy0^.Name, next_l_reg, 0, sym_DEF);
                      inc(next_l_reg);
                      LocalDef[locp].LoUsed := LocalDef[locp].LoUsed + 1;
                    end;
                  end else begin
                    if isWord then begin
                      Dec(next_h_reg);
                      DefineSymbol(yy0^.Name, next_h_reg, 0, sym_Word);
                      Dec(next_h_reg);
                      LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 2;
                    end else begin
                      DefineSymbol(yy0^.Name, next_h_reg, 0, sym_DEF);
                      Dec(next_h_reg);
                      LocalDef[locp].HiUsed := LocalDef[locp].HiUsed + 1;
                    end;
                  end;
                end;
              // Var i EEPROM[]
              T_EEPROM: begin
                  DropNode(yy0^.Right); { drop reg }
                  if yy0^.Right^.yylex = T_LOW then begin
                    DefineSymbol(yy0^.Name, next_eel_reg, 0, sym_EE);
                    inc(next_eel_reg);
                  end else begin
                    DefineSymbol(yy0^.Name, next_eeh_reg, 0, sym_EE);
                    Dec(next_eeh_reg);
                  end;
                end;
            end;
          end else begin
            error(45);
          end;

        end;
      T_INTERRUPT: begin
          if not has_sram then LocalDef[locp].bRegister := True;
          LocalDef[locp].bInterrupt := True;
        end;
      T_Assembler: begin
          LocalDef[locp].bAssembler := True;
          LocalDef[locp].bRegister := False;
        end;
      T_REG: begin
          LocalDef[locp].bRegister := True;
        end;
      T_FUNCTION: begin
          if locp = 0 then next_local_sym := 0;

          inc(locp); { Increase nesting! }
          LocalDef[locp].LastSym := next_local_sym; { Save Symbol pointer! }
          LocalDef[locp].LoUsed := 0;
          LocalDef[locp].HiUsed := 0;
          LocalDef[locp].LocalUsed := 0;
          LocalDef[locp].bInterrupt := False;
          LocalDef[locp].bAssembler := False;
          LocalDef[locp].bRegister := False;

          AddProcedure(yy0);
        end;
      T_PROCEDURE: begin
          if locp = 0 then next_local_sym := 0;
          inc(locp); { Increase nesting! }
          LocalDef[locp].LastSym := next_local_sym; { Save Symbol pointer! }
          LocalDef[locp].LoUsed := 0;
          LocalDef[locp].HiUsed := 0;
          LocalDef[locp].LocalUsed := 0;
          LocalDef[locp].bInterrupt := False;
          LocalDef[locp].bAssembler := False;
          LocalDef[locp].bRegister := False;

          AddProcedure(yy0);
          Exit;
        end;
      T_SWITCH: begin
          inc(next_sw); { Current Level }
          SWStack[next_sw].V := yy0^.Right^; { Save Switch Variable }
          SWStack[next_sw].N := 0; { Clear Statent Count  }
          inc(sw_cnt); { Total Count..}
          inc(cend);
          e2[cend] := T_SWITCH; { Next End to Match }
        end;

      T_BEGIN: begin
          assume_none;
          inc(be);

          if locp = 0 then
          begin { Define Main Procedure! }
            // Main Entry Generated...

            if pass >= 10 then
              if p_lstfile then
                WrLstLine('---- MAIN ENTRY POINT ASSUMED HERE ----');
            { Main Entrance }
            vectors[0] := ip;

            if has_sram and
              (pass > 0) and StackNeeded and (not UserStackOk) or DoInitStack then
            begin
              DoInitStack := True;

              Tmp.Val := $3D; // SPL
              emit_ldi(WREG, sram_top);
              emit_out(Tmp, WREG);

              if sram_top > 255 then
              begin
                Tmp.Val := $3E; // SPH
                emit_ldi(WREG, (sram_top) shr 8);
                emit_out(Tmp, WREG);
              end;
              if pass >= 10 then
                if p_lstfile then
                  WrLstLine('---- Default Stack Init Added ----');
            end;

            //
            // Call AutoInit
            //
            yy1 := ProcPool;
            if yy1 <> nil then
            begin
              repeat
                if StrPos(yy1.name, '$CREATE') <> nil then
                begin
                  emit_call(FindLabelAddr(yy1^));
                end;
                // next procedure
                yy1 := yy1^.right;
              until yy1 = nil;
            end;


          end;

          if locp <> 0 then
          begin // ??
            if LocalDef[locp].bInterrupt then begin
              if LocalDef[locp].bAssembler then begin
              end else begin
                if LocalDef[locp].bRegister or (not has_sram) then begin
                  bIntUsesSREG := True;
                  bIntUsesWREG := True;
                  IntrCode(0, True);

                end else IntrCode(0, LocalDef[locp].bRegister);
              end;
            end;
          end;
        end;
      T_BREAK: begin
          assume_none;
          StrPCopy(SwLab.Name, 'SWITCH@' + L2HEX(sw_cnt, 2) + '@BREAK');
          emit_jmp(FindLabelAddr(SwLab));
        end;
      T_ELSE: begin
          if e2[cend] <> T_IFTHEN then error(err_else_without_if);
          assume_none;
          StrPCopy(SwLab.Name, 'IF@' + L2HEX(IFStack[next_if].num, 3) + '@END');
          emit_jmp(FindLabelAddr(SwLab));

          InsertLabel('IF@' + L2HEX(IFStack[next_if].num, 3) + '@ELSE', 0);
          IFStack[next_if].typ := 1;
        end;
      T_PROGEND: begin
          // jump to..? WDR? DI?
          if be <> 1 then Error(9997);
          dec(be);
          core.emit_word($CFFF);
          // todo
        end;
      T_END: begin
          assume_none;
          if (cend = 0) and (be = 0) then error(1234);

          case e2[cend] of
            T_IFTHEN: begin
                if IFStack[next_if].typ = 0 then
                  InsertLabel('IF@' + L2HEX(IFStack[next_if].num, 3) + '@ELSE', 0);
                InsertLabel('IF@' + L2HEX(IFStack[next_if].num, 3) + '@END', 0);

                Dec(next_if); { Decrease Level }
                e2[cend] := 0; { ? }
                Dec(cend);
                Exit;
              end;
            T_SWITCH: begin
                { Last Jump Label }
                InsertLabel('SWITCH@' + L2HEX(sw_cnt, 2) + '@' + L2HEX(SWStack[next_sw].N, 2), 0);
                InsertLabel('SWITCH@' + L2HEX(sw_cnt, 2) + '@BREAK', 0);

                Dec(next_sw); { Decrease Level }
                e2[cend] := 0; { ? }
                Dec(cend);
                Exit;
              end;
            { Function or Procedure }
            0: begin
                Dec(be);
                if locp = 0 then
                begin
                  emit_jmp(ip);
                end else
                begin
                  {}
                  if LocalDef[locp].bInterrupt then begin
                    if LocalDef[locp].bAssembler then begin
                    end else begin
                      IntrCode(1, LocalDef[locp].bRegister);
                    end;
                    emit_reti;
                  end else begin
                    if model = 1200 then
                    begin
                      next_l_reg := next_l_reg - LocalDef[locp].LoUsed;
                      next_h_reg := next_h_reg + LocalDef[locp].HiUsed;
                    end else begin
                      if LocalDef[locp].LocalUsed <> 0 then begin
                        tcon.val := LocalDef[locp].LocalUsed;
                        emitn_adiw(@Y, @tcon);
                      end;
                    end;
                    emit_ret; { Return from Proc }
                  end;
                  next_local_sym := LocalDef[locp].LastSym; { Forget Local Symbols }
                  Dec(locp);
                end;
                { Fun Proc }
              end else begin
                // unknown
              error(9999);

            end;
          end; { case}

        end; // T_END
      { # line 99 }
      T_23: begin
          doprep;
        end;
      { 0   1 2  }
      { Var = VarConst }
      T_VAR: begin
          Evaluate(yy0, yy0); // Errors Here!
        end;

      T_SYMBOL: begin
          yy0 := DropNode(yy0);
          { 0      1     2 3   }
          { Symbol Label = Def }
          if yy0^.yylex = T_LABEL then begin
            yy1 := yy0^.Right;
            if yy1^.yylex = T_EQUAL then begin
              yy1 := DropNode(yy1); { Drop= }
              case yy1^.yylex of
                T_EEPROM: begin
                    yy1 := DropNode(yy1); { Drop EEPROM }
                    yy1 := DropNode(yy1); { Drop [ }

                    if yy1^.yylex = T_CONST then begin
                      DefineSymbol(yy0^.Name, yy1^.val, 0, sym_EE);
                    end;
                  end;
                T_VAR: begin
                    { Define a new Variable }
                    DefineSymbol(yy0^.Name, yy1^.val, yy1^.subval, yy1^.typ);
                  end;
                T_CONST: begin
                    { Define a new Const }
                    DefineSymbol(yy0^.Name, yy1^.val, 0, sym_Const);
                  end else
                Error(err_Error_In_Symbol_Definition);
                goto next_error;
              end;
            end;
          end;
        end;
      { Implied LET RAM[] = }
      T_RAM: begin
          yy2 := yy0; { T_RAM    }
          yyc := yy0^.Right; { Drop RAM }
          bpre := 0;
          { 0  12    3 4 5 }
          { RAM[index] = Value }
          if (yyc^.yylex = T_LBRACKET2) then begin
            yyc := DropNode(yyc); { Drop [ }

            if yyc^.yylex = T_DECDEC then begin
              yyc := DropNode(yyc); { Drop -- }
              bpre := 2; { pre-decrement }
            end;

            if yyc^.Right^.yylex = T_INCINC then begin
              DropNode(yyc^.Right); { Drop ++ }
              bpre := 1; { post-incre }
            end;

            IX := @ZL;
            TCon.val := 0;

            if ((yyc^.typ = sym_DEF) or (yyc^.typ = sym_Word)) and
              (yyc^.yylex = T_VAR) and
              ((yyc^.val = 26) or (yyc^.val = 28) or (yyc^.val = 30)) then
            begin
              if ((yyc^.val = 28) or (yyc^.val = 30)) and (yyc^.Right^.yylex = T_MATH)
                and (yyc^.Right^.Right^.yylex = T_CONST) then begin
                if (yyc^.Right^.Right^.val < 64) and ((yyc^.Right^.val = 2) or (yyc^.Right^.val = 3)) then
                begin
                  TCon.val := yyc^.Right^.Right^.val;
                  DropNode(yyc^.Right);
                  DropNode(yyc^.Right);
                end;
              end;

              yy0 := yyc; { X, Y }
              IX := yyc;
            end else begin
              yy0 := emit_eval2(IX, yyc); { Evaluate Index! }
            end;
            {
            yy0 := emit_eval2(@ZL, yyc);
                                                      }
            case yy0^.yylex of
              T_VAR: begin
                  { RAM[var] = }
                  emit_assign(IX, yy0);

                  if yy2^.val <> 0 then
                  begin
                    yy2^.typ := sym_Const;
                    yy2^.yylex := T_CONST;
                    emit_plus(IX, IX, yy2);
                  end;

                  yyc := DropNode(yyc); { Drop index }
                  yyc := DropNode(yyc); { Drop ] }
                  yyc := DropNode(yyc); { Drop = }
                  yy0 := emit_eval2(@WREG, yyc); { Eval Value ?? }
                  case yy0^.yylex of
                    T_VAR: begin
                        case yy0^.typ of
                          sym_DEF: begin
                              if bpre = 0 then emitn_std(yy0, IX, @TCon);
                              if bpre = 1 then emitn_stp(yy0, IX);
                              if bpre = 2 then emitn_stm(yy0, IX);
                            end; { sym_DEF}
                          sym_WORD: begin
                              {#todo1 eval ram[]}
                              if bpre = 0 then emitn_std(yy0, IX, @TCon);

                              if bpre = 1 then begin
                                emitn_stp(yy0, IX);
                                yy0^.val := yy0^.val + 1;
                                emitn_stp(yy0, IX);
                              end;
                              if bpre = 2 then begin
                                yy0^.val := yy0^.val + 1;
                                emitn_stm(yy0, IX);
                                yy0^.val := yy0^.val - 1;
                                emitn_stm(yy0, IX);
                              end;
                            end; { sym_DEF}

                        end; { case 5}
                      end; { T_VAR}
                    T_CONST: begin // BUGBUG
                        { RAM[var] = const }
                        emit_ldi(WREG, yy0^.val);
                        emit_st(WREG);
                      end;
                  end;
                end;
            end;
          end;
        end;
      { EEPROM[] = }
      T_EEPROM: begin
          yyc := DropNode(yy0); { Drop EEPROM }
          case yyc^.yylex of
            T_DOT: begin
              end;
            { 0     1  2  3 4 5  }
            { EEPROM[index] = var }
            T_LBRACKET2: begin
                { Get Index }
                yyc := DropNode(yyc); { Drop [ }
                TempSym.val := a_EEAR; {EEAR}

                yy0 := emit_eval2(@WREG, yyc); { Eval Index }
                case yy0^.typ of
                  sym_DEF: begin
                      emit_out(TempSym, yy0^);
                    end;
                  sym_Const: begin
                      emit_ldi(WREG, yy0^.val);
                      emit_out(TempSym, WREG);
                    end;
                end;
                yyc := DropNode(yyc); { Drop index }
                yyc := DropNode(yyc); { Drop ] }
                yyc := DropNode(yyc); { Drop = }

                TempSym.val := a_EEDR; {EEDR}
                yy0 := emit_eval2(nil, yyc); { Eval Value }
                case yy0^.yylex of
                  T_VAR, T_CONST: begin
                      case yy0^.typ of
                        sym_DEF: begin
                            emit_out(TempSym, yy0^);
                          end;
                        sym_Const: begin
                            emit_ldi(WREG, yy0^.val);
                            emit_out(TempSym, WREG);
                          end;
                      end;
                    end;
                end;
                emit_ee_wr(nil, nil, '');
              end;
          end;
        end;
      { use Rx as WREG }
      { use default as WREG }
      { use EEPROM WAIT }
      { use not EEPROM WAIT }
      T_USE: begin
          yy1 := DropNode(yy0); { Drop Use }
          yy2 := yy1^.Right;
          yy3 := yy2^.Right;
          if yy1^.yylex = T_LABEL then
          begin

          end;

          if yy2^.yylex = T_AS then
            case yy3^.yylex of
              T_VAR: begin
                  { Use R30 as WREG }
                  if StrComp(yy3^.Name, 'WREG') = 0 then begin
                    if yy1^.yylex = T_DEFAULT then WREG.val := wreg_def;
                    if yy1^.yylex = T_VAR then begin
                      WREG.val := yy1^.val;
                      wreg_def := WREG.val; { ??!!! }
                    end;
                  end;
                end;
            end;
          {
                      If (yy1^.yylex = T_EEPROM) and (yy2^.val = T_WAIT) Then
                      Begin
                        use_eewait := True;
                      End;
          If (yy1^.yylex = T_NOT) And (yy2^.yylex = T_EEPROM) And (yy2^.Right^.val = T_WAIT) Then Begin
            use_eewait := False;
          End;
          }
        end;

      T_USES: begin
          yy0 := DropNode(yy0);
          if yy0 <> nil then
          begin
            if yy0^.yylex <> T_LABEL then Error(1999) // Bad USES
            else begin
              Link_AVR_Unit(StrPas(yy0^.name));
            end;
            yy0 := DropNode(yy0); // Drop Name
          end;

          if yy0 <> nil then
            while yy0^.yylex = T_COMMA do
            begin
              yy0 := DropNode(yy0); // drop comma
              if yy0^.yylex <> T_LABEL then Error(1999) // Bad USES
              else begin
                Link_AVR_Unit(StrPas(yy0^.name));
              end;
              if yy0^.right <> nil then
                yy0 := DropNode(yy0);
            end;
        end;

      T_PUBLIC: begin
          if pass = 10 then
          begin
            if yy0^.Right <> nil then begin
              case yy0^.Right^.yylex of
                T_LABEL: mCOFF.AddSymbol(StrPas(yy0^.Right^.Name), FindLabelAddr(yy0^.Right^), 0, 2);
                T_VAR: begin
                    case yy0^.Right^.typ of
                      // C_REG T_UCHAR
                      sym_DEF: begin
                          mCOFF.AddSymbol(StrPas(yy0^.Right^.Name), $FFFFFF00 or yy0^.Right^.val, $0C, 4);
                        end;
                      // C_REG T_USHORT
                      sym_WORD: mCOFF.AddSymbol(StrPas(yy0^.Right^.Name), $FFFFFF00 or yy0^.Right^.val, $0D, 4);
                      // C_STAT T_FLOAT
                      sym_SINGLE: mCOFF.AddSymbol(StrPas(yy0^.Right^.Name), yy0^.Right^.val, $06, 3);
                    end;
                  end;
              end;
            end;

          end;
        end;

      T_TOKEN: begin
          case yy0^.val of
            //------------- asm only
            T_MUL: begin
              emitn_mul(yy0^.right^, yy0^.right^.right^.right^);
            end;
            // oops!!
            T_SPM: begin
                emit_typ($95E8);
              end;  { TODO : lpm rn }
            T_LPM: begin
                if (yy0^.right <> nil) and (yy0^.right^.yylex = T_VAR) then
                begin
                  yy0 := DropNode(yy0);
                // LD R0,Z
                // LD R0,Z+
                // LD R0,-Z
                  if yy0^.yylex = T_VAR then
                  begin
                    yy1 := @TempSym;
                    yy1.Val := 0;
                    if yy0^.right^.right^.right <> nil then
                    begin
                      if yy0^.right^.right^.right^.yylex = T_MATH then
                      begin
                      //z+
                        yy1 := yy0^.right^.right^.right;
                        DropNode(yy0^.right^.right^.right);
                      end;
                      if yy0^.right^.right^.yylex = T_MATH then
                      begin
                      //-z
                        yy1 := yy0^.right^.right;
                        DropNode(yy0^.right^.right);
                      end;
                    end;
                    if (yy0^.right^.right^.name = 'X') then yy0^.right^.right^.val := 26;
                    if (yy0^.right^.right^.name = 'Y') then yy0^.right^.right^.val := 28;
                    if (yy0^.right^.right^.name = 'Z') then yy0^.right^.right^.val := 30;
                  //
                    case yy1^.val of
                      0: emitn_ldd(yy0, yy0^.right^.right, CON(0));
                    {-}
                      2: emitn_ldm(yy0, yy0^.right^.right);
                    {+}
                      3: emitn_lpmp(yy0, yy0^.right^.right);
                    end;
                  end;
                end else begin
                  emit_typ($95C8);
                end;
              end;
            T_ELPM: begin
                emit_typ($95D8);
              end;
            T_WDR: begin
                emit_typ($95A8);
              end;
            T_SLEEP: begin
                emit_typ($9588);
              end;
            //
            T_SEI: begin
                core.ei;
              end;
            T_CLI: begin
                core.di;
              end;
            T_LDI: begin
                emit_ldi(yy0^.right^, yy0^.right^.right^.right^.val);
              end;
            T_SER: begin
                emit_ldi(yy0^.right^, 255);
              end;
            T_CLR: begin
                emit_eor(yy0^.right^, yy0^.right^);
              end;
            T_TST: begin
                emit_and(yy0^.right^, yy0^.right^);
              end;
            T_SBR: begin
                emit_ori(yy0^.right^, yy0^.right^.right^.right^.val);
              end;
            T_CBR: begin
                emit_andi(yy0^.right^, yy0^.right^.right^.right^.val xor 255);
              end;

            T_LD: begin
                yy0 := DropNode(yy0);
                // LD R0,Z
                // LD R0,Z+
                // LD R0,-Z
                yy1 := @TempSym;
                yy1.Val := 0;
                if yy0^.right^.right^.right <> nil then
                begin
                  if yy0^.right^.right^.right^.yylex = T_MATH then
                  begin
                    //z+
                    yy1 := yy0^.right^.right^.right;
                    DropNode(yy0^.right^.right^.right);
                  end;
                  if yy0^.right^.right^.yylex = T_MATH then
                  begin
                    //-z
                    yy1 := yy0^.right^.right;
                    DropNode(yy0^.right^.right);
                  end;
                end;
                if (yy0^.right^.right^.name = 'X') then yy0^.right^.right^.val := 26;
                if (yy0^.right^.right^.name = 'Y') then yy0^.right^.right^.val := 28;
                if (yy0^.right^.right^.name = 'Z') then yy0^.right^.right^.val := 30;
                //
                case yy1^.val of
                  0: emitn_ldd(yy0, yy0^.right^.right, CON(0));
                  {-}
                  2: emitn_ldm(yy0, yy0^.right^.right);
                  {+}
                  3: emitn_ldp(yy0, yy0^.right^.right);
                end;
                //#todo1 ld z+
              end;
            T_LDS: begin
                emitn_lds(yy0^.right, yy0^.right^.right^.right);
              end;
            T_LDD: begin
                // 0   1 2 3 4 5
                // LDD R0, Y + K
                yy0 := DropNode(yy0);
                if (yy0^.right^.right^.name = 'Y') then yy0^.right^.right^.val := 28;
                if (yy0^.right^.right^.name = 'Z') then yy0^.right^.right^.val := 30;

                emitn_ldd(yy0, yy0^.right^.right, yy0^.right^.right^.right^.right);
              end;
            T_ST: begin
                yy0 := DropNode(yy0);
                // LD Z,R0
                // LD Z+,R0
                // LD -Z,R0
                yy1 := @TempSym;
                yy1.Val := 0;
                if yy0^.right^.right^.right <> nil then
                begin
                  if yy0^.right^.yylex = T_MATH then
                  begin
                    //z+
                    yy1 := yy0^.right;
                    DropNode(yy0^.right);
                  end;
                  if yy0^.yylex = T_MATH then
                  begin
                    //-z
                    yy1 := yy0;
                    yy0 := DropNode(yy0);
                  end;
                end;
                if (yy0^.name = 'X') then yy0^.val := 26;
                if (yy0^.name = 'Y') then yy0^.val := 28;
                if (yy0^.name = 'Z') then yy0^.val := 30;
                //
                case yy1^.val of
                  0: emitn_std(yy0^.right^.right, yy0, CON(0));
                  {-}
                  2: emitn_stm(yy0^.right^.right, yy0);
                  {+}
                  3: emitn_stp(yy0^.right^.right, yy0);
                end;
                //#todo1 ld z+??
              end;
            T_STS: begin
                emitn_sts(yy0^.right^.right^.right, yy0^.right);
              end;
            T_STD: begin
                // 0   1 2 34  5
                // LDD Y + K, R0
                yy0 := DropNode(yy0);
                if (yy0^.name = 'Y') then yy0^.val := 28;
                if (yy0^.name = 'Z') then yy0^.val := 30;

                emitn_std(yy0^.right^.right^.right^.right, yy0, yy0^.right^.right);
              end;
            T_MOV: begin
                emit_mov(yy0^.right^, yy0^.right^.right^.right^);
              end;
            T_MOVW: begin
                emit_movw(yy0^.right^, yy0^.right^.right^.right^);
              end;
            T_ADIW: begin
                emitn_adiw(yy0^.right, yy0^.right^.right^.right);
              end;
            T_SBIW: begin
                emitn_sbiw(yy0^.right, yy0^.right^.right^.right);
              end;
            T_SUBI: begin
                emit_subi(yy0^.right^, yy0^.right^.right^.right^.val);
              end;
            T_ANDI: begin
                emit_andi(yy0^.right^, yy0^.right^.right^.right^.val);
              end;
            T_CPI: begin
                emit_cp(yy0^.right^, yy0^.right^.right^.right^);
              end;
            T_CPSE: begin
                emit_Typ2a(yy0^.right^, yy0^.right^.right^.right^, T_CPSE);
              end;
            T_IN: begin
                emit_in(yy0^.right^, yy0^.right^.right^.right^);
              end;
            T_OUT: begin
                emit_out(yy0^.right^, yy0^.right^.right^.right^);
              end;

            //
            T_BRBC: begin
                emit_brbc(yy0^.right^.val, yy0^.right^.right^.right);
              end;
            T_BRBS: begin
                emit_brbs(yy0^.right^.val, yy0^.right^.right^.right);
              end;
            //
            T_BRCC: begin
                emit_brbc(0, yy0^.right);
              end;
            T_BRCS: begin
                emit_brbs(0, yy0^.right);
              end;
            T_BRNE: begin
                emit_brbc(1, yy0^.right);
              end;
            T_BREQ: begin
                emit_brbs(1, yy0^.right);
              end;
            T_BRPL: begin
                emit_brbc(2, yy0^.right);
              end;
            T_BRMI: begin
                emit_brbs(2, yy0^.right);
              end;
            T_BRVC: begin
                emit_brbc(3, yy0^.right);
              end;
            T_BRVS: begin
                emit_brbs(3, yy0^.right);
              end;
            T_BRGE: begin
                emit_brbc(4, yy0^.right);
              end;
            T_BRLT: begin
                emit_brbs(4, yy0^.right);
              end;
            T_BRHC: begin
                emit_brbc(5, yy0^.right);
              end;
            T_BRHS: begin
                emit_brbs(5, yy0^.right);
              end;
            T_BRTC: begin
                emit_brbc(6, yy0^.right);
              end;
            T_BRTS: begin
                emit_brbs(6, yy0^.right);
              end;
            T_BRID: begin
                emit_brbc(7, yy0^.right);
              end;
            T_BRIE: begin
                emit_brbs(7, yy0^.right);
              end;


            // ASMStuff
            T_ICALL: begin
                emit_typ($9509);
              end;
            T_IJMP: begin
                emit_typ($9409);
              end;

            T_CLT: begin
                emit_typ($94E8);
              end;
            T_SET: begin
                emit_typ($9468);
              end;
            T_CLZ: begin
                emit_typ($9498);
              end;
            T_SEZ: begin
                emit_typ($9418);
              end;
            T_CLH: begin
                emit_typ($94D8);
              end;
            T_SEH: begin
                emit_typ($9458);
              end;
            T_CLV: begin
                emit_typ($94B8);
              end;
            T_SEV: begin
                emit_typ($9438);
              end;
            T_CLC: begin
                emit_typ($9488);
              end;
            T_SEC: begin
                emit_typ($9408);
              end;
            T_CLN: begin
                emit_typ($94A8);
              end;
            T_SEN: begin
                emit_typ($9428);
              end;
            T_CLS: begin
                emit_typ($94C8);
              end;
            T_SES: begin
                emit_typ($9448);
              end;
            T_BCLR: begin
                case yy0^.right^.yylex of
                  T_CONST: begin
                      emit_typ($9488 or (yy0^.right^.val shl 4 and $0070));
                    end;
                  T_VAR: begin
                      emit_typ($9488 or (yy0^.right^.subval shl 4 and $0070));
                    end;
                end;
              end;
            T_BSET: begin
                case yy0^.right^.yylex of
                  T_CONST: begin
                      emit_typ($9408 or (yy0^.right^.val shl 4 and $0070));
                    end;
                  T_VAR: begin
                      emit_typ($9408 or (yy0^.right^.subval shl 4 and $0070));
                    end;
                end;
              end;
            T_BLD: begin
                if yy0^.right^.yylex = T_VAR then
                begin
                  yy0 := DropNode(yy0);
                  case yy0^.typ of
                    sym_DEF: begin
                        // BLD RD,   b RD.b := T
                        if IfL(yy0^.right, T_COMMA) then
                        begin
                          yy1 := DropNode(yy0^.right);
                          emit_typ($F800 or (yy0^.val shl 4 and $01F0) or (yy1^.right^.val and $0007));
                        end;
                      end;
                    sym_bit: begin
                        // BLD RD,   b RD.b := T
                        emit_typ($F800 or (yy0^.val shl 4 and $01F0) or (yy0^.subval and $0007));
                      end;
                  end;
                end;
              end;
            T_BST: begin
                if yy0^.right^.yylex = T_VAR then
                begin
                  yy0 := DropNode(yy0);
                  case yy0^.typ of
                    sym_DEF: begin
                        // BLD RD,   b RD.b := T
                        if IfL(yy0^.right, T_COMMA) then
                        begin
                          yy1 := DropNode(yy0^.right);
                          emit_typ($FA00 or (yy0^.val shl 4 and $01F0) or (yy1^.right^.val and $0007));
                        end;
                      end;
                    sym_bit: begin
                        // BLD RD,   b RD.b := T
                        emit_typ($FA00 or (yy0^.val shl 4 and $01F0) or (yy0^.subval and $0007));
                      end;
                  end;
                end;
              end;
            T_CBI: begin
                if yy0^.right^.yylex = T_VAR then
                begin
                  yy0 := DropNode(yy0);
                  case yy0^.typ of
                    sym_io: begin
                        // BLD RD,   b RD.b := T
                        if IfL(yy0^.right, T_COMMA) then
                        begin
                          yy1 := DropNode(yy0^.right);
                          yy0^.subval := yy1^.right^.val;
                          emit_cbi(yy0^);
                        end;
                      end;
                    sym_iobit: begin
                        emit_cbi(yy0^);
                      end;
                  end;
                end;
              end;
            T_SBI: begin
                if yy0^.right^.yylex = T_VAR then
                begin
                  yy0 := DropNode(yy0);
                  case yy0^.typ of
                    sym_io: begin
                        // BLD RD,   b RD.b := T
                        if IfL(yy0^.right, T_COMMA) then
                        begin
                          yy1 := DropNode(yy0^.right);
                          yy0^.subval := yy1^.right^.val;
                          emit_sbi(yy0^);
                        end;
                      end;
                    sym_iobit: begin
                        emit_sbi(yy0^);
                      end;
                  end;
                end;
              end;

            T_SBIC: begin
                if yy0^.right^.yylex = T_VAR then
                begin
                  yy0 := DropNode(yy0);
                  case yy0^.typ of
                    sym_io: begin
                        // BLD RD,   b RD.b := T
                        if IfL(yy0^.right, T_COMMA) then
                        begin
                          yy1 := DropNode(yy0^.right);
                          yy0^.subval := yy1^.right^.val;
                          emit_sbic(yy0^);
                        end;
                      end;
                    sym_iobit: begin
                        emit_sbic(yy0^);
                      end;
                  end;
                end;
              end;

            T_SBIS: begin
                if yy0^.right^.yylex = T_VAR then
                begin
                  yy0 := DropNode(yy0);
                  case yy0^.typ of
                    sym_io: begin
                        // BLD RD,   b RD.b := T
                        if IfL(yy0^.right, T_COMMA) then
                        begin
                          yy1 := DropNode(yy0^.right);
                          yy0^.subval := yy1^.right^.val;
                          emit_sbis(yy0^);
                        end;
                      end;
                    sym_iobit: begin
                        emit_sbis(yy0^);
                      end;
                  end;
                end;
              end;

            T_SBRC: begin
                if yy0^.right^.yylex = T_VAR then
                begin
                  yy0 := DropNode(yy0);
                  case yy0^.typ of
                    sym_def: begin
                        // BLD RD,   b RD.b := T
                        if IfL(yy0^.right, T_COMMA) then
                        begin
                          yy1 := DropNode(yy0^.right);
                          yy0^.subval := yy1^.right^.val;
                          emit_sbrc(yy0^);
                        end;
                      end;
                    sym_bit: begin
                        emit_sbrc(yy0^);
                      end;
                  end;
                end;
              end;

            T_SBRS: begin
                if yy0^.right^.yylex = T_VAR then
                begin
                  yy0 := DropNode(yy0);
                  case yy0^.typ of
                    sym_def: begin
                        // BLD RD,   b RD.b := T
                        if IfL(yy0^.right, T_COMMA) then
                        begin
                          yy1 := DropNode(yy0^.right);
                          yy0^.subval := yy1^.right^.val;
                          emit_sbrs(yy0^);
                        end;
                      end;
                    sym_bit: begin
                        emit_sbrs(yy0^);
                      end;
                  end;
                end;
              end;



            //------------- basic and asm/basic
            T_RETURN: begin
                assume_none;
                if yy0^.Right^.yylex = T_CONST then
                  emit_retconst(yy0^.Right^) else emit_ret;
              end;
            T_RETI: begin
                assume_none;
                emit_reti;
              end;
            T_RETNMI: begin
                assume_none;
                emit_typ($0001);
              end;
            T_NOP: begin
                //emit_typ($0000);
                core.nop;
              end;
            T_DEBUGBREAK: begin
                emit_typ($9598);
              end;
            T_ORG: begin
                ip := yy0^.Right^.val;
              end;
            T_PUSH: emit_push(yy0^.Right);
            T_POP: emit_pop(yy0^.Right);
            T_GOTO: begin
                bgoto := True;
                if yy0^.Right^.yylex = T_ROM then begin
                  emit_typ($9409); { GOTO ROM ? }
                end else
                begin
                  if IfL(yy0^.Right^.Right, T_LBRACKET2) then
                  begin
                    I := FindLabelAddr(yy0^.Right^);
                    MakeConst(@Tmp, I and 255); emit_add(ZL, Tmp);
                    MakeConst(@Tmp, -I shr 8); emit_sbc(ZH, Tmp);
                    emit_typ($9409);
                  end else
                    emit_fixup(yy0^.Right^, 0);
                end;
              end;
            T_GOSUB: begin
                stackneeded := True;
                yy0 := DropNode(yy0);
                if yy0^.yylex = T_ROM then begin
                  emit_typ($9509);
                end else
                  if yy0^.Right^.yylex = T_LBRACKET2 then begin
                    { Gosub ROM[] }
                    I := FindLabelAddr(yy0^);
                    MakeConst(@Tmp, I and 255); emit_add(ZL, Tmp);
                    MakeConst(@Tmp, -I shr 8); emit_sbc(ZH, Tmp);
                    emit_typ($9509);
                  end else
                    emit_fixup(yy0^, 1);
              end;
            { 0  1   2    3   4    5    }
            { IF Dst cond Src Then Label}
            { 0  1      2    3          }
            { IF BitVar Then Label      }
            { 0  1   2      3    4}
            { IF Not BitVar Then Label  }
            T_IFTHEN: begin
                bnif := False;
                assume_none;
                yy0 := DropNode(yy0); { Drop If }
                bnot := False;
                if yy0^.yylex = T_NOT then begin
                  bnot := True;
                  yy0 := DropNode(yy0);
                end;

                yy4 := yy0;
                repeat
                  yy4 := yy4^.Right;
                  if yy4 = nil then begin
                    Error(144);
                    goto next_error;
                  end;
                until yy4^.yylex = T_THEN;

                yy4 := yy4^.Right;
                if yy4^.yylex = T_TOKEN then begin
                  if yy4^.val = T_GOTO then begin
                    yy4 := DropNode(yy4);
                    bgoto := True;
                  end;
                  if yy4^.val = T_GOSUB then begin
                    yy4 := DropNode(yy4);
                    bgoto := False;
                  end;
                end;
                { yy4 = Label }
                bpre := 0;
                if (yy0^.yylex = T_INCINC) then begin
                  bpre := 1;
                  yy0 := DropNode(yy0);
                end;
                if (yy0^.yylex = T_DECDEC) then begin
                  bpre := 2;
                  yy0 := DropNode(yy0);
                end;
                { First Operand! }
                if yy0^.yylex = T_LBRACKET then begin
                  yy0 := DropNode(yy0);

                  Evaluate(@WREG, yy0);

                  if yy0^.Right^.yylex = T_LBRACKET
                    then begin
                    DropNode(yy0^.Right);
                  end else begin
                    DropNode(yy0^.Right);
                    DropNode(yy0^.Right);
                  end;
                end;

                yy1 := yy0;
                if (yy4^.yylex <> T_LABEL) and (yy4^.yylex <> T_SKIP) then begin
                  inc(next_if); inc(if_cnt);
                  bnot := not bnot;
                  bnif := True;
                  IFStack[next_if].typ := 0;
                  IFStack[next_if].num := if_cnt;
                  inc(cend);
                  e2[cend] := T_IFTHEN;
                  yy4 := @SwLab;
                  StrPCopy(SwLab.Name, 'IF@' + L2HEX(if_cnt, 3) + '@ELSE');
                end;

                { left then label}
                { left op right label }
                {0: Left Operand! }
                if bpre <> 0 then begin
                  { if --i = 0 Then Label }
                  I := FindLabelAddr(yy4^);
                  if bpre = 1 then emit_ijnz(yy1^, I);
                  if bpre = 2 then emit_djnz(yy1^, I);
                  Exit;
                end;
                yy2 := yy1^.Right;
                //
                // Add Float Support Here!
                //

                // yy1 evaluated cant DROP^.right....

                yy1 := emit_eval2(nil, yy1); { Evaluate first! }
                if (yy1^.yylex = T_VAR) and (yy1^.right <> nil) then
                begin
                  case yy1^.right^.yylex of
                    { IF Boolean THEN ... }
                    T_THEN: begin
                        {yy0 := DropNode(yy0^.right);
                                              }
                        yy3 := yy4; { Label }

                        { IF [bit or boolean] THEN ... }
                        case yy1^.typ of
                          sym_ioBIT: begin
                              case yy1^.val of
                                $3F: begin
                                    if yy3^.yylex = T_SKIP then begin
                                      if bnot then emit_typ($F408 + (yy1^.subval and 7))
                                      else emit_typ($F008 + (yy1^.subval and 7))
                                    end else begin
                                      if bnot then emit_fixup(yy3^, $F400 + (yy1^.subval and 7))
                                      else emit_fixup(yy3^, $F000 + (yy1^.subval and 7));
                                    end;
                                  end;
                                0..$1F: begin
                                    if yy3^.yylex = T_SKIP then begin
                                      if bnot then emit_sbic(yy1^)
                                      else emit_sbis(yy1^);
                                    end else begin
                                      if bnot then emit_sbis(yy1^)
                                      else emit_sbic(yy1^);
                                      emit_fixup(yy3^, 0);
                                    end;
                                  end;
                                $20..$3E: begin
                                    emit_in(WREG, yy0^);
                                    Tmp := WREG;
                                    Tmp.subval := yy0^.subval;

                                    if bnot then emit_sbrs(Tmp)
                                    else emit_sbrc(Tmp);
                                    emit_fixup(yy3^, 0);
                                  end;
                              end;
                              Exit;
                            end;
                          sym_BIT: begin
                              if yy3^.yylex = T_SKIP then begin
                                if bnot then emit_sbrc(yy1^)
                                else emit_sbrs(yy1^);
                              end else begin
                                if bnot then emit_sbrs(yy1^)
                                else emit_sbrc(yy1^);
                                emit_fixup(yy3^, 0);
                              end;
                              Exit;
                            end;
                        end; {err}
                        Exit;
                      end; { T_THEN }
                    T_LOG: begin
                        if yy1^.Right <> nil then
                        begin
                          op := yy1^.Right^.val;
                          DropNode(yy1^.Right);
                        end else begin
                          error(99);
                        end;
                      end;
                    T_EQUAL: begin
                        op := 4;
                        DropNode(yy1^.Right);
                      end else begin
                      Error(2009);
                      goto next_error;
                    end;
                  end;
                end else begin
                  { first op must be var}
                  Error(err_Var_Required);
                  goto next_error;
                end;

                { 0  1   2    3   4    5    }
                { If Dst cond Src Then Label}
                yy2 := yy1^.Right;
                case op of
                  { < }
                  1: begin
                      if bnif then emit_bge(yy1, yy2, yy4, 0)
                      else emit_blt(yy1, yy2, yy4, 0);
                    end;
                  { <= }
                  5: begin
                      if bnif then emit_blt(yy2, yy1, yy4, 0)
                      else emit_bge(yy2, yy1, yy4, 0);
                    end;
                  { > }
                  2: begin
                      if bnif then emit_bge(yy2, yy1, yy4, 0)
                      else emit_blt(yy2, yy1, yy4, 0);
                    end;
                  { >= }
                  6: begin
                      if bnif then emit_blt(yy1, yy2, yy4, 0)
                      else emit_bge(yy1, yy2, yy4, 0);
                    end;
                  {<>}
                  3: begin
                      if bnif then emit_beq(yy1, yy2, yy4, 0) else
                        emit_bne(yy1, yy2, yy4, 0);
                    end;
                  { = }
                  4: begin
                      if bnif then emit_bne(yy1, yy2, yy4, 0) else
                        emit_beq(yy1, yy2, yy4, 0);
                    end;
                end; { case }
              end;


              T_AND, T_OR, T_CP, T_CPC, T_ADC, T_ADD, T_SUB, T_SBC, T_EOR:
              begin
                if yy0^.right = nil then
                  Error(err_syntax)
                else begin
                  if yy0^.right^.right = nil then
                    Error(err_syntax)
                  else begin
                    if yy0^.right^.right^.right = nil then
                      Error(err_syntax)
                    else begin
                      emit_asm(yy0, yy0^.Right, yy0^.Right^.Right^.Right);
                    end;
                  end;
                end;
                Exit;
              end;

            T_SWAP, T_INC, T_DEC, T_NEG, T_COM, T_ASR, T_ROR, T_ROL, T_LSL, T_LSR:
              begin
                if yy0^.right = nil then
                  Error(err_syntax)
                else begin
                  emit_asm(yy0, yy0^.Right, nil);
                end;
              end;

            T_REPEAT: begin
                if next_repeat >= max_repeat then begin
                  Error(err_Too_Many_Repeat_Nestings);
                  goto next_error;
                end;
                {We are OK.}
                RepStack[next_repeat].Addr := ip;
                inc(repeat_cnt);
                RepStack[next_repeat].N := repeat_cnt;
                inc(next_repeat);
                InsertLabel('REPEAT@' + L2HEX(repeat_cnt, 2), 0);
              end;

            T_UNTIL: begin
                assume_none;
                { Inside Repeat Loop? }
                if next_repeat < 1 then begin
                  Error(err_Until_Without_Repeat);
                  goto next_error;
                end;
                { Decrease Nesting! }
                Dec(next_repeat);
                InsertLabel('REPEAT@' + L2HEX(RepStack[next_repeat].N, 2) + '@CONT', 0);

                { Until Var     }
                { 0     1   2   }
                { Until Not Var }
                yy0 := DropNode(yy0); { drop Until }
                bnot := False;
                if yy0^.yylex = T_NOT then begin
                  bnot := True;
                  yy0 := DropNode(yy0); { Drop Not }
                end;

                yys := emit_eval2(nil, yy0);
                case yys^.yylex of
                  T_NEWLINE: begin
                      emit_jmp(RepStack[next_repeat].Addr);
                    end;
                  T_CONST: begin
                      if yys^.val = 0 then emit_jmp(RepStack[next_repeat].Addr);
                    end;
                  { First is Var! }
                  T_VAR: begin
                      if ((yy0^.Right^.yylex = T_EQUAL) or (yy0^.Right^.yylex = T_LOG)) and (yy0^.Right^.Right^.yylex = T_CONST) then begin
                        if yys^.typ <> sym_DEF then begin
                          if yy0^.Right^.yylex <> T_EQUAL then
                            bnot := not bnot;
                          if (yy0^.Right^.Right^.val = 0) then
                            bnot := not bnot;
                          DropNode(yy0^.Right);
                          DropNode(yy0^.Right);
                        end;
                      end;
                      if yy0^.Right^.yylex = T_NEWLINE then begin
                        case yys^.typ of
                          sym_BIT: begin
                              { Skip }
                              if bnot then
                                emit_sbrc(yys^)
                              else
                                emit_sbrs(yys^);
                              { Rjmp }
                              emit_jmp(RepStack[next_repeat].Addr);
                            end;
                          sym_ioBIT: begin
                              { Repeat Until [Not] SREG.n }
                              case yys^.val of
                                $3F: begin
                                    if bnot then
                                      emit_typ($F000 + ((RepStack[next_repeat].Addr - ip - 1) shl 3 and $3F8)
                                        + (yys^.subval and 7))
                                    else
                                      emit_typ($F400 + ((RepStack[next_repeat].Addr - ip - 1) shl 3 and $3F8)
                                        + (yys^.subval and 7));
                                  end;
                                { Bit Addressable IO}
                                $00..$1F: begin
                                    if bnot then
                                      emit_sbic(yys^)
                                    else
                                      emit_sbis(yys^);
                                    { Rjmp }
                                    emit_jmp(RepStack[next_repeat].Addr);
                                  end;
                                { Non-Bit Addressable IO}
                                $20..$3E: begin
                                    emit_in(WREG, yys^);
                                    Tmp := WREG;
                                    Tmp.subval := yys^.subval;

                                    if bnot then
                                      emit_sbrc(Tmp)
                                    else
                                      emit_sbrs(Tmp);
                                    { Rjmp }
                                    emit_jmp(RepStack[next_repeat].Addr);
                                  end;
                              end;
                            end;
                        end; { case yy[1] }
                      end else begin
                        { repeat var <> var con }
                        yy2 := yy0^.Right;
                        yy3 := yy2^.Right;
                        { 0     1   2 3        }
                        { until var = varconst }
                        if yys^.yylex = T_VAR then begin
                          StrPCopy(SwLab.Name, 'REPEAT@' + L2HEX(RepStack[next_repeat].N, 2));
                          case yy2^.typ of
                            {0       1  2  3}
                            { until var <> val }
                            sym_DEF: begin
                                case yy2^.val of
                                  100: begin
                                      emit_bne(yys, yy3, @SwLab, 0);
                                    end;
                                  3: begin
                                      { <> }
                                      emit_beq(yys, yy3, @SwLab, 0);
                                    end
                                else begin
                                    Error(124);
                                  end;
                                end;
                              end;
                            sym_Word: begin
                              end;
                          end;
                        end;
                      end;
                    end;
                  T_INCINC: begin
                      emit_ijnz(yy0^.Right^, RepStack[next_repeat].Addr);
                    end;
                  T_DECDEC: begin
                      emit_djnz(yy0^.Right^, RepStack[next_repeat].Addr);
                    end;
                end;
                InsertLabel('REPEAT@' + L2HEX(RepStack[next_repeat].N, 2) + '@BREAK', 0);
              end;
            T_FOR: begin
                assume_none;
                if next_for >= max_fors then begin
                  Error(err_Too_Many_For_Next_Nestings);
                  goto next_error;
                end;
                { Get Loop Var }
                { 0   1       2 3        4  5      6    7       }
                { For LoopVar = StartVal To EndVal Step StepVal }
                { For LoopVar = StartVal To EndVal Step - StepVal }
                yy0 := DropNode(yy0); { drop FOR }
                yyd := yy0; { Get Loop Var }
                if yyd^.yylex = T_VAR then begin
                  { Save loop Variable }
                  ForStack[next_for].Loop := yyd^;
                  { Check = }
                  yy1 := yy0^.Right; { = }
                  yy3 := yy1^.Right; { loopvar }
                  if yy1^.yylex = T_EQUAL then begin
                    yy1 := DropNode(yy1); { Drop = }
                    yys := emit_eval2(yyd, yy1); { eval loop value }
                    {?? }
                    case yys^.yylex of
                      T_VAR: begin
                          { Save Start Value?? }
                          ForStack[next_for].Start := yy3^;
                          emit_assign(yyd, yys);
                        end;
                      T_CONST: begin
                          ForStack[next_for].Start := yy3^;
                          case yyd^.typ of
                            sym_lDEF,
                              sym_sDEF,
                              sym_DEF,
                              sym_Word: begin
                                emit_assign(yyd, yys); {}
                              end;
                          end;
                        end;
                    else begin
                        Error(98);
                        goto next_error;
                      end;
                    end;
                    { Save Loop Back Address! }
                    ForStack[next_for].Addr := ip;
                    { Get TO }
                    if yy3^.Right^.yylex = T_TO then begin
                      DropNode(yy3^.Right);
                      case yy3^.Right^.yylex of
                        T_VAR, T_CONST: begin
                            ForStack[next_for].Fin := yy3^.Right^;
                          end else begin
                          Error(189);
                          goto next_error;
                        end;
                      end;
                      { STEP 1 as Default! }
                      ForStack[next_for].STEP.val := 1;
                      ForStack[next_for].STEP.typ := sym_Const;
                      ForStack[next_for].StepUp := True; { Positive Step }

                      StrCopy(ForStack[next_for].STEP.Name, '* Default Constant 1 *');

                    end else begin
                      { TO Expected }
                      Error(err_For_Next_Syntax);
                      goto next_error;
                    end;
                    inc(next_for);


                  end else begin
                    { =expected }
                    Error(err_For_Next_Syntax);
                    goto next_error;
                  end;
                end else begin
                  Error(err_For_Variable_Type);
                  goto next_error;
                end;
              end;
            T_NEXT: begin
                assume_none;
                { Inside FOR Loop? }
                if next_for < 1 then begin
                  Error(err_Next_Without_For);
                  goto next_error;
                end;
                { Decrease Nesting! }
                Dec(next_for);
                case ForStack[next_for].Loop.typ of
                  sym_DEF: begin
                      case ForStack[next_for].Fin.typ of
                        sym_Const: begin
                            emit_cp(ForStack[next_for].Loop, ForStack[next_for].Fin);
                          end; { if sym_Const }
                        sym_DEF: begin

                          end;
                      end; { End Case Fin.Typ }
                      { Inc/Dec LOOP Variable..  }
                      { Depending on Step Type.. }
                      case ForStack[next_for].STEP.typ of
                        sym_Const: begin
                            case ForStack[next_for].STEP.val of
                              1: begin
                                  emit_typ($F011); { breq + 2}
                                  if ForStack[next_for].StepUp then
                                    emit_inc(ForStack[next_for].Loop)
                                  else
                                    emit_dec(ForStack[next_for].Loop);
                                  { rjmp to where we need to! }
                                  emit_jmp(ForStack[next_for].Addr);
                                end else begin
                                { not 1 not -1 ?}
                              end;
                            end; { End Case Step.Val }
                          end; { if sym_Const }
                      end; { End Case Step.Typ }
                    end;
                  sym_lDEF: begin
                      case ForStack[next_for].Fin.typ of
                        sym_Const: begin
                            emit_cp(ForStack[next_for].Loop, ForStack[next_for].Fin);
                          end; { if sym_Const }
                        sym_DEF: begin

                          end;
                      end; { End Case Fin.Typ }
                      { Inc/Dec LOOP Variable..  }
                      { Depending on Step Type.. }
                      case ForStack[next_for].STEP.typ of
                        sym_Const: begin
                            case ForStack[next_for].STEP.val of
                              1: begin
                                  emit_typ($F021); { breq + 4}
                                  if ForStack[next_for].StepUp then
                                    emit_inc(ForStack[next_for].Loop)
                                  else
                                    emit_dec(ForStack[next_for].Loop);
                                  { rjmp to where we need to! }
                                  emit_jmp(ForStack[next_for].Addr);
                                end else begin
                                { not 1 not -1 ?}
                              end;
                            end; { End Case Step.Val }
                          end; { if sym_Const }
                      end; { End Case Step.Typ }
                    end;
                  sym_Word: begin
                      emit_cp(ForStack[next_for].Loop, ForStack[next_for].Fin);
        //bug #0005 fixed in 1.18
                      if ForStack[next_for].Loop.Val < 16 then
                        emit_typ($F021) { breq + 4}
                      else
                        emit_typ($F019); { breq + 3}

                      { ++Loopvar }
                      emit_inc(ForStack[next_for].Loop);
                      emit_jmp(ForStack[next_for].Addr);
                    end;
                end; { case loop.typ }
              end; { T_NEXT }

            //
            T_WAIT: begin
                emit_wait(yy0^.Right);
              end;
            T_WRITE: begin
                emit_write(yy0^.Right);
              end;
            T_READ: begin
                emit_read(yy0^.Right);
              end;

            // Enter into Inline Assembly mode
            T_ASM: begin
                yylex := a_yylex;
                mode := 1;
              end;
            // Exit from Inline Assembly mode
            T_ASMEND: begin
                yylex := b_yylex;
                mode := 0;
              end;


          end;
        end;
    end;
  Exit;

  next_error:

end;

//{$I ap2.inc}

procedure EmitStartup;
var
  maxusedint,
    i, j: integer;
  IntsUsed: Boolean;
begin
  if vectors[0] <> $FFFFFFFF then
  begin
    if vectors[0] > 1 then
    begin
      emit_jmp(vectors[0]); // Emit Reset Jump to main.
      //
          // Align if required
      if has_vec2 then
      begin
        if (ip and 1) <> 0 then
        begin
          emit_typ(0); // nop
        end;
      end;

    end;
    // If Vectors exists, then process them
    if core.MaxVector > 0 then
    begin
      maxusedint := 0;
      IntsUsed := false;
      for i := 1 to core.MaxVector do
      begin
        if Vectors[i] <> $FFFFFFFF then
          IntsUsed := True;
        maxusedint := i; // highest int vector in use
      end;
      // Fill interrupt table
      if intsused then
        for i := 1 to core.MaxVector do
        begin
          if vectors[i] <> $FFFFFFFF then
          begin
            emit_jmp(vectors[i]);
          end else
          begin
            emit_reti;
          end;
          // Align if required
          if has_vec2 then
          begin
            if (ip and 1) <> 0 then
            begin
              emit_typ(0); // nop
            end;
          end;
        end;
    end;
  end;
end;


procedure Init_AVR; { Called just Once! }
begin
  wreg_def := $1F; { AT90S1200}
  emit_init;
  cpu := 1200;

  emit_device; // From devstr
  EmitStartup;
end;

procedure Exit_AVR;
var
  I, J: Word;
  P: PChar;
begin
  WriteToolOutput('L exti_avr');

  used_ee := 0;
  J := ee_size;
  if J > 2048 then J := 2048;
  if J <> 0 then
  for I := 0 to J - 1 do
  begin
    if EEMEM[I] <> $FFFF then inc(used_ee);
  end;
  WriteToolOutput('L bevore close');

  CloseObjFile;

  (*
    hextyp := 1;
    If hextyp = 0 Then
    Begin
      WritePicHEX(szHexFile, hft_INHX8,
        True, True, True, 0, 0, Nil, Nil,
        @EEMEM, @CODEMEM, 0, 512, 64);
    End;

    P := StrPos(szHexFile, '.');
    If P <> Nil Then
    Begin
      P[1] := 'R'; P[2] := 'O'; P[3] := 'M';
    End;

    If hextyp = 1 Then
    Begin
      WritePicHEX(szHexFile, hft_INHX8,
        True, True, False, 0, 0, Nil, Nil,
        @EEMEM, @CODEMEM, 0, 512, 64);

      P := StrPos(szHexFile, '.');
      If P <> Nil Then
      Begin
        P[1] := 'E'; P[2] := 'E'; P[3] := 'P';
      End;

      WriteINHX8(szHexFile, hft_INHX8,
        True, True, False, 0, 0, Nil, Nil,
        @EEMEM, @EEMEM, 0, 64);

    End;

    If hextyp = 2 Then
    Begin
      For I := 0 To 31 Do
        CODEMEM[512 + I] := (EEMEM[I * 2 + 1] Shl 8) + (EEMEM[I * 2] And 255);

      WritePicHEX(szHexFile, hft_INHX8,
        True, True, False, 0, 0, Nil, Nil,
        @EEMEM, @CODEMEM, 0, 512 + 32, 0);
    End;
  *)

  WriteToolOutput('L P3');

  linenum := 0;
  if next_for <> 0 then
  begin Error(err_open_for); end;
  if next_repeat <> 0 then
  begin Error(err_open_repeat); end;
  WriteToolOutput('L P4');
  CloseLstFile;
  WriteToolOutput('L P5');
end;
{$R-}
end.

