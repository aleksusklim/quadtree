unit UStackArray; // ��������: WTFPL, ������������ ���������.

interface // ������ ��� x86

uses
  UXorList; // ���������� ���� ��� ������ �������

type // �������� ��� �����-�������
  TStackArrayIterator = record // ��������: 12 ����
    Index: Integer; // ������� ������
    Data: Pointer; // ��������� �� ���������������� ������ �� ����� �������
    Page: TXorList; // �������� ������, ������������ ������-��������.
  end; // ������� � ��������� �������� �� ��������� - �����������, ��� ������ ������.

// ������������� ����-������ � ����������� �������� ���������.
// ������ ���������� ��������� ��� �������� ��������� � �������� ���������.
// ������������ ������ ���������, � ���������������� � ����� ������� - �������.
// ��������� ������ �� �������� � �������� ����������� �� ������.
// �������� ���� ��������, ����� ������������ �������� � �������� �������.
// ��� ������������� ������ �����-������� ����� ������������ ���������.
// ��������: 36 ���� �� ��� ������, +12 ���� �� ������ ��������.

  TStackArray = class(TObject) // ��������� ������

    // �����������, ������ ����-������:
    // �� ������ �������� ����� Blocks ��������� �������� Bytes ������;
    // ������ ����� ����������� �� �������� ������ � ������� �������;
    constructor Create(Bytes, Blocks: Integer);

    // ����������, ����������� .Free():
    destructor Destroy(); override;

    // ������� ��� �������� �����-�������:
    // ����������� ����� ����������� �������������� �������� (�� ���������);
    procedure Clear(CacheFree: Boolean = True);

    // ��������� ������� � ����� ����-�������, ���������� ��������� �� ����:
    function Push(): Pointer;

    // ������� ��������� ������� �� �����-�������, ���������� ���������� ����������.
    function Pop(): Integer;

    // ���������� ��������� �� ��������� ������� �����-�������:
    function Peek(): Pointer;

    // ���������� ��������� �� ������� �� ������������� �������:
    function Index(Index: Integer): Pointer;

    // ���������� ��������, ������������ �� �������� ������:
    function Iterator(Index: Integer): TStackArrayIterator;

    // ������� �������� � ������ �������, ���������� ��������� �� ������� �������:
    function Move(Index: Integer; var Iterator: TStackArrayIterator): Pointer;

    // �������� ������ �����-�������:
    // ��� ����������, ����� �������� ������ ������������� ��������;
    // ��� ����������, ������� ������ ��������� �� �������� �������� ����� �������:
    procedure Resize(Count: Integer);

    //
    function Exchange(Index: Integer): Integer;

    // �������� ��������� �� ������� �����-������� ���������, ��������� � ���������� nil.
    // ������ ����-������ �� �������� ������� (����� ������������, ���� ����).
    // ���� �������� ��������� �� �������, ������� ��� ��� ����� (����� Pop, Clear ��� Resize),
    //    �� �� ���������� �������, � ���������� �� ���� ������ ������,
    //    ���� ���� ����� �������� ����� ������� �� ���� �� �������.

  protected
    function PageNew(): TXorList; // �������� ����� �������� ��� ���� �� ����
    procedure PageFree(Page: TXorList); // ����� �������� � ���, � ����������� ��
  protected
    First, Last, Middle: TXorList; // ��������� �� ������, ��������� � ���������� ��������
    Offset: Integer; // �������� � ���������� �������� �� ��������� ��������
    Bytes, Blocks, Mult: Integer; // �������, ���������� � ������������
    Cache: TXorList; // ���� �������� ����
    Size: Integer; // ������ ���������� ���������, ������������ ��� ������

  public

    // ���������� ���������� ��������� � �����-�������:
    // ������ ���������� �������� ����� Count-1;
    property Count: Integer read Size;
  end;

  TPtrArray = class(TStackArray)

    // ������ ���� ����������, �� ��������� 255 �� �������� (1 ��)
    constructor Create(Blocks: Integer = 255);

    // �������� ��������� � ���� (�� �� ������, �� ������� ��� ���������):
    procedure Push(Value: Pointer);

    // ������ ��������� �� �����, ������ ��� (�� �� ��, �� ��� �� ���������):
    function Pop(): Pointer;

    // ���������� ��������� �������� � �����:
    function Peek(): Pointer;

    //
    function Index(Index: Integer): Pointer;

    //
    function Move(Index: Integer; var Iterator: TStackArrayIterator): Pointer;

    // �� ������ ����� ������������ ������� ���������.
    // ������������ �������� �����, Clear � Empty ��������.
  end;

implementation

uses
  SysUtils; // ��� Abort

// TStackArray

type
  TInfo = record // ��� ������ �������������� ������ � ����� ������ ��������
    Previous: TXorList; // ��������� �� ���������� ��������
    Index: Integer; // ���������� ����� ���� ��������
  end;

  PInfo = ^TInfo;

