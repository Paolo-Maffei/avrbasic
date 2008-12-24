(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

Unit AVR_OBJ;

Interface

Uses
  AVRCore,
  SysUtils,
  CompDef,
  CompUt,
  NodePool,
  EFile,
  LstFile,
  emit_avr,
  mstrings;

var
  erun1: Boolean;

Function EvalObjects(Tree: PSym): Boolean;

Implementation

Function EvalObjects;
Var t1, t2, t3, t4: PSym;
Var i,vad: Integer;

Begin
  t1 := Tree;
  If t1^.right^.yylex <> T_DOT Then Exit;
  DropNode(t1^.right);  t2 := t1^.right; { Drop First DOT }

  If t1^.yylex = T_EEPROM Then
  Begin
    if t2^.right^.yylex = T_NEWLINE Then
    Begin
      if se(t2^.name, 'READ') Then
      Begin
        emit_ee_rd(nil, nil, '');
      End;
      if se(t2^.name, 'WRITE') Then
      Begin
        emit_ee_wr(nil, nil, '');
      End;
    End;
    if t2^.right^.yylex = T_EQUAL Then
    Begin
      DropNode(t2^.right);
      if se(t2^.name, 'WRITEENABLED') Then
      Begin
        TmpIO.val := a_EECR;
        TmpIO.subval := 2;

        If t2^.right^.val = 0 Then
        Begin
          emit_cbi(TmpIO);
        End else Begin
          emit_sbi(TmpIO);
        End;
        Exit;
      End;
    End;
    Exit;
  End;

  If se(t1^.name, 'WATCHDOG') Then
  Begin
      Case t2^.right^.yylex Of
        T_NEWLINE: Begin
          If se(t2^.name, 'RESET') Then
          Begin
            emit_Typ(word(T_WDR));
          End;
        End;
        T_EQUAL: Begin
          t3 := DropNode(t2^.right); { Drop = }
          If se(t2^.name, 'PRESCALER') Then
          Begin
            Case t3^.val Of
              16: Begin
                wdprescaler := 0;
              End;
              32: Begin
                wdprescaler := 1;
              End;
              128: Begin
                wdprescaler := 3;
              End;
              256: Begin
                wdprescaler := 4;
              End;
              512: Begin
                wdprescaler := 5;
              End;
              1024: Begin
                wdprescaler := 6;
              End;
              2048: Begin
                wdprescaler := 7;
              End;
              64: Begin
                wdprescaler := 2;
              End else Begin
                Warning(1234);
              End;
            End;
          End;
          If se(t2^.name, 'ENABLED') Then
          Begin
            if t3^.val = 0 Then
            Begin
              If cpu = 1200 Then
              Begin
                emit_ldi(WREG,$00);
                TempSym.Val := $21;
                emit_out(TempSym,WREG);
              end else begin
                TempSym.Val := $21;
                emit_ldi(WREG,$18);
                emit_out(TempSym,WREG);
                emit_ldi(WREG,$10);
                emit_out(TempSym,WREG);
              End;
            End else Begin
              use_watchdog := True;
              emit_ldi(WREG,$08 or (wdprescaler and 7) );
              TempSym.Val := $21;
              emit_out(TempSym,WREG)
            End;
          End;

        End; { T_EQ }
      End; { case }
      Exit;
  End;

  If se(t1^.name, 'CPU') Then
  Begin
      Case t2^.right^.yylex Of
        T_NEWLINE: Begin
            If se(t2^.name, 'SLEEP') Then Begin
              emit_Typ(word(T_SLEEP));
              Exit;
            End;
        End;
        T_DOT: Begin
          { t1  t2         }
          { CPU.Interrupt. }
          t3 := DropNode(t2^.right); { Drop . }
          If t3^.right^.yylex = T_EQUAL Then
          Begin
            { t1  t2        3         }
            { CPU.Interrupt.Enabled = }
            t4 := DropNode(t3^.right); { Drop = }
            if t4^.val = 0 Then emit_di else emit_ei;

          End else
          Begin
            Error(88);
          End;
        End;
        T_EQUAL: Begin
          { CPU.XXXX = XXXX }
          t3 := DropNode(t2^.right); { Drop = }
          If se(t2^.name, 'STACK') Then
          Begin
            if cpu<>1200 then
            Begin
              Tmp.Val := $3D; // SPL
              emit_ldi(WREG, t3^.val);
              emit_out(Tmp, WREG);
              If sram_top >255 then
              begin
                Tmp.Val := $3E; // SPH
                emit_ldi(WREG, (t3^.val) shr 8);
                emit_out(Tmp, WREG);
              end;
            End;
          End;
          If se(t2^.name, 'CLOCK') Then
          Begin
            If IfL(t3, T_LABEL) Then Begin
              if se(t3^.name, 'INTERNAL') Then Begin
                ClockType := 1;
                cpuclock := 1000000; // 1 MHz
              End;
            End else  begin
              cpuclock := t3^.val;
              ClockType := 0;
            End;
            Exit;
          End;
          // Vector table fill
          If t3^.yylex = T_AT Then
          Begin
            t4 := DropNode(t3);
            i := FindLabelAddr(t4^);
          End;
          // Retrieve OnXXX vector address
          vad := core.VecToAddr(t2^.name);
          if  vad <= 255 then begin
            vectors[vad] := i;
          end;
        End; { T_EQ }
      End; { case }
      Exit;
  End;

  If se(t1^.name, 'TIMER') Then
  Begin
      If t2^.yylex = T_INTERRUPT Then
      Begin
        t2 := DropNode(t2); t2 := DropNode(t2);
        If se(t2^.name, 'ENABLED') Then
        Begin
          t2 := DropNode(t2); t2 := DropNode(t2);
          If t2^.yylex = T_CONST Then
          If t2^.val = 0 Then Begin
            If (wreg_val=-1) then emit_ldi(WREG, $00) else
             If (wreg_val and $02) <> 0 Then emit_ldi(WREG, $00);
            TmpIO.val := $39; {TIMSK}
            emit_out(TmpIO, WREG)
          End else Begin
            { Enable Timer Interrupt }
            If (wreg_val=-1) then emit_ldi(WREG, $FF) else
             If (wreg_val and $02) = 0 Then emit_ldi(WREG, $FF);
            TmpIO.val := $39; {TIMSK}
            emit_out(TmpIO, WREG)
          End;
        End;

        Exit;
      End;
      If se(t2^.name, 'ENABLED') Then
      Begin
        t2 := DropNode(t2);
        t2 := DropNode(t2);
        If t2^.val = 0 Then
        Begin
          emit_ldi(WREG, $00);
          TmpIO.val := $33;
          emit_out(TmpIO, WREG)
        End else
        Begin

        End;
      End;

      If se(t2^.name, 'PRESCALER') Then
      Begin
        t2 := DropNode(t2);
        t2 := DropNode(t2);
        Case t2^.val Of
          1: Begin
            emit_ldi(WREG, $41)
          End;
          8: Begin
            emit_ldi(WREG, $42)
          End;
          64: Begin
            emit_ldi(WREG, $43)
          End;
          256: Begin
            emit_ldi(WREG, $43)
          End;
          1024: Begin
            emit_ldi(WREG, $45)
          End else Begin
            Warning(1999);
            emit_ldi(WREG, $41)
          End;
        End;
        TmpIO.val := $33;
        emit_out(TmpIO, WREG)
      End;
      Exit;
  End;

  If se(t1^.name, 'EXTINT') Then
  Begin
      If t2^.yylex = T_INTERRUPT Then
      Begin
        t2 := DropNode(t2); t2 := DropNode(t2);
        If se(t2^.name, 'ENABLED') Then
        Begin
          t2 := DropNode(t2); t2 := DropNode(t2);
          If t2^.yylex = T_CONST Then
          If t2^.val = 0 Then Begin
            If (wreg_val=-1) then emit_ldi(WREG, $00) else
             If (wreg_val and $02) <> 0 Then emit_ldi(WREG, $00);
            TmpIO.val := $3B; {GIMSK}
            emit_out(TmpIO, WREG)
          End else Begin
            { Enable Ext Interrupt }
            If (wreg_val=-1) then emit_ldi(WREG, $FF) else
             If (wreg_val and $02) = 0 Then emit_ldi(WREG, $FF);
            TmpIO.val := $3B; {GIMSK}
            emit_out(TmpIO, WREG)
          End;

       End;
      End;
      Exit;
  End;

  If se(t1^.name, 'ANACOMP') Then
  Begin
      If t2^.yylex = T_INTERRUPT Then
      Begin
        t2 := DropNode(t2); t2 := DropNode(t2);
        If se(t2^.name, 'ENABLED') Then
        Begin
          t2 := DropNode(t2); t2 := DropNode(t2);
          If t2^.yylex = T_CONST Then
          If t2^.val = 0 Then Begin
            TmpIO.val := $08; TmpIO.subval := 3;
            emit_cbi(TmpIO)
          End else Begin
            TmpIO.val := $08; TmpIO.subval := 3;
            emit_sbi(TmpIO)
          End;
       End;
      End;
      Exit;
  End;

End;



Begin

End.