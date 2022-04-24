
namespace eval ::befunge {

    namespace export IOHandler

    ::oo::class create IOHandler {

        method input_int {} {
            error "Input integer is not implemented"
        }

        method input_char {} {
            error "Input character is not implemented"
        }

        method output value {
            error "Output is not implemented"
        }

        method flush {} {
        }
    }
}
