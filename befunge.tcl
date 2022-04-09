package require Ttk

namespace import ttk::entry
namespace import oo::class
namespace import tcl::mathop::*

proc K { a b } { set a }

class create Stack {

    variable S
	
	constructor {} {
		my clear
	}
    
    method pop {} {
        if {[my is_empty]} { error "Stack is empty" }
        K [my top] [set S [lrange $S 0 end-1]]
    }
    
    method push args {
        lappend S {*}$args
    }
    
    method top {} {
        lindex $S end
    }
    
    method clear {} {
        set S {}
    }
    
    method is_empty {} {
        expr {[my size] == 0}
    }
    
    method values {} {
        return $S
    }
    
    method size {} {
        llength $S
    }
    
    method dup {} {
        my push [my top]
    }
    
    method swap {} {
        my push [my pop] [my pop]
    }
}

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
    
    method width {} {
        return $Width
    }
    
    method height {} {
        return $Height
    }
    
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

class create ProgramCounter {

    variable X Y DX DY
    
    constructor {} { my reset }
    
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
        set X $x
        set Y $y
    }
}

class create Interp {
    
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
