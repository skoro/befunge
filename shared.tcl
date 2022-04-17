 
proc K { a b } { set a }

proc times { count body } {
    for { set i 0 } { $i < $count } { incr i } {
        uplevel 1 $body
    }
}

#
# Parse a string of the format "-key val [etc]" into an array
# ie "-myKey myVal -foo bar" becomes:
#   argarray(myKey) = myVal
#   argarray(foo) = bar
#
# Source: https://github.com/flightaware/tcl-jira-api/blob/master/package/main.tcl
#
proc parse_args { _args _argarray } {
    upvar 1 $_argarray argarray

    unset -nocomplain argarray

    foreach { key value } $_args {
        set argarray([string range $key 1 end]) $value
    }
}
