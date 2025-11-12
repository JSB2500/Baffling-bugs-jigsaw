unit UMain;

// Copyright JSB Medical Systems 2000.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UData,
  StdCtrls, UControls, UTypes, ComCtrls, UGeneral, UGeneralVCL, UHighResTimer;

type
  TMain = class(TForm)
    InitialiseButton: TButton;
    OutputControl: TScrollBoxWithCanvas;
    PieceIndexUpDownContro: TUpDown;
    PieceIndexControl: TEditInteger;
    TestPiecesControl: TCheckBox;
    GroupBox1: TGroupBox;
    Rotate0Control: TRadioButton;
    Rotate90Control: TRadioButton;
    Rotate180Control: TRadioButton;
    Rotate270Control: TRadioButton;
    SolveButton: TButton;
    StopButton: TButton;
    Label1: TLabel;
    CurrentPieceIndexControl: TEditInteger;
    ShowControl: TCheckBox;
    Label2: TLabel;
    Label3: TLabel;
    CombinationsPerSecondControl: TEditNumber;
    NumCombinationsTriedControl: TEditNumber;
    procedure InitialiseButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OutputControlPaint(Sender: TObject);
    procedure PieceIndexUpDownControClick(Sender: TObject; Button: TUDBtnType);
    procedure TestPiecesControlClick(Sender: TObject);
    procedure Rotate0ControlClick(Sender: TObject);
    procedure SolveButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    Data:TData;
    Quit:TBoolean;
    IsRunning:TBoolean;
    SolveTimer:THighResTimer;
    PrevSolveTime:TNumber;
    function GetRotation:TRotation;
    procedure UpdateView(CurrentPieceIndex:TInteger;NumCombinationsTried:TLargeInteger;ForceUpdate:TBoolean);
  public
  end;

var
  Main: TMain;

implementation

{$R *.DFM}

procedure TMain.FormCreate(Sender: TObject);
begin
  Data:=TData.Create;
  SolveTimer:=THighResTimer.Create;

  OutputControl.DoubleBuffered:=True;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(Data);
  FreeAndNil(SolveTimer);
end;

procedure TMain.InitialiseButtonClick(Sender: TObject);
begin
  if IsRunning then Exit;

  Data.Initialise;
  PieceIndexControl.Value:=0;
  TestPiecesControl.Checked:=False;
  Rotate0Control.Checked:=True;
  ShowControl.Checked:=False;
  OutputControl.Invalidate;
  OutputControl.Update;
end;

procedure TMain.OutputControlPaint(Sender: TObject);
const
  BorderWidth=20;

  function Log2Dev(X,Y:TInteger):TPoint;
  var
    TextHeight:TInteger;
  begin
    TextHeight:=OutputControl.Canvas.TextExtent('M').cy;
    Result.X:=BorderWidth+Round((OutputControl.Width-2*BorderWidth)*(X+1)/(Data.BoardSize+2));
    Result.Y:=OutputControl.Height-1-(BorderWidth+Round((OutputControl.Height-2*BorderWidth)*(Y+1)/(Data.BoardSize+2)))-TextHeight;
  end;

  procedure DrawBorder(Canvas:TCanvas);
  var
    X,Y:TInteger;
    DP:TPoint;
  begin
    try
      Canvas.Font.Color:=$008000;
      for X:=0 to Data.BoardSize-1 do
      begin
        DP:=Log2Dev(X,-1);
        Canvas.TextOut(DP.X,DP.Y,ConvertToString(Data.GetOppositeCellType(Data.BoardCellTypes[X,0])));
      end;
      //
      for Y:=0 to Data.BoardSize-1 do
      begin
        DP:=Log2Dev(Data.BoardSize,Y);
        Canvas.TextOut(DP.X,DP.Y,ConvertToString(Data.GetOppositeCellType(Data.BoardCellTypes[Data.BoardSize-1,Y])));
      end;
      //
      for X:=Data.BoardSize-1 downto 0 do
      begin
        DP:=Log2Dev(X,Data.BoardSize);
        Canvas.TextOut(DP.X,DP.Y,ConvertToString(Data.GetOppositeCellType(Data.BoardCellTypes[X,Data.BoardSize-1])));
      end;
      //
      for Y:=0 to Data.BoardSize-1 do
      begin
        DP:=Log2Dev(-1,Y);
        Canvas.TextOut(DP.X,DP.Y,ConvertToString(Data.GetOppositeCellType(Data.BoardCellTypes[0,Y])));
      end;
    finally
      Canvas.Font.Color:=$000000;
    end;
  end;

  procedure DrawPiece(Canvas:TCanvas;const Piece:TPiece;const PieceDesign:TPieceDesign);
  var
    CellIndex:TInteger;
    Shape:PTShape;
    DP:TPoint;
    S:String;
    Cell:PTCell;
  begin
    if not Piece.Visible then Exit;

    Shape:=@PieceDesign.Shapes[Piece.Rotation];

    for CellIndex:=0 to Shape.NumCells-1 do
    begin
      Cell:=@Shape.Cells[CellIndex];
      DP:=Log2Dev(Piece.X+Cell.X,Piece.Y+Cell.Y);
      S:=ConvertToString(Cell.CellType);
      Canvas.TextOut(DP.X,DP.Y,S);
    end;
  end;

  procedure DrawPieces(Canvas:TCanvas);
  const
    Color_NotFixed=$0000FF;
    Color_Fixed=$000000;
  var
    PieceIndex:TInteger;
    Highlight:TBoolean;
    Piece:TPiece;
  begin
    try
      Canvas.Font.Color:=$0000C0;
      for PieceIndex:=0 to Data.NumPieces-1 do
      begin
        Piece:=Data.Pieces[PieceIndex];
        Highlight:=(PieceIndex=PieceIndexControl.Value);

        if Piece.Fixed then
          Canvas.Font.Color:=Color_Fixed
        else
          Canvas.Font.Color:=Color_NotFixed;

        if Highlight then
          Canvas.Font.Style:=[fsBold]
        else
          Canvas.Font.Style:=[];

        DrawPiece(Canvas,Piece,Data.PieceDesigns[PieceIndex]);
      end;
    finally
      Canvas.Font.Color:=$000000;
      Canvas.Font.Style:=[];
    end;
  end;
