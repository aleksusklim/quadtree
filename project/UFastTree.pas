unit UFastTree; // License: WTFPL, public domain.

interface // UFastTree v1.0 by Kly_Men_COmpany!

{(*}{$UNDEF INL}{$IFDEF FPC}{$DEFINE INL}type Native = PtrInt;{$ELSE}{$IF CompilerVersion > 18.0}{$DEFINE INL}{$IFEND}{$IF SizeOf(Pointer)=4}type Native = Integer;{$IFEND}{$IF SizeOf(Pointer)=8}type Native = Int64;{$IFEND}{$ENDIF}{*)}

type
  TSplayNode = class;

  TSplayCompare = function(const Node: TSplayNode; const Key: Pointer): Integer;

  TSplayNode = class
    class procedure FreeAndNil(var SplayNode: TSplayNode); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(const Bytes: Integer): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Bytes: Integer): TSplayNode; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    function Data(const Offset: Integer = 0): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function Next(): TSplayNode; {$IFDEF INL}inline;{$ENDIF}
  protected
    function RightChild(): TSplayNode; {$IFDEF INL}inline;{$ENDIF}
    function LeftChild(): TSplayNode; {$IFDEF INL}inline;{$ENDIF}
  end;

  PSplayNode = ^TSplayNode;

  RSplayNode = record // SizeOf = 3*N
    Succ, Left, Right: TSplayNode;
  end;

  SSplayNode = ^RSplayNode;

  TSplayTree = class
    class procedure FreeAndNil(var SplayTree: TSplayTree); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(): Integer; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer; const Compare: TSplayCompare): TSplayTree; {$IFDEF INL}inline;{$ENDIF}
    class function Create(const Compare: TSplayCompare): TSplayTree; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    function Empty(): Boolean; {$IFDEF INL}inline;{$ENDIF}
    function Get(const Key: Pointer): TSplayNode; {no inline}
    function Add(const Key: Pointer; const Memory: TSplayNode = nil): TSplayNode; {no inline}
    function Del(const Key: Pointer): TSplayNode; {no inline}
    function Min(): TSplayNode; {$IFDEF INL}inline;{$ENDIF}
  protected
    function Top(): TSplayNode; {$IFDEF INL}inline;{$ENDIF}
  private
    function Find(out Found: TSplayNode; const Key: Pointer; out Code: Pointer): Integer; {$IFDEF INL}inline;{$ENDIF}
    procedure Splay(const Node: TSplayNode; Code: Pointer); {$IFDEF INL}inline;{$ENDIF}
  end;

  PSplayTree = ^TSplayTree;

  RSplayTree = record // SizeOf = 3*N
    Root, Head: TSplayNode;
    Compare: TSplayCompare;
  end;

  SSplayTree = ^RSplayTree;

implementation

// TSplayNode //

class procedure TSplayNode.FreeAndNil(var SplayNode: TSplayNode);
begin
  SplayNode.Free();
  SplayNode := nil;
end;

class function TSplayNode.SizeFor(const Bytes: Integer): Integer;
begin
  Assert((Bytes >= 0) and (Bytes <= $7FFFFFE0));
  Result := SizeOf(RSplayNode) + Bytes;
end;

class function TSplayNode.Create(const Bytes: Integer): TSplayNode;
begin
  GetMem(Pointer(Result), Self.SizeFor(Bytes));
end;

procedure TSplayNode.Free();
begin
  if Self <> nil then
    FreeMem(Pointer(Self));
end;

function TSplayNode.Data(const Offset: Integer = 0): Pointer;
begin
  Assert((Self <> nil) and (Offset >= 0));
  Result := {%H-}Pointer({%H-}Native({%H-}Pointer(Self)) + SizeOf(RSplayNode) + Offset);
end;

function TSplayNode.Next(): TSplayNode;
begin
  Assert(Self <> nil);
  Result := SSplayNode(Self).Succ;
end;

function TSplayNode.RightChild(): TSplayNode;
begin
  Assert(Self <> nil);
  Result := SSplayNode(Self).Right;
end;

function TSplayNode.LeftChild(): TSplayNode;
begin
  Assert(Self <> nil);
  Result := SSplayNode(Self).Left;
end;

// TSplayTree //

