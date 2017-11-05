unit UFastStack; // License: WTFPL, public domain.

interface // UFastStack v1.0 by Kly_Men_COmpany!

// Comment out this line if it doesn't compile:
{$UNDEF INL}{$IFDEF FPC}{$DEFINE INL}{$ELSE}{$IF CompilerVersion > 18.0}{$DEFINE INL}{$IFEND}{$ENDIF}

uses
  UFastList;

type
  TFastStack = class
    class procedure FreeAndNil(var FastStack: TFastStack); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastStack; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes, Blocks: Integer): TFastStack; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    procedure Clear(const CacheFree: Boolean = True); {$IFDEF INL}inline;{$ENDIF}
    function Empty(): Boolean; {$IFDEF INL}inline;{$ENDIF}
    function Peek(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function Push(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function Pop(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    procedure Remove(const Count: Integer); {$IFDEF INL}inline;{$ENDIF}
  end;

  PFastStack = ^TFastStack;

  RFastStack = record // SizeOf = 1*N + 3*4
    Page, Cache: TXorList;
    Bytes, Total: Integer;
    Offset: Integer;
  end;

  SFastStack = ^RFastStack;

type
  TFastQueue = class
    class procedure FreeAndNil(var FastQueue: TFastQueue); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastQueue; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes, Blocks: Integer): TFastQueue; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    procedure Clear(); {$IFDEF INL}inline;{$ENDIF}
    procedure Release(); {$IFDEF INL}inline;{$ENDIF}
    function Count(): Integer; {$IFDEF INL}inline;{$ENDIF}
    function PeekHead(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function PeekTail(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function PushHead(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function PushTail(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function PopHead(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function PopTail(): Pointer; {$IFDEF INL}inline;{$ENDIF}
    procedure RemoveHead(const Count: Integer); {$IFDEF INL}inline;{$ENDIF}
    procedure RemoveTail(const Count: Integer); {$IFDEF INL}inline;{$ENDIF}
  end;

  PFastQueue = ^TFastQueue;

  RFastQueue = record // SizeOf = ??
    PageLeft, PageRight, Middle: TLinkList;
    Bytes, Total, Size: Integer;
    OffsetLeft, OffsetRight: Integer;
  end;

  SFastQueue = ^RFastQueue;

implementation

// TFastStack //

class procedure TFastStack.FreeAndNil(var FastStack: TFastStack);
begin
  FastStack.Free();
  FastStack := nil;
end;

class function TFastStack.SizeFor(): Integer;
begin
  Result := SizeOf(RFastStack);
end;

class function TFastStack.Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastStack;
begin
  Assert((Memory <> nil) and (Bytes > 0) and (Blocks > 0) and (((PAnsiChar(Memory) - PAnsiChar(0)) and (SizeOf(Pointer) - 1)) = 0));
  SFastStack(Memory).Page := nil;
  SFastStack(Memory).Bytes := Bytes;
  SFastStack(Memory).Total := Bytes * Blocks;
  Result := Memory;
end;

class function TFastStack.Create(const Bytes, Blocks: Integer): TFastStack;
begin
  GetMem(Pointer(Result), Self.SizeFor());
  Self.Init(Result, Bytes, Blocks);
end;

procedure TFastStack.Free();
begin
  if Self <> nil then
  begin
    Self.Clear(True);
    FreeMem(Pointer(Self));
  end;
end;

procedure TFastStack.Clear(const CacheFree: Boolean = True);
begin
  Assert(Self <> nil);
  while SFastStack(Self).Page <> nil do
    SFastStack(Self).Page := SFastStack(Self).Page.Remove(nil, True);
  if CacheFree then
    TXorList.FreeAndNil(SFastStack(Self).Cache);
end;

function TFastStack.Peek(): Pointer;
begin
  Assert((Self <> nil) and (SFastStack(Self).Page <> nil));
  Result := SFastStack(Self).Page[SFastStack(Self).Offset];
end;

function TFastStack.Empty(): Boolean;
begin
  Assert(Self <> nil);
  Result := (SFastStack(Self).Page = nil);
end;

function TFastStack.Push(): Pointer;
begin
  Assert(Self <> nil);
  Inc(SFastStack(Self).Offset, SFastStack(Self).Bytes);
  if (SFastStack(Self).Offset = SFastStack(Self).Total) or (SFastStack(Self).Page = nil) then
  begin
    if SFastStack(Self).Cache = nil then
      SFastStack(Self).Cache := TXorList.Create(SFastStack(Self).Total);
    if SFastStack(Self).Page = nil then
      SFastStack(Self).Page := SFastStack(Self).Cache
    else
      SFastStack(Self).Page := SFastStack(Self).Page.Connect(SFastStack(Self).Cache);
    SFastStack(Self).Cache := nil;
    SFastStack(Self).Offset := 0;
  end;
  Result := SFastStack(Self).Page[SFastStack(Self).Offset];
end;

function TFastStack.Pop(): Pointer;
begin
  Assert((Self <> nil) and (SFastStack(Self).Page <> nil));
  Result := SFastStack(Self).Page[SFastStack(Self).Offset];
  Dec(SFastStack(Self).Offset, SFastStack(Self).Bytes);
  if SFastStack(Self).Offset < 0 then
  begin
    SFastStack(Self).Offset := SFastStack(Self).Total - SFastStack(Self).Bytes;
    SFastStack(Self).Cache.Free();
    SFastStack(Self).Cache := SFastStack(Self).Page;
    SFastStack(Self).Page := SFastStack(Self).Page.Connect(SFastStack(Self).Page.Next());
  end;
end;

procedure TFastStack.Remove(const Count: Integer);
begin
  Assert((Self <> nil) and (Count >= 0));
  if SFastStack(Self).Page <> nil then
  begin
    Dec(SFastStack(Self).Offset, Count * SFastStack(Self).Bytes);
    if SFastStack(Self).Offset < 0 then
    begin
      SFastStack(Self).Cache.Free();
      SFastStack(Self).Cache := SFastStack(Self).Page;
      SFastStack(Self).Page := SFastStack(Self).Page.Remove(nil, False);
      if SFastStack(Self).Page <> nil then
        repeat
          Inc(SFastStack(Self).Offset, SFastStack(Self).Total);
          if SFastStack(Self).Offset >= 0 then
            Break;
          SFastStack(Self).Page := SFastStack(Self).Page.Remove(nil, True);
        until SFastStack(Self).Page = nil;
    end;
  end;
end;


// TFastQueue //

class procedure TFastQueue.FreeAndNil(var FastQueue: TFastQueue);
begin
  FastQueue.Free();
  FastQueue := nil;
end;

class function TFastQueue.SizeFor(): Integer;
begin
  Result := SizeOf(RFastQueue);
end;

class function TFastQueue.Init(const Memory: Pointer; const Bytes, Blocks: Integer): TFastQueue;
begin
  Assert((Memory <> nil) and (Bytes > 0) and (Blocks > 0) and (((PAnsiChar(Memory) - PAnsiChar(0)) and (SizeOf(Pointer) - 1)) = 0));
  SFastQueue(Memory).Bytes := Bytes;
  SFastQueue(Memory).Total := Bytes * Blocks; // dec ?
  SFastQueue(Memory).Middle := TLinkList.Create(SFastQueue(Memory).Total);
  SFastQueue(Memory).PageLeft := SFastQueue(Memory).Middle;
  SFastQueue(Memory).PageRight := SFastQueue(Memory).Middle;
  SFastQueue(Self).Size := 0;
  Result := Memory;
end;

class function TFastQueue.Create(const Bytes, Blocks: Integer): TFastQueue;
begin
  GetMem(Pointer(Result), Self.SizeFor());
  Self.Init(Result, Bytes, Blocks);
end;

procedure TFastQueue.Free();
begin
  if Self <> nil then
  begin
    Self.Release();
    FreeMem(Pointer(Self));
  end;
end;

procedure TFastQueue.Clear();
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  if SFastQueue(Self).Size > 0 then
  begin
    SFastQueue(Self).Middle := SFastQueue(Self).PageLeft.SplitLeft(False);
    while SFastQueue(Self).PageLeft <> SFastQueue(Self).PageRight do
      SFastQueue(Self).PageLeft := SFastQueue(Self).PageLeft.SplitRight(True);
    SFastQueue(Self).PageLeft.ConnectLeft(SFastQueue(Self).Middle);
    SFastQueue(Self).Middle := SFastQueue(Self).PageLeft;
    SFastQueue(Self).Size := 0;
  end;
end;

procedure TFastQueue.Release();
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  SFastQueue(Self).Middle := SFastQueue(Self).PageLeft.NextLeft();
  if SFastQueue(Self).Middle <> nil then
    SFastQueue(Self).PageLeft := SFastQueue(Self).Middle;
  while SFastQueue(Self).PageLeft <> nil do
    SFastQueue(Self).PageLeft := SFastQueue(Self).PageLeft.SplitRight(True);
  SFastQueue(Self).Size := -1;
end;

function TFastQueue.Count(): Integer;
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  Result := SFastQueue(Self).Size;
end;

function TFastQueue.PeekHead(): Pointer;
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  if SFastQueue(Self).Size = 0 then
    Result := nil
  else
    Result := SFastQueue(Self).PageLeft[SFastQueue(Self).OffsetLeft];
end;

function TFastQueue.PeekTail(): Pointer;
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  if SFastQueue(Self).Size = 0 then
    Result := nil
  else
    Result := SFastQueue(Self).PageRight[SFastQueue(Self).OffsetRight];
end;

function TFastQueue.PushHead(): Pointer;
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  if SFastQueue(Self).Size = 0 then
  begin
    SFastQueue(Self).OffsetLeft := SFastQueue(Self).Total - SFastQueue(Self).Bytes;
    SFastQueue(Self).OffsetRight := SFastQueue(Self).OffsetLeft;
  end
  else
  begin
    Dec(SFastQueue(Self).OffsetLeft, SFastQueue(Self).Bytes);
    if SFastQueue(Self).OffsetLeft < 0 then
    begin
      Result := SFastQueue(Self).PageLeft.NextLeft();
      if Result <> nil then
        SFastQueue(Self).PageLeft := Result
      else
        SFastQueue(Self).PageLeft := SFastQueue(Self).PageLeft.ConnectLeft(TLinkList.Create(SFastQueue(Self).Total));
      SFastQueue(Self).OffsetLeft := SFastQueue(Self).Total - SFastQueue(Self).Bytes;
    end;
  end;
  Inc(SFastQueue(Self).Size);
  Result := SFastQueue(Self).PageLeft[SFastQueue(Self).OffsetLeft];
end;

function TFastQueue.PushTail(): Pointer;
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  if SFastQueue(Self).Size = 0 then
  begin
    SFastQueue(Self).OffsetRight := 0;
    SFastQueue(Self).OffsetLeft := 0;
  end
  else
  begin
    Inc(SFastQueue(Self).OffsetRight, SFastQueue(Self).Bytes);
    if SFastQueue(Self).OffsetRight = SFastQueue(Self).Total then
    begin
      Result := SFastQueue(Self).PageRight.NextRight();
      if Result <> nil then
        SFastQueue(Self).PageRight := Result
      else
        SFastQueue(Self).PageRight := SFastQueue(Self).PageRight.ConnectRight(TLinkList.Create(SFastQueue(Self).Total));
      SFastQueue(Self).OffsetRight := 0;
    end;
  end;
  Inc(SFastQueue(Self).Size);
  Result := SFastQueue(Self).PageRight[SFastQueue(Self).OffsetRight];
end;

function TFastQueue.PopHead(): Pointer;
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  Result := SFastQueue(Self).PageLeft[SFastQueue(Self).OffsetLeft];
  Dec(SFastQueue(Self).Size);
  if SFastQueue(Self).Size > 0 then
  begin
    Inc(SFastQueue(Self).OffsetLeft, SFastQueue(Self).Bytes);
    if SFastQueue(Self).OffsetLeft = SFastQueue(Self).Total then
    begin
      SFastQueue(Self).OffsetLeft := 0;
      SFastQueue(Self).PageLeft.SplitLeft(False).Free();
      SFastQueue(Self).PageLeft := SFastQueue(Self).PageLeft.NextRight();
    end;
  end
  else
    SFastQueue(Self).Size := 0;
end;

function TFastQueue.PopTail(): Pointer;
begin
  Assert((Self <> nil) and (SFastQueue(Self).Size >= 0));
  Result := SFastQueue(Self).PageRight[SFastQueue(Self).OffsetRight];
  Dec(SFastQueue(Self).Size);
  if SFastQueue(Self).Size > 0 then
  begin
    Dec(SFastQueue(Self).OffsetRight, SFastQueue(Self).Bytes);
    if SFastQueue(Self).OffsetRight < 0 then
    begin
      SFastQueue(Self).OffsetRight := SFastQueue(Self).Total - SFastQueue(Self).Bytes;
      SFastQueue(Self).PageRight.SplitRight(False).Free();
      SFastQueue(Self).PageRight := SFastQueue(Self).PageRight.NextLeft();
    end;
  end
  else
    SFastQueue(Self).Size := 0;
end;

procedure TFastQueue.RemoveHead(const Count: Integer);
begin
  Assert((Self <> nil) and (Count >= 0));
  Dec(SFastQueue(Self).Size, Count);
  if SFastQueue(Self).Size > 0 then
  begin
    Inc(SFastQueue(Self).OffsetLeft, Count * SFastQueue(Self).Bytes);
    while SFastQueue(Self).OffsetLeft >= SFastQueue(Self).Total do
    begin
      SFastQueue(Self).PageLeft.SplitLeft(False).Free();
      SFastQueue(Self).PageLeft := SFastQueue(Self).PageLeft.NextRight();
      Dec(SFastQueue(Self).OffsetLeft, SFastQueue(Self).Total);
    end;
  end
  else
    SFastQueue(Self).Size := 0;
end;

procedure TFastQueue.RemoveTail(const Count: Integer);
begin
  Assert((Self <> nil) and (Count >= 0));
  Dec(SFastQueue(Self).Size, Count);
  if SFastQueue(Self).Size > 0 then
  begin
    Dec(SFastQueue(Self).OffsetRight, Count * SFastQueue(Self).Bytes);
    while SFastQueue(Self).OffsetRight < 0 do
    begin
      SFastQueue(Self).PageRight.SplitRight(False).Free();
      SFastQueue(Self).PageRight := SFastQueue(Self).PageRight.NextLeft();
      Inc(SFastQueue(Self).OffsetRight, SFastQueue(Self).Total);
    end;
  end
  else
    SFastQueue(Self).Size := 0;
end;

initialization
  Assert((SizeOf(Integer) = 4) and ((SizeOf(Pointer) = 4) or (SizeOf(Pointer) = 8)));

end.

