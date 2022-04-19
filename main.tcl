package require Tk 8.6

set BASE_DIR [file dirname [info script]]

source [file join $BASE_DIR shared.tcl]
source [file join $BASE_DIR keysyms.tcl]
source [file join $BASE_DIR stack.tcl]
source [file join $BASE_DIR program_counter.tcl]
source [file join $BASE_DIR code_matrix.tcl]
source [file join $BASE_DIR interp.tcl]

proc load_image { name filename } {
    global BASE_DIR
    return [image create photo $name \
        -file [file join $BASE_DIR images $filename]]
}

::oo::class create EditState {

    variable Editing RectTag

    constructor {} {
        set Editing 0
    }

    method start { tag } {
        set Editing 1
        set RectTag $tag
    }

    method is_editing {} { return [expr {$Editing == 1}] }

    method tag {} { return $RectTag }

    method done {} {
        set Editing 0
        set RectTag ""
    }
}

::oo::class create CodeCanvas {

    superclass ::befunge::CodeMatrix

    variable W CW
    variable CanvasWidth CanvasHeight
    variable RW RH
    variable Options
    variable EditState

    #
    # Options:
    #   -width
    #   -height
    #   -font
    #   -rectBgActive
    #   -rectColor
    #   -rectBgEdit
    constructor { w args } {
        set EditState [EditState new]
        set W $w
        my DefaultOptions
        my ParseArgs $args
        lassign [my CalcRectSize] RW RH
        my CalcCanvasSize
        set CW [my BuildCanvas]
        set Options(rectBgNormal) [lindex [$CW config -bg] end]
        my RenderGrid
        my SetBindings
        next $Options(width) $Options(height)
    }

    method DefaultOptions {} {
        set Options(width) 80
        set Options(height) 25
        set Options(font) TkDefaultFont
        set Options(rectBgActive) LightSeaGreen
        set Options(rectColor) Grey
        set Options(rectBgEdit) Yellow
        set Options(rectBgExec) Red
    }

    method ParseArgs { _args } {
        foreach { key value } $_args {
            set Options([string range $key 1 end]) $value
        }
    }

    method canvas {} { return $CW }
    method frame {} { return $W }

    method CalcRectSize {} {
        lassign [my GetFontSize] fontW fontH
        return [list [expr {$fontW + 4}] [expr {$fontH + 2}]]
    }

    method CalcCanvasSize {} {
        set CanvasWidth [expr { $Options(width) * $RW + 4}]
        set CanvasHeight [expr { $Options(height) * $RH + 4}]
    }

    method BuildCanvas {} {
        ::ttk::frame $W
        canvas $W.canvas \
            -width $CanvasWidth \
            -height $CanvasHeight \
            -xscrollcommand [list $W.xscroll set] \
            -yscrollcommand [list $W.yscroll set] \
            -scrollregion [list 0 0 $CanvasWidth $CanvasHeight]
        ::ttk::scrollbar $W.xscroll -orient horizontal \
            -command [list $W.canvas xview]
        ::ttk::scrollbar $W.yscroll -orient vertical \
            -command [list $W.canvas yview]
        grid $W.canvas $W.yscroll -sticky news
        grid $W.xscroll -sticky ew
        grid rowconfigure $W 0 -weight 1
        grid columnconfigure $W 0 -weight 1
        return $W.canvas
    }

    method RenderGrid {} {
        for { set y 0 } { $y < $Options(height) } { incr y } {
            set sy [expr {$y * $RH + 1}]
            for { set x 0 } { $x < $Options(width) } { incr x } {
                set sx [expr {$x * $RW + 1}]
                $CW create rect $sx $sy [expr {$sx + $RW}] [expr {$sy + $RH}] \
                    -fill $Options(rectBgNormal) \
                    -outline $Options(rectColor) \
                    -tags [list [my RectTagXY $x $y] rect]
                $CW create text [expr {$sx + 2}] $sy \
                    -anchor nw \
                    -font $Options(font) \
                    -tags [list [my TextTagXY $x $y] text]
            }
        }
    }

    method GetFontSize { } {
        set height [font metrics $Options(font) -linespace]
        set width 0
        for { set i 33 } { $i < 127 } { incr i } {
            set w [font measure $Options(font) [format "%c" $i]]
            if { $w > $width } {
                set width $w
            }
        }
        return [list $width $height]
    }

    method clear {} {
        next
        $CW itemconfigure text -text ""
        my reset
    }

    method reset {} {
        my SetRectAsNormal rect
    }

    method enable {} {
        #TODO:
    }

    method disable {} {
        #TODO:
    }

    method set_op { x y op } {
        next $x $y $op
        $CW itemconfigure [my TextTagXY $x $y] -text $op
    }

    method SetRectAsNormal { tag } {
        $CW itemconfigure $tag -fill $Options(rectBgNormal)
    }

    method SetRectAsActive { tag } {
        $CW itemconfigure $tag -fill $Options(rectBgActive)
    }

    method SetRectAsEdited { tag } {
        $CW itemconfigure $tag -fill $Options(rectBgEdit)
    }

    method SetBindings {} {
        $CW bind all <Button-1> [my ObjectCallback OnButton1Press]
        $CW bind all <Button-3> [my ObjectCallback OnButton3Press]
        $CW bind all <Any-Enter> [my ObjectCallback OnEnterLeaveRect SetRectAsActive]
        $CW bind all <Any-Leave> [my ObjectCallback OnEnterLeaveRect SetRectAsNormal]

        # Canvas vertical scroll (mouse wheel)
        bind $CW <4> { %W yview scroll -1 units }
        bind $CW <5> { %W yview scroll 1 units }
        # Canvas horizontal scroll (shift + mouse wheel)
        bind $CW <Shift-4> { %W xview scroll -1 units }
        bind $CW <Shift-5> { %W xview scroll 1 units }

        bind $CW <KeyRelease> [my ObjectCallback OnKeyPress %K]
    }

    method ObjectCallback { callback args } {
        return [namespace code [list my $callback {*}$args]]
    }

    method OnButton1Press {} {
        set tag [my GetCurrentRectTag]
        if {$tag eq ""} {
            return
        }
        if {! [$EditState is_editing]} {
            focus $CW
            my SetRectAsEdited $tag
            $EditState start $tag
        }
    }

    method OnButton3Press {} {
        if {[$EditState is_editing]} {
            my DoneEdit
        }
    }

    method OnKeyPress { key } {
        if {[$EditState is_editing]} {
            switch -- [string tolower $key] {
                "delete" - "backspace" {
                    set char ""
                }
                "escape" {
                    my DoneEdit
                    return
                }
                default {
                    try {
                        set char [keysym_to_char $key]
                    } on error _ {
                        return
                    }
                }
            }
            my set_op {*}[my GetTagXY [$EditState tag]] $char
            my DoneEdit
        }
    }

    method OnEnterLeaveRect { rectMethod } {
        set tag [my GetCurrentRectTag]
        if {($tag ne "") && ! [$EditState is_editing]} {
            my $rectMethod $tag
        }
    }

    method GetCurrentRectTag {} {
        set tags [$CW gettags current]
        # In order to find a selected rect, text is also
        # considered as rect.
        set rect [lsearch -inline -glob $tags *-*]
        if {($rect ne "") && ([string first "text" $rect] == 0)} {
            return [string replace $rect 0 3 "rect"]
        }
        return $rect
    }

    method GetTagXY { tag } {
        return [lrange [split $tag "-"] 1 end]
    }

    method DoneEdit {} {
        my SetRectAsNormal [$EditState tag]
        $EditState done
    }

    method TextTagXY { x y } {
        return [format "text-%d-%d" $x $y]
    }

    method RectTagXY { x y } {
        return [format "rect-%d-%d" $x $y]
    }
}

