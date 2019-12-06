program gul;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Imaging.pngimage;

function GetColor(Color: string): TAlphaColorRec;
begin
  var Components: TArray<string> := Color.Split([',']);
  if Length(Components) <> 3 then
    raise Exception.Create('Bad bg color!');

  try
    Result.A := 255;
    Result.R := Components[0].toInteger;
    Result.G := Components[1].toInteger;
    Result.B := Components[2].toInteger;
  except
    raise Exception.Create('Bad bg color params!');
  end;
end;

type
  TRGBAArray = array[Word] of TAlphaColorRec;
  PRGBAArray = ^TRGBAArray;

procedure Convert(Src: TBitmap; Dst: TStream; BackgroundColor: TAlphaColorRec; Deviation: Integer);
var
  X, Y: Integer;
  pBitmap: PRGBAArray;
  b, p, c: Byte;
begin
  for Y := 0 to Src.Height - 1 do
  begin
    pBitmap := Src.ScanLine[Y];

    b := 0;
    c := 0;
    for X := 0 to Src.Width - 1 do
    begin
      if Abs(pBitmap[X].R - BackgroundColor.R) +
         Abs(pBitmap[X].G - BackgroundColor.G) +
         Abs(pBitmap[X].B - BackgroundColor.B) <= Deviation
      then
        p := 0
      else
        p := 1;

      b := b or (p shl (7 - x mod 8));

      Inc(c);

      if c = 8 then
      begin
        Dst.Write(b, 1);
        c := 0;
        b := 0;
      end;
    end;

    if c <> 0 then
      Dst.Write(b, 1);
  end;
end;

procedure Process;
var
  Source, Destanation: string;
  BackgroundColor: TAlphaColorRec;
  Deviation: Integer;
  SrcPicture: TPicture;
  SrcBitmap: TBitmap;
  Stream: TBytesStream;
begin
  writeln('errorsoft.org "gul"');
  if FindCmdLineSwitch('src', Source) and FindCmdLineSwitch('dst', Destanation) then
  begin
    if IsRelativePath(Source) then
      Source := GetCurrentDir + '\' + Source;

    if IsRelativePath(Destanation) then
      Destanation := GetCurrentDir + '\' + Destanation;

    // get bg color
    var bg: string;
    if not FindCmdLineSwitch('bg', bg) then
      bg := '0,0,0';
    BackgroundColor := GetColor(bg);

    // get dev
    var dev: string;
    if not FindCmdLineSwitch('dev', dev) then
      dev := '20';
    try
      Deviation := dev.ToInteger;
    except
      raise Exception.Create('Bag dev param!');
    end;

    writeln('Source = ' + Source);
    writeln('Destanation = ' + Destanation);
    writeln('Background Color = (' + BackgroundColor.R.ToString + ', ' + BackgroundColor.G.ToString + ', ' + BackgroundColor.B.ToString + ')');
    writeln('Deviation = ' + Deviation.ToString);

    SrcPicture := nil;
    SrcBitmap := nil;
    Stream := nil;
    try
      SrcPicture := TPicture.Create;
      try
        SrcPicture.LoadFromFile(Source);
      except
        raise Exception.Create('Can''t read src image!');
      end;
      SrcBitmap := TBitmap.Create;
      SrcBitmap.Assign(SrcPicture.Graphic);
      SrcBitmap.PixelFormat := pf32bit;

      writeln('Width = ' + SrcBitmap.Width.ToString + ' (' + (SrcBitmap.Width / 8).ToString + ' attr)');
      writeln('Height = ' + SrcBitmap.Height.ToString + ' (' + (SrcBitmap.Height / 8).ToString + ' attr)');

      Stream := TBytesStream.Create();

      Convert(SrcBitmap, Stream, BackgroundColor, Deviation);
      writeln('Size = ', Stream.Position.ToString);

      try
        Stream.SaveToFile(Destanation);
      except
        raise Exception.Create('Can''t write dst file!');
      end;

    finally
      SrcPicture.Free;
      SrcBitmap.Free;
      Stream.Free;
    end;

  end else
    raise Exception.Create('Bad cmd!');
end;

begin
  try
    Process;
    writeln('ok!');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
