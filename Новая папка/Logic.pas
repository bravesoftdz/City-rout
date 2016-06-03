unit Logic;

interface

uses
  System.SysUtils, FileUnit, Math;

type
  TLinks = record
    bus : PTTraffic;
    trolBus : PTTraffic;
    tram : PTTraffic;
    metro : PTTraffic;
  end;

  PTStationTable = ^TStationTable;
  TstationTable = record
    data : PTStationList;
    used : boolean;
    next : PTStationTable;
  end;

  PTTraceStack = ^TTraceStack;
  TTraceStack = record
    station : PTStationList;
    transport : PTTransportList;
    prev : PTTraceStack;
  end;

  PTTraceTable = ^TTraceTable;
  TTraceTable = record
    data : PTTraceStack;
    next : PTTraceTable;
  end;

var
  useBus, useTrol, useTram, useMetro : boolean;
  stationTable : PTStationTable;
  traceTable : PTTraceTable;

function GetStation : PTStationList;
function GetDistance(latitude1, longitude1, latitude2, longitude2 : double) : double;
procedure StationTableSort(var stationTable : PTStationTable; station : PTStationList);
procedure FindRoute(var start, stop : PTStationList; transport : PTTransportList);
procedure StationTableCreate(var stationTable : PTStationTable);
procedure PrepareData;

implementation

var
  connectMatrix : array of array of TLinks;

  traceStack : PTTraceStack;


function GetDistance(latitude1, longitude1, latitude2, longitude2 : double) : double;
const diameter = 12756200 ;
var   dx, dy, dz:double;
begin
  longitude1 := degtorad(longitude1 - longitude2);
  latitude1 := degtorad(latitude1);
  latitude2 := degtorad(latitude2);

  dz := sin(latitude1) - sin(latitude2);
  dx := cos(longitude1) * cos(latitude1) - cos(latitude2);
  dy := sin(longitude1) * cos(latitude1);
  Result := arcsin(sqrt(sqr(dx) + sqr(dy) + sqr(dz)) / 2) * diameter;
end;

function GetStation : PTStationList;
var
  pnt : pTStationList;
  i, num : integer;
