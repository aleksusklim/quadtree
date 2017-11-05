program quadtree;

{$apptype console}

uses
  UFastList,
  ULinkList,
  USparseMatrix,
  UFastStack,
  UFastTree,
//  UFastQueue,
//  UStackArray,
//  UQuad,
  UFastMem,
//  Classes,
  Windows;

{
function iter(x, y: Integer; value, data: Pointer): Pointer;
begin
  Result := nil;
end;
}
//var
//  u: TSparseMatrix;
//  s: TMyStColl;
//  i: Integer;
{
function print(Container: TStContainer; Data: Pointer; OtherData: Pointer): Boolean;
begin
  Writeln(Integer(Data));
  Result := True;
end;
 }

var
  s: string;
{
var
  que: TFastQueue;
  i: Integer;
  st: TPtrStack;
  a: NativeInt;
  t: TStack;

function bench0(cnt: Integer): Integer;
var
  s: TStack;
  i: Integer;
begin
  Result := GetTickCount();
  s := TStack.Create();
  s.Push(nil);
  for i := 0 to cnt * 2 do
    s.Push(Pointer(i + Integer(s.Peek)));
  for i := 0 to cnt do
    s.Push(Pointer(Integer(s.Peek) - Integer(s.Peek)));
  for i := 0 to cnt * 4 do
    s.Push(Pointer(i + Integer(s.Peek)));
  for i := 0 to cnt * 2 do
    s.Push(Pointer(Integer(s.Peek) - Integer(s.Peek)));
  s.Free();
  Result := GetTickCount() - Result;
end;

function bench1(cnt: Integer): Integer;
var
  s: TCopyStack;
  i: Integer;
  v, w: Integer;
begin
  Result := GetTickCount();
  s := TCopyStack.Create(4);
  v := 0;
  s.Push(v);
  for i := 0 to cnt * 2 do
  begin
    s.Peek(v);
    Inc(v, i);
    s.Push(v);
  end;
  for i := 0 to cnt do
  begin
    s.Peek(v);
    s.Peek(w);
    Dec(v, w);
    s.Push(v);
  end;
  for i := 0 to cnt * 4 do
  begin
    s.Peek(v);
    Inc(v, i);
    s.Push(v);
  end;
  for i := 0 to cnt * 2 do
  begin
    s.Peek(v);
    s.Peek(w);
    Dec(v, w);
    s.Push(v);
  end;
  s.Free();
  Result := GetTickCount() - Result;
end;

function bench2(cnt: Integer): Integer;
var
  s: TPtrStack;
  i: Integer;
begin
  Result := GetTickCount();
  s := TPtrStack.Create();
  s.Push(nil);
  for i := 0 to cnt * 2 do
    s.Push(Pointer(i + Integer(s.Peek)));
  for i := 0 to cnt do
    s.Push(Pointer(Integer(s.Peek) - Integer(s.Peek)));
  for i := 0 to cnt * 4 do
    s.Push(Pointer(i + Integer(s.Peek)));
  for i := 0 to cnt * 2 do
    s.Push(Pointer(Integer(s.Peek) - Integer(s.Peek)));
  s.Free();
  Result := GetTickCount() - Result;
end;

var
  b: Integer;

}

  ar: array[0..1000000] of Pointer;
  ac: Integer;

function bench3(My: Boolean): Integer;
var
  i, j, k: Integer;
  m: TFastMem1;
  p: Pointer;
begin
  m := nil;
  ac := 0;
  Result := GetTickCount();
  if My then
    m := TFastMem1.Create(4096);
  for i := 0 to 10000 do
  begin
    for k := 0 to Random(i) do
    begin
      if My then
        p := m.Alloc(4)
      else
        GetMem(p, 4);
      ar[ac] := p;
      Inc(ac);
    end;
    for k := 0 to Random(i) do
      if ac > 0 then
      begin
        j := Random(ac);
        p := ar[j];
        ar[j] := ar[ac - 1];
        Dec(ac);
        if My then
          m.Release(p)
        else
          FreeMem(p);
      end;
  end;
  if My then
    m.Free();
  Result := Integer(GetTickCount()) - Result;
