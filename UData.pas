unit UData;

// Copyright JSB Medical Systems 2000.

////////////////////////////////////////////////////////////////
// Notes:
//
// 1) All shapes must be as far down and left as they will go. This includes rotated shapes.
// 2) Coordinate origin is bottom left of border.
//
////////////////////////////////////////////////////////////////

interface

uses
  Windows, SysUtils, UTypes, UGeneral;

const
  MaxPieceSize=4;
  MaxNumPieces=14;
  MaxBoardSize=8;
  MaxNumShapeCoordinates=MaxPieceSize*MaxPieceSize;

type
  TRotation=(rt0,rt90,rt180,rt270);

  TCellType=(ctNone,ctMale,ctFemale);

  TCell=record
    X,Y:TInteger;
    CellType:TCellType;
  end;
  PTCell=^TCell;

  TCells=Array[0..MaxNumShapeCoordinates-1] of TCell;

  TShape=record
    Width,Height:TInteger;
    NumCells:TInteger;
    Cells:TCells;
    GenderX,GenderY:TInteger;
    GenderCellType:TCellType;
  end;
  PTShape=^TShape;

  TShapes=Array[TRotation] of TShape; // Includes rotations.

  TPieceDesign=record
    Shapes:TShapes;
  end;
  PTPieceDesign=^TPieceDesign;

  TPieceDesigns=Array[0..MaxNumPieces-1] of TPieceDesign;

  TPiece=record
    Visible:TBoolean;
    X,Y:TInteger;
    Rotation:TRotation;
    Fixed:TBoolean;
  end;
  PTPiece=^TPiece;

  TPieces=Array[0..MaxNumPieces-1] of TPiece;

  TBoard=Array[0..MaxBoardSize-1,0..MaxBoardSize-1] of TBoolean;

  TBoardCellTypes=Array[0..MaxBoardSize-1,0..MaxBoardSize-1] of TCellType;

  TUpdateViewEvent=procedure(CurrentPieceIndex:TInteger;NumCombinationsTried:TLargeInteger;ForceUpdate:TBoolean) of object;

  TData=class(TObject)
  private
    procedure ParseInputData;
    procedure RotateShape(InputShape:TShape;out OutputShape:TShape);
    function GetBoardCellType(X,Y:TInteger):TCellType;
  public
    Initialised:TBoolean;
    NumPieces:TInteger;
    PieceDesigns:TPieceDesigns;
    Pieces:TPieces;
    BoardSize:TInteger;
    Board:TBoard;
    BoardCellTypes:TBoardCellTypes;
    procedure Initialise;
    procedure ClearPieces;
    procedure SetPiece(PieceIndex,X,Y:TInteger;Rotation:TRotation;Fixed:TBoolean);
    function Solve(UpdateView:TUpdateViewEvent;var Quit:TBoolean):TBoolean;
    function GetOppositeCellType(Value:TCellType):TCellType;
    procedure ClearBoard;
    function DoesPieceFit(PieceIndex:TInteger):TBoolean;
    procedure AddPiece(PieceIndex:TInteger);
    procedure RemovePiece(PieceIndex:TInteger);
    function IncrementPiece(PieceIndex:TInteger):TBoolean;
    procedure CalculateShapeGenderCheckDetails(var Shape:TShape);
  end;

function ConvertToString(Value:TCellType):String; overload;

implementation

type
  TInputPiece=record
    X,Y:TInteger;
    D:String;
  end;
  PTInputPiece=^TInputPiece;

  TInputBorders=Array[0..3] of String;

////////////////////////////////////////////////////////////////
// Input data.

// Note: Pieces are scanned in row order starting at the bottom left.
// Note: Piece 6 must go bottom right, rotated 270 degrees anticlockwise, as it is the only piece that matches the border.
//       Currently this is hard wired.

