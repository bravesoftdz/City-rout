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
    weight : double;
    distance : double;
  end;

var
  useBus, useTrol, useTram, useMetro : boolean;
  connectMatrix : array of array of TLinks;
  //i, j : integer;

procedure ConnectiveMatrixCreate;
procedure FindRoute;
function GetAnswer(start : boolean) : PTStationList;
function GetDistance(latitude1, longitude1, latitude2, longitude2 : double) : double;
function GetStationPnt(num : integer) : PTStationList;

implementation

var
  maxCount : integer;

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
  i, j, k, num : integer;
begin
  pnt1 := stationList^.next;
  pnt2 := stationList^.next;

  while pnt1 <> nil do
  begin
    pnt2 := stationList^.next;
    while pnt2 <> nil do
    begin
      if (pnt1 <> pnt2) and ConnectiveMatrixPointsTired(pnt1, pnt2) then
      begin
        connectMatrix[pnt1^.num - 1, pnt2^.num - 1].weight :=
        GetDistance(pnt1^.X, pnt1^.Y, pnt2^.X, pnt2^.Y);
        connectMatrix[pnt2^.num - 1, pnt1^.num - 1].weight :=
        connectMatrix[pnt1^.num - 1, pnt2^.num - 1].weight;
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
      connectMatrix[i,j].weight := MIN_DISTANCE;
      connectMatrix[i,j].distance := MAX_DISTANCE;
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
  pnt : PTStationList;
begin
  if start then write (#13, #10'Введите исходную точку: ')
  else write (#13, #10'Введите пункт назначения: ');

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

procedure Dijkstra(var prev, last : PTStationList; distance : double; count : integer);
var
  i, num : integer;
  pnt : PTStationList;
begin
  if (prev <> last) and (count * 2 <= maxCount)   then
  begin
    num := High(connectMatrix);
    for i := 0 to num do
    begin
      pnt := GetStationPnt(i + 1);
      if (pnt <> prev) and not PointInList(prev, pnt) and
      (connectMatrix[prev^.num - 1, i].weight <> MIN_DISTANCE) and
      (distance + connectMatrix[prev^.num - 1, i].weight <
      connectMatrix[prev^.num - 1, i].distance) then
      begin
        connectMatrix[prev^.num - 1, i].distance :=
        distance + connectMatrix[prev^.num - 1, i].weight;
        pnt.prev := prev;
        //writeln(prev^.name);
        //Readln;
        Dijkstra(pnt, last, connectMatrix[prev^.num - 1, i].distance, count + 1);
      end;
    end
  end
  else if (count * 2 <= maxCount) then
  begin
    if distance + connectMatrix[prev^.num - 1, last^.num - 1].weight <
    connectMatrix[prev^.num - 1, last^.num - 1].distance then
    begin
      connectMatrix[prev^.num - 1, last^.num - 1].distance :=
      distance + connectMatrix[prev^.num - 1, last^.num - 1].weight;
      writeln('Конец найден ', connectMatrix[prev^.num - 1, last^.num - 1].distance : 0 : 3);
      Writeln(#13,#10);
      PrintList(last);
      maxCount := count;
    end;
  end;
end;

procedure FindRoute;
var
  start, last : PTStationList;
  num : integer;
begin
  start := GetAnswer(true);
  last := GetAnswer(false);
  maxCount := StationListGetSize * 2;
  Dijkstra(start, last, 0, 0);
end;

end.
