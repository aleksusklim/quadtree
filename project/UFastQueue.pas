unit UFastQueue; // ��������: WTFPL, ������������ ���������.

interface

uses
  UXorList; // ���������� ���� ��� ������ �������

type // ������ ��� x86

// ������� ������������ ������� � ����������� �������� ���������.
// ��������� ������ �� �������� � �������� ����������� �� ������.
// �������� ��� ��������, ����� ������������ �������� � �������� �������.
// ��������: 36 ���� �� ��� ������, +4 ����� �� ������ ��������.

  TFastQueue = class(TObject) // ��������� ������

    // �����������, ������ �������:
    // �� ������ �������� ����� Blocks ��������� �������� Bytes ������;
    // ������ ����� ����������� �� �������� ������ � ������� �������;
    constructor Create(Bytes, Blocks: Integer);

    // ����������, ����������� .Free():
    destructor Destroy(); override;

    // ������� ��� �������� �������:
    // ����������� ����� ����������� �������������� �������� (�� ���������);
    procedure Clear(CacheFree: Boolean = True);

    // ��������� ������� � ������ ����� �������, ���������� ��������� �� ����:
    function IncHead(): Pointer;

    // ������� ���� ��� ��������� ��������� �� ������� ����� �������:
    procedure DecHead(Count: Integer = 1);

    // ��������� ������� � ����� ����� �������, ���������� ��������� �� ����:
    function IncTail(): Pointer;

    // ������� ���� ��� ��������� ��������� �� ������ ����� �������:
    procedure DecTail(Count: Integer = 1);

    // ���������� ��������� �� ��������� ������� � ������� ����� �������:
    function GetHead(): Pointer;

    // ���������� ��������� �� ��������� ������� � ������ ����� �������:
    function GetTail(): Pointer;

    // �������� ��������� �� ������ ������� ���������, ��������� � ���������� nil.
    // ������ ������� �� �������� ������� (����� ������������, ���� ����).

  protected
    function PageNew(): TXorList; // �������� ����� �������� ��� ���� �� ����
    procedure PageFree(Page: TXorList); // ����� �������� � ���, � ����������� ������
  protected
    HeadPage, TailPage: TXorList; // ��������� �� ������ � ��������� ��������
    HeadOffset, TailOffset: Integer; // �������� � ������ ������� �� ���
    Bytes, Mult: Integer; // �������, ���������� � ������������
    Cache1, Cache2: TXorList; // ��� �������� ����
    Size: Integer; // ������ ������, ������������ ��� ������
  public

    // ���������� ���������� ��������� � �������:
    property Count: Integer read Size;
  end;

implementation

uses
  SysUtils; // ��� Abort

constructor TFastQueue.Create(Bytes, Blocks: Integer);
begin
  inherited Create();
  if (Bytes < 1) or (Blocks < 1) then // ������ ������ ������������� �������
    Abort;
  if (Bytes and 3) > 0 then // �����������, ���� �� ������� �� 4
    Inc(Bytes, 4 - (Bytes and 3));
  Self.Bytes := Bytes;
  Self.Mult := Bytes * Blocks; // ��������� ������������ ������ ��������
end;

destructor TFastQueue.Destroy();
begin
  Clear(True); // ������ ������������ ������
  inherited Destroy();
end;

procedure TFastQueue.Clear(CacheFree: Boolean = True);
begin
  while HeadPage <> nil do // ������� ��� ��������
    TXorList.Pop(HeadPage).Free();
  if CacheFree then
  begin // ������� ����
    Cache1.Free;
    Cache2.Free;
    Cache1 := nil;
    Cache2 := nil;
  end;
  Size := 0; // ������������� ������ �������
  HeadOffset := 0;
  TailOffset := 0;
  HeadPage := nil;
  TailPage := nil;
end;

