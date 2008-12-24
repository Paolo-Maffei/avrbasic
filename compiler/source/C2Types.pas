(*
  AVR Basic Compiler
  Copyright 1997-2002 Silicon Studio Ltd.
  Copyright 2008 Trioflex OY
  http://www.trioflex.com
*)

unit C2Types;

// Copyright 2000 Case2000

interface

uses
  SysUtils;

// Exceptions

//type
//  EAbstractError = class(Exception);

// Procedural types

type
  TWriteStringProc = procedure(str: string);

  TGetErrorLineNumberProc = function(str: string): integer;
  TGetErrorFileNameProc = function(str: string): string;
  TClearErrorOutput = procedure;

// Events

  TStringEvent = procedure(str: string) of object;


implementation

end.