class procedure TSplayTree.FreeAndNil(var SplayTree: TSplayTree);
begin
  SplayTree.Free();
  SplayTree := nil;
end;

class function TSplayTree.SizeFor(): Integer;
begin
  Result := SizeOf(RSplayTree);
end;

class function TSplayTree.Init(const Memory: Pointer; const Compare: TSplayCompare): TSplayTree;
begin
  Assert((Memory <> nil) and (({%H-}Native(Memory) and (SizeOf(Pointer) - 1)) = 0));
  SSplayTree(Memory).Head := nil;
  SSplayTree(Memory).Root := nil;
  SSplayTree(Memory).Compare := Compare;
  Result := Memory;
end;

class function TSplayTree.Create(const Compare: TSplayCompare): TSplayTree;
begin
  GetMem(Pointer(Result), Self.SizeFor());
  Self.Init(Result, Compare);
end;

procedure TSplayTree.Free();
begin
  if Self <> nil then
    FreeMem(Pointer(Self));
end;

function TSplayTree.Empty(): Boolean;
begin
  Assert(Self <> nil);
  Result := (SSplayTree(Self).Root = nil);
end;

function TSplayTree.Get(const Key: Pointer): TSplayNode;
var
  Code: Pointer;
  Value: Integer;
begin
  Assert(Self <> nil);
  Value := Self.Find(Result, Key, Code);
  if Value <> 0 then
  begin
    Self.Splay(Result, Code);
    SSplayTree(Self).Root := Result;
    if Value > 0 then
      Result := SSplayNode(Result).Succ;
  end
  else if Result <> nil then
  begin
    Self.Splay(Result, Code);
    SSplayTree(Self).Root := Result;
  end;
end;

function TSplayTree.Add(const Key: Pointer; const Memory: TSplayNode = nil): TSplayNode; {no inline}
var
  Value: Integer;
  Node: TSplayNode;
  Code, Temp: Pointer;
begin
  Assert(Self <> nil);
  Value := Self.Find(Result, Key, Code);
  if Result = nil then
  begin
    if Memory <> nil then
    begin
      SSplayNode(Memory).Left := nil;
      SSplayNode(Memory).Right := nil;
      SSplayTree(Self).Root := Memory;
      SSplayTree(Self).Head := Memory;
      SSplayNode(Memory).Succ := nil;
    end;
  end
  else if Value = 0 then
  begin
    Self.Splay(Result, Code);
    SSplayTree(Self).Root := Result;
  end
  else
  begin
    if Memory = nil then
    begin
      Self.Splay(Result, Code);
      SSplayTree(Self).Root := Result;
      Result := nil;
    end
    else
    begin
      if Value < 0 then
      begin
        SSplayNode(Memory).Succ := Result;
        SSplayNode(Result).Left := Code;
        Code := {%H-}Pointer({%H-}Native(Pointer(Result)) or (({%H-}Native(Code) and 1) shl 1));
        if SSplayTree(Self).Head = Result then
          SSplayTree(Self).Head := Memory
        else
        begin
          Node := Result;
          Temp := Code;
          repeat
            if ({%H-}Native(Temp) and 1) <> 0 then
              Temp := SSplayNode(Node).Right
            else
              Temp := SSplayNode(Node).Left;
            Node := {%H-}Pointer({%H-}Native(Temp) and not 3);
          until SSplayNode(Node).Succ = Result;
          SSplayNode(Node).Succ := Memory;
        end;
      end
      else
      begin
        SSplayNode(Memory).Succ := SSplayNode(Result).Succ;
        SSplayNode(Result).Right := Code;
        Code := {%H-}Pointer({%H-}Native(Pointer(Result)) or ((({%H-}Native(Code) and 1) shl 1) xor 3));
        SSplayNode(Result).Succ := Memory;
      end;
      SSplayNode(Memory).Left := nil;
      SSplayNode(Memory).Right := nil;
      Self.Splay(Memory, Code);
      SSplayTree(Self).Root := Memory;
      Result := nil;
    end;
  end;
end;

function TSplayTree.Del(const Key: Pointer): TSplayNode;
var
  Node, Par: TSplayNode;
  Code, Temp: Pointer;
