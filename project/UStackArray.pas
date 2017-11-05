unit UStackArray; // Лицензия: WTFPL, общественное достояние.

interface // только для x86

uses
  UXorList; // Использует лист для связки страниц

type // Итератор для стека-массива
  TStackArrayIterator = record // Нагрузка: 12 байт
    Index: Integer; // Текущий индекс
    Data: Pointer; // Указатель на пользовательские данные по этому индексу
    Page: TXorList; // Страница памяти, используется стеком-массивом.
  end; // Переход к соседнему элементу по итератору - эффективнее, чем прямой запрос.

// Односторонний стек-массив с константным размером элементов.
// Хранит внутренний указатель для быстрого обращения к соседним элементам.
// Произвольный доступ медленный, а последовательный в любую сторону - быстрый.
// Разбивает данные на страницы с заданным количеством на каждой.
// Кеширует одну страницу, делая многократную загрузку и выгрузку плавной.
// Для многократного обхода стека-массива можно использовать итераторы.
// Нагрузка: 36 байт на сам объект, +12 байт на каждую страницу.

  TStackArray = class(TObject) // настоящий объект

    // Конструктор, создаёт стек-массив:
    // на каждой странице будет Blocks элементов размером Bytes каждый;
    // размер блока округляется до кратного четырём в большую сторону;
    constructor Create(Bytes, Blocks: Integer);

    // Деструктор, используйте .Free():
    destructor Destroy(); override;

    // Очищает все элементы стека-массива:
    // опционально также освобождает закешированную страницу (по умолчанию);
    procedure Clear(CacheFree: Boolean = True);

    // Добавляет элемент в конец стек-массива, возвращает указатель на него:
    function Push(): Pointer;

    // Удаляет последний элемент из стека-массива, возвращает оставшееся количество.
    function Pop(): Integer;

    // Возвращает указатель на последний элемент стека-массива:
    function Peek(): Pointer;

    // Возвращает указатель на элемент по произвольному индексу:
    function Index(Index: Integer): Pointer;

    // Возвращает итератор, показывающий на заданный индекс:
    function Iterator(Index: Integer): TStackArrayIterator;

    // Смещает итератор к новому индексу, возвращает указатель на искомый элемент:
    function Move(Index: Integer; var Iterator: TStackArrayIterator): Pointer;

    // Изменяет размер стека-массива:
    // при увеличении, новые элементы хранят неопределённое значение;
    // при уменьшении, прошлые взятые итераторы на удалённые элементы будут неверны:
    procedure Resize(Count: Integer);

    //
    function Exchange(Index: Integer): Integer;

    // Удаление элементов из пустого стека-массива допустимо, получение – возвращает nil.
    // Пустой стек-массив не занимает страниц (кроме кешированной, если была).
    // Если итератор показывал на элемент, который уже был убран (через Pop, Clear или Resize),
    //    то он становится неверен, и обращаться по нему больше нельзя,
    //    даже если потом добавить новый элемент по тому же индексу.

  protected
    function PageNew(): TXorList; // Выделяет новую страницу или берёт из кеша
    procedure PageFree(Page: TXorList); // Отдаёт страницу в кеш, и освобождает ту
  protected
    First, Last, Middle: TXorList; // Указатели на первую, последнюю и внутреннюю страницу
    Offset: Integer; // Смещение к последнему элементу на последней странице
    Bytes, Blocks, Mult: Integer; // Размеры, полученные в конструкторе
    Cache: TXorList; // Одна страница кеша
    Size: Integer; // Хранит количество элементов, используется при работе

  public

    // Возвращает количество элементов в стеке-массиве:
    // индекс последнего элемента равен Count-1;
    property Count: Integer read Size;
  end;

  TPtrArray = class(TStackArray)

    // Создаёт стек указателей, по умолчанию 255 на страницу (1 Кб)
    constructor Create(Blocks: Integer = 255);

    // Помещает указатель в стек (но не данные, на которые тот указывает):
    procedure Push(Value: Pointer);

    // Достаёт указатель из стека, удаляя его (но не то, на что он указывает):
    function Pop(): Pointer;

    // Возвращает последнее значение в стеке:
    function Peek(): Pointer;

    //
    function Index(Index: Integer): Pointer;

    //
    function Move(Index: Integer; var Iterator: TStackArrayIterator): Pointer;

    // На пустом стеке возвращаются нулевые указатели.
    // Эквивалентен быстрому стеку, Clear и Empty работают.
  end;

