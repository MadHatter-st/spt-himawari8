#Ссылка на json - файл, из которого получаем время последней съемки
$latestInfoUri = "https://ncthmwrwbtst.cr.chiba-u.ac.jp/img/D531106/latest.json? + (New-Guid).ToString()";
$latestInfo = Invoke-RestMethod -Uri $latestInfoUri

$current = Get-Date $latestInfo.date;
$time = $current.ToString("HHmmss")
$year = $current.ToString("yyyy")
$month = $current.ToString("MM")
$day = $current.ToString("dd")
Write-Output "$latestInfo.date"
$width = 550

#$parts = Read-Host "Please enter dimentions(1/2/4/8/16)"
$parts = 4
$resolution = [String]$parts + "d"
$resolution = "4d" 


#Создание папки для изображения, если такой нет
$outpath = [Environment]::GetFolderPath("MyPictures") + "\Himawari\"
if(!(Test-Path -Path $outpath ))
{
    [void](New-Item -ItemType directory -Path $outpath)
}

$outfile = "Earth.jpg" 

#Ссылка на изображение Земли
#$url = "https://jh170034-2.kudpc.kyoto-u.ac.jp/img/D531106/thumbnail/$width/$year/$month/$day/$time"
$url = "https://jh170034-2.kudpc.kyoto-u.ac.jp/img/D531106/$resolution/$width/$year/$month/$day/$time"

[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")

#Формирование места для изображения
$image = New-Object System.Drawing.Bitmap(($width * $parts), ($width * $parts))
$graphics = [System.Drawing.Graphics]::FromImage($image)
$graphics.Clear([System.Drawing.Color]::Black)

#Скачивание изображения  
for ($y = 0; $y -lt $parts; $y++)
{
for ($x = 0; $x -lt $parts; $x++)
{
    $thisurl = $url + "_" + [String]$x + "_" + [String]$y + ".png"
    Write-Output "Downloading: $thisurl"
    
    try
    {
    
        $request = [System.Net.WebRequest]::create($thisurl)
        $response = $request.getResponse()
        $HTTP_Status = [int]$response.StatusCode
        If ($HTTP_Status -eq 200)
        { 
            $imgblock = [System.Drawing.Image]::fromStream($response.getResponseStream())
            $graphics.DrawImage($imgblock,($x*$width),($y*$width) , $width, $width)   
            $imgblock.dispose()
            $response.Close()
        }
    }
    Catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Output "Failed! $ErrorMessage with $FailedItem"
    }
}
}


Write-Output "Setting Wallpaper..."

Add-Type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper
{
   public enum Style : int
   {
       Tile, Center, Stretch, NoChange
   }
   public class Setter {
      public const int SetDesktopWallpaper = 20;
      public const int UpdateIniFile = 0x01;
      public const int SendWinIniChange = 0x02;
      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
      public static void SetWallpaper ( string path, Wallpaper.Style style ) {
         SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
         RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
         switch( style )
         {
            case Style.Stretch :
               key.SetValue(@"WallpaperStyle", "2") ; 
               key.SetValue(@"TileWallpaper", "0") ;
               break;
            case Style.Center :
               key.SetValue(@"WallpaperStyle", "1") ; 
               key.SetValue(@"TileWallpaper", "0") ; 
               break;
            case Style.Tile :
               key.SetValue(@"WallpaperStyle", "1") ; 
               key.SetValue(@"TileWallpaper", "1") ;
               break;
            case Style.NoChange :
               break;
         }
         key.Close();
      }
   }
}
"@

#$parts = Read-Host "Please enter mode

[Wallpaper.Setter]::SetWallpaper( 'C:\Users\User\Pictures\Himawari\Earth.jpg', 1 )
