unit Convert;

interface

uses
  Math, System.SysUtils;

function StrHexToInt(s: Ansistring): LongWord;
function HexToStr(Num: LongWord; Len: integer): string;

implementation

function StrHexToInt(s: Ansistring): LongWord;
var
  i, j: integer;
  l, nasobitel: LongInt;
begin
  l := 0;
  nasobitel := length(s);

  for i := 1 to length(s) do
  begin
    if (Ord(s[i]) <= Ord('F')) and (Ord(s[i]) >= Ord('A')) then
    begin
      j := Ord(s[i]) - Ord('A') + 10;
      l := l + (j * Trunc(power(16, nasobitel - 1)));
    end
    else
    begin
      if (Ord(s[i]) <= Ord('9')) and (Ord(s[i]) >= Ord('0')) then
      begin
        j := Ord(s[i]) - Ord('0');
        l := l + (j * Trunc(power(16, nasobitel - 1)));
      end
      else
      begin
        Result := 0;
        Exit;
      end;
    end;

    nasobitel := nasobitel - 1;

  end;
  Result := l;
end;

function HexToStr(Num: LongWord; Len: integer): string;
var
  s: string;
  i, j: integer;
begin
  s := Format('%x', [Num]);
  i := length(s);
  for j := 1 to Len - i do
    s := '0' + s;

  Result := s;
end;

end.
