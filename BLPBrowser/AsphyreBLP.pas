{******************************************************************************}
{单元名称：AsphyreBLP.pas                                                      }
{功能描述：Open Blizzard Warcraft III .BLP                                     }
{开发人员：Piao40993470 (xbpiao@gmail)                                         }
{创建时间：2013-04-18 13:16:14                                                 }
{使用说明：                                                                    }
{修改历史：                                                                    }
{          使用Delphi2007+jpeg_xe2.pas编译显示没问题，但保存会有错误           }
{          推荐使用Delphi.XE2以上编译(使用自带的JPEG.pas)                      }
{******************************************************************************}
unit AsphyreBLP;

interface

uses
 Classes, SysUtils, Graphics,
{$IF RTLVersion <= 18.0}
  jpeg_xe2;
{$ELSE}
  jpeg;
{$IFEND}

const
  MAX_NR_OF_BLP_MIP_MAPS = 16;
  
  cBlp_MagicNumber:Cardinal = $31504C42; // '1PLB'

type
  TBlpHeader = record
    MagicNumber: Cardinal;
    Compression: Cardinal;
    Flags: Cardinal;
    Width: Cardinal;
    Height: Cardinal;
    PictureType: Cardinal;
    PictureSubType: Cardinal;
    Offset: array[0..MAX_NR_OF_BLP_MIP_MAPS - 1] of Cardinal;
    Size: array[0..MAX_NR_OF_BLP_MIP_MAPS - 1] of Cardinal;
  end;

  TBlpRgba = record
    Red: Byte;
    Green: Byte;
    Blue: Byte;
    Alpha: Byte;
  end;

  TBlpPixel = record
    Index: Byte;
  end;
  
const
  cTBlpHeaderSize = SizeOf(TBlpHeader);

type
  TBlpImage = class(TObject)
  private
    FBlpHeader: TBlpHeader;
    FJpegMipImageList: TList;
    FEmpty: Boolean;
    FOnlyLoadFirst: Boolean; // 仅加载第一张，为提升加载速度
    function GetEmpty: Boolean;
    function GetHeight: Integer;
    function GetWidth: Integer;
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);

    function LoadCompressed(const Stream: TStream): Boolean;
    procedure ClearJpegMipImageList;
    function GetJpegMipImage(const AIndex: Integer): TJpegImage;
    function GetJpegMipImageCount: Integer;
    function CacleJpegHeaderSize(const AStreamList: TList): Cardinal;
  protected

  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const Filename: string);
    procedure SaveToFile(const Filename: string);
    procedure LoadFromStream(const Stream: TStream);
    procedure SaveToStream(Stream: TStream);


    property Empty: Boolean read GetEmpty;
    property Height: Integer read GetHeight write SetHeight;
    property Width: Integer read GetWidth write SetWidth;
    property JpegMipImage[const AIndex: Integer]: TJpegImage read GetJpegMipImage;
    property JpegMipImageCount: Integer read GetJpegMipImageCount;
  published 

  end;    
 
//---------------------------------------------------------------------------
// LoadBLPtoBMP()
//
// Loads BLP format stream to bitmap.
//---------------------------------------------------------------------------
function LoadBLPtoBMP(Stream: TStream; Dest: TBitmap): Boolean; overload;

//---------------------------------------------------------------------------
// SaveBMPtoPNG()
//
// Saves bitmap as BLP format in steam.
// NOTICE: 'Quality' is between 0 and 100.
//---------------------------------------------------------------------------
function SaveBMPtoBLP(Stream: TStream; Source: TBitmap;
 Quality: Cardinal = 100): Boolean; overload;

//---------------------------------------------------------------------------
// Overloaded functions to save/load JPGs to/from external files.
//---------------------------------------------------------------------------
function LoadBLPtoBMP(const FileName: string; Dest: TBitmap): Boolean; overload;
function SaveBMPtoBLP(const FileName: string; Source: TBitmap;
 Quality: Cardinal = 100): Boolean; overload;

procedure SureBmpTo32Bit(Dest: Graphics.TBitmap);

implementation

uses GraphicEx;

