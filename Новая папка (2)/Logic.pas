unit Logic;

interface

uses
  System.SysUtils, FileUnit, Math;

const
  MAX_DISTANCE = $FFFF;

type
  TLinks = record
    bus : PTTraffic;
    trolBus : PTTraffic;
    tram : PTTraffic;
    metro : PTTraffic;
    distance : double;
  end;

  PTTraceStack = ^TTraceStack;
  TTraceStack = record
    station : PTStationList;
    prev : PTTraceStack;
  end;

  PTTraceTable = ^TTraceTable;
  TTraceTable = record
    data : PTTraceStack;
    count : integer;
    distance : double;
    next : PTTraceTable;
  end;

var
  useBus, useTrol, useTram, useMetro : boolean;
  traceTable : PTTraceTable;
  connectMatrix : array of array of TLinks;

procedure ConnectiveMatrixCreate;
procedure TraceStackAddPoint(station : PTStationList);
procedure TraceStackExcludePoint;
procedure TraceTableAdd;
procedure FindRoute;
function GetAnswer(start : boolean) : PTStationList;
function GetDistance(latitude1, longitude1, latitude2, longitude2 : double) : double;
function GetStationPnt(num : integer) : PTStationList;

implementation

var
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

function CheckDoubleStations(var pnt1, pnt2 : PTStationList) : boolean;
var
  i : integer;
begin
  i := 0;
  while (i <= High(pnt1^.name)) and (pnt1^.name[i] <> ':') and (pnt2^.name[i] <> ':')
  and (AnsiLowerCase(pnt1^.name[i]) = AnsiLowerCase(pnt2^.name[i])) do inc(i);
  if (pnt1^.name[i] = ':') and (pnt1^.name[i] = ':') then Result := true
  else Result := false;
end;

function CheckDistance (var pnt1, pnt2 : PTStationList) : boolean;
begin
  Result := GetDistance(pnt1^.X, pnt1^.Y, pnt2^.X, pnt2^.Y) < 200;
end;

function ConnectiveMatrixPointsTired(pnt1, pnt2 : PTStationList) : boolean;
var
  i, j, num : integer;
begin
  if pnt1 <> pnt2 then
  begin
    Result := false;
    num := StationListGetSize - 1;
    Result := (connectMatrix[pnt1^.num - 1, pnt2^.num - 1].bus <> nil) or
    (connectMatrix[pnt1^.num - 1, pnt2^.num - 1].trolBus <> nil) or
    (connectMatrix[pnt1^.num - 1, pnt2^.num - 1].tram <> nil) or
    (connectMatrix[pnt1^.num - 1, pnt2^.num - 1].metro <> nil) or
    (connectMatrix[pnt2^.num - 1, pnt1^.num - 1].bus <> nil) or
    (connectMatrix[pnt2^.num - 1, pnt1^.num - 1].trolBus <> nil) or
    (connectMatrix[pnt2^.num - 1, pnt1^.num - 1].tram <> nil) or
    (connectMatrix[pnt2^.num - 1, pnt1^.num - 1].metro <> nil);

    if not Result then Result := CheckDoubleStations(pnt1, pnt2);
    if not Result then Result := CheckDistance(pnt1, pnt2);
  end else Result := false;
end;

procedure ConnectiveMatrixFillTraffic;
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
              AddTransport(connectMatrix[pnt1^.data^.num - 1, pnt2^.data^.num - 1].bus, mainPnt);
          2 :
            if useTrol then
              AddTransport(connectMatrix[pnt1^.data^.num - 1, pnt2^.data^.num - 1].trolBus, mainPnt);
          3 :
            if useTram then
              AddTransport(connectMatrix[pnt1^.data^.num - 1, pnt2^.data^.num - 1].tram, mainPnt);
          4 :
            if useMetro then
              AddTransport(connectMatrix[pnt1^.data^.num - 1, pnt2^.data^.num - 1].metro, mainPnt);
          0 : Halt;
        end;
        pnt2 := pnt2^.next
      end;
      pnt1 := pnt1^.next;
    end;
    mainPnt := mainPnt^.next;
  end;
