if { ![namespace exists pw::ExtrudeAlongRail] } {

package require PWI_Glyph

#*****************************************************************************
#                     CreateFromAnalyticFunction.glf procs
#*****************************************************************************

proc beginSurface { uStart vStart uEnd vEnd uNumPoints vNumPoints } {
  #puts [info level 0]
  pw::ExtrudeAlongRail::init {rail} {generatrix} $uStart $vStart $uEnd $vEnd
}


proc beginSurfaceV { v } {
  #puts [info level 0]
  pw::ExtrudeAlongRail::beginV $v
}


proc computeSurfacePoint { u v uvMin uvMax } {
  #puts [info level 0]
  return [pw::ExtrudeAlongRail::computePoint $u $v $uvMin $uvMax]
}


proc endSurfaceV { v } {
  #puts [info level 0]
  pw::ExtrudeAlongRail::endV $v
}


proc endSurface { } {
  #puts [info level 0]
}


#####################################################################
#              public namespace pw::ExtrudeAlongRail procs
#####################################################################

namespace eval pw::ExtrudeAlongRail {
  # init rail data
  variable railDbCrv {}
  variable railXPt {}
  variable railAnchorPt {}

  # init generatrix data
  variable gtxDbCrv {}

  # These transforms are fixed for a given run.
  variable xformToOrigin {}
  variable xformAlignGlobal {}

  # The working V curve on which u values are evaluated.
  #   == clone(gtxDbCrv) * xformToOrigin * xformAlignGlobal * <beginV xforms>
  variable vDbCrv {}
}


proc pw::ExtrudeAlongRail::init { railName gtxName uStart vStart uEnd vEnd } {
  # init rail data
  variable railDbCrv [pw::Database getByName $railName]
  variable railXPt [[pw::Database getByName "${railName}XPt"] getPoint]
  variable railAnchorPt [$railDbCrv getXYZ -parameter $vStart]

  # init generatrix data
  variable gtxDbCrv [pw::Database getByName $gtxName]
  set gtxXPt [[pw::Database getByName "${gtxName}XPt"] getPoint]
  set gtxDbZAxis [pw::Database getByName "${gtxName}ZAxis"]
  set gtxAnchorPt [[pw::Database getByName "${gtxName}Anchor"] getPoint]
  set gtxAxisSys [createAxisSystem $gtxAnchorPt $gtxXPt \
                    [pwu::Vector3 subtract [$gtxDbZAxis getXYZ -parameter 1.0] \
                                           [$gtxDbZAxis getXYZ -parameter 0.0]]]

  # These transforms are fixed for a given run.
  variable xformToOrigin [pwu::Transform translation \
    [pwu::Vector3 subtract {0 0 0} $gtxAnchorPt]]
  variable xformAlignGlobal [pwu::Transform inverse \
    [pwu::Transform rotation [lindex $gtxAxisSys 0] [lindex $gtxAxisSys 1]]]
}


proc pw::ExtrudeAlongRail::beginV { v } {
  variable vDbCrv
  variable gtxDbCrv
  variable railDbCrv
  variable railXPt
  variable railAnchorPt
  variable xformToOrigin
  variable xformAlignGlobal

  set pt [$railDbCrv getXYZ -parameter $v]
  # create working copy of generatrix curve
  set vDbCrv [clone $gtxDbCrv]
  # move vDbCrv from generatrix's anchorPt to origin
  $vDbCrv transform $xformToOrigin
  # rotate vDbCrv to align its axis system with the global axis system
  $vDbCrv transform $xformAlignGlobal

  # get rail tangent vec at pt
  set tangent [paramToCurveTangent $v $railDbCrv]
  # offset railXPt to vicinity of current pt on rail
  set xform [pwu::Transform translation [pwu::Vector3 subtract $pt $railAnchorPt]]
  set tmpRailXPt [pwu::Transform apply $xform $railXPt]
  # build rail axis system for pt, tmpRailXPt, and tangent
  set railAxisSys [createAxisSystem $pt $tmpRailXPt $tangent]

  # rotate vDbCrv to align with the rail axis system at pt
  set xform [pwu::Transform rotation [lindex $railAxisSys 0] [lindex $railAxisSys 1]]
  $vDbCrv transform $xform
  # move vDbCrv from origin to pt
  set xform [pwu::Transform translation [pwu::Vector3 subtract $pt {0 0 0}]]
  $vDbCrv transform $xform
}


proc pw::ExtrudeAlongRail::computePoint { u v uvMin uvMax } {
  variable vDbCrv
  return [$vDbCrv getXYZ -parameter $u]
}


proc pw::ExtrudeAlongRail::endV { v } {
  variable vDbCrv
  catch { $vDbCrv delete }
  set vDbCrv {}
}



#####################################################################
#            private namespace pw::ExtrudeAlongRail procs
#####################################################################

proc pw::ExtrudeAlongRail::paramToCurveTangent { param vDbCrv {dparam 0.01} } {
  # get pts just behind/ahead of param and build a vector from low to high
  set param0 [expr {$param - $dparam}]
  if { $param0 < 0.0 } {
    set param0 0.0
  }
  set param1 [expr {$param + $dparam}]
  if { $param1 > 1.0 } {
    set param1 1.0
  }
  return [pwu::Vector3 normalize [pwu::Vector3 subtract \
    [$vDbCrv getXYZ -parameter $param1] [$vDbCrv getXYZ -parameter $param0]]]
}


proc pw::ExtrudeAlongRail::createAxisSystem { anchorPt xPt zVec } {
  # xPt and zVec form the XZ plane
  set zAxis [pwu::Vector3 normalize $zVec]
  set xVec [pwu::Vector3 subtract $xPt $anchorPt]
  set yAxis [pwu::Vector3 normalize [pwu::Vector3 cross $zAxis $xVec]]
  set xAxis [pwu::Vector3 normalize [pwu::Vector3 cross $yAxis $zAxis]]
  return [list $xAxis $yAxis $zAxis]
}


proc pw::ExtrudeAlongRail::clone { ent } {
  set copier [pw::Application begin Copy $ent]
  set theClone [$copier getEntities]
  $copier end
  unset copier
  #puts "$ent / $theClone"
  return $theClone
}

} ;# ![namespace exists pw::ExtrudeAlongRail]
