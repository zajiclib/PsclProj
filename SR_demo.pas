unit SR_demo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, ComPort, IniFiles, Vcl.ComCtrls, Convert;

type
  TfrmMain = class(TForm)
    imgCoil: TImage;
    tPort1Move: TTimer;
    btnCoil: TButton;
    imgArm: TImage;
    btnMinus: TButton;
    btnPlus: TButton;
    imgPrint: TImage;
    btnPrint: TButton;
    tPrint: TTimer;
    imgCut: TImage;
    btnCut: TBitBtn;
    tCut: TTimer;
    imgMeas: TImage;
    Button1: TButton;
    tMeas: TTimer;
    ComPort1: TComPort;
    sbInfo: TStatusBar;
    tPort1Open: TTimer;
    edtCurr: TEdit;
    edtReq: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Button2: TButton;
    Button3: TButton;
    Label3: TLabel;
    Label4: TLabel;
    edtPrintCurr: TEdit;
    edtPrintReq: TEdit;
    ComPort4: TComPort;
    tPort4Open: TTimer;
    edtArm: TEdit;
    tAuto: TTimer;
    ComPort2: TComPort;
    tPort2Open: TTimer;
    btnMode: TButton;
    tIni: TTimer;
    edtLength: TEdit;
    Label5: TLabel;
    btnHome: TButton;
    tHome: TTimer;
    tPort3Move: TTimer;
    ComPort3: TComPort;
    procedure LoadPicture(vName: string; Image: TImage);
    procedure tPort1MoveTimer(Sender: TObject);
    procedure ServeMovePort1;
    procedure ServeMovePort3;
    procedure SetCoilMoving;
    function GetCurrPos(Answer: string; var vX, vY, vZ: integer; var vError: Boolean): Boolean;
    function IsAnswer(Answer, OK: string; var Error: Boolean): Boolean;
    procedure FormCreate(Sender: TObject);
    procedure btnPlusClick(Sender: TObject);
    procedure SetArmPosition(Position: integer);
    procedure btnMinusClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure btnCutClick(Sender: TObject);
    procedure tCutTimer(Sender: TObject);
    procedure tMeasTimer(Sender: TObject);
    procedure Button1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure Button1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure ComPort1AfterOpen(ComPort: TCustomComPort);
    procedure tPort1OpenTimer(Sender: TObject);
    procedure ComPort1Error(ComPort: TCustomComPort; E: EComError; var Action: TComAction);
    procedure ComPort1RxChar(Sender: TObject);
    procedure btnCoilClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ComPort4AfterOpen(ComPort: TCustomComPort);
    procedure tPort4OpenTimer(Sender: TObject);
    procedure ComPort4Error(ComPort: TCustomComPort; E: EComError; var Action: TComAction);
    procedure ComPort4RxChar(Sender: TObject);
    procedure ClearOutBit(Bit: LongWord);
    procedure SetOutBit(Bit: LongWord);
    procedure tAutoTimer(Sender: TObject);
    procedure ComPort2AfterOpen(ComPort: TCustomComPort);
    procedure tPort2OpenTimer(Sender: TObject);
    procedure ComPort2Error(ComPort: TCustomComPort; E: EComError; var Action: TComAction);
    procedure ComPort2RxChar(Sender: TObject);
    procedure btnModeClick(Sender: TObject);
    procedure tIniTimer(Sender: TObject);
    procedure tHomeTimer(Sender: TObject);
    procedure btnHomeClick(Sender: TObject);
    procedure tPort3MoveTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

  CoilNum, ArmNum, PrintNum, CutStep, MeasNum, Com1OpenCount, Com2OpenCount, Com4OpenCount: integer;
  CoilPos, PrintPos, tCoilCount, tPrintCount, PrintCount, CoilSteps, PrintSteps, Analog, ArmCount: integer;
  ArmMin, ArmMax, IniStep, HomeStep, Move1Step: integer;
  CoilMove, PrintMove, PrintClear, PrintClearRun, AutoMode, IniRun: Boolean;
  CoilMoveT: Boolean;
  AdrCom1, AdrCom2, AdrCom3, AnswerPort1, AnswerPort2, AnswerPort3, sCoilSteps, sPrintSteps: string;
  Inputs, PLC_Q, Outputs: LongWord;
  LastCom, LastCom2, LastCom3: char;