implementation

uses
  SysUtils; // Для Abort

// TStackArray

type
  TInfo = record // для чтения дополнительных данных в конце каждой страницы
    Previous: TXorList; // указатель на предыдущую страницу
    Index: Integer; // порядковый номер этой страницы
  end;

  PInfo = ^TInfo;

constructor TStackArray.Create(Bytes, Blocks: Integer);
begin
  inherited Create();
  if (Bytes < 1) or (Blocks < 1) then // только строго положительные размеры
    Abort;
  if (Bytes and 3) > 0 then // увеличиваем, если не делится на 4
    Inc(Bytes, 4 - (Bytes and 3));
  Self.Bytes := Bytes;
  Self.Blocks := Blocks; // количество элементов на странице важно для расчётов
  Self.Mult := Bytes * Blocks; // общий размер особенно важен при чтении конца
end;

destructor TStackArray.Destroy();
begin
  Clear(True); // полное освобождение памяти
  inherited Destroy();
end;

procedure TStackArray.Clear(CacheFree: Boolean = True);
begin
  while First <> nil do // очищаем все страницы
    TXorList.Pop(First).Free();
  if CacheFree then
  begin // очистка кеша
    Cache.Free;
    Cache := nil;
  end;
  Offset := 0;
  First := nil; // зануляем все указатели
  Last := nil;
  Middle := nil;
end;

function TStackArray.Push(): Pointer;
var
  Old: TXorList; // последняя до создания новой
  Info: PInfo; // доступ к дополнительным данным
begin
  Inc(Size); // увеличиваем счётчик элементов
  Inc(Offset, Bytes); // поднимаем границу
  if (Last = nil) or (Offset = Mult) then // первая или вышли
  begin
    Old := Last; // текущая
    Last := Last.Connect(PageNew()); // берём новую страницу
    Offset := 0; // к её началу
    if First = nil then
    begin // добавлен первый элемент
      First := Last; // первая страница
      Info := First.Data(Mult); // её доп-данные
      Info.Previous := nil; // нет предыдущей
      Info.Index := 0; // нулевой номер страницы
    end
    else
    begin // вторая и последующие страницы
      Info := Last.Data(Mult); // доп-данные
      Info.Previous := Old; // ставим ссылку на предыдущую
      Info.Index := PInfo(Old.Data(Mult)).Index + 1; // номер на единицу больше
    end;
  end;
  Result := Last.Data(Offset); // вернём данные
end;

function TStackArray.Pop(): Integer;
begin
  Dec(Size); // уменьшаем размер
  if Size <= 0 then
  begin
    Clear(False); // чистка, если уже пуст
    Result := 0;
    Exit;
  end;
  Dec(Offset, Bytes); // уменьшаем смещение
  if Offset < 0 then
  begin // ушли за край страницы
    Offset := Mult - Bytes; // смещение на последний элемент предыдущей
    PageFree(Last); // удаляем, но фактически - она пока останется в кеше
    if Last = Middle then
      Middle := nil; // если это была внутренняя - зануляем
    Last := Last.Connect(Last.Next(nil)); // отбрасываем последнюю страницу
  end;
  Result := Size; // возвращаем размер
end;

function TStackArray.Peek(): Pointer;
begin
  Result := Last.Data(Offset); // смещение показывает прямо на данные
end;

function TStackArray.Index(Index: Integer): Pointer;
var
  Page, // номер искомой страницы
Left, Right: Integer; // расстояния до первой и последней

  function Current(Page: TXorList): Integer;
  begin // возвращает номер заданной страницы
    Result := PInfo(Page.Data(Mult)).Index;
  end;

begin
  if (Index < 0) or (Index >= Size) then
  begin // запрошен индекс вне границ
    Result := nil;
    Exit;
  end;
  Page := Index div Blocks; // вычисляем номер страницы с нужным элементом
  if (Middle = First) or (Middle = Last) then
    Middle := nil; // если внутренняя на границе - пока уберём её вовсе
  Left := Page - Current(First); // сколько страниц до первой
  Right := Current(Last) - Page; // до последней
  if Left < Right then // до первой ближе
  begin
    if (Middle = nil) or (Left < Current(Middle) - Page) then
      Middle := First; // если нет внутренней, или если до первой всё равно ближе
  end
  else // (дальше, внутренняя будет содержать ближайшую из трёх известных страниц)
  begin
    if (Middle = nil) or (Page - Current(Middle) >= Right) then
      Middle := Last; // если нет внутренней, или если до последней всё равно ближе
  end;
  if Page < Current(Middle) then  // движемся влево
    while Page <> Current(Middle) do
      Middle := PInfo(Middle.Data(Mult)).Previous // переходим по известным указателям
  else
    while Page <> Current(Middle) do // движемся вправо
      Middle := Middle.Next(PInfo(Middle.Data(Mult)).Previous); //вперёд по страницам
  Result := Middle.Data((Index - Current(Middle) * Blocks) * Bytes); // итоговый расчёт
