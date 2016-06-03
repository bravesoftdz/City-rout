program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logic,
  FileUnit;

var
  start, stop : PTStationList;
  head : PTTraceStack;

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
  useBus := false;
  useTrol := false;
  useTram := false;
  useMetro := false;
  CreateStationList;
  CreateTransportList;
  PrintStations;
  PrepareData;
  
  Readln;
end.
