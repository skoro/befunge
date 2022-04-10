namespace eval ::befunge {

    namespace import ::oo::class
    namespace export CodeMatrix

    class create CodeMatrix {

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
    }
}
