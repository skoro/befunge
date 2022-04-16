package require Tk 8.6

set BASE_DIR [file dirname [info script]]

source [file join $BASE_DIR shared.tcl]
source [file join $BASE_DIR keysyms.tcl]

proc load_image { name filename } {
    global BASE_DIR
    return [image create photo $name \
        -file [file join $BASE_DIR images $filename]]
}

proc toolbar { w } {
    set t [frame $w]

    ttk::button $t.new -text "New" -style Toolbutton
    ttk::button $t.open -text "Open" -style Toolbutton
    ttk::button $t.save -text "Save" -style Toolbutton

    ttk::separator $t.sep1 -orient vertical

    ttk::button $t.run -text "Run" -style Toolbutton -compound left -image img.lightning
    ttk::button $t.step -text "Step" -style Toolbutton -compound left -image img.brick_go

    pack $t.new $t.open $t.save -side left -padx 2 -pady 2
    pack $t.sep1 -side left -fill y -padx 2 -pady 2
    pack $t.run $t.step -side left -padx 2 -pady 2

    return $t
}

proc app_menu {} {
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

    variable W CW
    variable CanvasWidth CanvasHeight
    variable RW RH
    variable Options
    variable EditState

    constructor { w {width 80} {height 25} } {
        set EditState [EditState new]
        set W $w
        set Options(width) $width
        set Options(height) $height
        set Options(font) TkDefaultFont
        lassign [my CalcRectSize] RW RH
        set CanvasWidth [expr { $width * $RW + 4}]
        set CanvasHeight [expr { $height * $RH + 4}]
        set CW [my BuildCanvas]
        set Options(rectBgNormal) [lindex [$CW config -bg] end]
        set Options(rectBgActive) LightSeaGreen
        set Options(rectColor) Grey
        set Options(rectBgEdit) Yellow
        my RenderGrid
        my SetBindings
    }

    method canvas {} { return $CW }
    method frame {} { return $W }

    method CalcRectSize {} {
        lassign [my GetFontSize] fontW fontH
        return [list [expr {$fontW + 4}] [expr {$fontH + 2}]]
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
                    -tags [list rect-${x}-${y} rect]
                $CW create text [expr {$sx + 2}] $sy \
                    -anchor nw \
                    -font $Options(font) \
                    -tags [list text-${x}-${y} text]
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

    method drawChar { x y char } {
        $CW itemconfigure text-${x}-${y} -text $char
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
            my drawChar {*}[my GetTagXY [$EditState tag]] $char
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
}

proc scrolled_canvas { w args } {
    frame $w
}

load_image img.brick_go brick_go.png
load_image img.bug bug.png
load_image img.lightning lightning.png

#ttk::style theme use alt

wm title . "Befunge"

pack [toolbar .t] -side top -fill x
#pack [scrolled_canvas .c] -fill both

set cc [CodeCanvas new .c]
pack .c -fill both -expand yes

. configure -menu [app_menu]
