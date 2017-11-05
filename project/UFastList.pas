unit UFastList; // License: WTFPL, public domain.

interface // UFastList v1.0 by Kly_Men_COmpany!

{(*}{$UNDEF INL}{$IFDEF FPC}{$DEFINE INL}type Native=PtrInt;{$ELSE}{$IF CompilerVersion > 18.0}{$DEFINE INL}{$IFEND}{$IF SizeOf(Pointer)=4}type Native=Integer;{$IFEND}{$IF SizeOf(Pointer)=8}type Native=Int64;{$IFEND}{$ENDIF}type PNative=^Native;{*)}

// Two classes for simple, efficient and very fast lists.
// Not delphi-objects actually, just direct memory records manipulation.
// So you cannot use any of TObject stuff along with inheritance and everything.
// There is no "list itself" structure, every object represents a node.

// TXorList - fast linked list, stores XOR of next and previous elements.
// Thus is can be iterated from both corners the same way.
// Often used just as a symmetric single-linked list.

// TLinkList - double linked list, stores two pointers.
// Use when you need to operate on middle nodes explicitly.
// Also can be circular.

// Use Class.Create just as you always use object constructors. Specify desired data size.
// You can release memory by calling .Free or Class.FreeAndNil (but not a global one!).
// Also you can convert any memory chunk to a list node: call Class.SizeFor to determine
//   a total amount of bytes to store the element + your data, then call Class.Init on that memory (must be native-aligned).
// Use .Data (or a simple array[] syntax) to get a pointer to real data in the list (do not dereference the object itself!)
// Single list element is limited to 2Gb on both x86 and x64.

// For TXorList:
// .Next - returns the next element when you have a previous or know that it's a corner (pass nil).
// .Connect - joins two corner elements, or splits two already connected; can be called on nil nodes.
//   Must not be called on arbitrary middle elements! Returns passed argument.
// .Remove - disconnects the current node if given a sibling (or nil for a corner),
//   can free this element; returns the other sibling.
// Class.Walk - moves to the next element given current and previous, updating your variables.

// For TLinkList:
// .NextRight/.NextLeft - returns the next or previous node.
// .ConnectRight/.ConnectLeft - joins two elements together from the desired side.
//   Must be called on opposite corner nodes; returns passed argument.
// .SplitRight/.SplitLeft - disconnects two joined nodes, can be called even if no sibling present.
//   Returns the other element, can optionally free the current one.
// .Remove - disconnects two siblings and connects them together directly, can free current node.

// For best performance disable assertations in release mode.
// Also use inlining whenever possible, along with enabled optimization.
// Designed for Delphi 6+ and Lazarus/FPC 3+, only for x86 and x64 systems.

type
  TXorList = class
    class procedure FreeAndNil(var XorList: TXorList); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(const Bytes: Native): Native; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer): TXorList; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes: Native): TXorList; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    function Data(const Offset: Native = 0): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function Next(const Previous: TXorList = nil): TXorList; {$IFDEF INL}inline;{$ENDIF}
    function Connect(const Another: TXorList): TXorList; {$IFDEF INL}inline;{$ENDIF}
    function Remove(const Another: TXorList; const Free: Boolean): TXorList; {$IFDEF INL}inline;{$ENDIF}
    property Byte[const Offset: Native]: Pointer read Data; default;
    class function Walk(var Current, Previous: TXorList): TXorList; {$IFDEF INL}inline;{$ENDIF}
  end;

  PXorList = ^TXorList;

  RXorList = record // SizeOf = 1*N
    Value: Pointer;
  end;

  SXorList = ^RXorList;

type
  TLinkList = class
    class procedure FreeAndNil(var LinkList: TLinkList); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(const Bytes: Native): Native; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes: Native): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    function Data(const Offset: Native = 0): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function NextRight(): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function NextLeft(): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function ConnectRight(const Another: TLinkList): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function ConnectLeft(const Another: TLinkList): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function SplitRight(const Free: Boolean = False): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    function SplitLeft(const Free: Boolean = False): TLinkList; {$IFDEF INL}inline;{$ENDIF}
    procedure Remove(const Free: Boolean); {$IFDEF INL}inline;{$ENDIF}
    property Byte[const Offset: Native]: Pointer read Data; default;
  end;

  PLinkList = ^TLinkList;

  RLinkList = record // SizeOf = 2*N
    Prev: Pointer;
    Next: Pointer;
  end;

  SLinkList = ^RLinkList;

implementation

// TXorList //

class procedure TXorList.FreeAndNil(var XorList: TXorList);
begin
  XorList.Free();
  XorList := nil;