const

  MASK_CUT = $00000001; // Q0.0

implementation

{$R *.dfm}
// podprogram vynuluje prislusny vystupni bit

procedure TfrmMain.ClearOutBit(Bit: LongWord);
begin
  PLC_Q := PLC_Q and (not Bit);
end;

// podprogram nastavy prislusny vystupni bit

procedure TfrmMain.SetOutBit(Bit: LongWord);
begin
  PLC_Q := PLC_Q or Bit;
end;

procedure TfrmMain.btnCoilClick(Sender: TObject);
begin
  if AutoMode then
    Exit;

  if btnCoil.Caption = 'Zapnout' then
  begin
    btnCoil.Caption := 'Vypnout';
    // CoilPos := 0;
    // CoilCount := 0;
    // tCoilCount := 0;
    CoilMove := True;
  end
  else
  begin
    btnCoil.Caption := 'Zapnout';
    CoilMove := False;
    // CoilCount := 0;
    // CoilClear := True;
  end;
end;

procedure TfrmMain.btnCutClick(Sender: TObject);
begin
  if AutoMode then
    Exit;

  CutStep := 1;
  tCut.Enabled := True;
end;

procedure TfrmMain.btnHomeClick(Sender: TObject);
begin
  HomeStep := 0;
  tHome.Enabled := True;
end;

procedure TfrmMain.btnMinusClick(Sender: TObject);
begin
  if AutoMode then
    Exit;

  Dec(ArmNum, Round((ArmMax - ArmMin) / 4) + 10);
  if ArmNum < ArmMin then
    ArmNum := ArmMin;

  SetArmPosition(ArmNum);
end;

procedure TfrmMain.btnPlusClick(Sender: TObject);
begin
  if AutoMode then
    Exit;

  Inc(ArmNum, Round((ArmMax - ArmMin) / 4) + 10);

  if ArmNum >= ArmMax then
    ArmNum := ArmMax - 1;

  SetArmPosition(ArmNum);
end;

procedure TfrmMain.btnPrintClick(Sender: TObject);
begin
  if AutoMode then
    Exit;

  if btnPrint.Caption = 'Zapnout' then
  begin
    btnPrint.Caption := 'Vypnout';
    PrintPos := 0;
    PrintMove := True;
    PrintCount := 0;
    tPrintCount := 0;
  end
  else
  begin
    PrintClear := True;
    PrintCount := 0;
    btnPrint.Caption := 'Zapnout';
    PrintMove := False;
  end;
end;

procedure TfrmMain.Button1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  tMeas.Enabled := True;
  // !0L0,1000,0<CR><LF>
end;

procedure TfrmMain.Button1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  tMeas.Enabled := False;
end;

