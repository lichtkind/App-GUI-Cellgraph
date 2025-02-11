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
    my $subrule_count = $result_calc->subrules->max_count;
    my $inputs = $state->{'global'}{'input_size'};
    my $state_count = $state->{'global'}{'state_count'};
    my $use_action_rules = $state->{'global'}{'use_action_rules'};
    my $input_overhang = int $inputs / 2;
    my $self_input     = $inputs % 2;
    my $odd_grid_size = $grid_size % 2;

# action rules missing

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
    my $compute_right_stop = $grid_size - $input_overhang - 1;
    my $compute_rows = ($sketch_length)                ? $sketch_length :
                       ($grow_direction eq 'top_down') ? $grid_size     :
                                                         (int($grid_size/2) + $odd_grid_size);
say "compute_rows $compute_rows / $grid_size ";

    my %subrule_result_cache = map {$_ => $result_calc->result_from_pattern( $_ )} 0 .. $subrule_count-1;

    my $code = 'for my $row_nr (1 .. '.($compute_rows - 1).') {'."\n".
               '@prev_states = @cell_states;'."\n\n".
               'my $pattern_nr = 0;'."\n";
    my $code_end = '$state_grid->[$row_nr] = [@cell_states];'."\n".'}';

    if ($self_input){
        if ($grid_circular){
            for my $row_nr (1 .. $compute_rows - 1) {
                @prev_states = @cell_states;

                if ($state->{'global'}{'use_action_rules'}){
                }

                my $pattern_nr = 0;
                for (@prev_states[-$input_overhang .. -1] ,
                    @prev_states[0 .. $input_overhang-1] ){
                    $pattern_nr *= $state_count;
                    $pattern_nr += $_;
                }
                for my $x_pos (0 .. $compute_right_stop){
                    $pattern_nr *= $state_count;
                    $pattern_nr += $prev_states[$x_pos+$input_overhang];
                    $pattern_nr %= $subrule_count;
                    $cell_states[$x_pos] = $subrule_result_cache{ $pattern_nr };
                }
                for my $x_pos ($compute_right_stop + 1 .. $grid_size - 1){
                    $pattern_nr *= $state_count;
                    $pattern_nr += $prev_states[$x_pos + $input_overhang - $grid_size];
                    $pattern_nr %= $subrule_count;
                    $cell_states[$x_pos] = $subrule_result_cache{ $pattern_nr };
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
                    $pattern_nr %= $subrule_count;
                    $cell_states[$x_pos] = $subrule_result_cache{ $pattern_nr };
                }
                for my $x_pos ($compute_right_stop + 1 .. $grid_size - 1){
                    $pattern_nr *= $state_count;
                    $pattern_nr %= $subrule_count;
                    $cell_states[$x_pos] = $subrule_result_cache{ $pattern_nr };
                }

                $state_grid->[$row_nr] = [@cell_states];
            }
        }
    } else { # current cell is not part of input
        my $part_max = $state_count ** $input_overhang;
        if ($grid_circular){
            for my $row_nr (1 .. $compute_rows - 1) {
                @prev_states = @cell_states;

                my $pattern_nr = 0;
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
                    $pattern_nr = $left_pattern*$part_max + $right_pattern;
                    $cell_states[$x_pos] = $subrule_result_cache{ $pattern_nr };
                    $left_pattern *= $state_count;
                    $right_pattern *= $state_count;
                    $left_pattern += $prev_states[$x_pos];
                    $right_pattern += $prev_states[$x_pos+$input_overhang+1];
                    $left_pattern %= $part_max;
                    $right_pattern %= $part_max;
                }
                $pattern_nr = $left_pattern*$part_max + $right_pattern;
                $cell_states[$compute_right_stop] = $subrule_result_cache{ $pattern_nr };
                for my $x_pos ($compute_right_stop+1 .. $grid_size - 1){
                    $left_pattern *= $state_count;
                    $right_pattern *= $state_count;
                    $left_pattern += $prev_states[$x_pos-1];
                    $right_pattern += $prev_states[$x_pos + $input_overhang - $grid_size];
                    $left_pattern %= $part_max;
                    $right_pattern %= $part_max;
                    $pattern_nr = $left_pattern*$part_max + $right_pattern;
                    $cell_states[$x_pos] = $subrule_result_cache{ $pattern_nr };
                }

                $state_grid->[$row_nr] = [@cell_states];
            }
        } else { # not circular/cylindrical grid
            for my $row_nr (1 .. $compute_rows - 1) {
                @prev_states = @cell_states;

                my $pattern_nr = 0;
                my $left_pattern = 0;
                my $right_pattern = 0;
                for (@prev_states[1 .. $input_overhang-1] ){
                    $right_pattern *= $state_count;
                    $right_pattern += $_;
                }
                for my $x_pos (0 .. $compute_right_stop-1){
                    $pattern_nr = $left_pattern*$part_max + $right_pattern;
                    $cell_states[$x_pos] = $subrule_result_cache{ $pattern_nr };
                    $left_pattern *= $state_count;
                    $right_pattern *= $state_count;
                    $left_pattern += $prev_states[$x_pos];
                    $right_pattern += $prev_states[$x_pos+$input_overhang+1];
                    $left_pattern %= $part_max;
                    $right_pattern %= $part_max;
                }
                $pattern_nr = $left_pattern*$part_max + $right_pattern;
                $cell_states[$compute_right_stop] = $subrule_result_cache{ $pattern_nr };
                for my $x_pos ($compute_right_stop+1 .. $grid_size - 1){
                    $left_pattern *= $state_count;
                    $right_pattern *= $state_count;
                    $left_pattern += $prev_states[$x_pos-1];
                    $left_pattern %= $part_max;
                    $right_pattern %= $part_max;
                    $pattern_nr = $left_pattern*$part_max + $right_pattern;
                    $cell_states[$x_pos] = $subrule_result_cache{ $pattern_nr };
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

#    my $iterator = compile_iterator( $state, $grid_size);
#    die "comile error $@" if $@;


    #~ if ($self->{'state'}{'global'}{'paint_direction'} eq 'inside_out') {
        #~ my $mid = int($self->{'cells'}{'x'} / 2);
        #~ if ($self->{'cells'}{'x'} % 2){
            #~ for my $y (1 .. ($sketch_length ? $sketch_length : $mid)) {
                #~ for my $x ($mid - $y .. $mid -1 + $y){
                    #~ $dc->SetPen( $pen[$grid->[$y][$x]] );
                    #~ $dc->SetBrush( $brush[$grid->[$y][$x]] );
                    #~ my ($nx, $ny) = ($x, $mid + $y);
                    #~ $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    #~ ($nx, $ny) = ($self->{'cells'}{'x'} - 1 - $x, $mid - $y);
                    #~ $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    #~ ($nx, $ny) = ($mid - $y, $x);
                    #~ $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    #~ ($nx, $ny) = ($mid + $y, $self->{'cells'}{'y'} - 1 - $x);
                    #~ $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                #~ }
                #~ $dc->SetPen( $pen[ $grid->[0][$mid] ] );
                #~ $dc->SetBrush( $brush[ $grid->[0][$mid] ] );

                #~ $dc->DrawRectangle( 1 + ($mid * $grid_d), 1 + ($mid * $grid_d), $cell_size, $cell_size )
                    #~ if $grid->[0][$mid];
            #~ }
        #~ } else {
            #~ for my $y (0 .. ($sketch_length ? $sketch_length : (int($self->{'cells'}{'y'} / 2) + 1))) {
                #~ last if $y >= $mid;
                #~ for my $x ($mid - $y .. $mid + $y){
                    #~ $dc->SetPen( $pen[$grid->[$y][$x]] );
                    #~ $dc->SetBrush( $brush[$grid->[$y][$x]] );
                    #~ my ($nx, $ny) = ($self->{'cells'}{'x'} - 1 - $x, $mid - 1 - $y);
                    #~ $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    #~ ($nx, $ny) = ($x, $mid + $y);
                    #~ $dc->DrawRectangle( 1 + ($x * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    #~ ($nx, $ny) = ($mid - 1 - $y, $x);
                    #~ $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($x * $grid_d), $cell_size, $cell_size );
                    #~ ($nx, $ny) = ($mid + $y, $self->{'cells'}{'x'} - 1 - $x);
                    #~ $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                #~ }
            #~ }
        #~ }
    #~ } elsif ($self->{'state'}{'global'}{'paint_direction'} eq 'outside_in') {
        #~ for my $y (0 .. ($sketch_length ? $sketch_length : (int($self->{'cells'}{'y'} / 2) + 1)) ) {
            #~ last if $y >= $self->{'cells'}{'x'} - 2 - $y;
            #~ for my $x ($y .. $self->{'cells'}{'x'} - 2 - $y){
                #~ $dc->SetPen( $pen[$grid->[$y][$x]] );
                #~ $dc->SetBrush( $brush[$grid->[$y][$x]] );
                #~ my ($nx, $ny) = ($self->{'cells'}{'x'} - 1 - $x, $self->{'cells'}{'y'} - 1 - $y);
                #~ $dc->DrawRectangle( 1 + ( $x * $grid_d), 1 + ( $y * $grid_d), $cell_size, $cell_size );
                #~ $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                #~ $dc->DrawRectangle( 1 + ( $y * $grid_d), 1 + ($nx * $grid_d), $cell_size, $cell_size );
                #~ $dc->DrawRectangle( 1 + ($ny * $grid_d), 1 + ( $x * $grid_d), $cell_size, $cell_size );
            #~ }
        #~ }
    #~ } else {
        #~ for my $y (0 .. ($sketch_length ? $sketch_length : $self->{'cells'}{'y'} - 1)) {
            #~ for my $x (0 .. $self->{'cells'}{'x'} - 1){
                #~ $dc->SetPen( $pen[$grid->[$y][$x]] );
                #~ $dc->SetBrush( $brush[$grid->[$y][$x]] );
                #~ $dc->DrawRectangle( 1 + ($x * $grid_d), 1 + ($y * $grid_d), $cell_size, $cell_size );
            #~ }
        #~ }
    #~ }
