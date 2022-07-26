$zone_whitelist = .\zone_whitelist.ps1

$dats_dir = "C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI\"
$img_dir = "..\..\remapster\dat_img"

$source_dir = $args[0]
$zones_p = $source_dir + '\metadata\zones\'
$out_path = "..\..\remapster\dat_img\"
$marker_blacklist = 'pop','harvesting','logging','mining','lost_article','chest','coffer','zone','zone_to','zone_from','voidwatch_rift','unity_junction','questionmarks','seed_fragment','seed_afterglow','geomagnetic_fount'
$final_size = $args[1]
$rescale_markers = $args[2]
$rescale_map = $args[3]
$composite_keys = "dat", "w$final_size", "wiki"
$out_dats_path = "..\dats\$final_size"

$zone_info = @{}
(((Get-Content ".\zones.json" | Out-String) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/') | ConvertFrom-Json).psobject.properties | ForEach-Object { $zone_info[$_.Name] = $_.Value }

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

$null = get-ChildItem -Path $out_path| Remove-Item -Recurse -Force

Function get_map_name {
  param($zone_id, $map_index, $map_id, $n_maps, $zone, $map)
  
  if ($map.dats) {
    $names = @()
    foreach ($dat in $map.dats) {
      $names += "" + $dat.type + "\" + $dat.dat + ".png"
    }
    return $names
  }
  else {
    return $null
  }
}

$zones_p = $source_dir + '\metadata\zones\'

if ($args[4]) {
  $zone_id = $args[4]
  $single_zone = $zones_p + $zone_id + ".json"
  $zones = @($single_zone)
}
else {
  $zones = get-ChildItem -Path $zones_p
}

.\composite_zones.ps1


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

$maps = get-ChildItem -Path $img_dir -Filter *.png -Recurse

$jobs = @()
foreach($map_file in $maps) {
  $p = $map_file.FullName
  Push-Location $img_dir
  $img_path = Resolve-Path -Path $p -Relative
  Pop-Location
  $rel_file = [regex]::Match($img_path, '..(.*)\.png').Groups[1].Value
  $rel_file = $rel_file -split '\\'
  $tex_type = $rel_file[0]

  $jobs += start-job {
    param ($dats_d,$dat_p,$img_path,$tex_type)
    
    if ($tex_type -eq "1") {
      if (-not [System.IO.File]::Exists("$img_path.dds")) {
        ..\..\remapster\DDSTool.exe --png2dxt3 --std_mips --gamma_22 --scale_none "$img_path" "$img_path.dds"
      }
      $img_path = "$img_path.dds"
      Write-Host $img_path.dds
    }
    elseif ($tex_type -eq "4") {
      if (-not [System.IO.File]::Exists("$img_path.dds")) {
        ..\..\remapster\DDSTool.exe --png2dxt1 --std_mips --gamma_22 --scale_none "$img_path" "$img_path.dds"
      }
      $img_path = "$img_path.dds"
      Write-Host $img_path.dds
    }
  } -ArgumentList $dats_dir, $dat_path, $map_file.FullName, $tex_type
  # Invoke-Expression $cmd
  # Write-Output $cmd
}
$null = $jobs | Wait-Job
$jobs | Receive-Job
$jobs | Remove-Job


$jobs = @()
foreach($map_file in $maps) {
  $p = $map_file.FullName
  Push-Location $img_dir
  $img_path = Resolve-Path -Path $p -Relative
  Pop-Location
  $rel_file = [regex]::Match($img_path, '..(.*)\.png').Groups[1].Value
  $rel_file = $rel_file -split '\\'
  $tex_type = $rel_file[0]
  $dat_path = $rel_file | select -skip 1 | Join-String -Separator '\'

  $img_path = $map_file.FullName
  if ($tex_type -eq "1" -or $tex_type -eq "4") {
    $img_path = "$img_path.dds"
  }

  $outp = $out_dats_path + "\" + $dat_path
  $outd = [System.IO.Path]::GetDirectoryName($outp)
  if (-not (Test-Path $outd))
  {
    $null = New-Item $outd -ItemType Directory
  }

  $real_dat_path = Join-Path -Path $dats_dir -ChildPath $dat_path
  $cmd = '..\..\texhammerlite\TexHammerLite.exe replace "'+$real_dat_path+'" "'+$img_path+'" 0 '+$final_size+' "' + $outp+'"'

  $jobs += start-job {
    param ($c,$p)

    Invoke-Expression $c
    Write-Host $p
    
  } -ArgumentList $cmd, $outp
}

$null = $jobs | Wait-Job
$jobs | Receive-Job
$jobs | Remove-Job

$totalSecs = [math]::Round($stopwatch.Elapsed.TotalSeconds, 0)
Write-Output "Completed in $totalSecs seconds"