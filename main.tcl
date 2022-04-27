package require Tk 8.6

set BASE_DIR [file dirname [info script]]

source [file join $BASE_DIR shared.tcl]
source [file join $BASE_DIR keysyms.tcl]
source [file join $BASE_DIR stack.tcl]
source [file join $BASE_DIR program_counter.tcl]
source [file join $BASE_DIR code_matrix.tcl]
source [file join $BASE_DIR interp.tcl]
source [file join $BASE_DIR iohandler.tcl]

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
        my RenderGrid
        my RenderRuler
        my SetBindings
        next $Options(width) $Options(height)
    }

    method DefaultOptions {} {
        set Options(width) 80
        set Options(height) 25
        set Options(font) TkDefaultFont
        set Options(rulerFont) TkFixedFont
        set Options(rulerColor) Black
        set Options(rectBgActive) LightSeaGreen
        set Options(rectBgNormal) LightGrey
        set Options(rectColor) DarkGrey
        set Options(rectBgEdit) Yellow
    }

    method ParseArgs _args {
        foreach { key value } $_args {
            set Options([string range $key 1 end]) $value
        }
    }

    method canvas {} { return $CW }
    method frame {} { return $W }

    method CalcRectSize {} {
        lassign [my GetFontSize $Options(font)] font_w font_h
        return [list [expr {$font_w + 4}] [expr {$font_h + 4}]]
    }

    method CalcRulerSize {} {
        return [list \
            [font measure $Options(rulerFont) "$Options(width)"] \
            [font metrics $Options(rulerFont) -linespace] \
        ]
    }

    method CalcCanvasSize {} {
        lassign [my CalcRulerSize] ruler_w ruler_h
        set CanvasWidth [expr { $Options(width) * $RW + $ruler_w + 4 }]
        set CanvasHeight [expr { $Options(height) * $RH + $ruler_h + 4 }]
    }

    method BuildCanvas {} {
        ::ttk::frame $W
        canvas $W.canvas \
            -width $CanvasWidth \
            -height $CanvasHeight \
            -xscrollcommand [list $W.xscroll set] \
            -yscrollcommand [list $W.yscroll set] \
            -scrollregion [list 0 0 $CanvasWidth $CanvasHeight] \
            -highlightthickness 0
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
        lassign [my CalcRulerSize] ruler_w ruler_h
        for { set y 0 } { $y < $Options(height) } { incr y } {
            set sy [expr {$y * $RH + $ruler_h + 2}]
            for { set x 0 } { $x < $Options(width) } { incr x } {
                set sx [expr {$x * $RW + $ruler_w + 2}]
                $CW create rect $sx $sy [expr {$sx + $RW}] [expr {$sy + $RH}] \
                    -fill $Options(rectBgNormal) \
                    -outline $Options(rectColor) \
                    -tags [list [my RectTagXY $x $y] rect]
                $CW create text [expr {$sx + $RW/2}] [expr {$sy + $RH/2}] \
                    -font $Options(font) \
                    -tags [list [my TextTagXY $x $y] text]
            }
        }
    }

    method RenderRuler {} {
        lassign [my CalcRulerSize] ruler_w ruler_h
        # horizontal ruler
        set y [expr {$ruler_h/2}]
        for { set i 1 } { $i <= $Options(width) } { incr i } {
            set x [expr { ($i-1) * $RW + $ruler_w + 2 + $RW /2 }]
            $CW create text $x $y \
                -text $i \
                -font $Options(rulerFont) \
                -fill $Options(rulerColor)
        }
        # vertical ruler
        set x [expr {$ruler_w/2}]
        for { set i 1 } { $i <= $Options(height) } { incr i } {
            set y [expr { ($i-1) * $RH + $ruler_h + 2 + $RH / 2}]
            $CW create text $x $y \
                -text $i \
                -font $Options(rulerFont) \
                -fill $Options(rulerColor)
        }
    }

    # TODO: move to shared ?
    method GetFontSize font {
        set height [font metrics $font -linespace]
        set width 0
        for { set i 33 } { $i < 127 } { incr i } {
            set w [font measure $font [format "%c" $i]]
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
        $CW configure -state normal
    }

    method disable {} {
        $CW configure -state disabled
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

    constructor canvas {
        set CW $canvas
        next
    }

    method move {} {
        my RevertOldPos
        next
        my FillNewPos
    }

    method set_x x {
        my RevertOldPos
        next $x
        my FillNewPos
    }

    method set_y y {
        my RevertOldPos
        next $y
        my FillNewPos
    }

    method RevertOldPos {} {
        # TODO: should be configurable via options
        $CW itemconfigure [my Tag rect] -fill white
        $CW itemconfigure [my Tag text] -fill black
    }

    method FillNewPos {} {
        # TODO: should be configurable via options
        $CW itemconfigure [my Tag rect] -fill blue
        $CW itemconfigure [my Tag text] -fill white
    }

    method Tag name {
        return [format "%s-%d-%d" $name [my x] [my y]]
    }
}

::oo::class create Interp {

    superclass ::befunge::Interp

    method start {} {
        next
        [my code] reset
        [my code] disable
    }

    method stop {} {
        next
        [my code] enable
    }
}

::oo::class create StackUI {

    superclass ::befunge::Stack

    variable W L

    constructor w {
        set W [::ttk::frame $w]
        my RenderUI
        my ListHeader
        next
    }

    method RenderUI {} {
        ::ttk::label $W.title -text "Stack" -background Grey -foreground Black
        set L $W.lb
        listbox $L -yscrollcommand [list $W.vert set] \
            -font TkFixedFont
        ::ttk::scrollbar $W.vert -command [list $L yview]
        pack $W.title -side top -fill x
        pack $W.vert -side right -fill y
        pack $L -side left -fill both -expand yes
    }

    method ListHeader {} {
        $L insert 0 [format " %-6s %-4s %-5s" "Dec" "Hex" "Char"]
        $L itemconfigure 0 \
            -background DarkGrey \
            -foreground Black \
            -selectbackground DarkGrey \
            -selectforeground Black
    }

    method frame {} {
        return $W
    }

    method listbox {} {
        return $L
    }

    method pop {} {
        $L delete 1
        next
    }

    method push args {
        next {*}$args
        my AddValues {*}$args
    }

    method AddValues args {
        foreach arg $args {
            $L insert 1 [ \
                format " %-6d 0x%02x   %c" $arg $arg \
                    [expr {($arg > 32 && $arg < 255) ? $arg : 32}] \
            ]
        }
    }

    method clear {} {
        next
        $L delete 1 end
    }
}

::oo::class create IOHandlerUI {

    superclass ::befunge::IOHandler

    variable W Out In

    constructor { w } {
        set W [::ttk::frame $w]
        my RenderUI
    }

    method frame {} {
        return $W
    }

    method RenderUI {} {
        ::ttk::label $W.titleOut -text "Output" -background Grey -foreground Black
        set f [::ttk::frame $W.f]
        set Out $f.out
        text $Out \
            -yscrollcommand [list $f.vert set] \
            -height 10
        bind $Out <KeyPress> break; # set output as readonly widget
        ::ttk::scrollbar $f.vert -command [list $f.t yview]
        pack $f.vert -side right -fill y
        pack $f.out -fill both -expand yes
        pack $W.titleOut -side top -fill x
        pack $f -side top -fill both -expand yes
    }

    method ModalInput { msg } {
        set In ""
        set t [toplevel .in]
        wm title $t "Input"
        set f1 [::ttk::frame $t.f1]
        ::ttk::label $f1.title -text "$msg:"
        ::ttk::entry $f1.in -textvariable [self]::In
        set f2 [::ttk::frame $t.f2]
        ::ttk::button $f2.ok -text "OK" -command [list destroy $t]
        bind $f1.in <Return> [list $f2.ok invoke]
        pack $f1 -side top -fill x
        pack $f1.title $f1.in -side left -anchor w -padx 4
        pack $f2 -side bottom
        pack $f2.ok -pady 4
        focus $f1.in
        grab $t
        raise $t
        tkwait window $t
        return $In
    }

    method input_int {} {
        my ModalInput "Integer"
    }

    method input_char {} {
        my ModalInput "Character"
    }

    method output value {
        $Out insert end $value
        $Out see end
    }

    method flush {} {
        $Out delete 0.0 end
    }
}

namespace eval ::befunge::app {

    variable Int
    variable Toolbar
    variable Speed
    variable RunTimer

    proc init {} {
        variable Int
        variable Toolbar
        variable Speed

        wm title . "Befunge"

        LoadImages

        set Speed 5
        set Toolbar [Toolbar .t]

        set main_pane [panedwindow .pw -orient vertical]

        set font [font create code_font -family fixed -size 8 -weight bold]
        set ruler_font [font create ruler_font -family fixed -size 6]
        set code [CodeCanvas new $main_pane.c -width 80 -height 25 -font $font -rulerFont $ruler_font]
        set bottom_frame [frame $main_pane.bt]
        set stack [StackUI new $bottom_frame.st]
        set io [IOHandlerUI new $bottom_frame.io]
        pack [$stack frame] -side left -fill y -padx 2 -pady 2
        pack [$io frame] -side right -fill both -expand yes -padx 2 -pady 2

        $main_pane add [$code frame] $bottom_frame

        pack $Toolbar -side top -fill x
        pack $main_pane -fill both -expand yes

        . configure -menu [AppMenu]

        set pc [PCCanvas new [$code canvas]]
        set Int [Interp new $stack $code $pc $io]
    }

    proc LoadImages {} {
        load_image ico.run control_play_blue.png
        load_image ico.pause control_pause_blue.png
        load_image ico.continue control_repeat_blue.png
        load_image ico.stop control_stop_blue.png

        load_image ico.new table.png
        load_image ico.open folder.png
        load_image ico.save table_save.png
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
        $m add command -label "Run" -compound left
        $m add command -label "Step"
        $m add command -label "Stop"
        $w add cascade -label "Run" -underline 0 -menu $m

        return $w
    }

    proc Toolbar { w } {
        set t [frame $w]

        ttk::button $t.new -text "New" \
            -style Toolbutton \
            -compound left \
            -image ico.new \
            -command [namespace code DoNew]
        ttk::button $t.open -text "Open" \
            -style Toolbutton \
            -compound left \
            -image ico.open \
            -command [namespace code DoOpenFile]
        ttk::button $t.save -text "Save" \
            -style Toolbutton \
            -compound left \
            -image ico.save \
            -command [namespace code DoSaveFile]

        ttk::separator $t.sep1 -orient vertical

        ttk::button $t.run -text "Run" \
            -style Toolbutton \
            -compound left \
            -image ico.run \
            -command [namespace code DoRun]
        ttk::button $t.pause -text "Pause" \
            -style Toolbutton \
            -compound left \
            -image ico.pause \
            -command [namespace code DoPause]
        ttk::button $t.continue -text "Continue" \
            -style Toolbutton \
            -compound left \
            -image ico.continue \
            -command [namespace code DoContinue]
        ttk::button $t.stop -text "Stop" \
            -style Toolbutton \
            -compound left \
            -image ico.stop \
            -command [namespace code DoStop]

        ttk::separator $t.sep2 -orient vertical

        ttk::label $t.speed_lb -text "Speed:"
        ttk::scale $t.speed -from 1 -to 20 \
            -orient horizontal \
            -length 100 \
            -variable [namespace current]::Speed \
            -command [list apply {{varName idx} {
                upvar 1 $varName var
                set var [tcl::mathfunc::int $idx]
            }} [namespace current]::Speed]
        ttk::label $t.speed_val -textvariable [namespace current]::Speed

        pack $t.new $t.open $t.save -side left -padx 2 -pady 2
        pack $t.sep1 -side left -fill y -padx 2 -pady 2
        pack $t.run $t.pause $t.continue $t.stop -side left -padx 2 -pady 2
        pack $t.sep2 -side left -fill y -padx 2 -pady 2
        pack $t.speed_lb $t.speed $t.speed_val -side left -padx 4

        return $t
    }

    proc ToolbarState { args } {
        variable Toolbar
        foreach item $args {
            foreach { btn newState} $item {
                $Toolbar.$btn state $newState
            }
        }
    }

    proc DoNew {} {
        variable Int
        $Int init
        ToolbarState {run !disabled} {pause disabled} {continue disabled} {stop disabled}
    }

    proc DoRun {} {
        variable Int
        ResetTimer
        $Int start
        ToolbarState {run disabled} {pause !disabled} {stop !disabled}
        ToolbarState {new disabled} {open disabled} {save disabled}
        RunLoop
    }

    proc RunLoop {} {
        variable Int
        variable RunTimer
        variable Speed

        try {
            $Int step
        } trap STATE_STOPPED _ {
            # nothing to do...
        } on error msg {
            DoStop
            ShowError $msg
        }

        if {[$Int isStopped]} {
            DoStop
        }

        set RunTimer [after [expr {$Speed * 30}] [namespace code RunLoop]]
    }

    proc DoPause {} {
        ResetTimer
        ToolbarState {pause disabled} {continue !disabled}
    }

    proc DoContinue {} {
        RunLoop
        ToolbarState {pause !disabled} {continue disabled}
    }

    proc DoStop {} {
        variable Int
        # TODO: catch
        $Int stop
        ToolbarState {run !disabled} {pause disabled} {continue disabled} {stop disabled}
        ToolbarState {new !disabled} {open !disabled} {save !disabled}
    }

    proc DoOpenFile {} {
        variable Int
        set filename [tk_getOpenFile]
        set check [::befunge::CodeMatrix new [[$Int code] width] [[$Int code] height]]
        if {$filename eq ""} {
            return
        }
        try {
            set fd [open $filename]
            set str [read $fd]
            $check from_string $str
            DoNew
            [$Int code] from_string $str
        } on error msg {
            ShowError [format "%s: %s" $filename $msg]
        } finally {
            close $fd
        }
    }

    proc DoSaveFile {} {
        variable Int
        set filename [tk_getSaveFile]
        if {$filename eq ""} {
            return
        }
        try {
            set fd [open $filename "w"]
            puts -nonewline $fd [[$Int code] to_string]
        } on error msg {
            ShowError [format "%s: %s" $filename $msg]
        } finally {
            close $fd
        }
    }

    proc ResetTimer {} {
        variable RunTimer
        catch { after cancel $RunTimer }
    }

    proc ShowError msg {
        tk_messageBox -icon error -parent . -type ok -message $msg -title "Error"
    }

    proc main { args } {
        init
        DoNew
    }
}

::befunge::app::main
