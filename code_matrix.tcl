namespace eval ::befunge {

    namespace export CodeMatrix

    ::oo::class create CodeMatrix {

        variable Width Height Code

        constructor { { width 80 } { height 25 } } {
            set Width $width
            set Height $height
            my clear
        }

        method clear {} {
            for { set y 0 } { $y < $Height } { incr y } {
                for { set x 0 } { $x < $Width } { incr x } {
                    set Code($x,$y) ""
                }
            }
        }

        method width {} { return $Width }

        method height {} { return $Height }

        method set_op { x y op } {
            my ValidateBounds $x $y
            set Code($x,$y) $op
        }

        method get { x y } {
            my ValidateBounds $x $y
            return $Code($x,$y)
        }

        method ValidateBounds { x y } {
            if { ! ($x >= 0 && $x < $Width && $y >= 0 && $y < $Height) } {
                error [format "Pos out of bounds (%d, %d) got (%d, %d)" $Width $Height $x $y]
            }
        }

        method to_string {} {
            for { set y 0 } { $y < $Height } { incr y } {
                for { set x 0 } { $x < $Width } { incr x } {
                    set op $Code($x,$y)
                    append result [expr { $op eq "" ? " " : $op }]
                }
                append result "\n"
            }
            return $result
        }

        method from_string str {
            set lines [split $str "\n"]
            # skip trailing new line character
            if {[lindex $lines end] == {}} {
                set lines [lrange $lines 0 end-1]
            }
            if {[set len [llength $lines]] > $Height} {
                error [ \
                    format "Lines count \"%d\" is more than code matrix height \"%d\"" \
                        $len $Height]
            }
            set y 0
            set n 1
            foreach line $lines {
                if {[set len [string length $line]] > $Width} {
                    error [ \
                        format "String length \"%d\" of line \"%d\" is more than matrix width \"%d\"" \
                            $len $n $Width]
                }
                for { set i 0 } { $i < $Width } { incr i } {
                    my set_op $i $y [string index $line $i]
                }
                incr y
                incr n
            }
        }
    }
}