constructor TStackArray.Create(Bytes, Blocks: Integer);
begin
  inherited Create();
  if (Bytes < 1) or (Blocks < 1) then // ������ ������ ������������� �������
    Abort;
  if (Bytes and 3) > 0 then // �����������, ���� �� ������� �� 4
    Inc(Bytes, 4 - (Bytes and 3));
  Self.Bytes := Bytes;
  Self.Blocks := Blocks; // ���������� ��������� �� �������� ����� ��� ��������
  Self.Mult := Bytes * Blocks; // ����� ������ �������� ����� ��� ������ �����
end;

destructor TStackArray.Destroy();
begin
  Clear(True); // ������ ������������ ������
  inherited Destroy();
end;

procedure TStackArray.Clear(CacheFree: Boolean = True);
begin
  while First <> nil do // ������� ��� ��������
    TXorList.Pop(First).Free();
  if CacheFree then
  begin // ������� ����
    Cache.Free;
    Cache := nil;
  end;
  Offset := 0;
  First := nil; // �������� ��� ���������
  Last := nil;
  Middle := nil;
end;

function TStackArray.Push(): Pointer;
var
  Old: TXorList; // ��������� �� �������� �����
  Info: PInfo; // ������ � �������������� ������
begin
  Inc(Size); // ����������� ������� ���������
  Inc(Offset, Bytes); // ��������� �������
  if (Last = nil) or (Offset = Mult) then // ������ ��� �����
  begin
    Old := Last; // �������
    Last := Last.Connect(PageNew()); // ���� ����� ��������
    Offset := 0; // � � ������
    if First = nil then
    begin // �������� ������ �������
      First := Last; // ������ ��������
      Info := First.Data(Mult); // � ���-������
      Info.Previous := nil; // ��� ����������
      Info.Index := 0; // ������� ����� ��������
    end
    else
    begin // ������ � ����������� ��������
      Info := Last.Data(Mult); // ���-������
      Info.Previous := Old; // ������ ������ �� ����������
      Info.Index := PInfo(Old.Data(Mult)).Index + 1; // ����� �� ������� ������
    end;
  end;
  Result := Last.Data(Offset); // ����� ������
end;

function TStackArray.Pop(): Integer;
begin
  Dec(Size); // ��������� ������
  if Size <= 0 then
  begin
    Clear(False); // ������, ���� ��� ����
    Result := 0;
    Exit;
  end;
  Dec(Offset, Bytes); // ��������� ��������
  if Offset < 0 then
  begin // ���� �� ���� ��������
    Offset := Mult - Bytes; // �������� �� ��������� ������� ����������
    PageFree(Last); // �������, �� ���������� - ��� ���� ��������� � ����
    if Last = Middle then
      Middle := nil; // ���� ��� ���� ���������� - ��������
    Last := Last.Connect(Last.Next(nil)); // ����������� ��������� ��������
  end;
  Result := Size; // ���������� ������
end;

function TStackArray.Peek(): Pointer;
begin
  Result := Last.Data(Offset); // �������� ���������� ����� �� ������
end;

function TStackArray.Index(Index: Integer): Pointer;
var
  Page, // ����� ������� ��������
Left, Right: Integer; // ���������� �� ������ � ���������

  function Current(Page: TXorList): Integer;
  begin // ���������� ����� �������� ��������
    Result := PInfo(Page.Data(Mult)).Index;
  end;

begin
  if (Index < 0) or (Index >= Size) then
  begin // �������� ������ ��� ������
    Result := nil;
    Exit;
  end;
  Page := Index div Blocks; // ��������� ����� �������� � ������ ���������
  if (Middle = First) or (Middle = Last) then
    Middle := nil; // ���� ���������� �� ������� - ���� ����� � �����
  Left := Page - Current(First); // ������� ������� �� ������
  Right := Current(Last) - Page; // �� ���������
  if Left < Right then // �� ������ �����
  begin
    if (Middle = nil) or (Left < Current(Middle) - Page) then
      Middle := First; // ���� ��� ����������, ��� ���� �� ������ �� ����� �����
  end
  else // (������, ���������� ����� ��������� ��������� �� ��� ��������� �������)
  begin
    if (Middle = nil) or (Page - Current(Middle) >= Right) then
      Middle := Last; // ���� ��� ����������, ��� ���� �� ��������� �� ����� �����
  end;
  if Page < Current(Middle) then  // �������� �����
    while Page <> Current(Middle) do
      Middle := PInfo(Middle.Data(Mult)).Previous // ��������� �� ��������� ����������
  else
    while Page <> Current(Middle) do // �������� ������
      Middle := Middle.Next(PInfo(Middle.Data(Mult)).Previous); //����� �� ���������
  Result := Middle.Data((Index - Current(Middle) * Blocks) * Bytes); // �������� ������
end;

