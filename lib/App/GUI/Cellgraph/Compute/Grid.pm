
# compute each cells state and action value

package App::GUI::Cellgraph::Compute::Grid;
use v5.12;
use warnings;
use Wx;
use Benchmark;

sub create {
    my ($state, $grid_size, $sketch_length) = @_;
    return unless defined $grid_size and ref $state eq 'HASH' and exists $state->{'global'}{'input_size'};
    my $grid_circular = $state->{'global'}{'circular_grid'};
    my $grow_direction = $state->{'global'}{'paint_direction'};
    my $result_calc = $state->{'rules'}{'calc'};
    my $subrule_count = $result_calc->subrules->max_count;
    my $inputs = $state->{'global'}{'input_size'};
    my $state_count = $state->{'global'}{'state_count'};
    my $use_action_rules = $state->{'global'}{'use_action_rules'};
    my $input_overhang = int $inputs / 2;
    my $self_input     = $inputs % 2;
    my $odd_grid_size  = $grid_size % 2;
    my $half_grid_size = int($grid_size / 2);

# action rules missing
my $t0 = Benchmark->new;

    my @start_states = @{ $state->{'start'}{'list'} };
    if ($state->{'start'}{'repeat_states'}) { # repeat first row into left and right direction
        my @repeat = @start_states;
        my $prepend_length = int( ($grid_size - @start_states) / 2);
        unshift @start_states, @repeat for 1 .. $prepend_length / @repeat;
        unshift @start_states, @repeat[ $#repeat - ( $prepend_length % @repeat) .. $#repeat];
        my $append_length = $grid_size - @start_states;
        push @start_states, @repeat for 1 .. $append_length / @repeat;
        push @start_states, @repeat[0 .. $append_length % @repeat];
    } else {
        if (@start_states < $grid_size) { # center predefined first row
            push @start_states, (0) x int( ($grid_size - @start_states) / 2);
            unshift @start_states, (0) x ($grid_size - @start_states);
        } else { splice @start_states, $grid_size }
    }

    my $action_grid = [ [(1) x $grid_size] ];
    my $state_grid  = [ [@start_states] ];
    my $paint_grid  = [ [] ];
    my @empty_row   =  (0) x $grid_size;
    my $row_start = "'".('0' x $input_overhang)."'";
    my @cell_states = @start_states;
    my @prev_states;
    my $compute_right_stop = $grid_size - 1 - $input_overhang;
    my $compute_rows = ($sketch_length)                ? $sketch_length :
                       ($grow_direction eq 'top_down') ? $grid_size     :
                                                         ($half_grid_size + $odd_grid_size);
    my %subrule_result_cache = map {$_ => $result_calc->result_from_pattern( $_ )} $result_calc->subrules->all_pattern;

    my $code =     'for my $row_nr (1 .. '.($compute_rows - 1).') {'."\n".
                   '  @prev_states = @cell_states;'."\n\n";
    my $code_end = '  $state_grid->[$row_nr] = [@cell_states];'."\n".'}';

    my $wrap_overhang = 'join("", @prev_states[-'.$input_overhang.' .. -1])';
    my $right_overhang = 'join("", @prev_states[0 .. '.$input_overhang.'-1])';

    if ($self_input) {
        $code .= '  my $pattern = "0".'
              .($grid_circular ? $wrap_overhang : $row_start).'.'.$right_overhang.";\n"
              .'  for my $x_pos (0 .. '.$compute_right_stop.'){'."\n"
              .'  '.move_pattern_string('$pattern','$x_pos+$input_overhang')
              .'    $cell_states[$x_pos] = $subrule_result_cache{ $pattern };'."\n  }\n"
              .'  for my $x_pos ('.($compute_right_stop + 1).' .. '.($grid_size - 1).'){'."\n"
              .'    $pattern = substr($pattern,1).';
        $code .= ($grid_circular ? '$prev_states[$x_pos + $input_overhang - $grid_size]' : "'0'").";\n"
              .'    $cell_states[$x_pos] = $subrule_result_cache{ $pattern };'."\n  }\n\n";
    } else {
        my $eval_pattern = '$subrule_result_cache{ $left_pattern.$right_pattern };';
        $code .= '  my $left_pattern = '.($grid_circular ? $wrap_overhang : $row_start).";\n"
              .  '  my $right_pattern = join("", @prev_states[1 .. $input_overhang]);'."\n"
              .  '  $cell_states[0] = '.$eval_pattern."\n\n"
              .  '  for my $x_pos (1 .. '.$compute_right_stop.'){'."\n"
              .  '  '.move_pattern_string('$left_pattern','$x_pos-1')
              .  '  '.move_pattern_string('$right_pattern','$x_pos+$input_overhang')
              .  '    $cell_states[$x_pos] = '.$eval_pattern."\n  }\n"
              .  '  for my $x_pos ('.($compute_right_stop+1).' .. '.($grid_size - 1).'){'."\n"
              .  '  '.move_pattern_string('$left_pattern','$x_pos-1')
              .  '  '.move_pattern_string('$right_pattern' )
              .  '    $cell_states[$x_pos] = '.$eval_pattern."\n  }\n"
    }

    my $result = eval( $code . $code_end);
    say "compile in code:\n$code\n\n error: $@" if $@;

    if ($state->{'global'}{'result_application'}){  }
    if ($state->{'global'}{'use_action_rules'}){  }

say "got grid in:",timestr( timediff(Benchmark->new, $t0) );

    if ($sketch_length){
        $state_grid->[$_] = [@empty_row] for $compute_rows .. $grid_size - 1;
        return $state_grid;
    }
    return $state_grid if $grow_direction eq 'top_down';

    # implementing paint directions
    if ($grow_direction eq 'inside_out') {
        $paint_grid->[$half_grid_size][$half_grid_size]
            = $state_grid->[0][$half_grid_size] if $odd_grid_size;      # center cell state

        for my $y_pos ($odd_grid_size .. $half_grid_size - 1 + $odd_grid_size){
            my $cy_pos = $half_grid_size - $y_pos - 1 + $odd_grid_size; # mirror on Center pos
            my $dy_pos = $half_grid_size + $y_pos;
            for my $x_pos ($half_grid_size - $y_pos .. $half_grid_size + $y_pos){
                my $bx_pos = $grid_size - 1 - $x_pos;
                $paint_grid->[$cy_pos][$bx_pos] = $paint_grid->[$bx_pos][$dy_pos] =
                $paint_grid->[$dy_pos] [$x_pos] = $paint_grid-> [$x_pos][$cy_pos] = $state_grid->[$y_pos][$x_pos];
            }
        }
    }
    if ($grow_direction eq 'outside_in') {
        $paint_grid->[$half_grid_size][$half_grid_size]
            = $state_grid->[$half_grid_size][$half_grid_size] if $odd_grid_size; # center cell state

        for my $y_pos (0 .. $half_grid_size - 1){
            my $by_pos = $grid_size - 1 - $y_pos;
            for my $x_pos ($y_pos .. $by_pos - 1){
                my $bx_pos = $grid_size - 1 - $x_pos;
                $paint_grid->[$y_pos] [$x_pos]  = $paint_grid->[$x_pos] [$by_pos] =
                $paint_grid->[$by_pos][$bx_pos] = $paint_grid->[$bx_pos][$y_pos]  = $state_grid->[$y_pos][$x_pos];
            }
        }
    }
    $paint_grid;
}

sub move_pattern_string {
    my ($var, $index) = @_;
    my $str = '  '.$var.' = substr('.$var.',1).';
    $str .= (defined $index) ? '$prev_states['.$index.']': "'0'";

    return $str.";\n";
}

1;
__END__
