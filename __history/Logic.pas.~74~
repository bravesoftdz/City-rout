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
    time : double;
    distance : double;
  end;

  PTTraceTable = ^TTraceTable;
  TTraceTable = record
    data : PTTrace;
    time : double;
    next : PTTraceTable;
  end;

var
  useBus, useTrol, useTram, useMetro : boolean;
  connectMatrix : array of array of TLinks;
  start, stop : PTStationList;
  traceTable : PTTraceTable;
  maxTime : double;

procedure ConnectiveMatrixCreate;
//procedure FindRoute;
procedure FindFuckingRoute(var start : PTStationList; timer : double);
procedure CheckTransport(var start, checkPoint : PTStationList; timer : double);
procedure SaveTrace(time : double);
procedure CopyStackToTraceTable(var head : PTTrace);
procedure TraceClear(var stack : PTTrace);
function GetOverallTime(start, stop : PTStationList; transportType : byte) : double;
function CheckTime(var start, checkPoint : PTStationList; var timer : double; specif : byte) : boolean;
function FinalPointInTrace(var start : PTStationList; var timer : double) : boolean;
function GetAnswer(start : boolean) : PTStationList;
function GetDistance(latitude1, longitude1, latitude2, longitude2 : double) : double;
function GetStationPnt(num : integer) : PTStationList;
function StationsTired(i, j : integer) : boolean;
function StationEnableOnTransport(pnt1, pnt2 : PTStationList; out transportType : byte) : PTTrace;

implementation

const
  BUS_SPEED = 12.7 * 1000 / 60;
  TRAM_SPEED = BUS_SPEED * 0.9;
  METRO_SPEED = 41 * 1000 / 60;
  ON_FOOT_SPEED = 5.288 * 1000 / 60;
  MAX_TIME = $FFFF;

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

{function CheckDoubleStations(var pnt1, pnt2 : PTStationList) : boolean;
var
  i : integer;
begin
  i := 0;
  while (i < High(pnt1^.name)) and (pnt1^.name[i] <> ':') and (pnt2^.name[i] <> ':')
  and (AnsiLowerCase(pnt1^.name[i]) = AnsiLowerCase(pnt2^.name[i])) do inc(i);
  if (pnt1^.name[i] = ':') and (pnt1^.name[i] = ':') then Result := true
  else Result := false;
end; }

function CheckDistance (var pnt1, pnt2 : PTStationList) : boolean;
begin
  Result := GetDistance(pnt1^.X, pnt1^.Y, pnt2^.X, pnt2^.Y) < 200;
end;

function ConnectiveMatrixPointsTired(pnt1, pnt2 : PTStationList) : boolean;
begin
  if pnt1 <> pnt2 then
  begin
    Result := (connectMatrix[pnt1^.num - 1, pnt2^.num - 1].bus <> nil) or
    (connectMatrix[pnt1^.num - 1, pnt2^.num - 1].trolBus <> nil) or
    (connectMatrix[pnt1^.num - 1, pnt2^.num - 1].tram <> nil) or
    (connectMatrix[pnt1^.num - 1, pnt2^.num - 1].metro <> nil) or
    (connectMatrix[pnt2^.num - 1, pnt1^.num - 1].bus <> nil) or
    (connectMatrix[pnt2^.num - 1, pnt1^.num - 1].trolBus <> nil) or
    (connectMatrix[pnt2^.num - 1, pnt1^.num - 1].tram <> nil) or
    (connectMatrix[pnt2^.num - 1, pnt1^.num - 1].metro <> nil);

    //if not Result then Result := CheckDoubleStations(pnt1, pnt2);
    if not Result then Result := CheckDistance(pnt1, pnt2);
  end else Result := false;
end;

procedure ConnectiveMatrixFillTraffic;
var
  head : PTTransportList;
  pnt: PTTrace;
  num : byte;
begin
  head := TransportList^.next;
  while head <> nil do
  begin
    pnt := head^.trace;
    num := GetType(head^.specif);
    while pnt^.next^.enable do
    begin
      case num of
        1 :
          if useBus then
            AddTransport(connectMatrix[pnt^.data^.num - 1, pnt^.next^.data^.num - 1].bus, head);
        2 :
          if useTrol then
            AddTransport(connectMatrix[pnt^.data^.num - 1, pnt^.next^.data^.num - 1].trolBus, head);
        3 :
          if useTram then
            AddTransport(connectMatrix[pnt^.data^.num - 1, pnt^.next^.data^.num - 1].tram, head);
        4 :
          if useMetro then
            AddTransport(connectMatrix[pnt^.data^.num - 1, pnt^.next^.data^.num - 1].metro, head);
        0 : Halt;
      end;
      pnt := pnt^.next;
    end;
    head := head^.next;
  end;
