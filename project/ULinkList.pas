unit ULinkList; // License: WTFPL, public domain.

interface // ULinkList v1.0 by Kly_Men_COmpany!

//{$UNDEF INL}{$IFDEF FPC}{$DEFINE INL}{$ELSE}{$IF CompilerVersion > 18.0}{$DEFINE INL}{$IFEND}{$ENDIF}

type
  TLinkList = class
    class procedure FreeAndNil(var LinkList: TLinkList); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(const Bytes: Integer): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes: Integer): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    function Data(const Offset: Integer = 0): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function NextRight(): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function NextLeft(): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function ConnectRight(const Another: TLinkList): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function ConnectLeft(const Another: TLinkList): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function SplitRight(const Free: Boolean = False): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function SplitLeft(const Free: Boolean = False): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    procedure Remove(const Free: Boolean); {$IFDEF INL}inline;{$ENDIF}
    property Byte[const Offset: Integer]: Pointer read Data; default;
  end;

  PLinkList = ^TLinkList;

type
  RLinkList = record // SizeOf = 2*N
    Prev: Pointer;
    Next: Pointer;
  end;

  SLinkList = ^RLinkList;

implementation

class procedure TLinkList.FreeAndNil(var LinkList: TLinkList);
begin
  LinkList.Free();
  LinkList := nil;
end;

class function TLinkList.SizeFor(const Bytes: Integer): Integer;
begin
  Assert((Bytes > $0) and (Bytes <= $7FFFFFE0));
  Result := SizeOf(RLinkList) + Bytes;
end;

class function TLinkList.Init(const Memory: Pointer): TLinkList;
begin
  Assert((Memory <> nil) and (((PAnsiChar(Memory) - PAnsiChar(0)) and (SizeOf(Pointer) - 1)) = 0));
  SLinkList(Memory).Prev := nil;
  SLinkList(Memory).Next := nil;
  Result := Memory;
end;

class function TLinkList.Create(const Bytes: Integer): TLinkList;
begin
  GetMem(Pointer(Result), TLinkList.SizeFor(Bytes));
  TLinkList.Init(Result);
end;

procedure TLinkList.Free();
begin
  if Self <> nil then
    FreeMem(Pointer(Self));
end;

function TLinkList.Data(const Offset: Integer = 0): Pointer;
begin
  Assert((Self <> nil) and (Offset >= 0));
  Result := PAnsiChar(Self) + SizeOf(RLinkList) + Offset;
end;

function TLinkList.NextRight(): TLinkList;
begin
  Assert(Self <> nil);
  Result := SLinkList(Self).Next;
end;

function TLinkList.NextLeft(): TLinkList;
begin
  Assert(Self <> nil);
  Result := SLinkList(Self).Prev;
end;

function TLinkList.ConnectRight(const Another: TLinkList): TLinkList;
begin
  Assert((Self <> nil) and (Another <> nil) and (SLinkList(Self).Next = nil) and (SLinkList(Another).Prev = nil));
  SLinkList(Self).Next := Another;
  SLinkList(Another).Prev := Self;
  Result := Another;
end;

function TLinkList.ConnectLeft(const Another: TLinkList): TLinkList;
begin
  Assert((Self <> nil) and (Another <> nil) and (SLinkList(Self).Prev = nil) and (SLinkList(Another).Next = nil));
  SLinkList(Self).Prev := Another;
  SLinkList(Another).Next := Self;
  Result := Another;
end;

function TLinkList.SplitRight(const Free: Boolean = False): TLinkList;
begin
  Assert((Self <> nil) and ((SLinkList(Self).Next = nil) or (SLinkList(SLinkList(Self).Next).Prev = Self)));
  Result := SLinkList(Self).Next;
  if Result <> nil then
    SLinkList(Result).Prev := nil;
  SLinkList(Self).Next := nil;
  if Free then
  begin
    Assert(SLinkList(Self).Prev = nil);
    Self.Free();
  end;
end;

function TLinkList.SplitLeft(const Free: Boolean = False): TLinkList;
begin
  Assert((Self <> nil) and ((SLinkList(Self).Prev = nil) or (SLinkList(SLinkList(Self).Prev).Next = Self)));
  Result := SLinkList(Self).Prev;
  if Result <> nil then
    SLinkList(Result).Next := nil;
  SLinkList(Self).Prev := nil;
  if Free then
  begin
    Assert(SLinkList(Self).Next = nil);
    Self.Free();
  end;
end;

procedure TLinkList.Remove(const Free: Boolean);
begin
  Assert((Self <> nil) and ((SLinkList(Self).Next = nil) or (SLinkList(SLinkList(Self).Next).Prev = Self)) and ((SLinkList(Self).Prev = nil) or (SLinkList(SLinkList(Self).Prev).Next = Self)));
  if SLinkList(Self).Next <> nil then
    SLinkList(SLinkList(Self).Next).Prev := SLinkList(Self).Prev;
  if SLinkList(Self).Prev <> nil then
    SLinkList(SLinkList(Self).Prev).Next := SLinkList(Self).Next;
  if Free then
    Self.Free();
end;

procedure TryLinkList();
var
  LinkList, Next: TLinkList;
begin
  TLinkList.SizeFor(8);
  LinkList := TLinkList.Create(8);
  TLinkList.Init(LinkList);
  Next := TLinkList.Create(8);
  LinkList.ConnectRight(Next);
  Next.ConnectRight(LinkList);
  LinkList.SplitRight(False);
  LinkList.SplitLeft(False);
  Next.ConnectLeft(LinkList);
  LinkList.ConnectLeft(Next);
  Next.Remove(True);
  LinkList.Data();
  Next := LinkList.NextRight();
  PLinkList(LinkList[0])^ := Next;
  Next := LinkList.NextLeft();
  TLinkList.FreeAndNil(Next);
  Next.Free();
end;

initialization
  Assert((SizeOf(Integer) = 4) and (SizeOf(Pointer) >= (SizeOf(Integer))));

end.