procedure TfrmMain.Button2Click(Sender: TObject);
begin
  ComPort1.WriteUtf8('!' + AdrCom1 + 'A1' + #$0D);
  LastCom := 'A';
end;

procedure TfrmMain.Button3Click(Sender: TObject);
begin
  ComPort1.WriteUtf8('!' + AdrCom1 + 'V1000' + #$0D);
  LastCom := 'V';
end;

procedure TfrmMain.btnModeClick(Sender: TObject);
begin
  if AutoMode then
  begin
    AutoMode := False;
    btnMode.Caption := 'MANUAL';
  end
  else
  begin
    AutoMode := True;
    btnMode.Caption := 'AUTO'
  end;
end;

procedure TfrmMain.ComPort1AfterOpen(ComPort: TCustomComPort);
begin
  sbInfo.Panels[0].Text := 'Port1: opened';
  tPort1Open.Enabled := False;
  IniStep := 0;
  IniRun := True;
  tIni.Enabled := True;
end;

procedure TfrmMain.ComPort1Error(ComPort: TCustomComPort; E: EComError; var Action: TComAction);
begin
  Action := caAbort;
  ComPort1.Close;
  sbInfo.Panels[0].Text := 'Port1: closed';
  tPort1Open.Enabled := True;
end;

procedure TfrmMain.ComPort1RxChar(Sender: TObject);
var
  mEncoding: TEncoding;
  Error: Boolean;
begin
  mEncoding := TEncoding.ASCII;
  AnswerPort1 := ComPort1.Read(mEncoding);

  case LastCom of
    'H':
      begin
        if IsAnswer(AnswerPort1, '8', Error) then
        begin
          if Error then
          begin
            ComPort1.WriteUtf8('!' + AdrCom1 + 'H' + #$0D);
            LastCom := 'H';
          end
          else
          begin
            ComPort1.WriteUtf8('!' + AdrCom1 + 'D' + #$0D);
            LastCom := 'D';
          end;
        end;
      end;
    'N':
      begin
        if AnswerPort1[1] <> '0' then
        begin
          ComPort1.WriteUtf8('!' + AdrCom1 + 'N' + #$0D);
          AnswerPort1 := '';
          LastCom := 'N';
        end;
      end;
    'M':
      begin
        if AnswerPort1[1] <> '0' then
        begin
          ComPort1.WriteUtf8('!' + AdrCom1 + 'VN' + #$0D);
          AnswerPort1 := '';
          LastCom := 'M';
        end;
      end;
    'Y':
      begin
        if AnswerPort1[1] <> '0' then
        begin
          ComPort1.WriteUtf8('!' + AdrCom1 + 'NY0' + #$0D);
          LastCom := 'Y';
        end
        else
        begin
          PrintClearRun := False;
          LastCom := 'Y';
          PrintClear := False;
        end;
      end;
  else
    Error := True;
  end;
end;

procedure TfrmMain.ComPort2AfterOpen(ComPort: TCustomComPort);
begin
  sbInfo.Panels[1].Text := 'Port2: opened';
  tPort2Open.Enabled := False;
  ComPort2.WriteUtf8('!' + AdrCom2 + 'N' + #$0D);
  LastCom2 := 'N';
end;

procedure TfrmMain.ComPort2Error(ComPort: TCustomComPort; E: EComError; var Action: TComAction);
begin
  Action := caAbort;
  ComPort2.Close;
  sbInfo.Panels[1].Text := 'Port2: closed';
  tPort2Open.Enabled := True;
end;

procedure TfrmMain.ComPort2RxChar(Sender: TObject);
var
  mEncoding: TEncoding;
  Error: Boolean;
begin
  mEncoding := TEncoding.ASCII;
  AnswerPort2 := ComPort2.Read(mEncoding);

  case LastCom2 of
    'H':
    begin
    if IsAnswer(AnswerPort2, '8', Error) then
      begin
      if Error then
        begin
        ComPort2.WriteUtf8('!' + AdrCom2 + 'H' + #$0D);
        LastCom2 := 'H';
        end
    else
        begin
          ComPort2.WriteUtf8('!' + AdrCom2 + 'D' + #$0D);
          LastCom2 := 'D';
        end;
      end;
    end;
    'N':
    begin
      if AnswerPort2[1] <> '0' then
        begin
          ComPort2.WriteUtf8('!' + AdrCom2 + 'N' + #$0D);
          LastCom2 := 'N';
        end;
    end;
    'X':
    begin
      if AnswerPort2[1] <> '0' then
      begin
        ComPort2.WriteUtf8('!' + AdrCom2 + 'NX0' + #$0D);
        LastCom2 := 'X';
      end
    else
      begin
        LastCom2 := 'X';
        // CoilClearRun := False;
        // CoilClear := False;
      end;
    end;
    'Y':
      begin
          if AnswerPort2[1] <> '0' then
          begin
            ComPort2.WriteUtf8('!' + AdrCom2 + 'NY0' + #$0D);
            LastCom2 := 'Y';
          end
      else
        begin
          LastCom2 := 'Y';
        // PrintClearRun := False;
        // PrintClear := False;
        end;
      end;
  end;
end;

procedure TfrmMain.ComPort4AfterOpen(ComPort: TCustomComPort);
begin
  sbInfo.Panels[3].Text := 'TUMIO: opened';
  tPort4Open.Enabled := False;
end;

procedure TfrmMain.ComPort4Error(ComPort: TCustomComPort; E: EComError; var Action: TComAction);
begin
  Action := caAbort;
  ComPort4.Close;
  sbInfo.Panels[3].Text := 'TUMIO: closed';
  tPort4Open.Enabled := True;
end;

procedure TfrmMain.ComPort4RxChar(Sender: TObject);
var
  mEncoding: TEncoding;
  s, SIN, SQ, ANQ: string;
  i: integer;
  Error: Boolean;
begin
  mEncoding := TEncoding.ASCII;
  s := ComPort4.Read(mEncoding);

  Error := False;

  i := Pos('PLC_I:', s);
  if i > 0 then
  begin
    SIN := Copy(s, i + 6, 8);
    Inputs := StrHexToInt(SIN);
  end
  else
    Error := True;

  i := Pos('PLC_Q:', s);
  if i > 0 then
  begin
    SQ := Copy(s, i + 6, 8);
    Outputs := StrHexToInt(SQ);
  end
  else
    Error := True;

  i := Pos('AN0:', s);
  if i > 0 then
  begin
    ANQ := Copy(s, i + 4, 4);
    Analog := StrHexToInt(ANQ);
  end
  else
    Error := True;

  if (not Error) then
  begin
    s := 'PLC_Q:' + HexToStr(PLC_Q, 8) + #$0D#$0A;
    ComPort4.WriteUtf8(s);
  end;
end;

procedure TfrmMain.SetArmPosition(Position: integer);
begin
  if (Position >= ArmMin) AND (Position < Round((ArmMax - ArmMin) / 4) + ArmMin) then
    LoadPicture('Rameno0.bmp', imgArm)
  else if (Position >= Round((ArmMax - ArmMin) / 4) + ArmMin) AND (Position < Round((ArmMax - ArmMin) / 4 * 2) + ArmMin) then
    LoadPicture('Rameno10.bmp', imgArm)
  else if (Position >= Round((ArmMax - ArmMin) / 4 * 2) + ArmMin) AND (Position < Round((ArmMax - ArmMin) / 4 * 3) + ArmMin) then
    LoadPicture('Rameno20.bmp', imgArm)
  else if (Position >= Round((ArmMax - ArmMin) / 4 * 3) + ArmMin) AND (Position <= ArmMax) then
    LoadPicture('Rameno30.bmp', imgArm);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  CoilNum := 1;
  PrintNum := 1;
  MeasNum := 1;
  CoilMove := False;
  CoilMoveT := False;
  PrintMove := False;
  ArmNum := ArmMin;
  AutoMode := False;
  IniRun := False;

  ArmNum := ArmMin;

  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Setting.ini');

  CoilSteps := StrToInt(Ini.ReadString('Machine', 'CoilSpeed', '1000')) DIV 2;
  sCoilSteps := IntToStr(CoilSteps);
  PrintSteps := StrToInt(Ini.ReadString('Machine', 'PrintSpeed', '1000')) DIV 2;
  sPrintSteps := IntToStr(PrintSteps);

  ArmMin := StrToInt(Ini.ReadString('Machine', 'ArmMin', '0'));
  ArmMax := StrToInt(Ini.ReadString('Machine', 'ArmMax', '1000'));

  ComPort1.DeviceName := Ini.ReadString('Machine', 'Port1', 'COM1');
  AdrCom1 := Ini.ReadString('Machine', 'AddrPort1', '0');
  Com1OpenCount := StrToInt(Ini.ReadString('Machine', 'Port1OpenCount', '-1'));

  ComPort2.DeviceName := Ini.ReadString('Machine', 'Port2', 'COM2');
  AdrCom2 := Ini.ReadString('Machine', 'AddrPort2', '0');
  Com2OpenCount := StrToInt(Ini.ReadString('Machine', 'Port2OpenCount', '-1'));

  ComPort4.DeviceName := Ini.ReadString('Machine', 'Port4', 'COM3');
  Com4OpenCount := StrToInt(Ini.ReadString('Machine', 'Port4OpenCount', '-1'));

  Ini.Free;
end;

procedure TfrmMain.LoadPicture(vName: string; Image: TImage);
var
  Path: string;
begin
  begin
    Path := ExtractFilePath(Application.ExeName) + 'Pictures\' + vName;
    if FileExists(Path) then
      Image.Picture.LoadFromFile(Path)
    else
      Image.Picture := nil;
  end;
end;

procedure TfrmMain.tPort1OpenTimer(Sender: TObject);
begin
  if (Com1OpenCount > 0) or (Com1OpenCount < 0) then
  begin
    if Com1OpenCount > 0 then
      Dec(Com1OpenCount);
    ComPort1.Open;
    tPort1Open.Enabled := False;
  end
  else
    tPort1Open.Enabled := False;
end;

procedure TfrmMain.tPort2OpenTimer(Sender: TObject);
begin
  if (Com2OpenCount > 0) or (Com2OpenCount < 0) then
  begin
    if Com2OpenCount > 0 then
      Dec(Com2OpenCount);
    ComPort2.Open;
    tPort2Open.Enabled := False;
  end
  else
    tPort2Open.Enabled := False;
end;

procedure TfrmMain.tPort3MoveTimer(Sender: TObject);
begin
  if PrintMove then
  begin
    Inc(tPrintCount);
    if tPrintCount > 3 then
    begin
      Inc(PrintNum);
      if PrintNum > 3 then
        PrintNum := 1;

      LoadPicture('Tampoprint' + IntToStr(PrintNum) + '.bmp', imgPrint);
      tPrintCount := 0;
    end;
  end;

  ServeMovePort3;
end;

procedure TfrmMain.tPort4OpenTimer(Sender: TObject);
begin
  if (Com4OpenCount > 0) or (Com4OpenCount < 0) then
  begin
    if Com4OpenCount > 0 then
      Dec(Com4OpenCount);
    ComPort4.Open;
    tPort4Open.Enabled := False;
  end
  else
    tPort4Open.Enabled := False;
end;

procedure TfrmMain.tPort1MoveTimer(Sender: TObject);
begin
  if CoilMove then
  begin
    Inc(tCoilCount);
    if tCoilCount > 3 then
    begin
      Inc(CoilNum);
      if CoilNum > 3 then
        CoilNum := 1;

      LoadPicture('Civka' + IntToStr(CoilNum) + '.bmp', imgCoil);
      tCoilCount := 0;
    end;
  end;

  ServeMovePort1;
end;

procedure TfrmMain.SetCoilMoving;
begin
  if Analog < (((ArmMax - ArmMin) DIV 2) + ArmMin) then
    CoilMove := True
  else
    CoilMove := False;
end;

procedure TfrmMain.ServeMovePort3;
var
  Cont, Error: Boolean;
  pX, pY, pZ: integer;
  vPrintSteps: string;
begin
  if NOT ComPort3.Active then
    Exit;

  if PrintMove then
  begin

    if PrintMove then
      vPrintSteps := sPrintSteps
    else
      vPrintSteps := '0';

    if PrintCount = 0 then
    begin
      LastCom := 'C'; // <---prvni spusteni
      AnswerPort3 := '';
      ComPort1.WriteUtf8('!' + AdrCom3 + 'C' + vPrintSteps + ',0,0' + #$0D);

      Inc(PrintCount);
      Inc(PrintPos, PrintSteps);
      edtPrintReq.Text := IntToStr(PrintPos);
    end
    else
    begin
      // <----pokracovani komunikace
      if (LastCom3 = 'C') AND IsAnswer(AnswerPort3, '0', Error) then
      begin
        Cont := False;
        AnswerPort3 := '';
        ComPort3.WriteUtf8('!' + AdrCom3 + 'PF' + #$0D);
        LastCom3 := 'P';
      end
      else
      begin
        Cont := False;
        begin
          if GetCurrPos(AnswerPort3, pX, pY, pZ, Error) then
          begin
            if Error then
            begin
              AnswerPort3 := '';
              ComPort3.WriteUtf8('!' + AdrCom3 + 'PF' + #$0D);
              LastCom3 := 'P';
            end
            else
            begin
              edtPrintCurr.Text := IntToStr(pX);
              if (PrintPos - pX < PrintSteps) AND (PrintPos >= pX) then
              begin
                Cont := True;
              end
              else
              begin
                if NOT PrintClear then
                begin
                  AnswerPort3 := '';
                  ComPort3.WriteUtf8('!' + AdrCom3 + 'PF' + #$0D);
                  LastCom3 := 'P';
                end;
              end;
            end;
          end
        end;
      end;

      if Cont then
      begin
        AnswerPort3 := '';
        ComPort1.WriteUtf8('!' + AdrCom3 + 'C' + vPrintSteps + ',0,0' + #$0D);
        LastCom3 := 'C';

        Inc(PrintPos, PrintSteps);
        edtPrintReq.Text := IntToStr(PrintPos);
      end;

    end;
  end;

  if NOT PrintMove AND PrintClear then
  begin
    if AnswerPort3 <> '' then
    begin
      PrintClearRun := True;
      AnswerPort3 := '';
      ComPort3.WriteUtf8('!' + AdrCom3 + 'NX0' + #$0D);
      LastCom := 'X';
    end;
  end;
end;

procedure TfrmMain.ServeMovePort1;
var
  Error: Boolean;
  pX, pY, pZ: integer;
  vCoilSteps: string;
begin
  if NOT ComPort1.Active then
    Exit;

  if CoilMove then
  begin
    if CoilMove then
      vCoilSteps := sCoilSteps
    else
      vCoilSteps := '0';

    if NOT CoilMoveT then
    begin
      Move1Step := 0; // <---prvni spusteni
      CoilPos := 0;
    end;
  end
  else
  begin
    if CoilMoveT then
      Move1Step := 30;
  end;

  case Move1Step of
    0:
      begin
        LastCom := 'C';
        AnswerPort1 := '';
        ComPort1.WriteUtf8('!' + AdrCom1 + 'C' + vCoilSteps + ',0,0' + #$0D);

        Inc(CoilPos, CoilSteps);
        edtReq.Text := IntToStr(CoilPos);
        Move1Step := 10;
      end;
    10:
      begin
        AnswerPort1 := '';
        ComPort1.WriteUtf8('!' + AdrCom1 + 'PF' + #$0D);
        LastCom := 'P';
        Move1Step := 20;
      end;
    20:
      begin
        if GetCurrPos(AnswerPort1, pX, pY, pZ, Error) then
        begin
          if Error then
          begin
            AnswerPort1 := '';
            ComPort1.WriteUtf8('!' + AdrCom1 + 'PF' + #$0D);
            LastCom := 'P';
          end
          else
          begin
            edtCurr.Text := IntToStr(pX);
            if (CoilPos - pX < CoilSteps) AND (CoilPos >= pX) then
            begin
              Move1Step := 0;
            end
            else
            begin
              AnswerPort1 := '';
              ComPort1.WriteUtf8('!' + AdrCom1 + 'PF' + #$0D);
              LastCom := 'P';
            end;
          end;
        end
        else
        begin
          AnswerPort1 := '';
          ComPort1.WriteUtf8('!' + AdrCom1 + 'PF' + #$0D);
          LastCom := 'P';
        end;
      end;
    30:
      begin
        AnswerPort1 := '';
        ComPort1.WriteUtf8('!' + AdrCom1 + 'NX0' + #$0D);
        LastCom := 'X';
        Move1Step := 40;
      end;
    40:
      begin
        if IsAnswer(AnswerPort1, '0', Error) then
        begin
          if Error then
          begin
            AnswerPort1 := '';
            ComPort1.WriteUtf8('!' + AdrCom1 + 'NX0' + #$0D);
            LastCom := 'X';
          end
          else
          begin
            Move1Step := -1;
          end;
        end
        else
        begin
          AnswerPort1 := '';
          ComPort1.WriteUtf8('!' + AdrCom1 + 'NX0' + #$0D);
          LastCom := 'X';
        end;
      end;
  end;

  CoilMoveT := CoilMove;
end;

function TfrmMain.GetCurrPos(Answer: string; var vX, vY, vZ: integer; var vError: Boolean): Boolean;
var
  i, j, X, Y, Z: integer;
  SX, SY, SZ: string;
begin
  i := Pos('0', Answer);
  j := Pos(#$0D, Answer);
  vError := False;

  if (j > 0) then
  begin
    vError := True;
    Result := True;

    if (i > 0) AND (j > i) then
    begin

      j := Pos(',', Answer);
      Delete(Answer, 1, j);

      j := Pos(',', Answer);
      SX := Copy(Answer, i, j - i);
      Delete(Answer, 1, j);

      j := Pos(',', Answer);
      SY := Copy(Answer, 1, j - 1);
      Delete(Answer, 1, j);

      SZ := Copy(Answer, 1, Length(Answer) - 1);

      if (SX = '') OR (SY = '') OR (SZ = '') then
        Exit;

      try
        X := StrToInt(SX);
        Y := StrToInt(SY);
        Z := StrToInt(SZ);
      finally

      end;

      vX := X;
      vY := Y;
      vZ := Z;

      vError := False;
    end;
  end
  else
    Result := False;
end;

function TfrmMain.IsAnswer(Answer, OK: string; var Error: Boolean): Boolean;
var
  i, j: integer;
begin
  i := Pos(OK, Answer);
  j := Pos(#$0D, Answer);

  if j > 0 then
    Result := True
  else
    Result := False;

  if (i > 0) AND (j > 0) AND (j > i) then
    Error := False
  else
    Error := True;
end;

procedure TfrmMain.tAutoTimer(Sender: TObject);
begin
  Inc(ArmCount);
  if ArmCount > 5 then
  begin
    ArmCount := 0;
    edtArm.Text := IntToStr(Analog);

    if AutoMode then
    begin
      SetArmPosition(Analog);
    end;
  end;

  if AutoMode then
  begin
    SetCoilMoving;
    PrintMove := True;
  end
  else begin
    PrintMove := False;
  end;

end;

procedure TfrmMain.tCutTimer(Sender: TObject);
begin
  case CutStep of
    1:
      begin
        CutStep := 5;
        LoadPicture('Strih2.bmp', imgCut);
        SetOutBit(MASK_CUT);
      end;
    5:
      begin
        tCut.Enabled := False;
        LoadPicture('Strih1.bmp', imgCut);
        ClearOutBit(MASK_CUT);
      end;
  end;
end;

procedure TfrmMain.tHomeTimer(Sender: TObject);
var
  Error: Boolean;
begin
  case HomeStep of
    0:
      begin
        ComPort2.WriteUtf8('!' + AdrCom2 + 'L10000,0,1000' + #$0D);
        AnswerPort2 := '';
        HomeStep := 10;
      end;
    10:
      begin
        if IsAnswer(AnswerPort2, '0', Error) then
        begin
          if NOT Error then
          begin
            tHome.Enabled := False;
            Exit;
          end
        end;
        ComPort2.WriteUtf8('!' + AdrCom2 + 'L0,-10000,-1000' + #$0D);
        AnswerPort2 := '';
      end;
  end;
end;

procedure TfrmMain.tIniTimer(Sender: TObject);
var
  Error: Boolean;
begin
  case IniStep of
    0:
      begin
        ComPort1.WriteUtf8('!' + AdrCom1 + 'N' + #$0D); // Nulovani vsech os
        AnswerPort1 := '';
        LastCom := 'N';
        IniStep := 10;
      end;
    10:
      begin
        if IsAnswer(AnswerPort1, '0', Error) then
        begin
          if NOT Error then
          begin
            ComPort1.WriteUtf8('!' + AdrCom1 + 'VN' + #$0D); // vypnuti korekce rychlosti
            AnswerPort1 := '';
            LastCom := 'M';
            IniStep := 20;
          end;
        end;
      end;
    20:
      begin
        if IsAnswer(AnswerPort1, '0', Error) then
        begin
          if NOT Error then
          begin
            ComPort1.WriteUtf8('!' + AdrCom1 + '$480' + #$0D); // nastaveni kratkeho vektoru
            AnswerPort1 := '';
            LastCom := '$';
            IniStep := 30;
          end;
        end;
      end;
    30:
      begin
        if IsAnswer(AnswerPort1, '0', Error) then
        begin
          if NOT Error then
          begin
            ComPort1.WriteUtf8('!' + AdrCom1 + 'B500' + #$0D); // nastaveni kratkeho vektoru
            AnswerPort1 := '';
            LastCom := 'B';
            IniStep := 50;
          end;
        end;
      end;
    50:
      begin
        IniRun := False;
        tIni.Enabled := False;
      end;
  end;
end;

procedure TfrmMain.tMeasTimer(Sender: TObject);
begin
  Dec(MeasNum);
  if MeasNum < 1 then
    MeasNum := 3;

  LoadPicture('Mereni' + IntToStr(MeasNum) + '.bmp', imgMeas);
end;

end.