begin
  Assert(Self <> nil);
  if Self.Find(Result, Key, Code) = 0 then
  begin
    if Result <> nil then
    begin
      Par := {%H-}Pointer({%H-}Native(Code) and not 3);
      if SSplayTree(Self).Head = Result then
        SSplayTree(Self).Head := SSplayNode(Result).Succ
      else
      begin
        Node := SSplayNode(Result).Left;
        if Node <> nil then
        begin
          while SSplayNode(Node).Right <> nil do
            Node := SSplayNode(Node).Right;
          SSplayNode(Node).Succ := SSplayNode(Result).Succ;
        end
        else
        begin
          Node := Par;
          if ({%H-}Native(Code) and 1) <> 0 then
            SSplayNode(Node).Succ := SSplayNode(Result).Succ
          else
          begin
            Temp := Code;
            repeat
              if ({%H-}Native(Temp) and 1) <> 0 then
                Temp := SSplayNode(Node).Right
              else
                Temp := SSplayNode(Node).Left;
              Node := {%H-}Pointer({%H-}Native(Temp) and not 3);
            until SSplayNode(Node).Succ = Result;
            SSplayNode(Node).Succ := SSplayNode(Result).Succ;
          end;
        end;
      end;
      Node := nil;
      if SSplayNode(Result).Left <> nil then
        if SSplayNode(Result).Right <> nil then
        begin
          Self.Splay(Result, Code);
          Par := SSplayNode(Result).Left;
          Code := Pointer(1);
          while SSplayNode(Par).Right <> nil do
          begin
            Node := SSplayNode(Par).Right;
            SSplayNode(Par).Right := Code;
            Code := {%H-}Pointer({%H-}Native(Pointer(Par)) or 1);
            Par := Node;
          end;
          Self.Splay(Par, Code);
          SSplayNode(Par).Right := SSplayNode(Result).Right;
          SSplayTree(Self).Root := Par;
          Exit;
        end
        else
          Node := SSplayNode(Result).Left
      else if SSplayNode(Result).Right <> nil then
        Node := SSplayNode(Result).Right;
      if Par <> nil then
      begin
        if ({%H-}Native(Code) and 1) <> 0 then
        begin
          Code := SSplayNode(Par).Right;
          SSplayNode(Par).Right := Node;
        end
        else
        begin
          Code := SSplayNode(Par).Left;
          SSplayNode(Par).Left := Node;
        end;
        Self.Splay(Par, Code);
        SSplayTree(Self).Root := Par;
      end
      else
        SSplayTree(Self).Root := Node;
    end;
  end
  else
  begin
    Self.Splay(Result, Code);
    SSplayTree(Self).Root := Result;
    Result := nil;
  end;
end;

function TSplayTree.Min(): TSplayNode;
begin
  Assert(Self <> nil);
  Result := SSplayTree(Self).Head;
end;

function TSplayTree.Top(): TSplayNode;
begin
  Assert(Self <> nil);
  Result := SSplayTree(Self).Root;
end;

function TSplayTree.Find(out Found: TSplayNode; const Key: Pointer; out Code: Pointer): Integer;
var
  Target: TSplayNode;
begin
  Assert(Self <> nil);
  Code := nil;
  Target := nil;
  Found := SSplayTree(Self).Root;
  if Found = nil then
    Result := 0
  else
    repeat
      Result := SSplayTree(Self).Compare(Found, Key);
      if Result = 0 then
        Break;
      if Result < 0 then
      begin
        if SSplayNode(Found).Left <> nil then
        begin
          Target := SSplayNode(Found).Left;
          SSplayNode(Found).Left := Code;
          Code := {%H-}Pointer({%H-}Native(Pointer(Found)) or (({%H-}Native(Code) and 1) shl 1));
        end
        else
          Break;
      end
      else
      begin
        if SSplayNode(Found).Right <> nil then
        begin
          Target := SSplayNode(Found).Right;
          SSplayNode(Found).Right := Code;
          Code := {%H-}Pointer({%H-}Native(Pointer(Found)) or ((({%H-}Native(Code) and 1) shl 1) xor 3));
        end
        else
          Break
      end;
      Found := Target;
    until False;
end;

procedure TSplayTree.Splay(const Node: TSplayNode; Code: Pointer);
var
  Par, Gran: TSplayNode;
