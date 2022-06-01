

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

$jobs = @()
$completed_jobs = @()

$anchor_params = "x", "y"
$color_params = "red", "green", "blue", "alpha"

$watermark_loc = [math]::Round($final_size * 0.03125)

if (Test-Path $out_path) {}
else
{
	$null = New-Item $out_path -ItemType Directory
}

Function get-value {
    param($param, $instance, $metadata)

    ForEach($key in $composite_keys) {
        $key_param = $key + "_" + $param

        $v = $instance.$key_param ?? $metadata.$key_param
        if (-not ($null -eq $v)) {
            return $v
        }
    }
    return $instance.$param ?? $metadata.$param
}

Function get-table() {
    param($param, $instance, $metadata, [string[]]$table_params)

    $v = @{}
    ForEach($x in $composite_keys) {
        $key_param = $x + "_" + $param
        
        if (-not ($null -eq $instance.$key_param)) {
            foreach($p in $table_params) {
                $v.$p = $v.$p ?? $instance.$key_param.$p
            }
        }
        if (-not ($null -eq $metadata.$key_param)) {
            foreach($p in $table_params) {
                $v.$p = $v.$p ?? $metadata.$key_param.$p
            }
        }
    }
    if (-not ($null -eq $instance.$param)) {
        foreach($p in $table_params) {
            $v.$p = $v.$p ?? $instance.$param.$p
        }
    }
    if (-not ($null -eq $metadata.$param)) {
        foreach($p in $table_params) {
            $v.$p = $v.$p ?? $metadata.$param.$p
        }
    }
    return $v
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
            $anchor = get-table "anchor" $marker $marker_metadata $anchor_params
            # Write-Output $anchor

            $width = get-value "width" $marker $marker_metadata
            $height = get-value "height" $marker $marker_metadata

            $width = $width * $rescale_markers
            $height = $height * $rescale_markers

            $flipflop = ''
            if ($width -lt 0) {
              $anchor.x = -1 * $anchor.x
              $width = -1 * $width
              $flipflop = $flipflop + " -flop"
            }
            if ($height -lt 0) {
              $anchor.y = -1 * $anchor.y
              $height = -1 * $height
              $flipflop = $flipflop + " -flip"
            }

            $x = get-value "x" $marker $marker_metadata
            $y = get-value "y" $marker $marker_metadata

            $x = ($x * $rescale_map) - ($anchor.x * ($rescale_markers))
            $y = ($y * $rescale_map) - ($anchor.y * ($rescale_markers))

            $size = '' + $width + 'x' + $height
            $geometry = ' -geometry ' + $size + '+' + $x + '+' + $y

            $color = get-table "color" $marker $marker_metadata $color_params

            $tint = ' -fill "rgb('+$color.red+','+$color.green+','+$color.blue+')" -tint 100'
            # Write-Output $color.alpha
            $alpha = $color.alpha / 255
            $transp = ' -alpha on -channel A -evaluate multiply ' + $alpha + ' +channel'

            $markers_cmd = $markers_cmd + "``( '" + $marker_file_name + "'" + $flipflop + $tint + $transp + ' `)' + $geometry + ' -compose over -composite '
          }
        }
      }
    }
    $markers_cmd = $markers_cmd + '..\..\remapster\remapster_watermark.png -gravity south -geometry +0+'+$watermark_loc+' -compose over -composite '
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