end;

procedure ConnectiveMatrixFillLinks;
var
  pnt1, pnt2 : PTStationList;
begin
  pnt1 := stationList^.next;

  while pnt1 <> nil do
  begin
    pnt2 := pnt1^.next;
    while pnt2 <> nil do
    begin
      if (pnt1 <> pnt2) and ConnectiveMatrixPointsTired(pnt1, pnt2) then
      begin
        connectMatrix[pnt1^.num - 1, pnt2^.num - 1].distance :=
        GetDistance(pnt1^.X, pnt1^.Y, pnt2^.X, pnt2^.Y);
        connectMatrix[pnt2^.num - 1, pnt1^.num - 1].distance :=
        connectMatrix[pnt1^.num - 1, pnt2^.num - 1].distance;
      end;
      pnt2 := pnt2^.next;
    end;
    pnt1 := pnt1^.next;
  end;
end;

procedure ConnectiveMatrixCreate;
var
  i, j, num : integer;
begin
  num := StationListGetSize - 1;
  SetLength(connectMatrix, StationListGetSize - 1);
  for i := 0 to num do
  begin
    SetLength(connectMatrix[i], StationListGetSize - 1);
    for j := 0 to num do
    begin
      connectMatrix[i,j].bus := nil;
      connectMatrix[i,j].trolBus := nil;
      connectMatrix[i,j].tram := nil;
      connectMatrix[i,j].metro := nil;
      connectMatrix[i,j].time := MAX_TIME;
      connectMatrix[i,j].distance := 0;
    end;
  end;

  ConnectiveMatrixFillTraffic;
  ConnectiveMatrixFillLinks;
end;

function GetStationPnt(num : integer) : PTStationList;
var
  pnt : PTStationList;
begin
  pnt := stationList;
  while (pnt <> nil) and (pnt^.num <> num) do pnt := pnt^.next;
  Result := pnt;
end;

//******************************************************************************
//******************************************************************************
function GetAnswer(start : boolean) : PTStationList;
var
  num : integer;
