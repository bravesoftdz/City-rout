unit FileUnit;

interface

uses System.SysUtils;

type
  TMas = array [1..100] of integer;
  TType = string[2];
//******************************************************************************
//--------------------����, ������������ ��� ������ �� �����-------------------*
//******************************************************************************
  TStationName = record              //��� ��� ������ �� ����� �������� �������
    num : integer;
    name : string[50];
  end;
  TStationInfo = record              //��� ��� ������ �� ����� ������ �� ��������
    num : integer;
    X : double;
    Y : double;
  end;
  TTransportInfo = record            //��� ��� ������ �� ����� ������ �� ����������
    specif : TType;
    num : string[5];
    trace : TMas;
  end;
  TMetro = record                    //��� ��� ������ �� ����� ������ �� ���� ������
    name : string[30];
    X : double;
    Y : double;
  end;
//******************************************************************************
//------------------------����, ������������ ��� ������------------------------*
//******************************************************************************
  PTStationList = ^TStationList;
  PTTransportList = ^TTransporList;
  PTMetroList = ^TMetroList;
  PTTraffic = ^TTraffic;
  PTTrace = ^TTrace;

  TTraffic = record                  //������ ��������, ����������� ����� �������
    data : PTTransportList;
    next : PTTraffic;
  end;
  TTrace = record                    //������ �������, ����� ������� �������� ���������
    data : PTStationList;
    next : PTTrace;
  end;
  TStationList = record              //����� ���������� � ������ �������
    num : integer;
    name : string[50];
    X : double;
    Y : double;
    bus : PTTraffic;
    trolBus : PTTraffic;
    tram : PTTraffic;
    metro : PTTraffic;
    used : boolean;
    next : PTStationList;
  end;
  TTransporList = record             //����� ���������� � ������ ������� ����������
    specif : TType;
    num : string[5];
    trace : PTTrace;
    next : PTTransportList;
  end;
  TMetroList = record                //���������� � �������� �����
    name : string[30];
    X : double;
    Y : double;
    next : PTMetroList;
  end;

const
  STATION_NAME_FILE = 'StationName.crtsn';
  STATION_INFO_FILE = 'StationInfo.crts';
  TRANSPORT_FILE = 'trace.crttr';
  METRO_FILE = 'metro.crtmm';

var
  stationList : PTStationList;          //������ �������
  transportList : PTTransportList;      //������ ����������
  metroList : PTMetroList;              //������ ������� �����

//��������� ������ �� ����� � �������� ������ �������
procedure CreateStationList;
//��������� ������ �� ����� � �������� ������ ����������
procedure CreateTransportList;
//���������, ��������� ������ �� ���������� ����� ������� ������� ����������
//� ���������� ���� (.bus, .trolBus, .tram);
procedure FillTraffic(elem : PTTransportList);
//��������� ����������������� �������� ����������������� ������ ����������,
//����������� ����� �������
procedure AddTransport(var head : PTTraffic; elem : PTTransportList);
//���������, ��������� ������ �� �������, ����� ������� �������� ������� ����������
procedure FillTrace (var head : PTTrace; var mas : TMas);
//������� ���������� ������������ ����� ������ �� ����, ����� ��� ����������
//�������� �� ����: 1 - �������, 2 - ����������, 3 - �������,  - ������
function GetType(specif : TType) : byte;
function StationListGetSize : integer;

implementation

procedure CreateStationList;
var
  head : PTStationList;
  tempName : TStationName;
  tempInfo : TStationInfo;
  StatNameFile : file of TStationName;
  StatInfoFile : file of TStationInfo;
  MetroInfoFile : file of TMetro;
