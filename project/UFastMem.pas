unit UFastMem; // License: WTFPL, public domain.

interface // UFastMem v1.0 by Kly_Men_COmpany!

uses
  UFastList, UFastStack;                                                                                      

{(*}{$UNDEF INL}{$IFDEF FPC}{$DEFINE INL}type Native=PtrInt;{$ELSE}{$IF CompilerVersion > 18.0}{$DEFINE INL}{$IFEND}{$IF SizeOf(Pointer)=4}type Native=Integer;{$IFEND}{$IF SizeOf(Pointer)=8}type Native=Int64;{$IFEND}{$ENDIF}type PNative=^Native;{*)}

//type
//TFastMemEach=function(Memory:Pointer)
(*
  TFastMem3 = class
    class function SizeFor(): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastMem3; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes, Blocks: Integer): TFastMem3; {$IFDEF INL}inline;{$ENDIF}
    class procedure FreeAndNil(var FastMem: TFastMem3); {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    procedure Clear(const Delete: Boolean); {$IFDEF INL}inline;{$ENDIF}
    function Alloc(): Pointer;
    procedure Release(Memory: Pointer);
    function Count(): Integer;
//    function Each()
  end;
*)

type
  TFastMem2 = class
    class function SizeFor(): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastMem2; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes, Blocks: Integer): TFastMem2; {$IFDEF INL}inline;{$ENDIF}
    class procedure FreeAndNil(var FastMem: TFastMem2); {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    procedure Clear(const Delete: Boolean); {$IFDEF INL}inline;{$ENDIF}
    function Alloc(): Pointer;
    procedure Release(Memory: Pointer);
  end;

type
  TMe2 = record // SizeOf == 16/24 + 20/28
    Page: TLinkList;
    Bytes, Total: Integer;
    Offset: Native;
    Stack: ^TFastStack;
  end;

  PMe2 = ^TMe2;

  TBlock2 = record
    Parent: TLinkList;
    Data: PPointer;
  end;

  PBlock2 = ^TBlock2;
(*
type
  TFastMem1 = class
    class function SizeFor(): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastMem1; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes, Blocks: Integer): TFastMem1; {$IFDEF INL}inline;{$ENDIF}
    class procedure FreeAndNil(var FastMem: TFastMem1); {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    procedure Clear(); {$IFDEF INL}inline;{$ENDIF}
    function Alloc(): Pointer;
    procedure Release(Memory: Pointer);
  end;
*)

type
  TFastMem1 = class
    class function SizeFor(): Native; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer; const PageSize: Native): TFastMem1; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const PageSize: Native): TFastMem1; {$IFDEF INL}inline;{$ENDIF}
    class procedure FreeAndNil(var FastMem1: TFastMem1); {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    procedure Clear(); {$IFDEF INL}inline;{$ENDIF}
    function Alloc(const Bytes: Native): Pointer; {$IFDEF INL}inline;{$ENDIF}
    procedure Release(const Memory: Pointer); {$IFDEF INL}inline;{$ENDIF}
  end;

  PFastMem1 = ^TFastMem1;

type
  RFastMem1 = record // SizeOf == 4*N
    Page: TLinkList;
    Bytes, Total, Offset: Native;
  end;

  SFastMem1 = ^RFastMem1;

type
  TFastMem0 = class
    class function SizeFor(): Native; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer; const PageSize: Native): TFastMem0; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const PageSize: Native): TFastMem0; {$IFDEF INL}inline;{$ENDIF}
    class procedure FreeAndNil(var FastMem0: TFastMem0); {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    procedure Clear(); {$IFDEF INL}inline;{$ENDIF}
    function Alloc(const Bytes: Native): Pointer; {$IFDEF INL}inline;{$ENDIF}
  end;

  PFastMem0 = ^TFastMem0;

type
  RFastMem0 = record // SizeOf == 4*N
    Page: PPointer;
    Bytes, Total, Offset: Native;
  end;

  SFastMem0 = ^RFastMem0;

implementation

{
type
  TMe3 = record // SizeOf == 16/24 + 20/28
    Page: TLinkList;
    Bytes, Total: Integer;
    Offset, Size: Native;
    Stack: ^TFastStack;
  end;

  PMe3 = ^TMe3;

  TBlock3 = record
    Parent: TLinkList;
    Data: PPointer;
  end;

  PBlock3 = ^TBlock3;

class function TFastMem3.SizeFor(): Integer;
begin
  Result := SizeOf(TMe3) - SizeOf(Native) + TFastStack.SizeFor();
end;

class function TFastMem3.Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastMem3;
begin
  Assert((Memory <> nil) and (Bytes >= SizeOf(Native)) and (Blocks > 0) and ((Bytes and (SizeOf(Native) - 1)) = 0));
  TFastStack.Init(@PMe(Memory).Stack, SizeOf(Native), 256);
  PMe(Memory).Page := nil;
  PMe(Memory).Bytes := Bytes + SizeOf(Native);
  PMe(Memory).Total := PMe(Memory).Bytes * Blocks;
  Result := Memory;
end;

class function TFastMem3.Create(const Bytes, Blocks: Integer): TFastMem3;
begin
  GetMem(Pointer(Result), SizeFor());
  Init(Result, Bytes, Blocks);
end;

class procedure TFastMem3.FreeAndNil(var FastMem: TFastMem3);
begin
  FastMem.Free();
  FastMem := nil;
end;

procedure TFastMem3.Free();
begin
  if Self <> nil then
  begin
    Clear(True);
    FreeMem(Pointer(Self));
  end;
end;

procedure TFastMem3.Clear(const Delete: Boolean);
begin
  Assert(Self <> nil);
  while PMe(Self).Page <> nil do
    PMe(Self).Page := PMe(Self).Page.SplitLeft(True);
  TFastStack(@PMe(Self).Stack).Clear(Delete);
end;

function TFastMem3.Alloc(): Pointer;
var
  Me: PMe;
  Stack: TFastStack;
  Block: PBlock;
  Page: TLinkList;
  Size: PInteger;
begin
  Assert(Self <> nil);
  Me := Pointer(Self);
  Stack := @Me.Stack;
  if Me.Page = nil then
  begin
    Me.Page := TLinkList.Create(Me.Total + SizeOf(Native));
    Me.Offset := 0;
    Size := Me.Page[Me.Total];
    Size^ := 0;
  end
  else
    Size := Me.Page[Me.Total];
  if Stack.Empty() then
  begin
    Page := Me.Page;
    if Me.Offset = Me.Total then
    begin
      Me.Offset := 0;
      if Size^ <> 0 then
      begin
        Me.Page := TLinkList.Create(Me.Total + SizeOf(Native));
        Page := Page.ConnectRight(Me.Page);
        Size := Page[Me.Total];
        Size^ := 0;
      end;
    end;
    Block := Page[Me.Offset];
    Block.Parent := Page;
    Inc(Me.Offset, Me.Bytes);
  end
  else
  begin
    Block := PPointer(Stack.Pop())^;
    Page := Block.Parent;
    Size := Page[Me.Total];
  end;
  Inc(Size^);
  Result := @Block.Data;
end;

procedure TFastMem3.Release(Memory: Pointer);
var
  Me: PMe;
  Stack: TFastStack;
  Block, Last: PBlock;
  Page: TLinkList;
  Size: PInteger;
begin
  Me := Pointer(Self);
  Stack := @Me.Stack;
  Assert((Memory <> nil) and (Me <> nil) and (Me.Page <> nil));
  Block := Pointer(Native(Memory) - SizeOf(Native));
  Page := Block.Parent;
  Block.Data := Stack.Push();
  Block.Data^ := Block;
  Size := Page[Me.Total];
  Assert(Size^ > 0);
  Dec(Size^);
  if (Size^ = 0) and (Page <> Me.Page) then
  begin
    Block := Page[0];
    Memory := Pointer(Native(Block) + PMe(Self).Total);
    repeat
      Last := PPointer(Stack.Pop())^;
      Last.Data := Block.Data;
      Block.Data^ := Last;
      Block := Pointer(Native(Block) + Me.Bytes);
    until Block = Memory;
    Page.Remove(True);
  end;
end;
}

class function TFastMem2.SizeFor(): Integer;
begin
  Result := SizeOf(TMe2) - SizeOf(Native) + TFastStack.SizeFor();
end;

class function TFastMem2.Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastMem2;
begin
  Assert((Memory <> nil) and (Bytes >= SizeOf(Native)) and (Blocks > 0) and ((Bytes and (SizeOf(Native) - 1)) = 0));
  TFastStack.Init(@PMe2(Memory).Stack, SizeOf(Native), 256);
  PMe2(Memory).Page := nil;
  PMe2(Memory).Bytes := Bytes + SizeOf(Native);
  PMe2(Memory).Total := PMe2(Memory).Bytes * Blocks;
  Result := Memory;
end;

class function TFastMem2.Create(const Bytes, Blocks: Integer): TFastMem2;
begin
  GetMem(Pointer(Result), SizeFor());
  Init(Result, Bytes, Blocks);
end;

class procedure TFastMem2.FreeAndNil(var FastMem: TFastMem2);
begin
  FastMem.Free();
  FastMem := nil;
end;

procedure TFastMem2.Free();
begin
  if Self <> nil then
  begin
    Clear(True);
    FreeMem(Pointer(Self));
  end;
end;

procedure TFastMem2.Clear(const Delete: Boolean);
begin
  Assert(Self <> nil);
  while PMe2(Self).Page <> nil do
    PMe2(Self).Page := PMe2(Self).Page.SplitLeft(True);
  TFastStack(@PMe2(Self).Stack).Clear(Delete);
end;

function TFastMem2.Alloc(): Pointer;
var
  Me: PMe2;
  Stack: TFastStack;
  Block: PBlock2;
  Page: TLinkList;
  Size: PInteger;
begin
  Assert(Self <> nil);
  Me := Pointer(Self);
  Stack := @Me.Stack;
  if Me.Page = nil then
  begin
    Me.Page := TLinkList.Create(Me.Total + SizeOf(Native));
    Me.Offset := 0;
    Size := Me.Page[Me.Total];
    Size^ := 0;
  end
  else
    Size := Me.Page[Me.Total];
  if Stack.Empty() then
  begin
    Page := Me.Page;
    if Me.Offset = Me.Total then
    begin
      Me.Offset := 0;
      if Size^ <> 0 then
      begin
        Me.Page := TLinkList.Create(Me.Total + SizeOf(Native));
        Page := Page.ConnectRight(Me.Page);
        Size := Page[Me.Total];
        Size^ := 0;
      end;
    end;
    Block := Page[Me.Offset];
    Block.Parent := Page;
    Inc(Me.Offset, Me.Bytes);
  end
  else
  begin
    Block := PPointer(Stack.Pop())^;
    Page := Block.Parent;
    Size := Page[Me.Total];
  end;
  Inc(Size^);
  Result := @Block.Data;
end;

procedure TFastMem2.Release(Memory: Pointer);
var
  Me: PMe2;
  Stack: TFastStack;
  Block, Last: PBlock2;
  Page: TLinkList;
  Size: PInteger;
begin
  Me := Pointer(Self);
  Stack := @Me.Stack;
  Assert((Memory <> nil) and (Me <> nil) and (Me.Page <> nil));
  Block := {%H-}Pointer({%H-}Native(Memory) - SizeOf(Native));
  Page := Block.Parent;
  Block.Data := Stack.Push();
  Block.Data^ := Block;
  Size := Page[Me.Total];
  Assert(Size^ > 0);
  Dec(Size^);
  if (Size^ = 0) and (Page <> Me.Page) then
  begin
    Block := Page[0];
    Memory := {%H-}Pointer({%H-}Native(Block) + PMe2(Self).Total);
    repeat
      Last := PPointer(Stack.Pop())^;
      Last.Data := Block.Data;
      Block.Data^ := Last;
      Block := {%H-}Pointer({%H-}Native(Block) + Me.Bytes);
    until Block = Memory;
    Page.Remove(True);
  end;
end;

type
  TMe1 = record // SizeOf == 16/24
    Page: TLinkList;
    Bytes, Total: Integer;
    Offset: Native;
  end;

  PMe1 = ^TMe1;

  TBlock1 = record
    Parent: TLinkList;
    Data: PPointer;
  end;

  PBlock1 = ^TBlock1;

// TFastMem1 //
(*
class function TFastMem1.SizeFor(): Integer;
begin
  Result := SizeOf(TMe1);
end;

class function TFastMem1.Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastMem1;
begin
  Assert((Memory <> nil) and (Bytes >= SizeOf(Native)) and (Blocks > 0) and ((Bytes and (SizeOf(Native) - 1)) = 0));
  PMe1(Memory).Page := nil;
  PMe1(Memory).Bytes := Bytes + SizeOf(Native);
  PMe1(Memory).Total := PMe1(Memory).Bytes * Blocks;
  Result := Memory;
end;

class function TFastMem1.Create(const Bytes, Blocks: Integer): TFastMem1;
begin
  GetMem(Pointer(Result), SizeFor());
  Init(Result, Bytes, Blocks);
end;

class procedure TFastMem1.FreeAndNil(var FastMem: TFastMem1);
begin
  FastMem.Free();
  FastMem := nil;
end;

procedure TFastMem1.Free();
begin
  if Self <> nil then
  begin
    Clear();
    FreeMem(Pointer(Self));
  end;
end;

procedure TFastMem1.Clear();
begin
  Assert(Self <> nil);
  while PMe1(Self).Page <> nil do
    PMe1(Self).Page := PMe1(Self).Page.SplitLeft(True);
end;

function TFastMem1.Alloc(): Pointer;
var
  Me: PMe1;
  Block: PBlock1;
  Page: TLinkList;
  Size: PInteger;
begin
  Assert(Self <> nil);
  Me := Pointer(Self);
  if Me.Page = nil then
  begin
    Me.Page := TLinkList.Create(Me.Total + SizeOf(Native));
    Me.Offset := 0;
    Size := Me.Page[Me.Total];
    Size^ := 0;
  end
  else
    Size := Me.Page[Me.Total];
  Page := Me.Page;
  if Me.Offset = Me.Total then
  begin
    Me.Offset := 0;
    if Size^ <> 0 then
    begin
      Me.Page := TLinkList.Create(Me.Total + SizeOf(Native));
      Page := Page.ConnectRight(Me.Page);
      Size := Page[Me.Total];
      Size^ := 0;
    end;
  end;
  Block := Page[Me.Offset];
  Block.Parent := Page;
  Inc(Me.Offset, Me.Bytes);
  Inc(Size^);
  Result := @Block.Data;
end;

procedure TFastMem1.Release(Memory: Pointer);
var
  Me: PMe1;
  Block: PBlock1;
  Page: TLinkList;
  Size: PInteger;
begin
  Me := Pointer(Self);
  Assert((Memory <> nil) and (Me <> nil) and (Me.Page <> nil));
  Block := {%H-}Pointer({%H-}Native(Memory) - SizeOf(Native));
  Page := Block.Parent;
  Size := Page[Me.Total];
  Assert(Size^ > 0);
  Dec(Size^);
  if (Size^ = 0) and (Page <> Me.Page) then
    Page.Remove(True);
end;
*)


// TFastMem1 //

class function TFastMem1.SizeFor(): Native;
begin
  Result := SizeOf(RFastMem1);
end;

class function TFastMem1.Init(const Memory: Pointer; const PageSize: Native): TFastMem1;
begin
  Assert((Memory <> nil) and (PageSize > 0));
  SFastMem1(Memory).Page := nil;
  SFastMem1(Memory).Total := SizeOf(Native) + PageSize;
  SFastMem1(Memory).Offset := SFastMem1(Memory).Total;
  Result := Memory;
end;

class function TFastMem1.Create(const PageSize: Native): TFastMem1;
begin
  GetMem(Pointer(Result), Self.SizeFor());
  Self.Init(Result, PageSize);
end;

class procedure TFastMem1.FreeAndNil(var FastMem1: TFastMem1);
begin
  FastMem1.Free();
  FastMem1 := nil;
end;

procedure TFastMem1.Free();
begin
  if Self <> nil then
  begin
    Self.Clear();
    FreeMem(Pointer(Self));
  end;
end;

procedure TFastMem1.Clear();
begin
  Assert(Self <> nil);
  while SFastMem1(Self).Page <> nil do
    SFastMem1(Self).Page := SFastMem1(Self).Page.SplitLeft(True);
  SFastMem1(Self).Offset := SFastMem1(Self).Total;
end;

function TFastMem1.Alloc(const Bytes: Native): Pointer;
begin
  Assert((Self <> nil) and (Bytes > 0) and (Bytes <= SFastMem1(Self).Total - SizeOf(Native)));
  if SFastMem1(Self).Offset + Bytes > SFastMem1(Self).Total then
  begin
    if SFastMem1(Self).Page = nil then
      SFastMem1(Self).Page := TLinkList.Create(SFastMem1(Self).Total + SizeOf(Pointer))
    else
      SFastMem1(Self).Page := SFastMem1(Self).Page.ConnectRight(TLinkList.Create(SFastMem1(Self).Total + SizeOf(Pointer)));
    SFastMem1(Self).Offset := SizeOf(Native);
    Result := SFastMem1(Self).Page.Data();
    ({%H-}PNative(Result))^ := 1;
  end
  else
  begin
    Result := SFastMem1(Self).Page.Data();
    Inc(PNative({%H-}Result)^);
  end;
  Result := {%H-}Pointer({%H-}Native(Result) + SFastMem1(Self).Offset + SizeOf(Pointer));
  PPointer({%H-}Pointer({%H-}Native(Result) - SizeOf(Pointer)))^ := SFastMem1(Self).Page;
  Inc(SFastMem1(Self).Offset, Bytes + SizeOf(Pointer));
end;

procedure TFastMem1.Release(const Memory: Pointer);
var
  Link: PLinkList;
  Size: PNative;
begin
  Assert((Self <> nil) and (Memory <> nil) and (SFastMem1(Self).Page <> nil));
  Link := {%H-}Pointer({%H-}Native(Memory) - SizeOf(Pointer));
  Size := Link^.Data();
  if Size^ = 1 then
    if Link^ = SFastMem1(Self).Page then
      SFastMem1(Self).Offset := SizeOf(Native)
    else
      Link^.Remove(True)
  else
    Dec(Size^);
end;

// TFastMem0 //

class function TFastMem0.SizeFor(): Native;
begin
  Result := SizeOf(RFastMem0);
end;

class function TFastMem0.Init(const Memory: Pointer; const PageSize: Native): TFastMem0;
begin
  Assert((Memory <> nil) and (PageSize > 0));
  SFastMem0(Memory).Page := nil;
  SFastMem0(Memory).Total := SizeOf(Pointer) + PageSize;
  Result := Memory;
end;

class function TFastMem0.Create(const PageSize: Native): TFastMem0;
begin
  GetMem(Pointer(Result), Self.SizeFor());
  Self.Init(Result, PageSize);
end;

class procedure TFastMem0.FreeAndNil(var FastMem0: TFastMem0);
begin
  FastMem0.Free();
  FastMem0 := nil;
end;

procedure TFastMem0.Free();
begin
  if Self <> nil then
  begin
    Self.Clear();
    FreeMem(Pointer(Self));
  end;
end;

procedure TFastMem0.Clear();
var
  Old: Pointer;
begin
  Assert(Self <> nil);
  while SFastMem0(Self).Page <> nil do
  begin
    Old := SFastMem0(Self).Page;
    SFastMem0(Self).Page := (SFastMem0(Self).Page)^;
    FreeMem(Old);
  end;
end;

function TFastMem0.Alloc(const Bytes: Native): Pointer;
var
  Old: Pointer;
begin
  Assert((Self <> nil) and (Bytes > 0) and (Bytes <= SFastMem0(Self).Total - SizeOf(Pointer)));
  if (SFastMem0(Self).Page = nil) or (SFastMem0(Self).Offset + Bytes > SFastMem0(Self).Total) then
  begin
    SFastMem0(Self).Offset := SizeOf(Pointer);
    Old := SFastMem0(Self).Page;
    GetMem(SFastMem0(Self).Page, SFastMem0(Self).Total);
    SFastMem0(Self).Page^ := Old;
  end;
  Result := {%H-}Pointer({%H-}Native(SFastMem0(Self).Page) + SFastMem0(Self).Offset);
  Inc(SFastMem0(Self).Offset, Bytes);
end;

end.

