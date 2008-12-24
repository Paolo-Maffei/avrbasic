(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit ucompile;

interface

uses
  ToolStd,

  SysUtils,
  StrUt,
  EFile,
  ToolSrv,
  ObjFiles,
  CompDef,
  prefer,
  common,
  doCoff,
  streams,
  BS1Emit,
  Pars_AVR;


procedure CompileFile(FileName: string);

implementation

procedure CompileFile(FileName: string);
var
  nlines, i, j: Integer;
  a, b: array[0..259] of char;
  incpath, s, s1, s2: string;
  f1, f2: Text;
begin
  // Clear Compiler Errors.
  ClearErrorOutput;

  // Open File Source File
  AssignFile(F1, FileName);
  Reset(F1);
  //
  linenum := 1; nlines := 0; i := 0;
  StrCopy(buf, ''); { Clear Buf }

  FileNum := 1; IncFileNum := 1;
  fname := FileName;
  files[0] := ExtractFilePath(FileName);

  //  AddSrcFileInObj(fname);
  files[1] := FileName;
  SetCurrentdir(ExtractFilePath(FileName));

  pass := last_pass;

  devstr := ''; // Default ?
  family := avr; // Default ?

  i := 0;
  while not EOF(F1) do
  begin
    Readln(F1, par); //  par := Ed.Lines[i];
    StrPCopy(a, par); inc(i);

    if a[0] = '#' then
    begin
      if StrLIComp(a, '#family', 7) = 0 then
      begin
        Delete(par, 1, 8);
        par := UpperCase(par);
        if Pos('AVR', par) > 0 then family := avr;

        StrCat(buf, #13);
        Continue;
      end;
      if StrLIComp(a, '#device', 7) = 0 then
      begin
        Delete(par, 1, 8); // device...
        devstr := par;

        StrCat(buf, #13);
        Continue;
      end;
      if StrLIComp(a, '#include', 8) = 0 then
      begin
        Delete(par, 1, 9);
        incpath := par;

        // Expand system inludes!
        if par[1] = '<' then begin
          incpath := RemoveQuote(incpath);
          incpath := RootDir + 'inc\avr\' + incpath;
        end else begin
          incpath := files[0] + incpath;
        end;

//        if Pos('.inc', incpath) < (length(incpath) - 4) then incpath := incpath + '.inc';
        incpath := ChangeFileExt(incpath, '.inc');

        if FileExists(incpath) then { Read Include File }
        begin
          Inc(IncFileNum);
          Files[IncFileNum] := incpath;
          FileNum := IncFileNum;

          StrPCopy(a, '#file ' + IntToStr(FileNum));
          StrCat(a, #13);
          StrCat(buf, a);
          {#file }
          StrCopy(a, '#line 1'#13);
          StrCat(buf, a);
          par := StrPas(b);

          { Include Stuff here }

          AssignFile(F2, files[IncFileNum]);
          Reset(F2);

          while not EOF(F2) do
          begin
            Readln(F2, s2);
            StrPCopy(a, S2); StrCat(buf, a); StrCat(buf, #13);
            Inc(nlines);
          end;
          CloseFile(F2);

          {#file - restore old file }
          StrPCopy(a, '#file 1'); StrCat(a, #13); StrCat(buf, a);
          {#line - restore old line num }
          Inc(nlines, 2);

          linenum := i + 1;
          Str(linenum, par);
          StrPCopy(b, par);
          StrCopy(a, '#line ');
          StrCat(a, b);
          StrCat(a, #13);
          StrCat(buf, a);
          FileNum := 1; { Back To Main }
        end else
        begin
          { BAD INCLUDE FILE }
  //          Error('ffsd');

          StrCat(buf, #13);
          Inc(nlines); Inc(linenum);
        end;
      end; { #include }
    end else { #.. }
    begin
      StrCat(buf, a); StrCat(buf, #13);
      Inc(nlines); Inc(linenum);
    end;
  end;

  CloseFile(F1);

  StrCat(buf, #13#13#0#0);
  LastIncFile := IncFileNum;

  s := incpath;
  Delete(s, Length(s) - 3, 4);
  filen := s;

  ClearListOutput;
  ClearObjectOutput;
  OpenObjFile;
  {  AssignFile(errfile, s + '.err');   rewrite(errfile);  }
  StrPCopy(szHexFile, s + '.hex');
  //
  //
  //
  for i := 0 to $3FFF do ROM[i] := $FF;

  //ClearListOutput;
  //ClearObjectOutput;

  Pass := -1;
  nooptpasses := False;
  CompileBS1;

  Pass := 0; CompileBS1; { Count Stuff for Optimizer }
  jmp_opt_failed := False;
  Pass := 1; CompileBS1; { Try to Fit!               }

  //If doLibrary Then
  //Begin

  (*
  mCoff.CreateEx(ChangeFileExt(FileName, '.cof'));
  mCOFF.AddFilename('test.bas');
  //
  // Add Main Function...
  //
  mCoff.AddFun('main', 'v');
  mCOFF.Add_bf;
  mCOFF.AddLineNum(0, 2); // Index to Sym

  //
  // AddFunction (Name: string; Line: cardinal);
  //

  //     COFF_AddFun('testfun');
  {
       COFF_Add_bf;
       //COFF_AddFilename('test\test2.bas');
       COFF_AddLineNum(0, 0); // Index to Sym
       COFF_AddLineNum(1, 0);
       COFF_AddLineNum(2, 2);
       COFF_AddLineNum(3, 4);
       COFF_AddLineNum(4, 6);
   }

    //End;

    *)
  if not nooptpasses then
    while (pass < 10) and jmp_opt_failed do
    begin
      WriteToolOutput('Compiling...Pass ' + IntToStr(pass));
      Inc(Pass);
      jmp_opt_failed := False;
      CompileBS1;
    end;

    WriteToolOutput('Compiled ');

  //  Bar.SimpleText := 'Compiling...Generating Code';  Bar.Update;

    //
    // Link in Libraries if ANY...
    //

  Pass := last_pass;
  //ListOn := 1; // Listing!
  p_lstfile := true;

  WriteToolOutput('Last pass ');
try
  CompileBS1; { Generate CODE! }
except
  WriteToolOutput('Last pass Exception');
end;

  WriteToolOutput('Code gen ');

  s := ExtractFileName(files[1]);
  Delete(s, Length(s) - 3, 4);

//  p_lstfile := True;

  WriteToolOutput('Saving Listing');
  ListStream.SaveToFile(s + '.lst');
  ObjectStream.SaveToFile(s + '.obj');
  CloseObjFile;


  (*
  // If doLibrary Then
   //Begin
  mCOFF.Add_ef;
  mCoff.Close;
  //End;

  *)

  if Elist.Count > 0 then
  begin
{$IFDEF IDE}
    ShowMessages;
    MessageForm := TMessageForm(FindFormWithClass(MessageFormClass));
    if MessageForm <> nil then
    begin
      // EList.Assign(MessageForm.MsgList.Items);
      MessageForm.MsgList.Clear;
      for i := 0 to Elist.Count - 1 do
      begin
        MessageForm.MsgList.Items.Add(EList[i]);
      end;
    end;
  end else begin
    MessageForm := TMessageForm(FindFormWithClass(MessageFormClass));
    if MessageForm <> nil then
    begin
      MessageForm.MsgList.Clear;
    end;
{$ELSE}
    EList.SaveToFile(ChangeFileExt(FileName, '.err'));
{$ENDIF}
  end else
  begin
{$IFDEF IDE}
{$ELSE}
    DeleteFile(ChangeFileExt(FileName, '.err'));
{$ENDIF}
  end;

end;

procedure ConsoleStringWrite(line: string);
begin
//  Writeln(line);
end;


initialization

  WriteStdOutput := @ConsoleStringWrite;

end.

