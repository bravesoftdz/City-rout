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

  PTResultTable = ^TResultTable;
  TResultTable = record
    station : PTStationList;
    transport : PTTraffic;
    next : PTResultTable;
  end;

var
  useBus, useTrol, useTram, useMetro : boolean;
  resultTable : PTResultTable;

procedure MainLogicProc(var start, stop : PTStationList);
function GetAnswer(start : boolean) : PTStationList;


implementation

const
  BUS_SPEED = 12.7 * 1000 / 60;
  TRAM_SPEED = BUS_SPEED * 0.9;
  METRO_SPEED = 41 * 1000 / 60;
  ON_FOOT_SPEED = 5.288 * 1000 / 60;
  MAX_TIME = $FFFF;

var
  start, stop : PTStationList;
  maxTime : double;
  connectMatrix : array of array of TLinks;

procedure ConnectiveMatrixCreate; forward;
procedure FindFuckingRoute(var start : PTStationList; timer : double); forward;
procedure CheckTransport(var start, checkPoint : PTStationList; timer : double); forward;
procedure SaveResultTrace(var stop : PTStationList); forward;
procedure GetTraffic(trace : PTResultTable); forward;
function GetOverallTime(start, stop : PTStationList; transportType : byte) : double; forward;
function CheckTime(var start, checkPoint : PTStationList; var timer : double; specif : byte) : boolean; forward;
function FinalPointInTrace(var start : PTStationList; var timer : double) : boolean; forward;
function GetDistance(latitude1, longitude1, latitude2, longitude2 : double) : double; forward;
function GetStationPnt(num : integer) : PTStationList; forward;
function StationsTired(i, j : integer) : boolean; forward;
function StationEnableOnTransport(pnt1, pnt2 : PTStationList; out transportType : byte) : PTTrace; forward;

procedure MainLogicProc(var start, stop : PTStationList);
begin
  ConnectiveMatrixCreate;
  maxTime := MAX_TIME;
  FindFuckingRoute(start, 0);
  SaveResultTrace(stop);
  //finalisation;
end;

function GetDistance(latitude1, longitude1, latitude2, longitude2 : double) : double;
const diameter = 12756200 ;
var   dx, dy, dz:double;
begin
  longitude1 := degToRad(longitude1 - longitude2);
  latitude1 := degToRad(latitude1);
  latitude2 := degToRad(latitude2);

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
  if start then write (#13, #10'Введите номер исходной точки: ')
  else write (#13, #10'Введите номер пункта назначения: ');

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
  if (timer < maxTime * 1.5) then maxTime := timer;
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
  startStation, finStation, pnt : PTTrace;
begin
  Result := nil;
  if stat1^.tram <> nil then
  begin
    head := stat1^.tram;
    pnt := stat1^.tram^.data^.trace;
    while head <> nil do
    begin
      startStation := GetStartStation(pnt, stat1);
      finStation := GetFinStation(startStation);
      if StationBetween(startStation, finStation, stat2) then Result := startStation;
      if Result <> nil then exit;
      pnt := head^.data^.trace;
      while pnt^.enable do pnt := pnt^.next;
      head := head^.next;
    end;
  end;
end;

function StationEnableOnMetro(stat1, stat2 : PTStationList) : PTTrace;
var
  head : PTTraffic;
  startStation, finStation, pnt : PTTrace;
begin
  Result := nil;
  if stat1^.metro <> nil then
  begin
    head := stat1^.metro;
    pnt := stat1^.metro^.data^.trace;
    while head <> nil do
    begin
      startStation := GetStartStation(pnt, stat1);
      finStation := GetFinStation(startStation);
      if StationBetween(startStation, finStation, stat2) then Result := startStation;
      if Result <> nil then exit;
      pnt := head^.data^.trace;
      while pnt^.enable do pnt := pnt^.next;
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

procedure PrintTable;
begin
  while resultTable <> nil do
  begin
    write (#13,#10,'До ',resultTable^.station^.name,' ');
    if resultTable^.transport = nil then write(' пешком') else
    while resultTable^.transport <> nil do
    begin
      write (' ',resultTable^.transport^.data^.specif,resultTable^.transport^.data^.num);
      resultTable^.transport := resultTable^.transport^.next;
    end;
    resultTable := resultTable^.next;
  end;
end;

procedure SaveResultTrace(var stop : PTStationList);
var
  temp : PTResultTable;
  count : integer;
begin
  resultTable := nil;
  while stop <> nil do
  begin
    new(temp);
    temp^.station := stop;
    temp^.transport := nil;
    temp^.next := resultTable;
    resultTable := temp;
    stop := stop^.prev;
  end;
  GetTraffic(resultTable);
  PrintTable;
end;

function TransportInTrafficList(traffic: PTTraffic; pnt : PTTransportList) : boolean;
begin
  Result := false;
  while traffic <> nil do
  begin
    Result := traffic^.data = pnt;
    If Result then exit else traffic := traffic^.next;
  end;
end;

function StationInTrace(stat1, stat2 : PTStationList; trace : PTTrace) : boolean;
begin
  while (trace^.data <> stat1) and (trace^.data <> stat2) do
    trace := trace^.next;
  if trace^.data = stat1 then Result := trace^.next^.data = stat2
  else Result := trace^.next^.data = stat1;
end;

procedure AddTransportToResultTable(stat1, stat2 : PTStationList; var traffic : PTTraffic; pnt : PTTraffic);
begin
  while pnt <> nil do
  begin
    if not TransportInTrafficList(traffic, pnt^.data) and StationInTrace(stat1, stat2, pnt^.data^.trace) then
    AddTransport(traffic, pnt^.data);
    pnt := pnt^.next;
  end;
end;

procedure GetTraffic(trace : PTResultTable);
var
  pnt : PTTraffic;
  transportType : byte;
begin
  while trace^.next <> nil do
  begin
    pnt := trace^.station^.bus;
    AddTransportToResultTable(trace^.station, trace^.next^.station, trace^.next^.transport, pnt);
    pnt := trace^.station^.trolBus;
    AddTransportToResultTable(trace^.station, trace^.next^.station, trace^.next^.transport, pnt);
    pnt := trace^.station^.tram;
    AddTransportToResultTable(trace^.station, trace^.next^.station, trace^.next^.transport, pnt);
    pnt := trace^.station^.metro;
    AddTransportToResultTable(trace^.station, trace^.next^.station, trace^.next^.transport, pnt);
    trace := trace^.next;
  end;
end;












end.
