$zone_whitelist = .\zone_whitelist.ps1

$source_dir = $args[0]
$zones_p = $source_dir + '\metadata\zones\'
$out_path = "..\..\remapster\dat_img\"
$marker_blacklist = 'pop','harvesting','logging','mining','lost_article','chest','coffer','zone','zone_to','zone_from','voidwatch_rift','unity_junction','questionmarks','seed_fragment','seed_afterglow','geomagnetic_fount'
$final_size = 2048
$rescale_markers = 1
$rescale_map = 1
$composite_keys = "dat", "w2048", "wiki"

$zone_info = @{}
(((Get-Content ".\zones.json" | Out-String) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/') | ConvertFrom-Json).psobject.properties | ForEach-Object { $zone_info[$_.Name] = $_.Value }

get-ChildItem -Path $out_path | Remove-Item

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

if ($args[1]) {
  $zone_id = $args[1]
  $single_zone = $zones_p + $zone_id + ".json"
  $zones = @($single_zone)
}
else {
  $zones = get-ChildItem -Path $zones_p
}

.\composite_zones.ps1