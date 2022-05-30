

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

$jobs = @()
$completed_jobs = @()

if (Test-Path $out_path) {}
else
{
	$null = New-Item $out_path -ItemType Directory
}

ForEach($zone_file_name in $zones) {
  $zone_metadata = ((Get-Content $zone_file_name | Out-String) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/') | ConvertFrom-Json
  $zone_id = [System.IO.Path]::GetFileNameWithoutExtension($zone_file_name)
  
  if ($zone_whitelist -and -not $zone_whitelist.Contains($zone_id)) { continue }
  $n_maps = $zone_metadata.maps.Count
  ForEach($map in $zone_metadata.maps) {
    $bg_file_name = $source_dir + '\img\maps\' + $map.bg
    $map_index = [array]::indexof($zone_metadata.maps, $map) + 1
    $map_name = get_map_name $zone_id $map_index $n_maps
    $map_file_name = $out_path + $map_name

    $markers_cmd = ''
    ForEach($marker in $map.markers) {
      if(-not $marker_blacklist.Contains($marker.marker)) {
        $marker_metadata_file_name = $source_dir + '\metadata\markers\' + $marker.marker + '.json'
        If (-not [System.IO.File]::Exists($marker_metadata_file_name)) {
          $marker_metadata_file_name = $source_dir + '\metadata\markers\transitions\' + $marker.marker + '.json'
        }
        If ([System.IO.File]::Exists($marker_metadata_file_name)) {
          $marker_metadata = ((Get-Content $marker_metadata_file_name | Out-String) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/') | ConvertFrom-Json
          $marker_file_name = $source_dir + '\img\markers\' + $marker_metadata.img
          If (-not [System.IO.File]::Exists($marker_file_name)) {
            $marker_file_name = $source_dir + '\img\markers\transitions\' + $marker_metadata.img
          }

          If ([System.IO.File]::Exists($marker_file_name)) {
            $anchor_x = 0
            $anchor_y = 0
            if ($marker_metadata.anchor -and $marker_metadata.anchor.x) { $anchor_x = $marker_metadata.anchor.x }
            if ($marker_metadata.anchor -and $marker_metadata.anchor.y) { $anchor_y = $marker_metadata.anchor.y }
            if ($marker.anchor -and $marker.anchor.x) { $anchor_x = $marker.anchor.x }
            if ($marker.anchor -and $marker.anchor.y) { $anchor_y = $marker.anchor.y }

            $width = $marker_metadata.width
            $height = $marker_metadata.height
            if ($marker.width) { $width = $marker.width }
            if ($marker.height) { $height = $marker.height }
            $width = $width * $rescale_markers
            $height = $height * $rescale_markers

            $flipflop = ''
            if ($width -lt 0) {
              $anchor_x = -1 * $anchor_x
              $width = -1 * $width
              $flipflop = $flipflop + " -flop"
            }
            if ($height -lt 0) {
              $anchor_y = -1 * $anchor_y
              $height = -1 * $height
              $flipflop = $flipflop + " -flip"
            }

            $composite_x_attr = 'c'+$final_size+'_x'
            $composite_y_attr = 'c'+$final_size+'_y'
            $x = $marker.$composite_x_attr ?? $marker.x
            $y = $marker.$composite_y_attr ?? $marker.y

            $x = ($x * $rescale_map) - ($anchor_x * ($rescale_markers))
            $y = ($y * $rescale_map) - ($anchor_y * ($rescale_markers))

            $size = '' + $width + 'x' + $height
            $geometry = ' -geometry ' + $size + '+' + $x + '+' + $y

            $red = 255
            $green = 255
            $blue = 255
            $alpha = 1
            if($marker.color) {
              if($marker.color.red) { $red = $marker.color.red }
              if($marker.color.green) { $green = $marker.color.green }
              if($marker.color.blue) { $blue = $marker.color.blue }
              if($marker.color.alpha) { $alpha = $marker.color.alpha / 255 }
            }
            elseif($marker_metadata.color) {
              if($marker_metadata.color.red) { $red = $marker_metadata.color.red }
              if($marker_metadata.color.green) { $green = $marker_metadata.color.green }
              if($marker_metadata.color.blue) { $blue = $marker_metadata.color.blue }
              if($marker_metadata.color.alpha) { $alpha = $marker_metadata.color.alpha / 255 }
            }

            $tint = ' -fill "rgb('+$red+','+$green+','+$blue+')" -tint 100'
            # Write-Output $alpha
            $transp = ' -alpha on -channel A -evaluate multiply ' + $alpha + ' +channel'

            $markers_cmd = $markers_cmd + "``( '" + $marker_file_name + "'" + $flipflop + $tint + $transp + ' `)' + $geometry + ' -compose over -composite '
          }
        }
      }
    }
    $markers_cmd = $markers_cmd.Trim()

    $cmd =  "& magick '" + $bg_file_name + "' -resize " + $final_size + "x" + $final_size + " " + $markers_cmd.Trim() + ' "' + $map_file_name + '"'
    
    # Invoke-Expression $cmd

    $jobs += start-job {
      param ($a,$b)
      Invoke-Expression $a
      Write-Output $b
    } -ArgumentList $cmd, $map_file_name

    
    # Write-Output $map_name
  }

  foreach ($j in ($jobs | Where-Object {$_.State -eq "Completed"})) {
    if (-not $completed_jobs.Contains($j)) {
      $completed_jobs += $j
      Receive-Job $j
    }
  }
}

$null = $jobs | Wait-Job
$jobs | Receive-Job
$jobs | Remove-Job

$totalSecs = [math]::Round($stopwatch.Elapsed.TotalSeconds, 0)
Write-Output "Completed in $totalSecs seconds"