unit uMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AsphyreBLP, StdCtrls, Menus, ExtCtrls, ImgList,
{$IF RTLVersion <= 18.0}
  jpeg_xe2,
{$ELSE}
  jpeg,
{$IFEND}
  AppEvnts
  ;

type

  PNXColor32 = ^TNXColor32;
  TNXColor32 = packed record
    b, g, r, a: Byte;
  end;// TNXColor3

  TNXExtType = (nxNone, nxBLP, nxBMP, nxJpg, nxPng, nxTga);

  TMainForm = class(TForm)
    btn1: TButton;
    scrlbx1: TScrollBox;
    img1: TImage;
    mm1: TMainMenu;
    N1: TMenuItem;
    jpg1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    aplctnvnts1: TApplicationEvents;
    N5: TMenuItem;
    Piao409934701: TMenuItem;
    bmp1: TMenuItem;
    blp1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure jpg1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure aplctnvnts1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure bmp1Click(Sender: TObject);
    procedure blp1Click(Sender: TObject);
  private
    { Private declarations }
    FRunPath: string;
    FDragFileName: string;
    FDragFilePath: string;
    FFileExt: TNXExtType;
    FBlpImage: TBlpImage;
    procedure WMDragFiles(var msg: TWMDropFiles);message WM_DROPFILES;
    function GetNXFileExtType(const AFileExt: string): TNXExtType;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$IF RTLVersion <= 18.0}
uses ShellAPI, AsphyreTGA, AsphyreJPG, AsphyrePNG;
{$ELSE}
uses ShellAPI, AsphyreTGA, AsphyreJPG;
{$IFEND}


{$R *.dfm}

procedure TMainForm.aplctnvnts1Message(var Msg: tagMSG; var Handled: Boolean);
begin
  if Msg.message = WM_KEYDOWN then
  begin
    if msg.wParam = VK_F2 then
    begin
      jpg1Click(nil);
      Handled := True;
    end;
  end;
end;

procedure TMainForm.blp1Click(Sender: TObject);
var newBlpFileName: string;
begin// 转换为BLP
  if FFileExt <> nxBLP then
  begin
    newBlpFileName := ChangeFileExt(FDragFileName, '.blp');
    AsphyreBLP.SaveBMPtoBLP(newBlpFileName, img1.Picture.Bitmap, 100);
  end
  else
  begin
    Application.MessageBox('源文件已经是BLP了不需要再转换！', '提示', MB_OK + MB_ICONSTOP);
  end;// if
end;

procedure TMainForm.bmp1Click(Sender: TObject);
var newBmpFileName: string;
    bmp: TBitmap;
begin
  if FBlpImage.JpegMipImageCount > 0 then
  begin
    newBmpFileName := ChangeFileExt(FDragFileName, '.bmp');
    bmp := TBitmap.Create;
    bmp.Assign(FBlpImage.JpegMipImage[0]);
    bmp.SaveToFile(newBmpFileName);
    bmp.Free;
  end;// if
end;


procedure TMainForm.btn1Click(Sender: TObject);
var blp: TBlpImage;
begin
  blp := TBlpImage.Create;
  blp.LoadFromFile(FRunPath + 'BLPFiles\TeamGlow06.blp');
  blp.Free;
end;

procedure TMainForm.btn2Click(Sender: TObject);
var Dest: Graphics.TBitmap;
    ScanIndex, i: Integer;
    PxScan: PNXColor32;
begin
  Exit;
  Dest := Graphics.TBitmap.Create;
  Dest.LoadFromFile('D:\testtt.bmp');
  SureBmpTo32Bit(Dest);
  
  for ScanIndex := 0 to Dest.Height - 1 do
  begin// 不知道如何转换Alpha通常的数据
    PxScan := Dest.ScanLine[ScanIndex];
    for i := 0 to Dest.Width - 1 do
    begin
      if (PxScan^.b = 0) and (PxScan^.g = 0) and (PxScan^.r = 0) then
      begin
        PxScan^.a := 0;
        PxScan^.b := 0;
        PxScan^.g := 0;
        PxScan^.r := 0;
      end;// IF
      Inc(PxScan);
    end;// if
  end;
  Dest.SaveToFile('D:\testtt32.bmp');
  Dest.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FRunPath := ExtractFilePath(Application.ExeName);
  DragAcceptFiles(Self.Handle, True);
  FBlpImage := TBlpImage.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  DragAcceptFiles(Self.Handle, False);
  FreeAndNil(FBlpImage);
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_F2 then
  begin
    jpg1Click(nil);
  end;
end;