::oo::class create PCCanvas {

    superclass ::befunge::ProgramCounter

    variable CW

    constructor { canvas } {
        set CW $canvas
        next
    }

    method move {} {
        my RevertOldPos
        next
        my FillNewPos
    }

    method set_x { x } {
        my RevertOldPos
        next $x
        my FillNewPos
    }

    method set_y { y } {
        my RevertOldPos
        next $y
        my FillNewPos
    }

    method RevertOldPos {} {
        $CW itemconfigure [my Tag] -fill white
    }

    method FillNewPos {} {
        $CW itemconfigure [my Tag] -fill blue
    }

    method Tag {} {
        return [format "rect-%d-%d" [my x] [my y]]
    }
}

::oo::class create Interp {

    superclass ::befunge::Interp

    method start {} {
        next
        [my code] reset
    }

    method stop {} {
        next
    }
}

namespace eval ::befunge::app {

    variable interp
    variable toolbar

    proc init {} {
        variable interp
        variable toolbar

        wm title . "Befunge"

        LoadImages

        set toolbar [Toolbar .t]
        set code [CodeCanvas new .c -width 80 -height 25 -font TkDefaultFont]

        pack $toolbar -side top -fill x
        pack .c -fill both -expand yes

        . configure -menu [AppMenu]

        set stack [::befunge::Stack new]
        set pc [PCCanvas new [$code canvas]]
        set interp [Interp new $stack $code $pc]
    }

