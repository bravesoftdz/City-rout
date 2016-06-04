program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Logic, FileUnit;

var
  i, j, num : integer;
  pnt : PTTransportList;

procedure PrintStations;
var
  pnt : PTStationList;
begin
  pnt := stationList^.next;
  while pnt <> nil do
  begin
    writeln(pnt^.num,'  ',pnt^.name);
    pnt := pnt^.next;
  end;
end;

begin
  useBus := true;
  useTrol := true;
  useTram := true;
  useMetro := true;
  CreateStationList;
  CreateTransportList;
  ConnectiveMatrixCreate;



  PrintStations;
  //FindRoute;
  start := GetAnswer(true);
  stop := GetAnswer(false);
  maxTime := MAX_TIME;
  FindFuckingRoute(start, 0);
  writeln ('Завершено!');

 { while traceTable^.data <> nil do
  begin
    Writeln(traceTable^.data^.data^.name);
    traceTable^.data := traceTable^.data^.next;
  end;       }


 { num := StationListGetSize - 1;
  for i := 0 to num do
    for j := 0 to num do
      if connectMatrix[i,j].time = 0 then
      writeln(GetStationPnt(i + 1)^.name, '  ',GetStationPnt(j + 1)^.name); }
  {writeln(#13,#10);
  write('   ');
  for i := 99 to 112 do write(i : 4);
  writeln;
  for i := 99 to 112 do
  begin
    write(i : 3);
    for j := 99 to 112 do
      if connectMatrix[i,j].weight <> 0 then write('   1')
      else write('   0');
    writeln;
  end;}

  {stationList := stationList^.next;
  while stationList <> nil do
  begin
    Write(stationList^.num, ' ');
    while stationList^.bus <> nil do
    begin
      write(' ',stationlist^.bus^.data^.specif, stationlist^.bus^.data^.num);
      stationList^.bus := stationList^.bus^.next;
    end;
    while stationList^.trolbus <> nil do
    begin
      write(' ',stationlist^.trolbus^.data^.specif, stationlist^.trolbus^.data^.num);
      stationList^.trolbus := stationList^.trolbus^.next;
    end;
    while stationList^.tram <> nil do
    begin
      write(' ',stationlist^.tram^.data^.specif, stationlist^.tram^.data^.num);
      stationList^.tram := stationList^.tram^.next;
    end;
    while stationList^.metro <> nil do
    begin
      write(' ',stationlist^.metro^.data^.specif, stationlist^.metro^.data^.num);
      stationList^.metro := stationList^.metro^.next;
    end;
    stationList := stationList^.next;
    writeln;
  end; }
  Readln;
end.