var
  Bitmap:TBitmap;
begin
  Bitmap:=TBitmap.Create;
  try
    Bitmap.Width:=OutputControl.Width;
    Bitmap.Height:=OutputControl.Height;

    Bitmap.Canvas.Pen.Style:=psClear;
    Bitmap.Canvas.Brush.Style:=bsSolid;
    Bitmap.Canvas.Brush.Color:=clWhite;
    Bitmap.Canvas.Rectangle(0,0,Bitmap.Width-1,Bitmap.Height-1);

    if Data.Initialised then
    begin
      DrawBorder(Bitmap.Canvas);

      if TestPiecesControl.Checked then
      begin
        Data.ClearPieces;
        Data.SetPiece(PieceIndexControl.Value,0,0,GetRotation,False);
        Data.AddPiece(PieceIndexControl.Value);
      end;

      DrawPieces(Bitmap.Canvas);
    end;

    OutputControl.Canvas.Draw(0,0,Bitmap);
  finally
    Bitmap.Free;
  end;
end;

procedure TMain.PieceIndexUpDownControClick(Sender: TObject; Button: TUDBtnType);
begin
  if not Data.Initialised then Exit;

  case Button of
    btNext:
    begin
      if PieceIndexControl.Value<Data.NumPieces-1 then PieceIndexControl.Value:=PieceIndexControl.Value+1;
      OutputControl.Invalidate;
      OutputControl.Update;
    end;

    btPrev:
    begin
      if PieceIndexControl.Value>0 then PieceIndexControl.Value:=PieceIndexControl.Value-1;
      OutputControl.Invalidate;
      OutputControl.Update;
    end;
  end;
end;

procedure TMain.TestPiecesControlClick(Sender: TObject);
begin
  Data.ClearPieces;
  OutputControl.Invalidate;
  OutputControl.Update;
end;

function TMain.GetRotation:TRotation;
begin
  if Rotate0Control.Checked then Result:=rt0
  else if Rotate90Control.Checked then Result:=rt90
  else if Rotate180Control.Checked then Result:=rt180
  else if Rotate270Control.Checked then Result:=rt270
  else raise Exception.Create('Invalid rotation.');
end;

procedure TMain.Rotate0ControlClick(Sender: TObject);
begin
  OutputControl.Invalidate;
  OutputControl.Update;
end;

procedure TMain.SolveButtonClick(Sender: TObject);
var
  Success:TBoolean;
begin
  if not Data.Initialised then InitialiseButtonClick(Sender);

  TestPiecesControl.Checked:=False;
  TestPiecesControl.Enabled:=False;
  Quit:=False;
  IncBusyCursor;
  try
    IsRunning:=True;
    SolveTimer.Start;
    SolveTimer.Sample;
    PrevSolveTime:=SolveTimer.CurrentTime;
    Success:=Data.Solve(UpdateView,Quit);
  finally
    DecBusyCursor;
    IsRunning:=False;
    TestPiecesControl.Enabled:=True;
  end;

  if not Quit then
  begin
    if Success then
      Application.MessageBox('Jigsaw completed!','Success',MB_OK)
    else
      Application.MessageBox('Failed to complete jigsaw.','Sorry',MB_OK);
  end;
end;

procedure TMain.UpdateView(CurrentPieceIndex:TInteger;NumCombinationsTried:TLargeInteger;ForceUpdate:TBoolean);
var
  SolveTime,FrameTime:TNumber;
  CombinationsPerSecond:TNumber;
begin
  SolveTimer.Sample;
  SolveTime:=SolveTimer.CurrentTime;
  FrameTime:=SolveTime-PrevSolveTime;

  if ForceUpdate or ShowControl.Checked or (FrameTime>1.0) then
  begin
    OutputControlPaint(Self);
    CurrentPieceIndexControl.Value:=CurrentPieceIndex;
    NumCombinationsTriedControl.Value:=NumCombinationsTried;
    if SolveTime<>0 then CombinationsPerSecond:=NumCombinationsTried/SolveTime else CombinationsPerSecond:=0;
    CombinationsPerSecondControl.Value:=CombinationsPerSecond;
    PrevSolveTime:=SolveTime;
    Application.ProcessMessages;
  end;
end;

procedure TMain.StopButtonClick(Sender: TObject);
begin
  Quit:=True;
end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=not IsRunning;
end;

end.
