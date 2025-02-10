use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Compute::Grid;


sub create {
    my ($state, $grid_size, $sketch_length) = @_;
    return unless defined $grid_size and ref $state eq 'HASH' and exists $state->{'global'}{'input_size'};
    my $grid_circular = $state->{'global'}{'circular_grid'};
    my $grow_direction = $state->{'global'}{'paint_direction'};
    my $result_calc = $state->{'rules'}{'calc'};
    my $subrules = $result_calc->subrules->max_count;
    my $inputs = $state->{'global'}{'input_size'};
    my $state_count = $state->{'global'}{'state_count'};
    my $input_overhang = int $inputs / 2;
    my $self_input     = $inputs % 2;
    my $odd_grid_size = $grid_size % 2;
    my $compute_right_stop = $grid_size - $input_overhang - 1;
    my $compute_rows = (defined $sketch_length) ? $sketch_length :
                       ($grow_direction ne 'top_down') ? (int($grid_size/2) + $odd_grid_size): $grid_size;

    my @start_states = @{ $state->{'start'}{'list'} };
    if ($state->{'start'}{'repeat'}) { # repeat first row into left and right direction
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
    my @cell_states = @start_states;
    my @prev_states;
    if ($self_input){
        if ($grid_circular){
            for my $row_nr (1 .. $compute_rows - 1) {
                @prev_states = @cell_states;

                my $pattern_nr = 0;
                for (@prev_states[-$input_overhang .. -1] ,
                     @prev_states[0 .. $input_overhang-1] ){
                    $pattern_nr *= $state_count;
                    $pattern_nr += $_;
                }
                for my $x_pos (0 .. $compute_right_stop){
                    $pattern_nr *= $state_count;
                    $pattern_nr += $prev_states[$x_pos+$input_overhang];
                    $pattern_nr %= $subrules;
                    $cell_states[$x_pos] = $result_calc->result_from_pattern( $pattern_nr );
                }
                for my $x_pos ($compute_right_stop + 1 .. $grid_size - 1){
                    $pattern_nr *= $state_count;
                    $pattern_nr += $prev_states[$x_pos + $input_overhang - $grid_size];
                    $pattern_nr %= $subrules;
                    $cell_states[$x_pos] = $result_calc->result_from_pattern( $pattern_nr );
                }

                $state_grid->[$row_nr] = [@cell_states];
            }
        } else { # not circular/cylindrical grid
            for my $row_nr (1 .. $compute_rows - 1) {
                @prev_states = @cell_states;

                my $pattern_nr = 0;
                for (@prev_states[0 .. $input_overhang-1] ){
                    $pattern_nr *= $state_count;
                    $pattern_nr += $_;
                }
                for my $x_pos (0 .. $compute_right_stop){
                    $pattern_nr *= $state_count;
                    $pattern_nr += $prev_states[$x_pos+$input_overhang];
                    $pattern_nr %= $subrules;
                    $cell_states[$x_pos] = $result_calc->result_from_pattern( $pattern_nr );
                }
                for my $x_pos ($compute_right_stop + 1 .. $grid_size - 1){
                    $pattern_nr *= $state_count;
                    $pattern_nr %= $subrules;
                    $cell_states[$x_pos] = $result_calc->result_from_pattern( $pattern_nr );
                }

                $state_grid->[$row_nr] = [@cell_states];
            }
        }
    } else { # current cell is not part of input
        my $part_max = $state_count ** $input_overhang;
        if ($grid_circular){
            for my $row_nr (1 .. $compute_rows - 1) {
                @prev_states = @cell_states;

                my $left_pattern = 0;
                my $right_pattern = 0;
                for (@prev_states[-$input_overhang .. -1]){
                    $left_pattern *= $state_count;
                    $left_pattern += $_;
                }
                for (@prev_states[1 .. $input_overhang] ){
                    $right_pattern *= $state_count;
                    $right_pattern += $_;
                }
                for my $x_pos (0 .. $compute_right_stop-1){
                    $cell_states[$x_pos] = $result_calc->result_from_pattern( $left_pattern*$part_max + $right_pattern );
                    $left_pattern *= $state_count;
                    $right_pattern *= $state_count;
                    $left_pattern += $prev_states[$x_pos];
                    $right_pattern += $prev_states[$x_pos+$input_overhang+1];
                    $left_pattern %= $part_max;
                    $right_pattern %= $part_max;
                }
                $cell_states[$compute_right_stop] = $result_calc->result_from_pattern( $left_pattern*$part_max + $right_pattern );
                for my $x_pos ($compute_right_stop+1 .. $grid_size - 1){
                    $left_pattern *= $state_count;
                    $right_pattern *= $state_count;
                    $left_pattern += $prev_states[$x_pos-1];
                    $right_pattern += $prev_states[$x_pos + $input_overhang - $grid_size];
                    $left_pattern %= $part_max;
                    $right_pattern %= $part_max;
                    $cell_states[$x_pos] = $result_calc->result_from_pattern( $left_pattern*$part_max + $right_pattern );
                }

                $state_grid->[$row_nr] = [@cell_states];
            }
        } else { # not circular/cylindrical grid
            for my $row_nr (1 .. $compute_rows - 1) {
                @prev_states = @cell_states;

                my $left_pattern = 0;
                my $right_pattern = 0;
                for (@prev_states[1 .. $input_overhang-1] ){
                    $right_pattern *= $state_count;
                    $right_pattern += $_;
                }
                for my $x_pos (0 .. $compute_right_stop-1){
                    $cell_states[$x_pos] = $result_calc->result_from_pattern( $left_pattern*$part_max + $right_pattern );
                    $left_pattern *= $state_count;
                    $right_pattern *= $state_count;
                    $left_pattern += $prev_states[$x_pos];
                    $right_pattern += $prev_states[$x_pos+$input_overhang+1];
                    $left_pattern %= $part_max;
                    $right_pattern %= $part_max;
                }
                $cell_states[$compute_right_stop] = $result_calc->result_from_pattern( $left_pattern*$part_max + $right_pattern );
                for my $x_pos ($compute_right_stop+1 .. $grid_size - 1){
                    $left_pattern *= $state_count;
                    $right_pattern *= $state_count;
                    $left_pattern += $prev_states[$x_pos-1];
                    $left_pattern %= $part_max;
                    $right_pattern %= $part_max;
                    $cell_states[$x_pos] = $result_calc->result_from_pattern( $left_pattern*$part_max + $right_pattern );
                }

                $state_grid->[$row_nr] = [@cell_states];
            }
        }
    }
    if (defined $sketch_length){
        for my $row_nr ($compute_rows .. $grid_size - 1) {
            $state_grid->[$row_nr] = [@empty_row];
        }
        return $state_grid;
    }
    return $state_grid if $grow_direction eq 'top_down';

    if ($grow_direction eq 'inside_out') {
    }
    if ($grow_direction eq 'outside_in') {
    }

    $paint_grid;
}



1;

# - flexible activity grid
__END__
