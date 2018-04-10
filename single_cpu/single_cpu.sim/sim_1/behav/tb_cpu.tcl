set curr_wave [current_wave_config]
if { [string length $curr_wave] == 0 } {
  add_wave /
  set_property needs_save false [current_wave_config]
}
run 1000ns
