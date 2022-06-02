$zone_whitelist = .\zone_whitelist.ps1

$dats_dir = "C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI\"
$img_dir = "..\..\remapster\dat_img"
$out_path = "..\dats"

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()


# $dat_map = (Get-Content ".\flat_dats.json" | Out-String) | ConvertFrom-Json
# $outdats = @{}
# foreach ($flatdat in $dat_map) {
#   if ($null -eq $outdats[''+$flatdat.zone]) {
#     $outdats[''+$flatdat.zone] = @{}
#   }
#   if ($null -eq $outdats[''+$flatdat.zone][''+$flatdat.map]) {
#     $outdats[''+$flatdat.zone][''+$flatdat.map] = @()
#   }

#   $vv = @{}
#   $vv["dat"] = $flatdat.dat
#   $vv["type"] = $flatdat.type
#   $outdats[''+$flatdat.zone][''+$flatdat.map] += $vv
# }

# $outdats | ConvertTo-Json -depth 100 | Out-File ".\new-dats.json"

get-ChildItem -Path $img_dir -Filter *.dds | Remove-Item

$dat_map = (Get-Content ".\dats.json" | Out-String) | ConvertFrom-Json


if ($args[0]) {
  $zone_id = $args[0]
  $map_id = $args[1]
  $single_zone = $img_dir + "\" + $zone_id + "_" + $map_id + ".png"
  $maps = @(Get-Item $single_zone)
}
else {
  $maps = get-ChildItem -Path $img_dir -Filter *.png 
}

$jobs = @()
foreach($map_file in $maps) {
  $ids = [System.IO.Path]::GetFileNameWithoutExtension($map_file) -split "_"

  $zone = $ids[0]
  $map = $ids[1]

  if ($null -eq $dat_map.$zone -or $null -eq $dat_map.$zone.$map) { continue }

  foreach($dat_info in $dat_map.$zone.$map) {

    $jobs += start-job {
      param ($dats_d,$dat_i,$map_f,$out_p)
      
      $tex_type = $dat_i.type
      $img_path = $map_f.FullName
      if ($tex_type -eq 1) {
        if (-not [System.IO.File]::Exists("$img_path.dds")) {
          ..\..\remapster\DDSTool.exe --png2dxt3 --std_mips --gamma_22 --scale_none "$img_path" "$img_path.dds"
        }
        $img_path = "$img_path.dds"
        Write-Output $img_path.dds
      }
      elseif ($tex_type -eq 4) {
        if (-not [System.IO.File]::Exists("$img_path.dds")) {
          ..\..\remapster\DDSTool.exe --png2dxt1 --std_mips --gamma_22 --scale_none "$img_path" "$img_path.dds"
        }
        $img_path = "$img_path.dds"
        Write-Output $img_path.dds
      }
    } -ArgumentList $dats_dir, $dat_info, $map_file, $out_path
    # Invoke-Expression $cmd
    # Write-Output $cmd
  }
}
$null = $jobs | Wait-Job
$jobs | Receive-Job
$jobs | Remove-Job


$jobs = @()
foreach($map_file in $maps) {
  $ids = [System.IO.Path]::GetFileNameWithoutExtension($map_file) -split "_"

  $zone = $ids[0]
  $map = $ids[1]

  if ($null -eq $dat_map.$zone -or $null -eq $dat_map.$zone.$map) { continue }

  foreach($dat_info in $dat_map.$zone.$map) {

      
      $dat_path = $dats_dir + $dat_info.dat
      $tex_type = $dat_info.type
      $img_path = $map_file.FullName
      if ($tex_type -eq 1 -or $tex_type -eq 4) {
        $img_path = "$img_path.dds"
      }

      $outp = $out_path + "\" + $dat_info.dat
      $outd = [System.IO.Path]::GetDirectoryName($outp)

      if (-not (Test-Path $outd))
      {
        $null = New-Item $outd -ItemType Directory
      }

      $cmd = '..\..\texhammerlite\TexHammerLite.exe replace "'+$dat_path+'" "'+$img_path+'" 0 2048 "' + $outp+'"'

    # $jobs += start-job {
    #   param ($a, $b)
    #   Invoke-Expression $a
    #   Write-Output $b
    # } -ArgumentList $cmd, $outp
    Invoke-Expression $cmd
    Write-Output $outp
  }
}

# $null = $jobs | Wait-Job
# $jobs | Receive-Job
# $jobs | Remove-Job

$totalSecs = [math]::Round($stopwatch.Elapsed.TotalSeconds, 0)
Write-Output "Completed in $totalSecs seconds"