begin
  AssignFile (StatNameFile, STATION_NAME_FILE);
  AssignFile (StatInfoFile, STATION_INFO_FILE);
  AssignFile (MetroInfoFile, METRO_FILE);

  if FileExists(STATION_NAME_FILE) and FileExists(STATION_INFO_FILE) then
  begin
    Reset(StatNameFile);
    Reset(StatInfoFile);
    New (stationList);
    head := stationList;
    while (not EOF (StatNameFile)) and (not EOF (StatNameFile)) do
    begin
      Read(StatNameFile, tempName);
      Read(StatInfoFile, tempInfo);
      new (head^.next);
      head := head^.next;
      head^.num := tempName.num;
      head^.name := tempName.name;
      head^.X := tempInfo.X;
      head^.Y := tempInfo.Y;
      head^.bus := nil;
      head^.trolBus := nil;
      head^.tram := nil;
      head^.metro := nil;
      head^.used := false;
      head^.next := nil;
    end;
    closeFile(StatNameFile);
    closeFile(StatInfoFile);
  end;
end;

procedure CreateTransportList;
var
  head : PTTransportList;
  temp : TTransportInfo;
  TranspFile : file of TTransportInfo;
begin
  AssignFile (TranspFile, TRANSPORT_FILE);
  if FileExists (TRANSPORT_FILE) then
  begin
    Reset(TranspFile);
    New (transportList);
    head := transportList;
    while not EOF(TranspFile) do
    begin
      new(head^.next);
      head := head^.next;
      Read(TranspFile, temp);
      head^.specif := temp.specif;
      head^.num := temp.num;
      head^.next := nil;
      head^.trace := nil;
      FillTrace(head^.trace, temp.trace);
      FillTraffic(head);
    end;
    CloseFile(transpFile);
  end;
end;

procedure FillTrace (var head : PTTrace; var mas : TMas);
var
  elem : PTTrace;
  pnt : PTStationList;
  i, j : integer;
  flag, direct : boolean;
begin
  i := 1;
  elem := nil;
  flag := true;
  repeat
    while mas[i] <> 0 do
    begin
      if head <> nil then
      begin
        new (elem^.next);
        elem := elem^.next;
      end else
      begin
        New (head);
        elem := head;
      end;

      pnt := stationList;
      for j := 1 to mas[i] do pnt := pnt^.next;
      elem^.data := pnt;
      elem^.next := nil;
      inc(i);
    end;
    inc(i);
    flag := not flag;
  until flag;
end;

function GetType(specif : TType) : byte;
begin
  if AnsiLowerCase(specif) = '�' then Result := 1 else
  if AnsiLowerCase(specif) = '�' then Result := 2 else
  if AnsiLowerCase(specif) = '��' then Result := 3 else
  if AnsiLowerCase(specif) = '�' then Result := 4 else
  Result := 0;
end;

procedure AddTransport(var head : PTTraffic; elem : PTTransportList);
var
  pnt : PTTraffic;
begin
  if head = nil then
  begin
    new(head);
    head^.data := elem;
    head^.next := nil;
  end else
  begin
    pnt := head;
    while pnt^.next <> nil do pnt := pnt^.next;
    new(pnt^.next);
    pnt := pnt^.next;
    pnt^.data := elem;
    pnt^.next := nil;
  end;
end;

procedure FillTraffic(elem : PTTransportList);
var
  pnt : PTTrace;
  num : byte;
begin
  num := GetType(elem^.specif);
  pnt := elem^.trace;
  while pnt <> nil do
  begin
    case num of
      1 : AddTransport(pnt^.data^.bus, elem);
      2 : AddTransport(pnt^.data^.trolBus, elem);
      3 : AddTransport(pnt^.data^.tram, elem);
      4 : AddTransport(pnt^.data^.metro, elem);
      0 : Halt;                         //������� ���������� ����� �� ���������
    end;
    pnt := pnt^.next;
  end;
end;

function StationListGetSize : integer;
var
  i : integer;
  pnt : PTStationList;
begin
  i := 0;
  pnt := stationList;
  while pnt <> nil do
  begin
    pnt := pnt^.next;
    inc(i);
  end;
  Result := i - 1;
end;

end.
