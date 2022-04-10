namespace eval ::befunge {

    namespace export Interp

    ::oo::class create Interp {

        variable Stack Code PC StringMode

        constructor { stack code pc } {
            set Stack $stack
            set Code $code
            set PC $pc
        }

        method init {} {
            $Stack clear
            $Code clear
        }

        method start {} {
            $PC reset
            set StringMode 0
        }

        method run {} {
            set op [$Code get {*}[$PC xy]]
            switch -- $op {
                "+"  { my OpMath + }
                "-"  { my OpMath - }
                "*"  { my OpMath * }
                "/"  { my OpMath / }
                "%"  { my OpMath % }
                "!"  { my OpLogicalNot }
                "`"  { my OpGreaterThan }
                ">"  { my OpPCMove right }
                "<"  { my OpPCMove left }
                "^"  { my OpPCMove up }
                "v"  { my OpPCMove down }
                "?"  { }
                "_"  { my OpHorizMove }
                "|"  { my OpVertMove }
                "\"" { my OpToggleStringMode }
                ":"  { my OpStackDup }
                "\\" { my OpStackSwap }
                "\$" { my OpStackPop }
                "."  {}
                ","  {}
                "#"  {}
                "g"  {}
                "p"  {}
                "&"  {}
                "~"  {}
                "@"  {}
                ""   {}
                default { my OpUnknown $op }
            }
            my MovePC
        }

        method OpMath { cmd } {
            $Stack push [$cmd [$Stack pop] [$Stack pop]]
        }

        method OpLocicalNot {} {
            set val [$Stack pop]
            $Stack push [expr { $val == 0 ? 1 : 0 }]
        }

        method OpGreaterThan {} {
            set a [$Stack pop]
            set b [$Stack pop]
            $Stack push [expr { $b > $a ? 1 : 0 }]
        }

        method OpStackDup {} { $Stack dup }

        method OpStackSwap {} { $Stack swap }

        method OpStackPop {} { $Stack pop }

        method OpPCMove { dir } { $PC $dir }

        method OpToggleStringMode {} { set StringMode [! $StringMode ] }

        method OpHorizMove {} {
            set val [$Stack pop]
            $PC [expr { $val == 0 ? "right" : "left" }]
        }

        method OpVertMove {} {
            set val [$Stack pop]
            $PC [expr { $val == 0 ? "down" : "up" }]
        }

        method OpUnknown { op } {
            if {[my isStringMode]} {
                $Stack push $op
            } else {
                error [format "Uknown op code: %s" $op]
            }
        }

        method isStringMode {} { == $StringMode 1 }

        method MovePC {} {
            $PC move
            if {[$PC x] >= [$Code width]} {
                $PC set_x 0
            }
            if {[$PC x] < 0} {
                $PC set_x [- [$Code width] 1]
            }
            if {[$PC y] >= [$Code height]} {
                $PC set_y 0
            }
            if {[$PC y] < 0} {
                $PC set_y [- [$Code height] 1]
            }
        }
    }
}