begin
  Assert((Self <> nil) and (Node <> nil));
  Par := {%H-}Pointer({%H-}Native(Code) and not 3);
  while (Par <> nil) do
  begin
    case ({%H-}Native(Code) and 3) of
      0:
        begin
          Gran := {%H-}Pointer({%H-}Native(Pointer(SSplayNode(Par).Left)) and not 3);
          SSplayNode(Par).Left := Node;
          if Gran <> nil then
          begin
            Code := SSplayNode(Gran).Left;
            SSplayNode(Gran).Left := Par;
            SSplayNode(Par).Left := SSplayNode(Node).Right;
            SSplayNode(Gran).Left := SSplayNode(Par).Right;
            SSplayNode(Node).Right := Par;
            SSplayNode(Par).Right := Gran;
            Par := {%H-}Pointer({%H-}Native(Code) and not 3);
            Continue;
          end;
        end;
      1:
        begin
          Gran := {%H-}Pointer({%H-}Native(Pointer(SSplayNode(Par).Right)) and not 3);
          SSplayNode(Par).Right := Node;
          if Gran <> nil then
          begin
            Code := SSplayNode(Gran).Right;
            SSplayNode(Gran).Right := Par;
            SSplayNode(Par).Right := SSplayNode(Node).Left;
            SSplayNode(Gran).Right := SSplayNode(Par).Left;
            SSplayNode(Node).Left := Par;
            SSplayNode(Par).Left := Gran;
            Par := {%H-}Pointer({%H-}Native(Code) and not 3);
            Continue;
          end;
        end;
      2:
        begin
          Gran := {%H-}Pointer({%H-}Native(Pointer(SSplayNode(Par).Left)) and not 3);
          SSplayNode(Par).Left := Node;
          if Gran <> nil then
          begin
            Code := SSplayNode(Gran).Right;
            SSplayNode(Gran).Right := Par;
            SSplayNode(Gran).Right := SSplayNode(Node).Left;
            SSplayNode(Par).Left := SSplayNode(Node).Right;
            SSplayNode(Node).Left := Gran;
            SSplayNode(Node).Right := Par;
            Par := {%H-}Pointer({%H-}Native(Code) and not 3);
            Continue;
          end;
        end;
      3:
        begin
          Gran := {%H-}Pointer({%H-}Native(Pointer(SSplayNode(Par).Right)) and not 3);
          SSplayNode(Par).Right := Node;
          if Gran <> nil then
          begin
            Code := SSplayNode(Gran).Left;
            SSplayNode(Gran).Left := Par;
            SSplayNode(Gran).Left := SSplayNode(Node).Right;
            SSplayNode(Par).Right := SSplayNode(Node).Left;
            SSplayNode(Node).Right := Gran;
            SSplayNode(Node).Left := Par;
            Par := {%H-}Pointer({%H-}Native(Code) and not 3);
            Continue;
          end;
        end;
    end;
    if ({%H-}Native(Code) and 1) <> 0 then
    begin
      SSplayNode(Par).Right := SSplayNode(Node).Left;
      SSplayNode(Node).Left := Par;
    end
    else
    begin
      SSplayNode(Par).Left := SSplayNode(Node).Right;
      SSplayNode(Node).Right := Par;
    end;
    Break;
  end;
end;

// Tests //

type
  DSplayTree = class(TSplayTree);

  DSplayNode = class(TSplayNode);

function DSplayCompare(const Node: TSplayNode; const Key: Pointer): Integer;
begin
  Result := {%H-}Integer(Key) - PInteger(Node.Data())^;
end;

procedure TrySplayTree();
var
  Tree: TSplayTree;
  Node: TSplayNode;
begin
  TSplayTree.SizeFor();
  Tree := TSplayTree.Create(DSplayCompare);
  TSplayTree.Init(Tree, DSplayCompare);
  Tree.Empty();
  DSplayNode.SizeFor(8);
  Node := DSplayNode(DSplayNode.Create(8));
  PInteger(Node.Data(0))^ := 10;
  Node.Next();
  DSplayNode(Node).RightChild();
  DSplayNode(Node).LeftChild();
  Tree.Add(Pointer(10), Node);
  Tree.Get(Pointer(10));
  Tree.Del(Pointer(10));
  Tree.Min();
  DSplayTree(Tree).Top();
  TSplayTree.FreeAndNil(Tree);
  Tree.Free();
  Node.FreeAndNil(Node);
  Node.Free();
end;

end.

