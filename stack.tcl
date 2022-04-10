
proc K { a b } { set a }

namespace eval ::befunge {

    namespace import ::oo::class
    namespace export Stack

    class create Stack {

        variable S

        constructor { args } {
            my clear
            if {[llength $args] > 0} { my push {*}$args }
        }

        method pop {} {
            if {[my is_empty]} { error "Stack is empty" }
            K [my top] [set S [lrange $S 0 end-1]]
        }

        method push args { lappend S {*}$args }

        method top {} { lindex $S end }

        method clear {} { set S {} }

        method is_empty {} { expr {[my size] == 0} }

        method values {} { return $S }

        method size {} { llength $S }

        method dup {} { my push [my top] }

        method swap {} { my push [my pop] [my pop] }
    }
}
