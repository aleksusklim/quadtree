unit UFastQueue; // Лицензия: WTFPL, общественное достояние.

interface

uses
  UXorList; // Использует лист для связки страниц

type // только для x86

// Быстрая двусторонняя очередь с константным размером элементов.
// Разбивает данные на страницы с заданным количеством на каждой.
// Кеширует две страницы, делая многократную загрузку и выгрузку плавной.
// Нагрузка: 36 байт на сам объект, +4 байта на каждую страницу.

  TFastQueue = class(TObject) // настоящий объект

    // Конструктор, создаёт очередь:
    // на каждой странице будет Blocks элементов размером Bytes каждый;
    // размер блока округляется до кратного четырём в большую сторону;
    constructor Create(Bytes, Blocks: Integer);

    // Деструктор, используйте .Free():
    destructor Destroy(); override;

    // Очищает все элементы очереди:
    // опционально также освобождает закешированные страницы (по умолчанию);
    procedure Clear(CacheFree: Boolean = True);

    // Добавляет элемент в правый конец очереди, возвращает указатель на него:
    function IncHead(): Pointer;

    // Удаляет один или несколько элементов из правого конца очереди:
    procedure DecHead(Count: Integer = 1);

    // Добавляет элемент в левый конец очереди, возвращает указатель на него:
    function IncTail(): Pointer;

    // Удаляет один или несколько элементов из левого конца очереди:
    procedure DecTail(Count: Integer = 1);

    // Возвращает указатель на последний элемент с правого конца очереди:
    function GetHead(): Pointer;

    // Возвращает указатель на последний элемент с левого конца очереди:
    function GetTail(): Pointer;

    // Удаление элементов из пустой очереди допустимо, получение – возвращает nil.
    // Пустая очередь не занимает страниц (кроме кешированных, если были).

  protected
    function PageNew(): TXorList; // Выделяет новую страницу или берёт из кеша
    procedure PageFree(Page: TXorList); // Отдаёт страницу в кеш, и освобождает лишнюю
  protected
    HeadPage, TailPage: TXorList; // Указатели на первую и последнюю страницы
    HeadOffset, TailOffset: Integer; // Смещения к концам очереди на них
    Bytes, Mult: Integer; // Размеры, полученные в конструкторе
    Cache1, Cache2: TXorList; // Две страницы кеша
    Size: Integer; // Хранит размер, используется при работе
  public

    // Возвращает количество элементов в очереди:
    property Count: Integer read Size;
  end;

implementation

uses
  SysUtils; // Для Abort

constructor TFastQueue.Create(Bytes, Blocks: Integer);
begin
  inherited Create();
  if (Bytes < 1) or (Blocks < 1) then // только строго положительные размеры
    Abort;
  if (Bytes and 3) > 0 then // увеличиваем, если не делится на 4
    Inc(Bytes, 4 - (Bytes and 3));
  Self.Bytes := Bytes;
  Self.Mult := Bytes * Blocks; // сохраняем подсчитанный размер страницы
end;

destructor TFastQueue.Destroy();
begin
  Clear(True); // полное освобождение памяти
  inherited Destroy();
end;

procedure TFastQueue.Clear(CacheFree: Boolean = True);
begin
  while HeadPage <> nil do // очищаем все страницы
    TXorList.Pop(HeadPage).Free();
  if CacheFree then
  begin // очистка кеша
    Cache1.Free;
    Cache2.Free;
    Cache1 := nil;
    Cache2 := nil;
  end;
  Size := 0; // инициализация пустой очереди
  HeadOffset := 0;
  TailOffset := 0;
  HeadPage := nil;
  TailPage := nil;
end;

function TFastQueue.IncHead(): Pointer;
begin
  Inc(Size); // размер
  Inc(HeadOffset, Bytes); // поднимаем границу
  if (HeadPage = nil) or (HeadOffset = Mult) then // первая или вышли
  begin
    HeadPage := HeadPage.Connect(PageNew()); // берём новую страницу
    HeadOffset := 0; // к её началу
    if TailPage = nil then
    begin // если первая - установить левый
      TailPage := HeadPage;
      TailOffset := HeadOffset; // ноль
    end;
  end;
  Result := HeadPage.Data(HeadOffset); // вернём данные
end;

procedure TFastQueue.DecHead(Count: Integer = 1);
begin
  Dec(Size, Count); // уменьшаем размер
  if Size <= 0 then
  begin // если заведомо кончилась, просто очищаем
    Clear(False);
    Exit;
  end;
  Count := Count * Bytes; // на сколько сдвинуть в байтах
  while Count > 0 do
  begin // пока есть что двигать
    Dec(HeadOffset, Count); // уменьшаем правую границу
    if HeadOffset < 0 then
    begin // ушли за край страницы
      Count := -HeadOffset - Bytes; // сколько не было размещено
      HeadOffset := Mult - Bytes; // указатель на последний элемент страницы
      PageFree(HeadPage); // удаляем, но фактически - она пока останется в кеше
      HeadPage := HeadPage.Connect(HeadPage.Next(nil)); // отбрасываем правую страницу
    end
    else
      Break; // всё было размещено
  end;
end;

function TFastQueue.IncTail(): Pointer;
begin
  Inc(Size); // размер
  Dec(TailOffset, Bytes); // опускаем границу
  if (TailPage = nil) or (TailOffset < 0) then // первая или вышли
  begin
    TailPage := TailPage.Connect(PageNew()); // берём новую страницу
    TailOffset := Mult - Bytes; // к её концу
    if HeadPage = nil then
    begin // если первая - установить правый
      HeadPage := TailPage;
      HeadOffset := TailOffset; // последний элемент
    end;
  end;
  Result := TailPage.Data(TailOffset); // вернём данные
end;

procedure TFastQueue.DecTail(Count: Integer = 1);
begin
  Dec(Size, Count); // уменьшаем размер
  if Size <= 0 then
  begin // если заведомо кончилась, просто очищаем
    Clear(False);
    Exit;
  end;
  Count := Count * Bytes; // на сколько сдвинуть в байтах
  while Count > 0 do
  begin // пока есть что двигать
    Inc(TailOffset, Count); // увеличиваем левую границу
    if TailOffset >= Mult then
    begin // ушли за край страницы
      Count := TailOffset - Mult; // столько не было размещено
      TailOffset := 0; // указатель на начало страницы
      PageFree(TailPage); // удаляем, но фактически - она пока останется в кеше
      TailPage := TailPage.Connect(TailPage.Next(nil)); // отбрасываем левую страницу
    end
    else
      Break; // всё было размещено
  end;
end;

function TFastQueue.GetHead(): Pointer;
begin
  Result := HeadPage.Data(HeadOffset); // правое смещение показывает прямо на данные
end;

function TFastQueue.GetTail(): Pointer;
begin
  Result := TailPage.Data(TailOffset); // впрочем, левое тоже
end;

function TFastQueue.PageNew(): TXorList;
begin
  if Cache1 = nil then
  begin // кеш пуст
    Result := TXorList.Create(Mult); // создаём
    if Result = nil then
      Abort; // не хватило памяти
    Exit;
  end;
  Result := TXorList.Init(Cache1); // берём из кеша
  Cache1 := Cache2; // проталкиваем
  Cache2 := nil; // один свободный
end;

procedure TFastQueue.PageFree(Page: TXorList);
begin
  Cache2.Free(); // просто удаляем лишний
  Cache2 := Cache1; // проталкиваем
  Cache1 := Page; // присваиваем этот
end;

end.

