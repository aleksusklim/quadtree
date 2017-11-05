unit UXorList; // License: WTFPL, public domain.

interface // UXorList v0.1 by Kly_Men_COmpany!

{$UNDEF INL}{$IFDEF FPC}{$DEFINE INL}{$ELSE}{$IF CompilerVersion > 18.0}{$DEFINE INL}{$IFEND}{$ENDIF}

type
  TXorList = class
    class procedure FreeAndNil(var XorList: TXorList); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(const Bytes: Integer): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer): TXorList; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes: Integer): TXorList; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    function Data(const Offset: Integer = 0): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function Next(const Previous: TXorList = nil): TXorList; {$IFDEF INL}inline;{$ENDIF}
    function Connect(const Another: TXorList): TXorList; {$IFDEF INL}inline;{$ENDIF}
    function Remove(const Another: TXorList; const Free: Boolean): TXorList; {$IFDEF INL}inline;{$ENDIF}
    property Byte[const Offset: Integer]: Pointer read Data; default;
    class function Walk(var Current, Previous: TXorList): TXorList; {$IFDEF INL}inline;{$ENDIF}
  end;

type
  RXorList = record // SizeOf = N
    Value: PAnsiChar;
  end;

  PXorList = ^RXorList;

implementation

class procedure TXorList.FreeAndNil(var XorList: TXorList);
begin
  XorList.Free();
  XorList := nil;
end;

class function TXorList.SizeFor(const Bytes: Integer): Integer;
begin
  Assert((Bytes > $0) and (Bytes <= $7FFFFFE0) and ((Bytes and $3) = 0));
  Result := SizeOf(RXorList) + Bytes;
end;

class function TXorList.Init(const Memory: Pointer): TXorList;
begin
  Assert((Memory <> nil) and (((PAnsiChar(Memory) - PAnsiChar(0)) and (SizeOf(Pointer) - 1)) = 0));
  PXorList(Memory).Value := nil;
  Result := Memory;
end;

class function TXorList.Create(const Bytes: Integer): TXorList;
begin
  GetMem(Pointer(Result), TXorList.SizeFor(Bytes));
  TXorList.Init(Result);
end;

procedure TXorList.Free();
begin
  if Self <> nil then
    FreeMem(Pointer(Self));
end;

function TXorList.Data(const Offset: Integer = 0): Pointer;
begin
  Assert((Self <> nil) and (Offset >= 0));
  Result := PAnsiChar(Self) + SizeOf(RXorList) + Offset;
end;

function TXorList.Next(const Previous: TXorList = nil): TXorList;
begin
  Assert(Self <> nil);
  Result := TXorList(PAnsiChar(0) + ((PXorList(Self).Value - PAnsiChar(0)) xor (PAnsiChar(Pointer(Previous)) - PAnsiChar(0))));
end;

function TXorList.Connect(const Another: TXorList): TXorList;
begin
  if Self <> nil then
    PXorList(Self).Value := PAnsiChar(0) + ((PXorList(Self).Value - PAnsiChar(0)) xor (PAnsiChar(Another) - PAnsiChar(0)));
  if Another <> nil then
    PXorList(Another).Value := PAnsiChar(0) + ((PXorList(Another).Value - PAnsiChar(0)) xor (PAnsiChar(Self) - PAnsiChar(0)));
  Result := Another;
end;

function TXorList.Remove(const Another: TXorList; const Free: Boolean): TXorList;
begin
  Result := Self.Next(Another);
  Self.Connect(Another);
  Self.Connect(Result);
  Result.Connect(Another);
  if Free then
    Self.Free();
end;

class function TXorList.Walk(var Current, Previous: TXorList): TXorList;
begin
  Result:=Current.Next(Previous);
  Previous := Current;
  Current := Result;
end;
{
class function TXorList.Align(const Number: Integer; const Size: Byte = SizeOf(PtrInt)): Integer;
begin
  Assert((Number > 0) and (Size > 0) and (Size and (Size - 1) = 0));
  Result := Number;
  if (Result and (Size - 1)) <> 0 then
    Inc(Result, Size - (Result and (Size - 1)));
end;
}

{
procedure TestXorList(ElemSize,ListLength:Integer);
var XorList,Prev:TXorList;
  Index,Value:Integer;
begin
  XorList:=nil;
  for Index:=1 to ListLength do begin
    XorList:=XorList.Connect(TXorList.Create(ElemSize));
    PAnsiChar(XorList[Index mod ElemSize])^:=chr(Index);
  end;
  Prev:=nil;
  for Index:=ListLength downto 1 do begin
    Value:=ord(PAnsiChar(XorList[Index mod ElemSize])^);
    Assert(Value=(Index and $ff));
    PAnsiChar(XorList.Data())^:=chr(Value);
    TXorList.Walk(XorList,Prev);
  end;
  XorList:=Prev;
  Prev:=nil;
  while XorList<>nil do begin
    XorList:=XorList.Remove(Prev,True);
    TXorList.Walk(XorList,Prev);
  end;
  XorList:=Prev;
  Value:=ListLength;
  while XorList<>nil do begin
      Prev:=XorList;
      Value:=ord(PAnsiChar(XorList.Data())^);
      Assert(Value=(ListLength and $ff));
    XorList:=XorList.Connect(XorList.Next());
    Prev.Free();
    Inc(ListLength,Value);
    Dec(ListLength,Value+2);
  end;
end;
}
initialization
  Assert((SizeOf(Integer) = 4) and (SizeOf(Pointer) >= (SizeOf(Integer))));

end.

