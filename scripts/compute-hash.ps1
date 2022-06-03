
Add-Type -AssemblyName System.Drawing

$sha = new-object System.Security.Cryptography.SHA256Managed

$file = @($args[0] | Resolve-Path | Convert-Path)
$bmp    = new-object System.Drawing.Bitmap $file[0]
$stream = new-object System.IO.MemoryStream
$writer = new-object System.IO.BinaryWriter $stream
for ($x = 0; $x -lt $bmp.Width; $x++) {
  for ($y = 0; $y -lt $bmp.Height; $y++) {
    $pixel = $bmp.GetPixel($x,$y)
    $writer.Write($pixel.ToArgb())
  }
}
$writer.Flush()
if (-not ($null -eq $bmp)) {
  $bmp.Dispose()
}
[void]$stream.Seek(0,'Begin')
$hash = $sha.ComputeHash($stream)
[BitConverter]::ToString($hash) -replace '-',''