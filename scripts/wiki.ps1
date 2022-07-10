$zone_whitelist = .\zone_whitelist.ps1

$source_dir = $args[0]
$zones_p = $source_dir + '\metadata\zones\'
$out_path = "..\wiki\" + $args[1] + "\"
$marker_blacklist = 'pop','harvesting','logging','mining','lost_article','chest','coffer','zone','zone_to','zone_from','voidwatch_rift','unity_junction','questionmarks','seed_fragment','seed_afterglow','geomagnetic_fount'
$final_size = $args[1]
$rescale_markers = $args[2]
$rescale_map = $args[3]

$ckey = "w"+$args[1]
$composite_keys = $ckey, "wiki"

$zone_info = @{}
(((Get-Content ".\zones.json" | Out-String) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/') | ConvertFrom-Json).psobject.properties | ForEach-Object { $zone_info[$_.Name] = $_.Value }

Function get_map_name {
  param($zone_id, $map_index, $map_id, $n_maps)
  
  $zone_name = $zone_info[''+$zone_id].en.ToLower().replace("'", '').replace(' - ', '_').replace('[', '').replace(']', '').replace(' ', '_')
  $map_name = $zone_name + "_$map_index.png"
  if ($n_maps -lt 2) {
      $map_name = "$zone_name.png"
  }
  return $map_name
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