end;

//var
//  sa: TPtrArray;
//  i, j, k: Integer;
//  t: TStackArrayIterator;
//  m: TFastMem;
//  p: Pointer;

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

var
  list: TXorList;
  p: Pointer;
  i: Integer;
  t: Cardinal;

function comp(const Node: TSplayNode; const Key: Pointer): Integer;
begin
  Result := {%H-}Integer(Key) - PInteger(Node.Data())^;
end;

procedure print(tree: TSplayTree);
var
  t: Text;
  n: TSplayNode;
  i: Integer;
begin
  Assign(t, 'gml.txt');
  Rewrite(t);
  n := tree.Min();
  i := 0;
  while n <> nil do
  begin
    PInteger(n.Data(8))^ := i;
    n := n.Next();
    Inc(i);
  end;
  Writeln(t, PInteger(TSplayNode(SSplayTree(tree).Root).Data(8))^);
  Writeln(t, PInteger(TSplayNode(tree.Min()).Data(8))^);
  Writeln(t, -1);
  n := tree.Min();
  while n <> nil do
  begin
    Writeln(t, PInteger(n.Data(8))^);
    Writeln(t, PInteger(n.Data(0))^);
    Writeln(t, PInteger(n.Data(4))^);
    Writeln(t, -1);
    if SSplayNode(n).Left = nil then
      Writeln(t, -1)
    else
      Writeln(t, PInteger(TSplayNode(SSplayNode(n).Left).Data(8))^);
    if SSplayNode(n).Right = nil then
      Writeln(t, -1)
    else
      Writeln(t, PInteger(TSplayNode(SSplayNode(n).Right).Data(8))^);
    Writeln(t, -1);
    if SSplayNode(n).Succ = nil then
      Writeln(t, -1)
    else
      Writeln(t, PInteger(TSplayNode(SSplayNode(n).Succ).Data(8))^);

    n := n.Next();
  end;
  Close(t);
end;

procedure gml();
var
  tree: TSplayTree;
  i, key: Integer;
  node, mem: TSplayNode;
begin
  mem := TSplayNode.Create(12);
  tree := TSplayTree.Create(comp);
  for i := 0 to 15 do
  begin
    key := Random(100) * 16 + i;
    node := tree.Add({%H-}Pointer(key), mem);
    if node = nil then
    begin
      node := mem;
      PInteger(node.Data())^ := key;
      PInteger(node.Data(4))^ := random($ffffff);
      mem := TSplayNode.Create(12);
    end;
  end;
  while true do
  begin
    print(tree);
    Readln(key);
    node := tree.Del({%H-}Pointer(key));
    if node <> nil then
      node.Free()
    else
    begin
//      Writeln(Integer(tree.Get(Pointer(key))));
      node := tree.Add({%H-}Pointer(key), mem);
      if node = nil then
      begin
        node := mem;
        mem := TSplayNode.Create(12);
      end;
      PInteger(node.Data())^ := key;
      PInteger(node.Data(4))^ := random($ffffff);
    end;
  end;
end;

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

function myloop(X, Y: Integer; const Value, {%H-}Data: Pointer): Pointer;
begin
  Writeln(x, ',', y, '=', PInteger(Value)^);
  if (x = 10) and (y = 10) then
    Result := Pointer(1)
  else
    Result := nil
end;

procedure TestMat();
var
  Mat: TSparseMatrix;
  x, y: Integer;
  r: PInteger;
begin
  Mat := TSparseMatrix.Create();
  while True do
  begin
    Readln(x, y);
    r := Mat.Get(x, y);
    if r <> nil then
    begin
      Writeln(r^);
      r := Mat.Del(x, y);
      Writeln(r^);
      Continue;
    end
    else
    begin
      Writeln('--');
      r := Mat.Del(x, y);
      Writeln({%H-}Integer(r));
    end;
    r := Mat.Put(x, y);
    r^ := x * y;
    Mat.Loop(-20, -20, 20, 20, myloop, nil);
  end;
  Mat.Free();
end;

