program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logic,
  FileUnit;

var
  i, j, num : integer;
  pnt : PTTraceStack;

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
  ConnectiveMatrixCreate;

  i := 0;
  j := 0;
  PrintStations;
  FindRoute;

  {num := StationListGetSize - 1;
  for i := 0 to num do
    for j := 0 to num do
      if connectMatrix[i,j].distance <> 0 then
      begin
      writeln(GetStationPnt(i + 1)^.name, ' -> ',GetStationPnt(j + 1)^.name);
      readln;
      end;
  Writeln (#13, #10, i, ' ',j);  }
  Readln;
end.
