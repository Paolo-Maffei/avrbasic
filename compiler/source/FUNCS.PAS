(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit funcs;

interface

uses
  SysUtils,
  CompDef,
  EFile,
  Common,
  CompUt,
  NodePool;

function emit_wait(O: PSym): PSym;
function emit_read(O: PSym): PSym;
function emit_write(O: PSym): PSym;

implementation

uses
  emit_avr;

function emit_wait;
var
  adr, adr2: integer;
  a, b: array[0..32] of char;

begin
  if O^.yylex = T_LBRACKET then
  begin
    O := DropNode(O); // Drop (
    if O <> nil then
    begin
      // Wait (
      if SE(O^.Name, 'MILLI') then
      begin
        O := DropNode(O); // Drop (
        if IfL(O, T_COMMA) then
        begin
          O := DropNode(O); // Drop ,
          emit_assign(@Z16, O);
          emit_call_byname('SYSTEM$WAIT1MS'); // Call n milliseconds
        end else begin
          Error(49);
        end;
        exit;
      end;
      if SE(O^.Name, 'CYCLE') then
      begin
        O := DropNode(O); // Drop (
        if IfL(O, T_COMMA) then
        begin
          O := DropNode(O); // Drop ,

          if IfL(O, T_VAR) then begin
            emit_assign(@Z16, O);
            emit_call_byname('SYSTEM$WAIT1CYCLEW30'); //

          end;
          if IfL(O, T_CONST) then begin
            O^.Val := O^.Val div 4;
            emit_assign(@Z16, O);
            if FindAddr('SYSTEM$WAIT4CYCLESW30') <> 0 then
            begin
              emit_call_byname('SYSTEM$WAIT4CYCLESW30'); //
            end else
            begin
              //#todo2 if 0 then..embedded delay
              if has_adiw then
              begin
                emit_typ($9731);
                emit_typ($F7F1);
              end else begin
                emit_typ($50E1);
                emit_typ($40F0);
                emit_typ($F7E9);
              end;
            end;
          end;

        end else begin
          Error(49);
        end;
        exit;
      end;
      // Wait (UART);
      if IfL(O, T_LABEL) then begin
        StrCopy(a, O^.Name);
        StrCopy(SwLab.name, a);
        StrCat(SwLab.name, '$BUSY');
        //
        adr := FindLabelAddr(SwLab);
        if adr <> 0 then
        begin
          emit_call(adr);
          emit_typ($F7F6); // jmp -1
          Exit;
        end;

      end else begin
        error(55);
        Exit;
      end;

      Error(99); // unimpl
      Exit;
    end;
  end else
  begin
    // Wait var
    bnot := False;
    if O^.yylex = T_NOT then
    begin
      bnot := True;
      O := DropNode(O);
    end;
    //
    case O^.yylex of
      T_EEPROM: begin
          emit_typ($99E1); { sbic eecr, 0 }
          emit_jmp(ip - 1); { ?? }
        end;
      //
      T_VAR: begin
          case O^.Typ of
            sym_ioBit: begin
                if O^.val = $3F then
                begin
                  if bnot then emit_typ($F7F8 + (O^.subval and 7))
                  else emit_typ($F7F8 + (O^.subval and 7));
                end else begin
                  if O^.val < $20 then
                  begin
                    if bnot then emit_sbic(O^)
                    else emit_sbis(O^);
                    emit_jmp(ip - 1); { ?? }
                  end else begin
                    emit_in(WREG, O^);
                    WREG.subval := O^.subval;
                    if bnot then emit_sbrc(WREG)
                    else emit_sbrs(WREG);
                    WREG.subval := 0;
                    emit_jmp(ip - 2); { ?? }
                  end;
                end;
              end;
            sym_Bit: begin
                if bnot then emit_sbrc(O^)
                else emit_sbrs(O^);
                emit_jmp(ip - 1); { ?? }
              end;
            sym_DEF: begin
                emit_and(O^, O^);

                if bnot then emit_typ($F7F1)
                else emit_typ($F3F1);

              end;
          end;
        end;
      // Wait Const
      T_CONST: begin
          case O^.val of
            0: begin
              end;
            1: begin
                emit_typ(0); { NOP }
              end;
            2: begin
                emit_typ($C000); { rjmp +00 }
              end;
            3: begin
                emit_typ($C000); { rjmp +00 }
                emit_typ(0); { NOP }
              end;
            4: begin
                emit_typ($C000); { rjmp +00 }
                emit_typ($C000); { rjmp +00 }
              end;
            5: begin
                emit_typ($C000); { rjmp +00 }
                emit_typ($C000); { rjmp +00 }
                emit_typ(0); { NOP }
              end;
            6: begin
                emit_typ($C000); { rjmp +00 }
                emit_typ($C000); { rjmp +00 }
                emit_typ($C000); { rjmp +00 }
              end;
            7..255 * 3: begin
                // if not RC!
                if ((O^.val) mod 3) = 2 then emit_typ(0); { NOP }
                if ((O^.val) mod 3) = 3 then emit_typ($C000); { NOP }
                //
                emit_ldi(WREG, (O^.val) div 3); // 1
                //-----------------------------------
                emit_dec(WREG); // 1
                emit_typ($F7F1); // 2 Loop
              end else begin
              Error(1987);
            end;
          end;
        end;
    end;
  end;
end;

function emit_read;
var
  adr, adr2: integer;
  a, b: array[0..32] of char;
begin
  if O^.yylex = T_LBRACKET then
  begin
    O := DropNode(O);
    StrCopy(a, O^.Name);
    StrCopy(SwLab.name, a);
    StrCat(SwLab.name, '$READ');
    //
    adr := FindLabelAddr(SwLab);
    if adr <> 0 then
    begin
      //?? loop til last...
      O := DropNode(O); // Drop object
      while IfL(O, T_COMMA) do
      begin
        O := DropNode(O); // Drop ,
        if IfL(O, T_VAR) then
        begin
          emit_call(adr);
          emit_assign(O, @WREG);
        end;

        if IfL(O, T_LABEL) then
        begin
          StrCopy(b, a);
          StrCat(b, '$');
          StrCat(b, O^.Name);
          StrCopy(SwLab.name, b);
          adr2 := FindLabelAddr(SwLab);
          if adr2 <> 0 then
            emit_call(adr2)
          else begin
            error(51);
          end;
        end;

        O := DropNode(O); // var
      end;
      // check )

    end else begin
      error(51);
    end;
  end else begin
    error(50);
  end;
end;

function emit_write;
var
  adr, adr2: integer;
  a, b: array[0..32] of char;
begin
  if O^.yylex = T_LBRACKET then
  begin
    O := DropNode(O);
    StrCopy(a, O^.Name);
    StrCopy(SwLab.name, a);
    StrCat(SwLab.name, '$WRITE');
    adr := FindLabelAddr(SwLab);

    if adr <> 0 then
    begin
      //?? loop til last...
      O := DropNode(O); // Drop object
      while IfL(O, T_COMMA) do
      begin
        O := DropNode(O); // Drop ,
        adr2 := adr;
        if SE(O^.name, 'HEX') then begin
          emit_ldi(Z16, adr);
          StrCopy(SwLab.name, '__STREAM_WRITE_HEX');
          adr := FindLabelAddr(SwLab);
          O := DropNode(O); // Drop hex
        end;
        if SE(O^.name, 'DEC') then begin
          emit_ldi(Z16, adr);
          StrCopy(SwLab.name, '__STREAM_WRITE_DEC');
          adr := FindLabelAddr(SwLab);
          O := DropNode(O); // Drop hex
        end;

        if IfL(O, T_VAR) then
        begin
          emit_assign(@WREG, O);
          emit_call(adr);
        end;

        if IfL(O, T_CONST) then
        begin
          emit_assign(@WREG, O);
          emit_call(adr);
        end;

        adr := adr2;
        if IfL(O, T_LABEL) then
        begin
          StrCopy(b, a);
          StrCat(b, '$');
          StrCat(b, O^.Name);
          StrCopy(SwLab.name, b);
          adr2 := FindLabelAddr(SwLab);
          if adr2 <> 0 then
            emit_call(adr2)
          else begin
            error(51);
          end;
        end;

        O := DropNode(O); // var
      end;
      // check )

    end else begin
      error(51);
    end;
  end else begin
    error(50);
  end;

end;

end.

