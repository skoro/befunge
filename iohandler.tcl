
namespace eval ::befunge {

    ::oo::class create IOHandler {

        method input {} {
            error "Input not implemented"
        }

        method output {} {
            error "Output not implemented"
        }
    }
}
