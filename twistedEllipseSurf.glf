global scaleLawCurve pi
set pi 3.1415926535897931
set scaleLawCurve [pw::DatabaseEntity getByName {computeSurfacePoint-xyScale}]
#set profileCurve [pw::DatabaseEntity getByName {computeSurfacePoint-profile}]

proc computeSurfacePoint { u v uvMin uvMax } {

  global scaleLawCurve pi
  set uMin [expr { 1.0 * [lindex $uvMin 0]}]
  set vMin [expr { 1.0 * [lindex $uvMin 1]}]
  set uMax [expr { 1.0 * [lindex $uvMax 0]}]
  set vMax [expr { 1.0 * [lindex $uvMax 1]}]

  # 1st axis
  set R1 0.25

  # 2nd axis
  set R2 0.4

  # number of rotations over the total Z length
  set N 2.0

  # calc law curve scale
  set t [expr { ($v / ($vMax - $vMin)) }]
  # x-distance is xyScale
  set xyz [$scaleLawCurve getXYZ -parameter $t]
  set xyScale [lindex $xyz 0]
  #puts "uv($u, $v) xyz=\{$xyz\} scale=$xyScale @ t=$t"

  set phi [expr { $u * $pi * 2.0 } ]
  set theta [expr { $N * $v * $pi * 2.0 } ]

  set x [expr { ($R1 * cos($phi) * cos($theta) - $R2 * sin($phi) * sin($theta)) * $xyScale }]
  set y [expr { ($R1 * cos($phi) * sin($theta) + $R2 * sin($phi) * cos($theta)) * $xyScale }]
  set z [expr { $v }]

  return "$x $y $z"
}

proc beginSurface { uStart vStart uEnd vEnd uNumPoints vNumPoints } {
  puts [info level 0]
}

proc beginSurfaceV { v } {
  puts [info level 0]
}

proc endSurfaceV { v } {
  puts [info level 0]
}

proc endSurface { } {
  puts [info level 0]
}
