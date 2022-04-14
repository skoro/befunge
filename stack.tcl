
# TODO: move to separate file
proc K { a b } { set a }

namespace eval ::befunge {

    namespace export Stack

    ::oo::class create Stack {

        variable S

        constructor { args } {
            my clear
            if {[llength $args] > 0} { my push {*}$args }
        }

        method pop {} {
            if {[my is_empty]} { error "Stack is empty" }
            K [my top] [set S [lrange $S 0 end-1]]
        }

        # pop as a list
        method lpop { {count 1} } {
            for { set i 0 } { $i < $count } { incr i } {
                lappend result [my pop]
            }
            return $result
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