const
  NumInputPieces=14;
  InputBoardSize=8;
  OriginCellType=ctFemale;

  InputPieces:Array[0..NumInputPieces-1] of TInputPiece=
  (
    (X:3;Y:2;D:'FXX,MFM'), // 0
    (X:4;Y:2;D:'FMFX,XXMF'), // 1
    (X:3;Y:3;D:'MXX,FMX,XFM'), // 2
    (X:4;Y:2;D:'FXXX,MFMF'), // 3
    (X:4;Y:2;D:'XXFM,MFMX'), // 4
    (X:4;Y:2;D:'XFXX,FMFM'), // 5
    (X:2;Y:2;D:'MF,XM'), // 6
    (X:3;Y:2;D:'XFX,FMF'), // 7
    (X:3;Y:3;D:'XMF,XFX,FMX'), // 8
    (X:3;Y:2;D:'XXM,FMF'), // 9
    (X:3;Y:2;D:'MFX,XMF'), // 10
    (X:4;Y:2;D:'MFMF,XMXX'), // 11
    (X:4;Y:2;D:'XXXM,MFMF'), // 12
    (X:3;Y:3;D:'XXM,FMF,MXX') // 13
  );

////////////////////////////////////////////////////////////////

function ConvertToString(Value:TCellType):String;
begin
  case Value of
    ctNone: Result:='X';
    ctMale: Result:='M';
    ctFemale: Result:='F';
    else raise ERangeError.Create('Invalid CellType');
  end;
end;

////////////////////////////////////////////////////////////////

procedure TData.RotateShape(InputShape:TShape;out OutputShape:TShape);
// Ensure that piece is as far up and left as possible.
// Rotates anti clockwise looking towards the face of the shape.
var
  InputShapeCellIndex,OutputShapeCellIndex,NewX,NewY,MinX,MinY:TInteger;
  First:TBoolean;
  InputCell,OutputCell:PTCell;
begin
  OutputShape.Width:=InputShape.Height;
  OutputShape.Height:=InputShape.Width;
  ZeroMemory(@OutputShape.Cells,sizeof(OutputShape.Cells));

  First:=True;
  MinX:=0;
  MinY:=0;
  OutputShapeCellIndex:=0;
  for InputShapeCellIndex:=0 to InputShape.NumCells-1 do
  begin
    InputCell:=@InputShape.Cells[InputShapeCellIndex];
    OutputCell:=@OutputShape.Cells[OutputShapeCellIndex];
    Inc(OutputShapeCellIndex);
    NewX:=MaxPieceSize-1-InputCell.Y;
    NewY:=InputCell.X;
    OutputCell.X:=NewX;
    OutputCell.Y:=NewY;
    OutputCell.CellType:=InputCell.CellType;
    if First then
    begin
      MinX:=NewX;
      MinY:=NewY;
      First:=False;
    end
    else
    begin
      MinX:=Integer_Min(MinX,NewX);
      MinY:=Integer_Min(MinY,NewY);
    end;
  end;
  OutputShape.NumCells:=OutputShapeCellIndex;

  // Shift piece to bottom-left.
  for OutputShapeCellIndex:=0 to OutputShape.NumCells-1 do
  begin
    with OutputShape.Cells[OutputShapeCellIndex] do
    begin
      X:=X-MinX;
      Y:=Y-MinY;
    end;
  end;
end;

procedure TData.CalculateShapeGenderCheckDetails(var Shape:TShape);
begin
  Shape.GenderX:=Shape.Cells[0].X;
  Shape.GenderY:=Shape.Cells[0].Y;
  Shape.GenderCellType:=Shape.Cells[0].CellType;
end;

procedure TData.ParseInputData;
var
  CellIndex,StringIndex,PieceIndex,Width,Height,X,Y:TInteger;
  pInputPiece:PTInputPiece;
  pPieceDesign:PTPieceDesign;
  S:String;
  C:Char;
  Shape:PTShape;
  CellType:TCellType;
  Cell:PTCell;