function LoadBLPtoBMP(Stream: TStream; Dest: TBitmap): Boolean;
var Blp: TBlpImage;
begin
  Result := False;
  Blp := TBlpImage.Create;
  try
    Blp.FOnlyLoadFirst := True;
    Blp.LoadFromStream(Stream);
    if Blp.JpegMipImageCount > 0 then
    begin
      Dest.Assign(Blp.JpegMipImage[0]);
      Result := True;
    end;// if
  finally
    Blp.Free;
  end;
end;

function SaveBMPtoBLP(Stream: TStream; Source: TBitmap;
 Quality: Cardinal): Boolean;
var i, sw, sh: Integer;
    Jpg: TJpegImage;
    Blp: TBlpImage;
    Dest: TBitmap;
begin// 保存时必须要使用GraphicEx
  Result := False;
  Blp := TBlpImage.Create;
  sw := Source.Width;
  sh := Source.Height;
  Dest := TBitmap.Create;
  Dest.Assign(Source);
  
  for i := 0 to MAX_NR_OF_BLP_MIP_MAPS - 1 do
  begin
    Jpg := TJpegImage.Create;
    Jpg.ProgressiveEncoding:= False;
    Jpg.Grayscale:= False;

    // set compression quality
    Jpg.CompressionQuality:= Quality;

    Jpg.Assign(Dest);
    Blp.FJpegMipImageList.Add(Jpg);
    sw := sw shr 1;
    sh := sh shr 1;
    if (sw < 2) or (sh < 2) then
    begin
      Break;
    end;// if
    GraphicEx.Stretch(sw, sh, sfBox, 0, Source, Dest);
  end;// for i

  Blp.SaveToStream(Stream);
  Blp.Free;
  Dest.Free;
end;

function LoadBLPtoBMP(const FileName: string; Dest: TBitmap): Boolean;
var Blp: TBlpImage;
begin
  Result := False;
  Blp := TBlpImage.Create;
  try
    Blp.FOnlyLoadFirst := True;
    Blp.LoadFromFile(FileName);
    if Blp.JpegMipImageCount > 0 then
    begin
      Dest.Assign(Blp.JpegMipImage[0]);
      Result := True;
    end;// if
  finally
    Blp.Free;
  end;
end;

function SaveBMPtoBLP(const FileName: string; Source: TBitmap;
 Quality: Cardinal): Boolean;
var MemStream: TMemoryStream;

begin
  Result := False;
  MemStream := TMemoryStream.Create;
  SaveBMPtoBLP(MemStream, Source, Quality);
  MemStream.SaveToFile(FileName);
  MemStream.Free;
end;

{ TBlpImage }

function TBlpImage.CacleJpegHeaderSize(const AStreamList: TList): Cardinal;
var i, k, j: Integer;
    s: TStream;
    MinSize: Int64;
    a, b: Byte;

begin
  Result := 0;
  MinSize := MaxLongint;
  if AStreamList.Count < 1 then
  begin
    Exit;
  end;// if
  
  for i := 0 to AStreamList.Count - 1 do
  begin
    s := AStreamList[i];
    if s.Size < MinSize then
    begin
      MinSize := s.Size;
    end;
    s.Position := 0;
  end;// for i
  k := MinSize;
  for i := 1 to k do
  begin
    s := AStreamList[0];
    s.Read(a, 1);
    for j := 1 to AStreamList.Count - 1 do
    begin
      s := AStreamList[j];
      s.Read(b, 1);
      if a <> b then
      begin
        Exit;
      end;// if
    end;// for i
    Inc(Result);
  end;
end;

procedure TBlpImage.ClearJpegMipImageList;
var i: Integer;
begin
  for i := 0 to FJpegMipImageList.Count - 1 do
  begin
    TObject(FJpegMipImageList[i]).Free;
  end;
  FJpegMipImageList.Clear;  
end;

constructor TBlpImage.Create;
begin
  FEmpty := True;
  FOnlyLoadFirst := False;
  FJpegMipImageList := TList.Create;

end;

destructor TBlpImage.Destroy;
begin
  ClearJpegMipImageList;
  FreeAndNil(FJpegMipImageList);
  inherited;
end;

function TBlpImage.GetEmpty: Boolean;
begin
  Result := FEmpty;
