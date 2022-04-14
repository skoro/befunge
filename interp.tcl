namespace import ::tcl::mathop::*

namespace eval ::befunge {

    namespace export Interp

    ::oo::class create Interp {

        variable Stack Code PC StringMode State

        constructor { stack code pc } {
            set Stack $stack
            set Code  $code
            set PC    $pc
            set State ""
        }

        method init {} {
            $Stack clear
            $Code clear
        }

        # Getters
        method stack {} { return $Stack }
        method code {} { return $Code }
        method pc {} { return $PC }

        method start {} {
            $PC reset
            set StringMode 0
            set State "running"
        }

        method stop {} {
            set State "stopped"
        }

        method step {} {
            if {! [my isRunning]} {
                error "State is not \"running\""
            }
            set op [$Code get {*}[$PC xy]]
            if {[my isStringMode]} {
                my OpPushChar $op
            } else {
                my HandleOp $op
            }
            my MovePC
        }

        method HandleOp { op } {
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
                "?"  { my OpRandomDir }
                "_"  { my OpHorizMove }
                "|"  { my OpVertMove }
                "\"" { my OpEnableStringMode }
                ":"  { my OpStackDup }
                "\\" { my OpStackSwap }
                "\$" { my OpStackPop }
                "."  {}
                ","  {}
                "#"  { my OpStepOver }
                "g"  {}
                "p"  {}
                "&"  {}
                "~"  {}
                "@"  { my stop }
                ""   {}
                default {
                    if {[string is digit $op]} {
                        $Stack push $op
                    } else {
                        my OpUnknown $op
                    }
                }
            }
        }

        method OpMath { cmd } {
            $Stack push [$cmd {*}[lreverse [$Stack lpop 2]]]
        }

        method OpLogicalNot {} {
            $Stack push [== [$Stack pop] 0]
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

        method OpEnableStringMode {} { set StringMode 1 }

        method OpHorizMove {} {
            set val [$Stack pop]
            $PC [expr { $val == 0 ? "right" : "left" }]
        }

        method OpVertMove {} {
            set val [$Stack pop]
            $PC [expr { $val == 0 ? "down" : "up" }]
        }

        method OpRandomDir {} {
            my OpPCMove [ \
                lindex {left right up down} [expr {int([::tcl::mathfunc::rand] * 4)}] \
            ]
        }

        method OpStepOver {} {
            my MovePC
        }

        method OpPushChar { char } {
            if {[string is ascii $char]} {
                if { $char eq "\"" } {
                    set StringMode 0
                } else {
                    $Stack push [scan $char %c]
                }
            } else {
                error "Only ascii characters are allowed"
            }
        }

        method OpUnknown { op } {
            error [format "Uknown op code: %s" $op]
        }

        method isStringMode {} { == $StringMode 1 }
        method isRunning {} { eq $State "running" }
        method isStopped {} { eq $State "stopped" }

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
