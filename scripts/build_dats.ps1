$zone_whitelist = .\zone_whitelist.ps1

$dats_dir = "C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI\"
$img_dir = "..\..\remapster\dat_img"
$out_path = "..\dats"

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()


# $dat_map = (Get-Content ".\flatdats.json" | Out-String) | ConvertFrom-Json
# $outdats = @{}
# foreach ($flatdat in $dat_map) {
#   if ($null -eq $outdats[''+$flatdat.zone]) {
#     $outdats[''+$flatdat.zone] = @{}
#   }
#   $outdats[''+$flatdat.zone][''+$flatdat.map] = @{}
#   $outdats[''+$flatdat.zone][''+$flatdat.map]["dat"] = $flatdat.dat
#   $outdats[''+$flatdat.zone][''+$flatdat.map]["type"] = $flatdat.type
# }

# $outdats | ConvertTo-Json -depth 100 | Out-File ".\new-dats.json"

$dat_map = (Get-Content ".\dats.json" | Out-String) | ConvertFrom-Json


if ($args[0]) {
  $zone_id = $args[0]
  $map_id = $args[1]
  $single_zone = $img_dir + "\" + $zone_id + "_" + $map_id + ".png"
  $maps = @($single_zone)
}
else {
  $maps = get-ChildItem -Path $img_dir
}

$jobs = @()
foreach($map_file in $maps) {
  $ids = [System.IO.Path]::GetFileNameWithoutExtension($map_file) -split "_"

  $zone = $ids[0]
  $map = $ids[1]

  if ($null -eq $dat_map.$zone -or $null -eq $dat_map.$zone.$map) { continue }

  $dat_path = $dats_dir + $dat_map.$zone.$map.dat
  $tex_type = $dat_map.$zone.$map.type
  $img_path = $map_file.FullName
  $temp_img = $img_dir + "\temp.dds"
  if ($tex_type -eq 1) {
    ..\..\remapster\DDSTool.exe --png2dxt3 --std_mips --gamma_22 --scale_none "$img_path" "$temp_img"
    $img_path = $temp_img
  }
  elseif ($tex_type -eq 4) {
    ..\..\remapster\DDSTool.exe --png2dxt1 --std_mips --gamma_22 --scale_none "$img_path" "$temp_img"
    $img_path = $temp_img
  }
  # else { continue }

  $out_p = $out_path + "\" + $dat_map.$zone.$map.dat
  $out_d = [System.IO.Path]::GetDirectoryName($out_p)

  if (-not (Test-Path $out_d))
  {
    $null = New-Item $out_d -ItemType Directory
  }

  $cmd = '..\..\texhammerlite\TexHammerLite.exe replace "'+$dat_path+'" "'+$img_path+'" 0 2048 "' + $out_p+'"'

  # $jobs += start-job {
  #   param ($a,$b)
  #   Invoke-Expression $a
  #   Write-Output $b
  # } -ArgumentList $cmd, $out_p
  Invoke-Expression $cmd
  Write-Output $cmd


}

$null = $jobs | Wait-Job
$jobs | Receive-Job
$jobs | Remove-Job

$totalSecs = [math]::Round($stopwatch.Elapsed.TotalSeconds, 0)
Write-Output "Completed in $totalSecs seconds"