begin
  Writeln(bench3(ParamStr(1) = '1'));
  Exit;
  TestMat();
  Randomize();
  TrySplayTree();
  TryLinkList();
  gml();
  //TryLinkList();
  Exit;
  t := GetTickCount();
  //TestXorList(1024,105600);
  WriteLn(GetTickCount() - t);
  ReadLn(s);
  Exit;
  list := TXorList.Create(16);
  TXorList.FreeAndNil(list);
  i := (100);
  list := TXorList.Create(16);
  list := TXorList.Init(list);
  TXorList.SizeFor(16);
//  p := list.Data(i);
  p := list[i];
  list.Next(nil);
  list.Connect(nil);
  list.Remove(nil, False);
  TXorList.FreeAndNil(list);
  list.Free();
  Writeln(P - PChar(0));


 // Randomize();
//  bench3(True);
//  while true do WriteLn(bench3(True));
 // Writeln(bench3(True));
//  Writeln(bench3(True));
  ReadLn(s);
  Exit;                    {
  Writeln(bench3(True), #9, bench3(False));
//  Writeln(bench3(False), #9, bench3(True));
  Readln(s);
  ac := 0;
  m := TFastMem.Create(4, 25);
  for i := 0 to 500 do
  begin
    Writeln('+');
    for k := 0 to Random(i) do
    begin
      p := m.Alloc();
      Writeln(Integer(p));
      ar[ac] := p;
      Inc(ac);
    end;
    Writeln('-');
    for k := 0 to Random(i) do
      if ac > 0 then
      begin
        j := Random(ac);
        p := ar[j];
        ar[j] := ar[ac - 1];
        Dec(ac);
        Writeln(#9, Integer(p));
        m.Release(p);
      end;
  end;
  m.Clear(True);
  Readln(s);
   {
  sa := TStackArray.Create(4, 5);

  for i := 0 to 100 do
    PInteger(sa.Push())^ := i;

  sa.Resize(200);
  for i := 2 to 100 do
    sa.Pop();

  Writeln(PInteger(sa.Peek())^);
  Readln(s);
  for i := 0 to 100 do
    PInteger(sa.Push())^ := i;
  for i := 100 downto 0 do
    Writeln(PInteger(sa.Index(i))^);
  for i := 0 to 50 do
    Writeln(PInteger(sa.Index(i))^);
  t := sa.Iterator(40);

  for i := 40 downto 10 do
    Writeln(PInteger(sa.Move(i, t))^);

  sa.Free();

  Readln(s);
{
  i := 2;
  while True do
  begin
    Writeln(i, #9, bench1(i), #9, bench2(i));
    i := i * 2;
  end;

  t := TStack.Create();
  t.Push(nil);
  a := -10;
  Writeln(SizeOf(st));
  st := TPtrStack.Create(49);
  Writeln(st.empty);
  for i := 1 to 50 do
    st.Push(Pointer(i));
  st.Remove(10);
  for i := 1 to 50 do
    Writeln(Integer(st.Pop()), #9, st.empty);

//st.
//st.

  que := TFastQueue.Create(10, 4);

  for i := 1 to 128 do
  begin
    PInteger(que.IncHead())^ := i;
    PInteger(que.IncHead())^ := -i;
    Writeln(PInteger(que.GetTail())^);
    que.DecTail();
  end;
  for i := 1 to 32 do
  begin
    Writeln(PInteger(que.GetHead())^);
    que.DecHead(2);
  end;

  que.Free();
  Readln(s);




{
  s := TMyStColl.Create(5);
  s[1] := Pointer(1);
  s[50] := Pointer(10);
  s[900] := Pointer(9);
  s.AtFree(50);
  s.Iterate(print, True, nil);
  Writeln(s.Efficiency);
  Writeln(Integer(s[50]));
  Writeln(Integer(s[4]));
  Writeln(Integer(s[5]));
}

{
  u := TSparseMatrix.Create();
  u.Put(0, 0, u);
  u.Get(0, 0);
  u.Num();
  u.Del(0, 0);
  u.Loop(iter, nil);
  u.Free();
}
end.

