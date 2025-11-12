program BafflingBugsJigsaw;

uses
  Forms,
  UMain in 'UMain.pas' {Main},
  UData in 'UData.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