end;

function TBlpImage.GetHeight: Integer;
begin
  Result := FBlpHeader.Height;
end;

function TBlpImage.GetJpegMipImage(const AIndex: Integer): TJpegImage;
begin
  Result := FJpegMipImageList[AIndex];
end;

function TBlpImage.GetJpegMipImageCount: Integer;
begin
  Result := FJpegMipImageList.Count;
end;

function TBlpImage.GetWidth: Integer;
begin
  Result := FBlpHeader.Width;
end;

procedure SureBmpTo32Bit(Dest: Graphics.TBitmap);
var ScanIndex, i: Integer;
    PxScan: System.PLongWord;
begin
  if Dest.PixelFormat <> pf32bit then
  begin// 转换为32位色
    Dest.PixelFormat := pf32bit;
    for ScanIndex := 0 to Dest.Height - 1 do
    begin
      PxScan := Dest.ScanLine[ScanIndex];
      for i := 0 to Dest.Width - 1 do
      begin
        PxScan^ := (PxScan^ and $FFFFFFFF) or $FF000000;
        Inc(PxScan);
      end;// if
    end;
  end;
end;

function TBlpImage.LoadCompressed(const Stream: TStream): Boolean;
var JpegHeaderSize: Cardinal;
  StreamPos: Int64;
  JpegMemoryStream: TMemoryStream;
  MipLevel: Integer;
  Image: TJpegImage;
  // Bmp: Graphics.TBitmap;
begin
  Result := False;
  JpegHeaderSize := 0;
  if Stream.Read(JpegHeaderSize, Sizeof(JpegHeaderSize)) = Sizeof(JpegHeaderSize) then
  begin
    // 记录读取JpegHeaderSize后的位置
    StreamPos := Stream.Position;
    JpegMemoryStream := TMemoryStream.Create;

    for MipLevel := 0 to MAX_NR_OF_BLP_MIP_MAPS - 1 do
    begin
      if FBlpHeader.Size[MipLevel] > 0 then
      begin// 有效的数据才加载
        JpegMemoryStream.SetSize(FBlpHeader.Size[MipLevel] + JpegHeaderSize);
        Stream.Position := StreamPos;
        JpegMemoryStream.Position := 0;
        if JpegMemoryStream.CopyFrom(Stream, JpegHeaderSize) = JpegHeaderSize then
        begin
          Stream.Position := FBlpHeader.Offset[MipLevel];
          if JpegMemoryStream.CopyFrom(Stream, FBlpHeader.Size[MipLevel]) = FBlpHeader.Size[MipLevel] then
          begin
            JpegMemoryStream.Position := 0;
            Image := TJpegImage.Create;
            Image.LoadFromStream(JpegMemoryStream);
            
//            if MipLevel = 0 then
//            begin// 转换为BMP有问题why?
//              Image.SaveToFile('d:\test.jpg');
//              Bmp := Graphics.TBitmap.Create;
//              Bmp.PixelFormat := pf24bit;
//              Bmp.Assign(Image);
//              SureBmpTo32Bit(Bmp);
//              Bmp.SaveToFile('d:\test.bmp');
//              Bmp.Free;
//            end;// if
            FJpegMipImageList.Add(Image);
            if FOnlyLoadFirst then
            begin// 仅加载一张
              Break;
            end;// if
          end;// if
        end;
      end;// if
    end;// for MipLevel
    JpegMemoryStream.Free;
  end;// if
end;

procedure TBlpImage.LoadFromFile(const Filename: string);
var MemoryStream: TMemoryStream;
begin
  MemoryStream := TMemoryStream.Create;
  try
    MemoryStream.LoadFromFile(Filename);
    MemoryStream.Position := 0;
    LoadFromStream(MemoryStream);
  finally
    MemoryStream.Free;
  end;// try f
end;

procedure TBlpImage.LoadFromStream(const Stream: TStream);
// var i: Integer;
begin
  FEmpty := True;
  ClearJpegMipImageList;
  FillChar(FBlpHeader, cTBlpHeaderSize, 0);
  if Stream.Read(FBlpHeader, cTBlpHeaderSize) = cTBlpHeaderSize then
  begin
    if FBlpHeader.MagicNumber <> cBlp_MagicNumber then
    begin
      raise Exception.Create('The file is not a BLP image!');
    end;// if