end;

function TStackArray.Iterator(Index: Integer): TStackArrayIterator;
begin
  Result.Data := Self.Index(Index); // пытаемся получить результат
  if Result.Data <> nil then
  begin // элемент найден
    Result.Index := Index; // номер верен
    Result.Page := Middle; // внутренняя страница как раз верна
  end
  else
  begin // нет такого
    Result.Index := -1; // неверный индекс
    Result.Page := nil; // нет страницы для итератора
  end;
end;

function TStackArray.Move(Index: Integer; var Iterator: TStackArrayIterator): Pointer;
begin
  Middle := Iterator.Page; // берём из итератора, если есть
  Result := Self.Index(Index); // ищем с её помощью
  Iterator.Data := Result; // копируем результат
  Iterator.Page := Middle; // обновляем страницу итератора
  if Result = nil then
    Iterator.Index := -1 // ошибка, значит ставим несуществующий индекс
  else
    Iterator.Index := Index; // верно, индекс тот же
end;

procedure TStackArray.Resize(Count: Integer);
var
  Page, Curr: Integer; // номера нужной и текущей страниц
  Old: TXorList; // для добавления
  Info: PInfo; // чтение дополнительных данных
begin
  if Count = Size then // тот же размер, нечего менять
    Exit;
  Dec(Count); // теперь это не размер, а индекс последнего элемента
  if Count < 0 then
  begin // если ушли в минус - чистка
    Clear(False);
    Exit;
  end;
  Page := Count div Blocks; // номер страницы, которая должна стать последней
  if Count >= Size then // увеличение размера
  begin
    if Size = 0 then // инициализируем страницы, если был пуст
      Push();
    Curr := PInfo(Last.Data(Mult)).Index; // номер фактически последней
    while Curr <> Page do // нужны новые страницы
    begin
      Inc(Curr); // изменяем номер текущей
      Old := Last;
      Last := Last.Connect(PageNew()); // создаём и цепляем новую
      Info := Last.Data(Mult); // дополнительные данные от новой
      Info.Previous := Old; // указатель на предыдущую
      Info.Index := Curr; // присваиваем номер
    end;
  end
  else
  begin // уменьшение размера
    Curr := PInfo(Last.Data(Mult)).Index; // номер фактически последней
    while Curr <> Page do // нужно удалить страницы
    begin
      PageFree(Last); // освобождаем, но она ещё побудет в кеше
      if Last = Middle then // сбрасываем внутреннюю, если встретилась
        Middle := nil;
      Last := Last.Connect(Last.Next(nil)); // отцепляем и переходим к предыдущей
      Dec(Curr); // уменьшаем номер
    end;
  end;
  Offset := (Count mod Blocks) * Bytes; // вычисляем смещение к последнему элементу
  Size := Count + 1; // новый размер, по сути - переданное значение
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
  begin // кеш пуст
    Result := TXorList.Create(Mult + SizeOf(TInfo)); // создаём
    if Result = nil then
      Abort; // не хватило памяти
    Exit;
  end;
  Result := TXorList.Init(Cache); // берём из кеша
  Cache := nil; // теперь он пуст
end;

procedure TStackArray.PageFree(Page: TXorList);
begin
  Cache.Free(); // просто освобождаем имеющийся
  Cache := Page; // присваиваем этот
end;

// TPtrArray

constructor TPtrArray.Create(Blocks: Integer = 255);
begin
  inherited Create(4, Blocks); // размер = 4
end;

procedure TPtrArray.Push(Value: Pointer);
begin
  PInteger(inherited Push())^ := Integer(Value); // сразу присваиваем
end;

function TPtrArray.Pop(): Pointer;
begin
  Result := Peek(); // просто берём
  inherited Pop(); // удаляем один
end;

function TPtrArray.Peek(): Pointer;
begin
  Result := inherited Peek(); // получаем указатель
  if Result <> nil then // если не нулевой, то берём по нему
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