function TStackArray.Iterator(Index: Integer): TStackArrayIterator;
begin
  Result.Data := Self.Index(Index); // �������� �������� ���������
  if Result.Data <> nil then
  begin // ������� ������
    Result.Index := Index; // ����� �����
    Result.Page := Middle; // ���������� �������� ��� ��� �����
  end
  else
  begin // ��� ������
    Result.Index := -1; // �������� ������
    Result.Page := nil; // ��� �������� ��� ���������
  end;
end;

function TStackArray.Move(Index: Integer; var Iterator: TStackArrayIterator): Pointer;
begin
  Middle := Iterator.Page; // ���� �� ���������, ���� ����
  Result := Self.Index(Index); // ���� � � �������
  Iterator.Data := Result; // �������� ���������
  Iterator.Page := Middle; // ��������� �������� ���������
  if Result = nil then
    Iterator.Index := -1 // ������, ������ ������ �������������� ������
  else
    Iterator.Index := Index; // �����, ������ ��� ��
end;

procedure TStackArray.Resize(Count: Integer);
var
  Page, Curr: Integer; // ������ ������ � ������� �������
  Old: TXorList; // ��� ����������
  Info: PInfo; // ������ �������������� ������
begin
  if Count = Size then // ��� �� ������, ������ ������
    Exit;
  Dec(Count); // ������ ��� �� ������, � ������ ���������� ��������
  if Count < 0 then
  begin // ���� ���� � ����� - ������
    Clear(False);
    Exit;
  end;
  Page := Count div Blocks; // ����� ��������, ������� ������ ����� ���������
  if Count >= Size then // ���������� �������
  begin
    if Size = 0 then // �������������� ��������, ���� ��� ����
      Push();
    Curr := PInfo(Last.Data(Mult)).Index; // ����� ���������� ���������
    while Curr <> Page do // ����� ����� ��������
    begin
      Inc(Curr); // �������� ����� �������
      Old := Last;
      Last := Last.Connect(PageNew()); // ������ � ������� �����
      Info := Last.Data(Mult); // �������������� ������ �� �����
      Info.Previous := Old; // ��������� �� ����������
      Info.Index := Curr; // ����������� �����
    end;
  end
  else
  begin // ���������� �������
    Curr := PInfo(Last.Data(Mult)).Index; // ����� ���������� ���������
    while Curr <> Page do // ����� ������� ��������
    begin
      PageFree(Last); // �����������, �� ��� ��� ������� � ����
      if Last = Middle then // ���������� ����������, ���� �����������
        Middle := nil;
      Last := Last.Connect(Last.Next(nil)); // ��������� � ��������� � ����������
      Dec(Curr); // ��������� �����
    end;
  end;
  Offset := (Count mod Blocks) * Bytes; // ��������� �������� � ���������� ��������
  Size := Count + 1; // ����� ������, �� ���� - ���������� ��������
end;

function TStackArray.Exchange(Index: Integer): Integer;
var
  Data: Pointer;
begin
  if Index = Size - 1 then
  begin
    Result := Pop();
    Exit;
  end;
  Data := Self.Index(Index);
  if Data = nil then
  begin
    Result := Size;
    Exit;
  end;
  System.Move(Peek()^, Data^, Bytes);
  Result := Pop();
end;

function TStackArray.PageNew(): TXorList;
begin
  if Cache = nil then
  begin // ��� ����
    Result := TXorList.Create(Mult + SizeOf(TInfo)); // ������
    if Result = nil then
      Abort; // �� ������� ������
    Exit;
  end;
  Result := TXorList.Init(Cache); // ���� �� ����
  Cache := nil; // ������ �� ����
end;

procedure TStackArray.PageFree(Page: TXorList);
begin
  Cache.Free(); // ������ ����������� ���������
  Cache := Page; // ����������� ����
end;

// TPtrArray

constructor TPtrArray.Create(Blocks: Integer = 255);
begin
  inherited Create(4, Blocks); // ������ = 4
end;

procedure TPtrArray.Push(Value: Pointer);
begin
  PInteger(inherited Push())^ := Integer(Value); // ����� �����������
end;

function TPtrArray.Pop(): Pointer;
begin
  Result := Peek(); // ������ ����
  inherited Pop(); // ������� ����
end;

function TPtrArray.Peek(): Pointer;
begin
  Result := inherited Peek(); // �������� ���������
  if Result <> nil then // ���� �� �������, �� ���� �� ����
    Result := Pointer(PInteger(Result)^);
end;

function TPtrArray.Index(Index: Integer): Pointer;
begin
  Result := inherited Index(Index);
  if Result <> nil then
    Result := Pointer(PInteger(Result)^);
end;

function TPtrArray.Move(Index: Integer; var Iterator: TStackArrayIterator): Pointer;
begin
  Result := inherited Move(Index, Iterator);
  if Result <> nil then
    Result := Pointer(PInteger(Result)^);
end;

end.