begin
  ZeroMemory(@PieceDesigns,sizeof(PieceDesigns));

  NumPieces:=NumInputPieces;
  BoardSize:=InputBoardSize;

  for PieceIndex:=0 to NumInputPieces-1 do
  begin
    pInputPiece:=@InputPieces[PieceIndex];
    pPieceDesign:=@PieceDesigns[PieceIndex];
    Width:=pInputPiece^.X;
    Height:=pInputPiece^.Y;
    S:=pInputPiece^.D;

    // Do default rotation.
    pPieceDesign^.Shapes[rt0].Width:=Width;
    pPieceDesign^.Shapes[rt0].Height:=Height;
    StringIndex:=1;
    CellIndex:=0;
    Shape:=@pPieceDesign^.Shapes[rt0];
    for Y:=0 to Height-1 do
    begin
      if Y<>0 then
      begin
        if S[StringIndex]<>',' then raise Exception.Create('Invalid input data');
        Inc(StringIndex);
      end;

      for X:=0 to Width-1 do
      begin
        C:=S[StringIndex];
        if C='M' then CellType:=ctMale
        else if C='F' then CellType:=ctFemale
        else if C='X' then CellType:=ctNone
        else raise Exception.Create('Invalid input data');
        Inc(StringIndex);

        if CellType<>ctNone then
        begin
          Cell:=@Shape.Cells[CellIndex];
          Cell.X:=X;
          Cell.Y:=Y;
          Cell.CellType:=CellType;
          Inc(CellIndex);
        end;
      end;
    end;
    Shape.NumCells:=CellIndex;

    // Calculate remaining rotations.
    RotateShape(pPieceDesign^.Shapes[rt0],pPieceDesign^.Shapes[rt90]);
    RotateShape(pPieceDesign^.Shapes[rt90],pPieceDesign^.Shapes[rt180]);
    RotateShape(pPieceDesign^.Shapes[rt180],pPieceDesign^.Shapes[rt270]);

    // Calculate shape gender details.
    CalculateShapeGenderCheckDetails(pPieceDesign^.Shapes[rt0]);
    CalculateShapeGenderCheckDetails(pPieceDesign^.Shapes[rt90]);
    CalculateShapeGenderCheckDetails(pPieceDesign^.Shapes[rt180]);
    CalculateShapeGenderCheckDetails(pPieceDesign^.Shapes[rt270]);
  end;
end;

procedure TData.Initialise;
var
  X,Y:TInteger;
begin
  ClearPieces;
  ParseInputData;

  for Y:=0 to BoardSize-1 do
  begin
    for X:=0 to BoardSize-1 do
    begin
      BoardCellTypes[X,Y]:=GetBoardCellType(X,Y);
    end;
  end;

  Initialised:=True;
end;

procedure TData.ClearPieces;
begin
  ZeroMemory(@Pieces,sizeof(Pieces));
end;

procedure TData.SetPiece(PieceIndex,X,Y:TInteger;Rotation:TRotation;Fixed:TBoolean);
var
  Piece:PTPiece;
begin
  Assert((PieceIndex>=0) and (PieceIndex<NumPieces));

  Piece:=@Pieces[PieceIndex];
  Piece.X:=X;
  Piece.Y:=Y;
  Piece.Rotation:=Rotation;
  Piece.Fixed:=Fixed;
end;

function TData.GetOppositeCellType(Value:TCellType):TCellType;
begin
  case Value of
    ctMale: Result:=ctFemale;
    ctFemale: Result:=ctMale;
    else raise ERangeError.Create('Invalid cell type.');
  end;
end;

function TData.GetBoardCellType(X,Y:TInteger):TCellType;
var
  Opposite:TBoolean;
begin
  Opposite:=((X+Y) and 1)<>0;
  if Opposite then
    Result:=GetOppositeCellType(OriginCellType)
  else
    Result:=OriginCellType;
end;

procedure TData.ClearBoard;
begin
  ZeroMemory(@Board,sizeof(Board));
end;

function TData.DoesPieceFit(PieceIndex:TInteger):TBoolean;
var
  CellIndex,BoardX,BoardY:TInteger;
  Piece:PTPiece;
  Shape:PTShape;
  Cell:PTCell;
begin
  Result:=False;
  Piece:=@Pieces[PieceIndex];
  Shape:=@PieceDesigns[PieceIndex].Shapes[Piece.Rotation];

  // Check shape does not overload edge of board at right or top.
  if (Shape.Height+Piece.Y>BoardSize) or (Shape.Width+Piece.X>BoardSize) then Exit;

  // Check gender.
  if BoardCellTypes[Piece.X+Shape.GenderX,Piece.Y+Shape.GenderY]<>Shape.GenderCellType then Exit;

  for CellIndex:=0 to Shape.NumCells-1 do
  begin
    Cell:=@Shape.Cells[CellIndex];
    BoardX:=Cell.X+Piece.X;
    BoardY:=Cell.Y+Piece.Y;
    if Board[BoardX,BoardY] then Exit;
  end;
  Result:=True;
end;

procedure TData.AddPiece(PieceIndex:TInteger);
var
  CellIndex,BoardX,BoardY:TInteger;
  Piece:PTPiece;
  Shape:PTShape;
  Cell:PTCell;