    proc LoadImages {} {
        load_image img.brick_go brick_go.png
        load_image img.bug bug.png
        load_image img.lightning lightning.png
    }

    proc AppMenu {} {
        set w [menu .m]

        set m [menu $w.file -tearoff 0]
        $m add command -label "New"
        $m add command -label "Open..."
        $m add command -label "Save"
        $m add separator
        $m add command -label "Quit"
        $w add cascade -label "File" -underline 0 -menu $m

        set m [menu $w.run -tearoff 0]
        $m add command -label "Run" -compound left -image img.lightning
        $m add command -label "Step"
        $m add command -label "Stop"
        $w add cascade -label "Run" -underline 0 -menu $m

        return $w
    }

    proc Toolbar { w } {
        set t [frame $w]

        ttk::button $t.new -text "New" -style Toolbutton \
            -command [namespace code DoNew]
        ttk::button $t.open -text "Open" -style Toolbutton
        ttk::button $t.save -text "Save" -style Toolbutton

        ttk::separator $t.sep1 -orient vertical

        ttk::button $t.start -text "Start" \
            -style Toolbutton \
            -compound left \
            -command [namespace code DoStart]
        ttk::button $t.step -text "Step" \
            -style Toolbutton \
            -compound left \
            -image img.brick_go \
            -command [namespace code DoStep]
        ttk::button $t.stop -text "Stop" \
            -style Toolbutton \
            -compound left \
            -command [namespace code DoStop]

        pack $t.new $t.open $t.save -side left -padx 2 -pady 2
        pack $t.sep1 -side left -fill y -padx 2 -pady 2
        pack $t.start $t.step $t.stop -side left -padx 2 -pady 2

        return $t
    }

    proc ToolbarState { args } {
        variable toolbar
        foreach item $args {
            foreach { btn newState} $item {
                $toolbar.$btn state $newState
            }
        }
    }

    proc DoNew {} {
        variable interp
        $interp init
        ToolbarState {start !disabled} {step disabled} {stop disabled}
    }

    proc DoStart {} {
        variable interp
        $interp start
        ToolbarState {start disabled} {step !disabled} {stop !disabled}
    }

    proc DoStep {} {
        variable interp
        # TODO: catch
        $interp step
    }

    proc DoStop {} {
        variable interp
        # TODO: catch
        $interp stop
        ToolbarState {stop disabled} {step disabled} {start !disabled}
    }

    proc main { args } {
        init
        DoNew
    }
}

::befunge::app::main
