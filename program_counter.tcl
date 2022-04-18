namespace eval ::befunge {

    namespace export ProgramCounter

    ::oo::class create ProgramCounter {

        variable X Y DX DY

        constructor {} {
            set X 0
            set Y 0
            my reset
        }

        method reset {} {
            my move_to 0 0
            my right
        }

        method x {} { return $X }

        method y {} { return $Y }

        method xy {} { return [list $X $Y] }

        method set_x { x } { set X $x }
        method set_y { y } { set Y $y }

        method up {} {
            set DX 0
            set DY -1
        }

        method down {} {
            set DX 0
            set DY 1
        }

        method left {} {
            set DX -1
            set DY 0
        }

        method right {} {
            set DX 1
            set DY 0
        }

        method move {} {
            incr X $DX
            incr Y $DY
        }

        method move_to { x y } {
            my set_x $x
            my set_y $y
        }
    }
}