function TFastQueue.IncHead(): Pointer;
begin
  Inc(Size); // ������
  Inc(HeadOffset, Bytes); // ��������� �������
  if (HeadPage = nil) or (HeadOffset = Mult) then // ������ ��� �����
  begin
    HeadPage := HeadPage.Connect(PageNew()); // ���� ����� ��������
    HeadOffset := 0; // � � ������
    if TailPage = nil then
    begin // ���� ������ - ���������� �����
      TailPage := HeadPage;
      TailOffset := HeadOffset; // ����
    end;
  end;
  Result := HeadPage.Data(HeadOffset); // ����� ������
end;

procedure TFastQueue.DecHead(Count: Integer = 1);
begin
  Dec(Size, Count); // ��������� ������
  if Size <= 0 then
  begin // ���� �������� ���������, ������ �������
    Clear(False);
    Exit;
  end;
  Count := Count * Bytes; // �� ������� �������� � ������
  while Count > 0 do
  begin // ���� ���� ��� �������
    Dec(HeadOffset, Count); // ��������� ������ �������
    if HeadOffset < 0 then
    begin // ���� �� ���� ��������
      Count := -HeadOffset - Bytes; // ������� �� ���� ���������
      HeadOffset := Mult - Bytes; // ��������� �� ��������� ������� ��������
      PageFree(HeadPage); // �������, �� ���������� - ��� ���� ��������� � ����
      HeadPage := HeadPage.Connect(HeadPage.Next(nil)); // ����������� ������ ��������
    end
    else
      Break; // �� ���� ���������
  end;
end;

function TFastQueue.IncTail(): Pointer;
begin
  Inc(Size); // ������
  Dec(TailOffset, Bytes); // �������� �������
  if (TailPage = nil) or (TailOffset < 0) then // ������ ��� �����
  begin
    TailPage := TailPage.Connect(PageNew()); // ���� ����� ��������
    TailOffset := Mult - Bytes; // � � �����
    if HeadPage = nil then
    begin // ���� ������ - ���������� ������
      HeadPage := TailPage;
      HeadOffset := TailOffset; // ��������� �������
    end;
  end;
  Result := TailPage.Data(TailOffset); // ����� ������
end;

procedure TFastQueue.DecTail(Count: Integer = 1);
begin
  Dec(Size, Count); // ��������� ������
  if Size <= 0 then
  begin // ���� �������� ���������, ������ �������
    Clear(False);
    Exit;
  end;
  Count := Count * Bytes; // �� ������� �������� � ������
  while Count > 0 do
  begin // ���� ���� ��� �������
    Inc(TailOffset, Count); // ����������� ����� �������
    if TailOffset >= Mult then
    begin // ���� �� ���� ��������
      Count := TailOffset - Mult; // ������� �� ���� ���������
      TailOffset := 0; // ��������� �� ������ ��������
      PageFree(TailPage); // �������, �� ���������� - ��� ���� ��������� � ����
      TailPage := TailPage.Connect(TailPage.Next(nil)); // ����������� ����� ��������
    end
    else
      Break; // �� ���� ���������
  end;
end;

function TFastQueue.GetHead(): Pointer;
begin
  Result := HeadPage.Data(HeadOffset); // ������ �������� ���������� ����� �� ������
end;

function TFastQueue.GetTail(): Pointer;
begin
  Result := TailPage.Data(TailOffset); // �������, ����� ����
end;

function TFastQueue.PageNew(): TXorList;
begin
  if Cache1 = nil then
  begin // ��� ����
    Result := TXorList.Create(Mult); // ������
    if Result = nil then
      Abort; // �� ������� ������
    Exit;
  end;
  Result := TXorList.Init(Cache1); // ���� �� ����
  Cache1 := Cache2; // ������������
  Cache2 := nil; // ���� ���������
end;

procedure TFastQueue.PageFree(Page: TXorList);
begin
  Cache2.Free(); // ������ ������� ������
  Cache2 := Cache1; // ������������
  Cache1 := Page; // ����������� ����
end;

end.