begin
  write(#13, #10, 'Введите номер станции: ');
  Readln(num);
  pnt := stationList;
  i := 1;
  while i <= num do
  begin
    pnt := pnt^.next;
    if pnt = nil then break;
    inc(i);
  end;
  Result := pnt;
end;

procedure StationTableCreate(var stationTable : PTStationTable);
var
  pnt : PTStationList;
  head : PTStationTable;
begin
  pnt := stationList^.next;
  new(stationTable);
  head := stationTable;
  while pnt <> nil do
  begin
    new(head^.next);
    head := head^.next;
    head^.data := pnt;
    head^.used := false;
    head^.next := nil;
    pnt := pnt^.next;
  end;
end;

procedure StationTableDeleteElem(var stationTable : PTStationTable); inline;
begin
  if stationTable^.next <> nil then
    stationTable^.next := stationTable^.next^.next
  else stationTable := nil;
end;

function StationTableFindMinimum(var stationTable : PTStationTable; var station : PTStationList) : PTStationTable;
var
  pnt, temp : PTStationTable;
  distance, check : double;
begin
  temp := stationTable;
  //находим расстояние между остановкой и первой станцией исходной таблицы
  distance := GetDistance(station^.X, station^.Y, stationTable^.next^.data^.X,
    stationTable^.next^.data^.Y);
  pnt := stationTable^.next;
  while pnt^.next <> nil do
  begin
    check := GetDistance(station^.X, station^.Y, pnt^.next^.data^.X, pnt^.next^.data^.Y);
    if distance >= check then
    begin
      temp := pnt;
      distance := check;
    end;
    pnt := pnt^.next;
  end;
  Result := temp;
end;

procedure StationTableClear(var stationTable : PTStationTable); inline;
var
  pnt : PTStationTable;
begin
  pnt := stationTable;
  while pnt^.next <> nil do
    if pnt^.next^.used then StationTableDeleteElem(pnt) else pnt := pnt^.next;
end;

procedure StationTableSort(var stationTable : PTStationTable; station : PTStationList);
var
  table, head, temp, pnt : PTStationTable;
begin
  //StationTableClear(stationTable);
  new(table);
  head := table;
  head^.next := nil;
  pnt := stationTable;
  while pnt^.next <> nil do
  begin
    new(head^.next);
    head := head^.next;
    temp := StationTableFindMinimum(stationTable, station);
    head^.data := temp^.next^.data;
    head^.used := temp^.next^.used;
    StationTableDeleteElem(temp);
    head^.next := nil;
  end;
  stationTable := table;
end;

procedure ConnectiveMatrixFill;
var
  mainPnt : PTTransportList;
  pnt1, pnt2 : PTTrace;
  num : byte;
begin
  mainPnt := TransportList^.next;
  while mainPnt <> nil do
  begin
    pnt1 := mainPnt^.trace;
    num := GetType(mainPnt^.specif);
    while pnt1^.next <> nil do
    begin
      pnt2 := pnt1^.next;
      while pnt2 <> nil do
      begin
        case num of
          1 :
            if useBus then
              AddTransport(connectMatrix[pnt1^.data^.num, pnt2^.data^.num].bus, mainPnt);
          2 :
            if useTrol then
              AddTransport(connectMatrix[pnt1^.data^.num, pnt2^.data^.num].trolBus, mainPnt);
          3 :
            if useTram then
              AddTransport(connectMatrix[pnt1^.data^.num, pnt2^.data^.num].tram, mainPnt);
          4 :
            if useMetro then
              AddTransport(connectMatrix[pnt1^.data^.num, pnt2^.data^.num].metro, mainPnt);
          0 : Halt;
        end;
        pnt2 := pnt2^.next
      end;
      pnt1 := pnt1^.next;
    end;
    mainPnt := mainPnt^.next;
  end;
end;

procedure ConnectivityMatrixCreate;
var
  i, j, num : integer;
begin
  num := GetListSize;
  for i := 0 to num do
    for j := 0 to num do
    begin
      connectMatrix[i,j].bus := nil;
      connectMatrix[i,j].trolBus := nil;
      connectMatrix[i,j].tram := nil;
      connectMatrix[i,j].metro:= nil;
    end;

  ConnectiveMatrixFill;
end;

//******************************************************************************
//******************************************************************************
function GetAnswer(start : boolean) : PTStationList;
var
  str : string[50];
  pnt : PTStationList;
begin
  if start then writeln ('Введите исходную точку')
  else writeln ('Введите пункт назначения');
  Readln(str);
  pnt := stationList^.next;
  while pnt <> nil do
  begin
    if AnsiLowerCase(str) <> AnsiLowerCase(pnt^.name) then pnt := pnt^.next else
    begin
      Result := pnt;
      break;
    end;
  end;
end;
//******************************************************************************
//******************************************************************************

procedure CopyStack(var stack : PTTraceStack);
var
  pnt, temp : PTTraceStack;
begin
  pnt := TraceStack;
  while pnt <> nil do
  begin
    new(temp);
    temp^.station := pnt^.station;
    temp^.transport := pnt^.transport;
    temp^.prev := stack;
    stack := temp;
    pnt := pnt^.prev;
  end;
end;

procedure TraceTableAdd;
var
  pnt : PTTraceTable;
  elem, head : PTTraceStack;
begin
  if traceTable = nil then
  begin
    new(traceTable);
    pnt := traceTable;
  end else
  begin
    pnt := traceTable;
    while pnt^.next <> nil do pnt := pnt^.next;
    new(pnt^.next);
    pnt := pnt^.next;
  end;

  CopyStack(pnt^.data);

    head := pnt^.data;
    while head <> nil do
    begin
      if head^.transport <> nil then
        writeln(head^.station^.name,' ', head^.transport^.specif, head^.transport^.num)
      else writeln ('Пешком до ', head^.station^.name);
      head := head^.prev;
    end;

  readln;
  halt;
end;

procedure TraceStackAddPoint(var point, stop : PTStationList; transport : PTTransportList);
var
  temp : PTTraceStack;
begin
  if traceStack <> nil then
  begin
    new(temp);
    temp^.station := point;
    temp^.transport := transport;
    temp^.prev := traceStack;
    traceStack := temp;
  end else
  begin
    new(traceStack);
    traceStack^.station := point;
    traceStack^.transport := transport;
    traceStack^.prev := nil;
  end;
  if point = stop then TraceTableAdd;

  if traceStack^.transport <> nil then
        writeln(traceStack^.station^.name,' ', traceStack^.transport^.specif, traceStack^.transport^.num)
      else writeln ('Пешком до ', traceStack^.station^.name);
end;

procedure TraceStackExcludePoint;
var
  temp : PTTraceStack;
begin
  temp := traceStack;
  traceStack := traceStack^.prev;
  Dispose(temp);
end;

function ConteinPoint(stop : PTStationList; var transport : PTTraffic) : boolean;
var
  pnt : PTTrace;
begin
  pnt := transport^.data^.trace;
  while pnt <> nil do
    if pnt^.data <> stop then pnt := pnt^.next else
    begin
      Result := true;
      exit;
    end;

  Result := false;
end;

procedure FindRouteStudyPoint(var start, stop : PTStationList; var trace : PTTraffic);
var
  pnt : PTTraffic;
  head : PTTrace;
begin
  pnt := trace;
  while pnt <> nil do
    if not pnt^.used then
    begin
      head := pnt^.data^.trace;
      while head^.data <> start do head := head^.next;
      while not (head^.next <> nil) and ((head^.next^.data <> stop) xor
      (head^.direction <> head^.next^.direction)) do head := head^.next;

      if head^.next = nil then
      begin
        head := pnt^.data^.trace;
        while head^.data <> start do head := head^.next;
        while head^.next <> nil do
          FindRoute(head^.next^.data, stop, pnt^.data)
      end else if (head^.next <> nil) and (head^.direction = not head^.next^.direction)
      and (head^.data <> stop) then
      begin
        if (head^.data = head^.next^.data) then
        begin
          head := pnt^.data^.trace;
          while head^.data <> start do head := head^.next;
          while (head^.direction = not head^.next^.direction) do
            FindRoute(head^.next^.data, stop, pnt^.data);
        end;
      end else if head^.data = stop then
        FindRoute(head^.data, stop, pnt^.data);
      pnt := pnt^.next;
    end;
end;

procedure FindRoute(var start, stop : PTStationList; transport : PTTransportList);
var
  pnt : PTStationTable;
begin
  TraceStackAddPoint(start, stop, transport);
  //выстраиваем таблицу расстояний вокруг данной точки
  if (start <> stop) then
  begin
    StationTableSort(stationTable, start);

    //просмотр связанных стнций
    //просматриваем маршруты, проходящие через данную ствнцию

    if start^.bus <> nil then FindRouteStudyPoint(start, stop, start^.bus);
    if start^.trolBus <> nil then FindRouteStudyPoint(start, stop, start^.trolBus);
    if start^.tram <> nil then FindRouteStudyPoint(start, stop, start^.tram);
    if start^.metro <> nil then FindRouteStudyPoint(start, stop, start^.metro);

    //просмотр несвязанных станций
    pnt := stationTable^.next^.next;
    while pnt^.data <> stop do
    begin
    //просмотр только тех станций, который до этого не использовались.
      if not pnt^.used then
      begin
        pnt^.used := true;
        FindRoute(pnt^.data, stop, nil);
        pnt^.used := false;
      end;
      pnt := pnt^.next;
    end;
  end;
  TraceStackExcludePoint;
end;

procedure PrepareData;
var
  start, stop : PTStationList;
begin
  start := GetStation;
  stop := GetStation;
  //ConnectivityMatrixCreate;
  StationTableCreate(stationTable);
  FindRoute(start, stop, nil);
end;

end.