begin
  Piece:=@Pieces[PieceIndex];
  Shape:=@PieceDesigns[PieceIndex].Shapes[Piece.Rotation];
  if (Shape.Height+Piece.Y>BoardSize) or (Shape.Width+Piece.X>BoardSize) then raise ERangeError.Create('Invalid board position.');
  for CellIndex:=0 to Shape.NumCells-1 do
  begin
    Cell:=@Shape.Cells[CellIndex];
    BoardX:=Cell.X+Piece.X;
    BoardY:=Cell.Y+Piece.Y;
    Board[BoardX,BoardY]:=True;
  end;
  Piece.Visible:=True;
end;

procedure TData.RemovePiece(PieceIndex:TInteger);
var
  CellIndex,BoardX,BoardY:TInteger;
  Piece:PTPiece;
  Shape:PTShape;
  Cell:PTCell;
begin
  Piece:=@Pieces[PieceIndex];
  Shape:=@PieceDesigns[PieceIndex].Shapes[Piece.Rotation];
  if (Shape.Height+Piece.Y>BoardSize) or (Shape.Width+Piece.X>BoardSize) then raise ERangeError.Create('Invalid board position.');
  for CellIndex:=0 to Shape.NumCells-1 do
  begin
    Cell:=@Shape.Cells[CellIndex];
    BoardX:=Cell.X+Piece.X;
    BoardY:=Cell.Y+Piece.Y;
    Board[BoardX,BoardY]:=False;
  end;
  Piece.Visible:=False;
end;

function TData.IncrementPiece(PieceIndex:TInteger):TBoolean;
// Returns True if carry.
var
  Piece:PTPiece;
  Shape:PTShape;
begin
  Result:=False;
  Piece:=@Pieces[PieceIndex];
  Shape:=@PieceDesigns[PieceIndex].Shapes[Piece.Rotation];
  Inc(Piece.X);
  if Piece.X+Shape.Width>BoardSize then
  begin
    Piece.X:=0;
    Inc(Piece.Y);
    if Piece.Y+Shape.Height>BoardSize then
    begin
      Piece.Y:=0;
      if Piece.Rotation=rt270 then
      begin
        Piece.Rotation:=rt0;
        Result:=True;
      end
      else
        Inc(Piece.Rotation);
    end;
  end;
end;

function TData.Solve(UpdateView:TUpdateViewEvent;var Quit:TBoolean):TBoolean;
var
  CurrentPiece:TInteger;
  NumCombinationsTried:TLargeInteger;
  Piece:PTPiece;
  Carry:TBoolean;
begin
  Result:=False;

  ClearPieces;
  ClearBoard;

  // Insert fixed pieces.
  // Original (2006):
  SetPiece(6,6,0,rt270,True);
  AddPiece(6);
  //
  // Extras added 11/11/2025:
  // SetPiece(7,6,5,rt270,True);
  // AddPiece(7);
  //
  // SetPiece(9,0,6,rt180,True);
  // AddPiece(9);
  //
  // SetPiece(12,0,0,rt180,True);
  // AddPiece(12);

  CurrentPiece:=0;
  NumCombinationsTried:=0;

  repeat
    Piece:=@Pieces[CurrentPiece];
    if Piece.Fixed then
    begin
      Inc(CurrentPiece);
    end
    else
    begin
      if DoesPieceFit(CurrentPiece) then
      begin
        AddPiece(CurrentPiece);
        Inc(CurrentPiece);
      end
      else
      begin
        repeat
          Carry:=IncrementPiece(CurrentPiece);
          Inc(NumCombinationsTried);
          if Carry then
          begin
            repeat
              if CurrentPiece=0 then Exit; // Fail.
              Dec(CurrentPiece);
            until not Pieces[CurrentPiece].Fixed;
            RemovePiece(CurrentPiece);
          end;
        until not Carry;
      end;
    end;

    if ((NumCombinationsTried and 128)=0) then
    begin
      if Assigned(UpdateView) then UpdateView(CurrentPiece,NumCombinationsTried,False);
      if Quit then Exit;
    end;
  until (CurrentPiece=NumPieces);

  UpdateView(CurrentPiece,NumCombinationsTried,True);

  Result:=True;
end;

end.
