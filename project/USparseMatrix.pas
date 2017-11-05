unit USparseMatrix; // License: WTFPL, public domain.

interface // USparseMatrix v1.0 by Kly_Men_COmpany!

uses
  UFastTree;                                                                                                                          

{(*}{$UNDEF INL}{$IFDEF FPC}{$DEFINE INL}type Native=PtrInt;{$ELSE}{$IF CompilerVersion > 18.0}{$DEFINE INL}{$IFEND}{$IF SizeOf(Pointer)=4}type Native=Integer;{$IFEND}{$IF SizeOf(Pointer)=8}type Native=Int64;{$IFEND}{$ENDIF}type PNative=^Native;{*)}

type
  TSparseMatrixLoop = function(X, Y: Native; const Value, Data: Pointer): Pointer;

type
  TSparseMatrix = class
    class procedure FreeAndNil(var SparseMatrix: TSparseMatrix); {$IFDEF INL}inline;{$ENDIF}
    class function SizeFor(): Native; {$IFDEF INL}inline;{$ENDIF}
    class function Init(const Memory: Pointer): TSparseMatrix; {$IFDEF INL}inline;{$ENDIF}
    class function Create(): TSparseMatrix; {$IFDEF INL}inline;{$ENDIF}
    procedure Free(); {$IFDEF INL}inline;{$ENDIF}
    function Put(const X, Y: Native): Pointer; {no inline}
    function Get(const X, Y: Native): Pointer; {$IFDEF INL}inline;{$ENDIF}
    function Del(const X, Y: Native): Pointer; {no inline}
    function Loop(const X1, Y1, X2, Y2: Native; Callback: TSparseMatrixLoop; const Data: Pointer): Pointer; {$IFDEF INL}inline;{$ENDIF}
  end;

  PSparseMatrix = ^TSparseMatrix;

  RSparseMatrix = record // SizeOf = ?
    TreeX: RSplayTree;
    CacheX, CacheY: TSplayNode;
  end;

  SSparseMatrix = ^RSparseMatrix;

  RDataX = record
    KeyX: Native;
    TreeY: RSplayTree;
  end;

  SDataX = ^RDataX;

  RDataY = record
    KeyY, Value: Native;
  end;

  SDataY = ^RDataY;

implementation

function SparseMatrixTreeCompare(const Node: TSplayNode; const Key: Pointer): Native;
begin
  Result := {%H-}Native(Key) - PNative(Node.Data())^;
end;

class procedure TSparseMatrix.FreeAndNil(var SparseMatrix: TSparseMatrix);
begin
  SparseMatrix.Free();
  SparseMatrix := nil;
end;

class function TSparseMatrix.SizeFor(): Native;
begin
  Result := SizeOf(RSparseMatrix);
end;

class function TSparseMatrix.Init(const Memory: Pointer): TSparseMatrix;
begin
  TSplayTree.Init(@SSparseMatrix(Memory).TreeX, SparseMatrixTreeCompare);
  SSparseMatrix(Memory).CacheX := nil;
  SSparseMatrix(Memory).CacheY := nil;
  Result := Memory;
end;

class function TSparseMatrix.Create(): TSparseMatrix;
begin
  GetMem(Pointer(Result), Self.SizeFor());
  Self.Init(Result);
end;

procedure TSparseMatrix.Free();
begin
  if Self <> nil then
    FreeMem(Pointer(Self));
end;

function TSparseMatrix.Put(const X, Y: Native): Pointer;
var
  Node: TSplayNode;
  Half: SDataX;
  Full: SDataY;
begin
  Assert(Self <> nil);
  if SSparseMatrix(Self).CacheX = nil then
    SSparseMatrix(Self).CacheX := TSplayNode.Create(SizeOf(RDataX));
  Node := TSplayTree(@SSparseMatrix(Self).TreeX).Add({%H-}Pointer(X), SSparseMatrix(Self).CacheX);
  if Node = nil then
  begin
    Half := SSparseMatrix(Self).CacheX.Data();
    Half.KeyX := X;
    TSplayTree.Init(@Half.TreeY, SparseMatrixTreeCompare);
    SSparseMatrix(Self).CacheX := nil;
  end
  else
    Half := Node.Data();
  if SSparseMatrix(Self).CacheY = nil then
    SSparseMatrix(Self).CacheY := TSplayNode.Create(SizeOf(RDataY));
  Node := TSplayTree(@Half.TreeY).Add({%H-}Pointer(Y), SSparseMatrix(Self).CacheY);
  if Node = nil then
  begin
    Full := SSparseMatrix(Self).CacheY.Data();
    Full.KeyY := Y;
    SSparseMatrix(Self).CacheY := nil;
  end
  else
    Full := Node.Data();
  Result := @Full.Value;
end;

function TSparseMatrix.Get(const X, Y: Native): Pointer;
var
  Half: SDataX;
  Node: TSplayNode;
begin
  Assert(Self <> nil);
  Result := nil;
  Node := TSplayTree(@SSparseMatrix(Self).TreeX).Add({%H-}Pointer(X));
  if Node <> nil then
  begin
    Half := Node.Data();
    Node := TSplayTree(@Half.TreeY).Add({%H-}Pointer(Y));
    if Node <> nil then
      Result := @SDataY(Node.Data()).Value;
  end;
end;

function TSparseMatrix.Del(const X, Y: Native): Pointer;
var
  Half: SDataX;
  Node: TSplayNode;
begin
  Assert(Self <> nil);
  Result := nil;
  Node := TSplayTree(@SSparseMatrix(Self).TreeX).Add({%H-}Pointer(X));
  if Node <> nil then
  begin
    Half := Node.Data();
    Node := TSplayTree(@Half.TreeY).Del({%H-}Pointer(Y));
    if Node <> nil then
    begin
      TSplayNode.FreeAndNil(SSparseMatrix(Self).CacheY);
      SSparseMatrix(Self).CacheY := Node;
      Result := @SDataY(Node.Data()).Value;
      if TSplayTree(@Half.TreeY).Empty then
      begin
        TSplayNode.FreeAndNil(SSparseMatrix(Self).CacheX);
        SSparseMatrix(Self).CacheX := TSplayTree(@SSparseMatrix(Self).TreeX).Del({%H-}Pointer(X));
      end;
    end;
  end;
end;

function TSparseMatrix.Loop(const X1, Y1, X2, Y2: Native; Callback: TSparseMatrixLoop; const Data: Pointer): Pointer;
var
  Half: SDataX;
  Full: SDataY;
  NodeX, NodeY: TSplayNode;
begin
  Assert(Self <> nil);
  Result := nil;
  NodeX := TSplayTree(@SSparseMatrix(Self).TreeX).Get({%H-}Pointer(X1));
  while NodeX <> nil do
  begin
    Half := NodeX.Data();
    if Native(Half.KeyX) > X2 then
      Break;
    NodeY := TSplayTree(@Half.TreeY).Get({%H-}Pointer(Y1));
    while NodeY <> nil do
    begin
      Full := NodeY.Data();
      if Native(Full.KeyY) > Y2 then
        Break;
      Result := Callback(Native(Half.KeyX), Native(Full.KeyY), @Full.Value, Data);
      if Result <> nil then
        Break;
      NodeY := NodeY.Next();
    end;
    if Result <> nil then
      Break;
    NodeX := NodeX.Next();
  end;
end;

end.