begin
  if start then write (#13, #10'¬ведите номер исходной точки: ')
  else write (#13, #10'¬ведите номер пункта назначени€: ');

  Readln(num);
  Result := GetStationPnt(num);
end;

procedure PrintList(var list : PTStationList);
begin
  if list^.prev <> nil then PrintList(list^.prev);
  Writeln (list^.name,' -> ');
end;
//******************************************************************************
//******************************************************************************

function PointInList(var main, elem : PTStationList) : boolean;
var
  pnt : PTStationList;
begin
  pnt := main;
  while (pnt <> nil) and (pnt <> elem) do pnt := pnt^.prev;
  Result := pnt <> nil;
end;

procedure PrintList1;
var
  pnt : PTStationList;
begin
  pnt := stop;
  while pnt <> nil do
  begin
    writeln(pnt^.name);
    pnt := pnt^.prev;
  end;
end;

procedure FindFuckingRoute(var start : PTStationList; timer : double);
var
  num, i : integer;
  pnt : PTStationList;
begin
  if (start <> stop) and (timer < maxTime * 1.5) then
  begin
    if FinalPointInTrace(start, timer) then exit;
    num := StationListGetSize - 1;
    for i := 0 to num do
    begin
      pnt := GetStationPnt(i + 1);
      if (StationsTired(start^.num - 1, i)) and not PointInList(start, pnt) then
        CheckTransport(start, pnt, timer);
    end;
  end else
  if (timer < maxTime * 1.5) then
  begin //SaveTrace(timer);
    writeln;
    PrintList1;
    maxTime := timer;
  end;
end;

function FinalPointInTrace(var start : PTStationList; var timer : double) : boolean;
var
  trace : PTTrace;
  distance : double;
  transportType : byte;
begin
  Result := false;
  trace := StationEnableOnTransport(start, stop, transportType);
  if (trace <> nil) and (transportType <> 0) then
  begin
    Result := true;
    connectMatrix[trace^.data^.num - 1, trace^.next^.data^.num - 1].time := GetOverallTime(trace^.data, trace^.next^.data, transportType);
    trace^.next^.data^.prev := trace^.data;
    FindFuckingRoute(trace^.next^.data, timer + connectMatrix[trace^.data^.num - 1, trace^.next^.data^.num - 1].time);
  end;
end;

function GetOverallTime(start, stop : PTStationList; transportType : byte) : double;
begin
  case transportType of
    1, 2 :
      Result := GetDistance(start^.X, start^.Y, stop^.X, stop^.Y) / BUS_SPEED;
    3 :
      Result := GetDistance(start^.X, start^.Y, stop^.X, stop^.Y) / TRAM_SPEED;
    4 :
      Result := GetDistance(start^.X, start^.Y, stop^.X, stop^.Y) / METRO_SPEED;
    0 :
      Result := GetDistance(start^.X, start^.Y, stop^.X, stop^.Y) / ON_FOOT_SPEED;
  end;
end;

function GetStartStation(trace : PTTrace; station : PTStationList) : PTTrace;
begin
  while trace^.data <> station do trace := trace^.next;
  Result := trace;
end;

function StationBetween(start, fin : PTTrace; stat : PTStationList) : boolean;
begin
  Result := False;
  if start^.enable and not start^.next^.enable then start := start^.next;
  while (start <> nil) and (start^.enable = fin^.enable) and not Result do
  begin
    Result := stat = start^.data;
    start := start^.next;
  end;
end;

function GetFinStation(station : PTTrace) : PTTrace;
var
  pnt : PTTrace;
begin
  if station^.enable and not station^.next^.enable then station := station^.next;
  pnt := station;
  while (pnt^.next <> nil) and (station^.enable = pnt^.next^.enable) do pnt := pnt^.next;
  Result := pnt;
end;

function StationEnableOnBus(stat1, stat2 : PTStationList) : PTTrace;
var
  head : PTTraffic;
  finStation, startStation : PTTrace;
begin
  Result := nil;
  if stat1^.bus <> nil then
  begin
    head := stat1^.bus;
    while head <> nil do
    begin
      startStation := GetStartStation(head^.data^.trace, stat1);
      finStation := GetFinStation(startStation);
      if StationBetween(startStation, finStation, stat2) then Result := startStation;
      if Result <> nil then exit;
      head := head^.next;
    end;
  end;
  if (Result = nil) and (stat1^.trolBus <> nil) then
  begin
    head := stat1^.trolBus;
    while head <> nil do
    begin
      startStation := GetStartStation(head^.data^.trace, stat1);
      finStation := GetFinStation(startStation);
      if StationBetween(startStation, finStation, stat2) then Result := startStation;
      if Result <> nil then exit;
      head := head^.next;
    end;
  end;
end;

function StationEnableOnTram(stat1, stat2 : PTStationList) : PTTrace;
var
  head : PTTraffic;
  startStation, finStation : PTTrace;
begin
  Result := nil;
  if stat1^.tram <> nil then
  begin
    head := stat1^.tram;
    while head <> nil do
    begin
      startStation := GetStartStation(head^.data^.trace, stat1);
      finStation := GetFinStation(startStation);
      if StationBetween(startStation, finStation, stat2) then Result := startStation;
      if Result <> nil then exit;
      head := head^.next;
    end;
  end;
end;

function StationEnableOnMetro(stat1, stat2 : PTStationList) : PTTrace;
var
  head : PTTraffic;
  startStation, finStation : PTTrace;
begin
  Result := nil;
  if stat1^.metro <> nil then
  begin
    head := stat1^.metro;
    while head <> nil do
    begin
      startStation := GetStartStation(head^.data^.trace, stat1);
      finStation := GetFinStation(startStation);
      if StationBetween(startStation, finStation, stat2) then Result := startStation;
      if Result <> nil then exit;
      head := head^.next;
    end;
  end;
end;

function StationEnableOnTransport(pnt1, pnt2 : PTStationList; out transportType : byte) : PTTrace;
begin
  transportType := 0;
  Result := StationEnableOnBus(pnt1, pnt2);
  if Result <> nil then
  begin
    transportType := 1;
    exit
  end else
  Result := StationEnableOnTram(pnt1, pnt2);
  if Result <> nil then begin
    transportType := 3;
    exit
  end else
  Result := StationEnableOnMetro(pnt1, pnt2);
  if Result <> nil then transportType := 4;
end;

procedure CheckTransport(var start, checkPoint : PTStationList; timer : double);
begin
  if connectMatrix[start^.num - 1, checkPoint^.num - 1].bus <> nil then
  begin
    if checkTime(start, checkPoint, timer, GetType(start^.bus^.data^.specif)) then
      checkPoint^.prev := start;
  end
  else if connectMatrix[start^.num - 1, checkPoint^.num - 1].TrolBus <> nil then
  begin
    if checkTime(start, checkPoint, timer, GetType(start^.trolBus^.data^.specif)) then
      checkPoint^.prev := start;
  end
  else if connectMatrix[start^.num - 1, checkPoint^.num - 1].tram <> nil then
  begin
    if checkTime(start, checkPoint, timer, GetType(start^.tram^.data^.specif)) then
      checkPoint^.prev := start;
  end
  else if connectMatrix[start^.num - 1, checkPoint^.num - 1].metro <> nil then
  begin
    if checkTime(start, checkPoint, timer, GetType(start^.metro^.data^.specif)) then
      checkPoint^.prev := start;
  end
  else
  begin
    if checkTime(start, checkPoint, timer, 0) then
      checkPoint^.prev := start;
  end;
end;

function CheckTime(var start, checkPoint : PTStationList; var timer : double; specif : byte) : boolean;
var
  time : double;
begin
  time := GetOverallTime(start, checkPoint, specif);
  if connectMatrix[start^.num - 1, checkPoint^.num - 1].time >= timer + time then
  begin
    connectMatrix[start^.num - 1, checkPoint^.num - 1].time := timer + time;
    checkPoint^.prev := start;
    FindFuckingRoute(checkPoint, timer + time);
    Result := true;
  end else Result := false;
end;

function StationsTired(i, j : integer) : boolean;
begin
  Result := connectMatrix[i, j].distance <> 0;
end;














procedure SaveTrace(time : double);
var
  trace, temp : PTTrace;
  pnt : PTStationList;
begin
  if traceTable = nil then
  begin
    new(traceTable);
    //traceTable^.data := nil;
    while pnt <> nil do
  begin
    new(traceTable^.data);
    temp^.data := pnt;
    temp^.next := traceTable^.data;
    traceTable^.data := temp;
    pnt := pnt^.prev;
  end;
    traceTable^.time := time;
  end else
  if traceTable^.next = nil then
  begin
    new(traceTable^.next);
    //traceTable^.next^.data := nil;
    while pnt <> nil do
  begin
    new(temp);
    temp^.data := pnt;
    temp^.next := traceTable^.next^.data;
    traceTable^.next^.data := temp;
    pnt := pnt^.prev;
  end;
    traceTable^.next^.time := time;
  end else
  if time < traceTable^.time then
  begin
    //TraceClear(traceTable^.data);
    traceTable^.data := nil;
    while pnt <> nil do
  begin
    new(temp);
    temp^.data := pnt;
    temp^.next := traceTable^.data;
    traceTable^.data := temp;
    pnt := pnt^.prev;
  end;
    traceTable^.time := time;
  end else
  if time < traceTable^.next^.time then
  begin
    //TraceClear(traceTable^.next^.data);
    traceTable^.next^.data := nil;
    while pnt <> nil do
  begin
    new(temp);
    temp^.data := pnt;
    temp^.next := traceTable^.next^.data;
    traceTable^.next^.data := temp;
    pnt := pnt^.prev;
  end;
    traceTable^.next^.time := time;
  end;
  if time < maxTime then maxTime := time;
end;

procedure CopyStackToTraceTable(var head : PTTrace);
var
  pnt : PTStationList;
  temp : PTTrace;
begin
  pnt := stop;
  while pnt <> nil do
  begin
    new(temp);
    new(temp^.data);
    temp^.data := pnt;
    temp^.next := head;
    head := temp;
    pnt := pnt^.prev;
  end;
end;

procedure TraceClear(var stack : PTTrace);
begin
  if stack <> nil then
  begin
    TraceClear(stack^.next);
    Dispose(stack);
    stack := nil;
  end;
end;

end.
