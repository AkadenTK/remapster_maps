
$source_dir = $args[0]
$zones_p = $source_dir + '\metadata\zones\'
$out_path = "..\minimaps\ffxidb\"
$marker_blacklist = @('pop','harvesting','logging','mining','lost_article','chest','coffer','zone','voidwatch_rift','unity_junction','questionmarks','seed_fragment','seed_afterglow')
$zone_whitelist = @('9','26','39','40','41','42','48','50','53','77','80','84','87','91','102','103','108','110','117','120','126','134','135','157','158','182','184','185','186','187','188','230','231','232','233','234','235','236','237','238','239','240','241','243','244','245','246','249','252','256','257','260','261','262','263','265','266','267','268','269','270','272','273','274','276','279','288','289','291','292','294','295','296','297','298')
$final_size = 2048
$rescale_markers = 1
$rescale_map = 1

$zone_info = @{}
(((Get-Content ".\zones.json" | Out-String) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/') | ConvertFrom-Json).psobject.properties | foreach { $zone_info[$_.Name] = $_.Value }

Function get_map_name {
  param($zone_id, $map_index, $n_maps)
  
  $map_name = $zone_name + "_$map_index.png"
  if ($n_maps -lt 2) {
      $map_name = $zone_id + "_0.png"
  }
  return $map_name
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