function TMainForm.GetNXFileExtType(const AFileExt: string): TNXExtType;
begin
  Result := nxNone;
  if SameText(AFileExt, '.blp') then
    Result := nxBLP
  else
  if SameText(AFileExt, '.bmp') then
    Result := nxBMP
  else
  if SameText(AFileExt, '.jpg') then
    Result := nxJpg
  else
  if SameText(AFileExt, '.jpeg') then
    Result := nxJpg
  else
  if SameText(AFileExt, '.png') then
    Result := nxPng
  else
  if SameText(AFileExt, '.tga') then
    Result := nxTga;
end;

procedure TMainForm.jpg1Click(Sender: TObject);
var newJpgFileName: string;
begin
  if FBlpImage.JpegMipImageCount > 0 then
  begin
    newJpgFileName := ChangeFileExt(FDragFileName, '.jpg');
    FBlpImage.JpegMipImage[0].SaveToFile(newJpgFileName);
  end;// if
end;

procedure TMainForm.N4Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.WMDragFiles(var msg: TWMDropFiles);
var PFileName: array[0..MAX_PATH] of Char;
    Bmp: Graphics.TBitmap;    
begin
  DragQueryFile(msg.Drop, 0, PFileName, MAX_PATH - 1);
  try
    FDragFileName := PFileName;
  finally
    DragFinish(msg.Drop);
  end;// try f

  FFileExt := GetNXFileExtType(ExtractFileExt(FDragFileName));

  FDragFilePath := ExtractFilePath(FDragFileName);
  case FFileExt of
    nxNone: ;
    nxBLP:
    begin
      try
        FBlpImage.LoadFromFile(FDragFileName);
        if FBlpImage.JpegMipImageCount > 0 then
        begin
          FBlpImage.JpegMipImage[0].DIBNeeded;
          img1.Picture.Bitmap.Assign(FBlpImage.JpegMipImage[0]);
          Self.Caption := 'BLP浏览[' + IntToStr(FBlpImage.Width) + '*' +
            IntToStr(FBlpImage.Height) + ']';
        end;// if
      except
        on E: Exception do
        begin
          Application.MessageBox(PChar('加载失败！'#13#10 + E.Message), '提示', MB_OK + MB_ICONSTOP);
        end;
      end;// try e
    end;// nxBLP
    nxBMP:
    begin
      try
        Bmp := Graphics.TBitmap.Create;
        Bmp.LoadFromFile(FDragFileName);
        Self.Caption := 'BMP浏览[' + IntToStr(Bmp.Width) + '*' +
            IntToStr(Bmp.Height) + ']';
        img1.Picture.Bitmap.Assign(Bmp);
        Bmp.Free;
      except
        on E: Exception do
        begin
          Application.MessageBox(PChar('加载失败！'#13#10 + E.Message), '提示', MB_OK + MB_ICONSTOP);
        end;
      end;// try e
    end;// nxBMP
    nxJpg:
    begin
      Bmp := Graphics.TBitmap.Create;
      if LoadJPGtoBMP(FDragFileName, Bmp) then
      begin
        Self.Caption := 'JPG浏览[' + IntToStr(Bmp.Width) + '*' +
            IntToStr(Bmp.Height) + ']';
        img1.Picture.Bitmap.Assign(Bmp);
      end
      else
      begin
        Application.MessageBox(PChar('加载失败！'), '提示', MB_OK + MB_ICONSTOP);
      end;
      Bmp.Free;
    end;// nxJpg
    nxPng:
    begin
      {$IF RTLVersion <= 18.0}
      Bmp := Graphics.TBitmap.Create;
      if LoadPNGtoBMP(FDragFileName, Bmp) then
      begin
        Self.Caption := 'PNG浏览[' + IntToStr(Bmp.Width) + '*' +
            IntToStr(Bmp.Height) + ']';
        img1.Picture.Bitmap.Assign(Bmp);
      end
      else
      begin
        Application.MessageBox(PChar('加载失败！'), '提示', MB_OK + MB_ICONSTOP);
      end;
      Bmp.Free;
      {$IFEND}
    end;// nxPng
    nxTga:
    begin
      Bmp := Graphics.TBitmap.Create;
      if LoadTGAtoBMP(FDragFileName, Bmp) then
      begin
        Self.Caption := 'TGA浏览[' + IntToStr(Bmp.Width) + '*' +
            IntToStr(Bmp.Height) + ']';
        img1.Picture.Bitmap.Assign(Bmp);
      end
      else
      begin
        Application.MessageBox(PChar('加载失败！'), '提示', MB_OK + MB_ICONSTOP);
      end;
      Bmp.Free;
    end;// nxTag
  end;// case
end;

end.