end;

class function TXorList.SizeFor(const Bytes: Native): Native;
begin
  Assert(Bytes >= 0);
  Result := SizeOf(RXorList) + Bytes;
end;

class function TXorList.Init(const Memory: Pointer): TXorList;
begin
  Assert((Memory <> nil) and (({%H-}Native(Memory) and (SizeOf(Pointer) - 1)) = 0));
  SXorList(Memory).Value := nil;
  Result := Memory;
end;

class function TXorList.Create(const Bytes: Native): TXorList;
begin
  GetMem(Pointer(Result), Self.SizeFor(Bytes));
  Self.Init(Result);
end;

procedure TXorList.Free();
begin
  if Self <> nil then
    FreeMem(Pointer(Self));
end;

function TXorList.Data(const Offset: Native = 0): Pointer;
begin
  Assert((Self <> nil) and (Offset >= 0));
  Result := {%H-}Pointer({%H-}Native({%H-}Pointer(Self)) + SizeOf(RXorList) + Offset);
end;

function TXorList.Next(const Previous: TXorList = nil): TXorList;
begin
  Assert(Self <> nil);
  Result := TXorList({%H-}Pointer({%H-}Native(SXorList(Self).Value) xor {%H-}Native(Pointer(Previous))));
end;

function TXorList.Connect(const Another: TXorList): TXorList;
begin
  Assert(Self <> Another);
  if Self <> nil then
    SXorList(Self).Value := {%H-}Pointer({%H-}Native(SXorList(Self).Value) xor {%H-}Native(Pointer(Another)));
  if Another <> nil then
    SXorList(Another).Value := {%H-}Pointer({%H-}Native(SXorList(Another).Value) xor {%H-}Native(Pointer(Self)));
  Result := Another;
end;

function TXorList.Remove(const Another: TXorList; const Free: Boolean): TXorList;
begin
  Assert(Self <> Another);
  Result := Self.Next(Another);
  Self.Connect(Another);
  Self.Connect(Result);
  Result.Connect(Another);
  if Free then
    Self.Free();
end;

class function TXorList.Walk(var Current, Previous: TXorList): TXorList;
begin
  Result := Current.Next(Previous);
  Previous := Current;
  Current := Result;
end;

// TLinkList //

class procedure TLinkList.FreeAndNil(var LinkList: TLinkList);
begin
  LinkList.Free();
  LinkList := nil;
end;

class function TLinkList.SizeFor(const Bytes: Native): Native;
begin
  Assert(Bytes >= 0);
  Result := SizeOf(RLinkList) + Bytes;
end;

class function TLinkList.Init(const Memory: Pointer): TLinkList;
begin
  Assert((Memory <> nil) and (({%H-}Native(Memory) and (SizeOf(Pointer) - 1)) = 0));
  SLinkList(Memory).Prev := nil;
  SLinkList(Memory).Next := nil;
  Result := Memory;
end;

class function TLinkList.Create(const Bytes: Native): TLinkList;
begin
  GetMem(Pointer(Result), Self.SizeFor(Bytes));
  Self.Init(Result);
end;

procedure TLinkList.Free();
begin
  if Self <> nil then
    FreeMem(Pointer(Self));
end;

function TLinkList.Data(const Offset: Native = 0): Pointer;
begin
  Assert((Self <> nil) and (Offset >= 0));
  Result := {%H-}Pointer({%H-}Native({%H-}Pointer(Self)) + SizeOf(RLinkList) + Offset);
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
  Assert((Self <> nil) and (SLinkList(Self).Next = nil) and ((Another = nil) or (SLinkList(Another).Next = nil)));
  SLinkList(Self).Next := Another;
  if Another <> nil then
    SLinkList(Another).Prev := Self;
  Result := Another;
end;

function TLinkList.ConnectLeft(const Another: TLinkList): TLinkList;
begin
  Assert((Self <> nil) and (SLinkList(Self).Prev = nil) and ((Another = nil) or (SLinkList(Another).Next = nil)));
  SLinkList(Self).Prev := Another;
  if Another <> nil then
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

// Tests //

procedure TryXorList();
var
  XorList, Next: TXorList;
begin
  TXorList.SizeFor(8);
  XorList := TXorList.Create(8);
  TXorList.Init(XorList);
  XorList.Connect(nil);
  XorList.Data();
  PXorList(XorList[0])^ := XorList;
  Next := XorList.Next();
  XorList.Walk(XorList, Next);
  XorList := Next;
  XorList.Remove(nil, False);
  TXorList.FreeAndNil(XorList);
  XorList.Free();
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

end.

