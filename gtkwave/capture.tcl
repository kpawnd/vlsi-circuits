set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root gtkwave-screenshots]
set build [file join $root build]
file mkdir $output $build
set log [open [file join $build gtk-capture.log] w]
fconfigure $log -buffering line

proc setup_view {group start stop mark} {
    set on_screen [gtkwave::getDisplayedSignals]
    if {[llength $on_screen] > 0} {
        gtkwave::deleteSignalsFromList $on_screen
    }
    set count [gtkwave::addSignalsFromList $group]
    if {$count != [llength $group]} {
        error "Only $count of [llength $group] signals were added"
    }
    gtkwave::setZoomRangeTimes $start $stop
    gtkwave::setWindowStartTime $start
    gtkwave::setMarker $mark
    gtkwave::nop
}

set groups {
    {01-multiplexer 1336 1344 1338 {data[7:0] sel[2:0] mux_y}}
    {02-demultiplexer 2048 2064 2056 {din sel[2:0] demux_y[7:0]}}
    {03-full-adder-both-styles 2064 2072 2067 {a b cin sum_data cout_data sum_beh cout_beh}}
    {04-full-subtractor 2064 2072 2065 {a b bin diff bout}}
    {05-sr-flip-flop 2088 2166 2155 {clk rst s r sr_q}}
    {06-jk-flip-flop 2088 2166 2125 {clk rst j k jk_q}}
    {07-binary-to-gray 2072 2088 2082 {binary[3:0] gray[3:0]}}
}

puts $log "file: [gtkwave::getDumpFileName]"
set grabs [info commands ::gtkwave::*Grab*]
puts $log "grab command: $grabs"
if {[llength $grabs] != 1} {
    error "GTKWave did not expose a single Grab To File command"
}
set capture [lindex $grabs 0]
gtkwave::presentWindow
gtkwave::nop
foreach params $groups {
    lassign $params name start stop marker signals
    set names {}
    foreach bit $signals {lappend names "tb_lab.$bit"}
    setup_view $names [expr {$start * 1000000}] [expr {$stop * 1000000}] [expr {$marker * 1000000}]
    set target [file join $output "${name}.png"]
    puts $log "view $name: [gtkwave::getWindowStartTime] .. [gtkwave::getWindowEndTime], [gtkwave::getDisplayedSignals]"
    $capture $target
    gtkwave::nop
    if {![file exists $target]} {
        error "GTKWave did not save $target"
    }
    puts $log "saved $target"
}
close $log
