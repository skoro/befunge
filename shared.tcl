 
proc K { a b } { set a }

proc times { count body } {
    for { set i 0 } { $i < $count } { incr i } {
        uplevel 1 $body
    }
}
