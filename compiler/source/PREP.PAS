(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

Unit prep;

Interface

Uses
  ToolSrv,
  
  CompDef,
  NodePool,
  Sysutils;

Procedure doprep;

Implementation

Procedure doprep;
Begin
                yy0 := DropNode(yy0);
                If StrLIComp(yy0^.name, 'FILE',4) = 0 Then
                Begin
                  FileNum := yy0^.right^.val;
                  IncFileNum := FileNum;
                  CFileNum := FileNum;
                  {
                  If StrPas(yy0^.right^.name) = fname Then
                  Begin
                    Filenum := 1;
                    cFileNum := 1;
                  End else Begin
                    inc(FileNum);
                    Files[IncFileNum] := StrPas(yy0^.right^.name);
                    inc(IncFilenum);
                    cFileNum := IncFileNum;
                  End;
                  }
                End;
                If StrLIComp(yy0^.name, 'LINE',4) = 0 Then
                Begin
                  linenum := yy0^.right^.val;
                End;

End;


Begin
End.