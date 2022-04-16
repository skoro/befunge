 
namespace eval ::keysyms {
    variable data

    array set data {
        space                               32
        exclam                              33
        quotedbl                            34
        numbersign                          35
        dollar                              36
        percent                             37
        ampersand                           38
        apostrophe                          39
        parenleft                           40
        parenright                          41
        asterisk                            42
        plus                                43
        comma                               44
        minus                               45
        period                              46
        slash                               47
        0                                   48
        1                                   49
        2                                   50
        3                                   51
        4                                   52
        5                                   53
        6                                   54
        7                                   55
        8                                   56
        9                                   57
        colon                               58
        semicolon                           59
        less                                60
        equal                               61
        greater                             62
        question                            63
        at                                  64
        A                                   65
        B                                   66
        C                                   67
        D                                   68
        E                                   69
        F                                   70
        G                                   71
        H                                   72
        I                                   73
        J                                   74
        K                                   75
        L                                   76
        M                                   77
        N                                   78
        O                                   79
        P                                   80
        Q                                   81
        R                                   82
        S                                   83
        T                                   84
        U                                   85
        V                                   86
        W                                   87
        X                                   88
        Y                                   89
        Z                                   90
        bracketleft                         91
        backslash                           92
        bracketright                        93
        asciicircum                         94
        underscore                          95
        grave                               96
        a                                   97
        b                                   98
        c                                   99
        d                                  100
        e                                  101
        f                                  102
        g                                  103
        h                                  104
        i                                  105
        j                                  106
        k                                  107
        l                                  108
        m                                  109
        n                                  110
        o                                  111
        p                                  112
        q                                  113
        r                                  114
        s                                  115
        t                                  116
        u                                  117
        v                                  118
        w                                  119
        x                                  120
        y                                  121
        z                                  122
        braceleft                          123
        bar                                124
        braceright                         125
        asciitilde                         126
        nobreakspace                       160
        exclamdown                         161
        cent                               162
        sterling                           163
        currency                           164
        yen                                165
        brokenbar                          166
        section                            167
        diaeresis                          168
        copyright                          169
        ordfeminine                        170
        guillemotleft                      171
        notsign                            172
        hyphen                             173
        registered                         174
        macron                             175
        degree                             176
        plusminus                          177
        twosuperior                        178
        threesuperior                      179
        acute                              180
        mu                                 181
        paragraph                          182
        periodcentered                     183
        cedilla                            184
        onesuperior                        185
        masculine                          186
        guillemotright                     187
        onequarter                         188
        onehalf                            189
        threequarters                      190
        questiondown                       191
        Agrave                             192
        Aacute                             193
        Acircumflex                        194
        Atilde                             195
        Adiaeresis                         196
        Aring                              197
        AE                                 198
        Ccedilla                           199
        Egrave                             200
        Eacute                             201
        Ecircumflex                        202
        Ediaeresis                         203
        Igrave                             204
        Iacute                             205
        Icircumflex                        206
        Idiaeresis                         207
        ETH                                208
        Ntilde                             209
        Ograve                             210
        Oacute                             211
        Ocircumflex                        212
        Otilde                             213
        Odiaeresis                         214
        multiply                           215
        Oslash                             216
        Ugrave                             217
        Uacute                             218
        Ucircumflex                        219
        Udiaeresis                         220
        Yacute                             221
        THORN                              222
        ssharp                             223
        agrave                             224
        aacute                             225
        acircumflex                        226
        atilde                             227
        adiaeresis                         228
        aring                              229
        ae                                 230
        ccedilla                           231
        egrave                             232
        eacute                             233
        ecircumflex                        234
        ediaeresis                         235
        igrave                             236
        iacute                             237
        icircumflex                        238
        idiaeresis                         239
        eth                                240
        ntilde                             241
        ograve                             242
        oacute                             243
        ocircumflex                        244
        otilde                             245
        odiaeresis                         246
        division                           247
        oslash                             248
        ugrave                             249
        uacute                             250
        ucircumflex                        251
        udiaeresis                         252
        yacute                             253
        thorn                              254
        ydiaeresis                         255
    }
}

proc keysym_to_char { keysym } {
    return [format %c $::keysyms::data($keysym)]
}