end;

procedure ConnectiveMatrixFillLinks;
var
  pnt1, pnt2 : PTStationList;
  i, j, k, num : integer;
begin
  pnt1 := stationList^.next;
  pnt2 := stationList^.next^.next;

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
      connectMatrix[i,j].metro:= nil;
      connectMatrix[i,j].distance:= 0;
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

procedure ConnectiveMatrixWalk(start, stop : PTStationList; const num : integer);
var
  i : integer;
  pnt : PTStationList;
begin
  TraceStackAddPoint(start);
  if start <> stop then
  begin
    for i := 0 to num do
    begin
      pnt := GetStationPnt(i + 1);
      if (connectMatrix[start^.num - 1, i].distance <> 0) and not pnt^.used then
      begin
        pnt^.used := true;
        ConnectiveMatrixWalk(pnt, stop, num);
      end;
    end;
  end
  else TraceTableAdd;
  TraceStackExcludePoint;
end;

procedure FindRoute;
var
  start, stop : PTStationList;
  num : integer;
begin
  useBus := true;
  useTrol := true;
  useTram := true;
  useMetro := true;
  CreateStationList;
  CreateTransportList;
  ConnectiveMatrixCreate;
  start := GetAnswer(true);
  start^.used := true;
  stop := GetAnswer(false);
  num := StationListGetSize - 1;
  if (start <> nil) and (stop <> nil) then
    ConnectiveMatrixWalk(start, stop, num);
end;
//******************************************************************************
//******************************************************************************
function GetAnswer(start : boolean) : PTStationList;
var
  num : integer;
  pnt : PTStationList;
begin
  if start then write (#13, #10'¬ведите исходную точку: ')
  else write (#13, #10'¬ведите пункт назначени€: ');

  Readln(num);
  Result := GetStationPnt(num);
end;
//******************************************************************************
//******************************************************************************

function TraceStackGetSize(stack : PTTraceStack) : integer;
begin
  if stack <> nil then Result := 1 + TraceStackGetSize(stack^.prev)
  else Result := 0;
end;

function TraceStackGetDistance(var stack : PTTraceStack) : double;
begin
  if stack^.prev <> nil then
    Result := TraceStackGetDistance(stack^.prev) +
    connectMatrix[stack^.station^.num - 1, stack^.prev^.station^.num - 1].distance
  else Result := 0;
end;

procedure TraceStackCopy(var stack : PTTraceStack);
var
  pnt, temp : PTTRaceStack;
begin
  pnt := traceStack;
  while pnt <> nil do
  begin
    new(temp);
    temp^.prev := stack;
    stack := temp;
    stack^.station := pnt^.station;
    pnt := pnt^.prev;
  end;
end;

procedure TraceTableAdd;
var
  pnt : PTTraceTable;
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
  end;
  pnt^.data := nil;
  TraceStackCopy(pnt^.data);
  pnt^.count := TraceStackGetSize(pnt^.data);
  pnt^.distance := TraceStackGetDistance (pnt^.data);
  pnt^.next := nil
end;

procedure TraceStackAddPoint(station : PTStationList);
var
  head, temp : PTTraceStack;
begin
  if traceStack = nil then
  begin
    new(traceStack);
    traceStack^.prev := nil;
  end else
  begin
    new(head);
    head^.prev := traceStack;
    traceStack := head;
  end;
  traceStack^.station := station;
  //writeln(TraceStackGetSize(traceStack),' + ',station^.name);
end;

procedure TraceStackExcludePoint;
var
  temp : PTTraceStack;
begin
  //writeln(TraceStackGetSize(traceStack),' - ',traceStack^.station^.name);
  temp := traceStack;
  traceStack := traceStack^.prev;
  Dispose(temp);
end;

end.