//    for i := 0 to MAX_NR_OF_BLP_MIP_MAPS - 1 do
//    begin
//      OutputDebugString(PAnsiChar('Size[' + IntToStr(i) + ']=' +
//        IntToStr(FBlpHeader.Size[i])
//        + ' Offset=' + IntToStr(FBlpHeader.Offset[i])
//        ));
//    end;

    case FBlpHeader.Compression of
      0:
      begin
        LoadCompressed(Stream);
      end;
//      1:
//      begin
//
//      end;
    else
      raise Exception.Create('Unable to load BLP unknown compression method!');
    end;// case
  end;// if
end;

procedure TBlpImage.SaveToFile(const Filename: string);
begin

end;

procedure TBlpImage.SaveToStream(Stream: TStream);
var Jpg: TJpegImage;
    JpegHeaderSize: Cardinal;
    i: Integer;
    JpgStream: TMemoryStream;
    FStreamList: TList;
    CurOffset: Cardinal;
    s: TMemoryStream;
begin
  if JpegMipImageCount = 0 then
  begin
    raise Exception.Create('TBlpImage.SaveToStream Error!'#13#10'No Images!');
  end;
  FEmpty := True;
  // ClearJpegMipImageList;
  FillChar(FBlpHeader, cTBlpHeaderSize, 0);
  FBlpHeader.MagicNumber := cBlp_MagicNumber;
  FBlpHeader.Compression := 0;
  FBlpHeader.Flags := 8;
  FBlpHeader.PictureType := 4;
  FBlpHeader.PictureSubType := 1;

  FStreamList := TList.Create;
  for i := 0 to JpegMipImageCount - 1 do
  begin
    Jpg := JpegMipImage[i];
    if Jpg <> nil then
    begin
      if i = 0 then
      begin// 默认宽、高总是第一张图片的
        FBlpHeader.Width := Jpg.Width;
        FBlpHeader.Height := Jpg.Height;
      end;// if
      JpgStream := TMemoryStream.Create;
      JpgStream.Clear;
      Jpg.SaveToStream(JpgStream);
      FStreamList.Add(JpgStream);
    end
    else
    begin
      Break;
    end;// if
  end;// for i

  if FStreamList.Count = 1 then
  begin
    JpegHeaderSize := 4;
  end
  else
  begin// 计算公共头部分大小
    JpegHeaderSize := CacleJpegHeaderSize(FStreamList);
  end;// if

  // 计算大小
  CurOffset := cTBlpHeaderSize + SizeOf(JpegHeaderSize) + JpegHeaderSize;
  for i := 0 to FStreamList.Count - 1 do
  begin
    s := FStreamList[i];
    FBlpHeader.Size[i] := s.Size - JpegHeaderSize;
    FBlpHeader.Offset[i] := CurOffset;
    CurOffset := CurOffset + FBlpHeader.Size[i];
  end;// for i

  // 写入数据
  // 1.写入BLP数据头
  Stream.WriteBuffer(FBlpHeader, cTBlpHeaderSize);
  // 2.写头JpegHeaderSize
  Stream.WriteBuffer(JpegHeaderSize, SizeOf(JpegHeaderSize));
  // 3.写头所有jpg公共部分
  s := FStreamList[0];
  Stream.WriteBuffer(Pointer(s.Memory)^, JpegHeaderSize);
  // 4.写入每张图片的其它数据
  for i := 0 to FStreamList.Count - 1 do
  begin
    s := FStreamList[i];
    Stream.WriteBuffer(Pointer(Cardinal(s.Memory) + JpegHeaderSize)^, FBlpHeader.Size[i]);
  end;// for i

  // 清除
  for i := 0 to FStreamList.Count - 1 do
  begin
    TObject(FStreamList[i]).Free;
  end;// for i     
  FStreamList.Free;
end;

procedure TBlpImage.SetHeight(const Value: Integer);
begin

end;


procedure TBlpImage.SetWidth(const Value: Integer);
begin

end;

end.
