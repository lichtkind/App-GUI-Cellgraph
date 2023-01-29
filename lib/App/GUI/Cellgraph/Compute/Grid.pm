use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Compute::Grid;


sub now {
    my ($size, $settings) = @_;
    return unless ref $settings eq 'HASH';
    my $rule_size = $settings->{'global'}{'input_size'};
    my $cylinder_grid = $settings->{'global'}{'circular_grid'};
    my ($size_x, $size_y);  # set grid size 3x * y
    if (ref $size eq 'ARRAY'){
        $size_x = $size->[0];
        $size_y = $size->[1];
    } else {
        $size_x = $size;
        $size_y = $size;
    }
    my $xskew_factor = int $rule_size / 2;
    my $paint_extra_x = $cylinder_grid ? 0 : ($xskew_factor * $size_y);
    my $comp_size_x = $size_x + (2 * $paint_extra_x);

    my $action_grid  = [ [(1) x $comp_size_x] ];
    my $state_grid   = [ [] ];
    my $iterator = compile_iterator($settings, $comp_size_x);

    my @start_states = @{ $settings->{'start'}{'list'} }; # init state values
    if ($settings->{'start'}{'repeat'}) {
        my @repeat = @start_states;
        my $prepend_length = int( ($comp_size_x - @start_states) / 2);
        unshift @start_states, @repeat for 1 .. $prepend_length / @repeat;
        unshift @start_states, @repeat[ $#repeat - ( $prepend_length % @repeat) .. $#repeat];
        my $append_length = $comp_size_x - @start_states;
        push @start_states, @repeat for 1 .. $append_length / @repeat;
        push @start_states, @repeat[0 .. $append_length % @repeat];
    } else {
        if (@start_states < $comp_size_x) { # center predefined first row
            push @start_states, (0) x int( ($comp_size_x - @start_states) / 2);
            unshift @start_states, (0) x ($comp_size_x - @start_states);
        } else {
            splice @start_states, $comp_size_x;
        }
    }

    $state_grid->[0] = \@start_states;
    my $last_row =  exists $settings->{'sketch'} ? $settings->{'sketch'} : $size_y - 1;
    for my $row_i (1 .. $last_row) { # compute next row
        ($state_grid->[$row_i], $action_grid->[$row_i])
            = $iterator->( $state_grid->[$row_i - 1], $action_grid->[$row_i - 1]);
    }

    if ($paint_extra_x){
        for my $row (@$state_grid) { # cut grid back to requested size
            splice @$row, 0, $paint_extra_x;
            splice @$row, $size_x;
        }
    }
    $state_grid;
}

sub compile_iterator {
    my ($settings, $comp_size_x) = @_;
    my $transfer_function = $settings->{'rules'}{'f'}; # state transfer
# say '--'; say for @$transfer_function;
    my $action_function = $settings->{'mobile'}{'f'};  #
    my $rule_size = $settings->{'global'}{'input_size'};
    my $act_size = 3;
    my $states = $settings->{'global'}{'state_count'};
    my $subrule_count = $states ** $rule_size;
    my $action_count = $states ** $act_size;
    my $x_skew_factor = int $rule_size / 2; # propagation skew
    my $a_skew_factor = 1;
    my $ignore_current_cell = $rule_size % 2;
    my $last_x_index = $comp_size_x - 1;

    # eval code head
    my $code = 'sub { my ($state_row, $action_row) = @_;'."\n";
    $code .= 'my ($new_state_row, $new_action_row, $arow) = ([], [(0) x $comp_size_x], [(0) x $comp_size_x]);'."\n";
    $code .= 'my $state = 0; my $active = 0;'."\n";
    # row start #say "tf -> ", int @$transfer_function, "  take avg ",$settings->{'rules'}{'avg'};
    my $shift_val = $settings->{'rules'}{'avg'} ? '' : '$state *= '.$states.';';
    my $crop_val = '$state %= '.$subrule_count.';';
    if ($settings->{'global'}{'circular_grid'}){
        $code .= $shift_val.'$state += $state_row->['.$_.'];'."\n" for $comp_size_x - $x_skew_factor .. $last_x_index;
    }
    $code .= $shift_val.'$state += $state_row->[0];' if $ignore_current_cell;
    $code .= $shift_val.'$state += $state_row->['.$_.'];'."\n" for reverse 1 .. $x_skew_factor;
    $code .= '$new_state_row->[0] = $transfer_function->[$state];'."\n";
    $code .= '$arow->[0] = $action_function->[$state];'."\n";
    for my $cell_i( 1 .. $x_skew_factor - 1){
        $code .= $settings->{'rules'}{'avg'}
              ? '$state -= $state_row->['.($comp_size_x - $x_skew_factor + $cell_i).'];'."\n"
              : $shift_val . $crop_val."\n";
        unless ($ignore_current_cell){
            $code .= $settings->{'rules'}{'avg'}
                   ? '$state += $state_row->['.($cell_i - 1).'] - $state_row->['.$cell_i.'];'."\n"
                   : '$state += ( $state_row->['.($cell_i - 1).'] * $plus_factor) - ($state_row->['.$cell_i.'] * $minus_factor);'."\n";
        }
        $code .= '$state += $state_row->['.($cell_i + $x_skew_factor).'];';
        $code .= '$new_state_row->['.$cell_i.'] = $transfer_function->[$state];';
        $code .= '$arow->['.$cell_i.'] = $action_function->[$state];';
    }
    my $plus_factor = $states ** ($x_skew_factor);
    my $minus_factor = $states ** ($x_skew_factor-1);
    my $row_stop = $last_x_index - $x_skew_factor;
    # main loop
    $code .= 'for my $cell_i'." ($x_skew_factor .. $row_stop){"."\n";

    unless ($ignore_current_cell){
        $code .= $settings->{'rules'}{'avg'}
               ? '  $state += $state_row->[$cell_i - 1] - $state_row->[$cell_i];'."\n"
               : '  $state += ( $state_row->[$cell_i - 1] * $plus_factor) - ($state_row->[$cell_i] * $minus_factor);'."\n";
    }
    $code .= $shift_val unless $settings->{'rules'}{'avg'};
    $code .= '  $state += $state_row->[$cell_i + '.$x_skew_factor.'];'."\n";
    $code .= $settings->{'rules'}{'avg'} ? '$state -= $state_row->[$cell_i - $x_skew_factor - 1];'."\n" : $crop_val;
    $code .= '  $new_state_row->[$cell_i] = $transfer_function->[$state];'."\n";
    $code .= '  $arow->[$cell_i] = $action_function->[$state];';
    $code .= '}'."\n";
    # loop tail
    for my $cell_i( $comp_size_x - $x_skew_factor .. $last_x_index){
        $code .= $settings->{'rules'}{'avg'}
              ? '$state -= $state_row->['.($cell_i - $x_skew_factor - 1).'];'."\n"
              : $shift_val . $crop_val."\n";
        unless ($ignore_current_cell){
            $code .= $settings->{'rules'}{'avg'}
                   ? '$state += $state_row->['.($cell_i - 1).'] - $state_row->['.$cell_i.'];'."\n"
                   : '$state += ( $state_row->['.($cell_i - 1).'] * $plus_factor) - ($state_row->['.$cell_i.'] * $minus_factor);'."\n";
        }
        $code .= '$state += $state_row->['.($cell_i - $comp_size_x + $x_skew_factor).'];' if $settings->{'global'}{'circular_grid'};
        $code .= '$new_state_row->['.$cell_i.'] = $transfer_function->[$state];'."\n";
        $code .= '$arow->['.$cell_i.'] = $action_function->[$state];';
    };
    # compute action rules
    $code .= '$new_action_row->['.$last_x_index.'] |= 1 if $arow->[0] & 4;'."\n" if $settings->{'global'}{'circular_grid'};
    $code .= '$new_action_row->[0] |= 1 if $arow->[0] & 2;'."\n";
    $code .= '$new_action_row->[1] |= 1 if $arow->[0] & 1;'."\n";

    $code .= 'for my $cell_i ( 1 ..'.($last_x_index - 1)."){\n";
    $code .= '  $active = $arow->[$cell_i];'."\n";
    $code .= '  $new_action_row->[$cell_i - 1 ] |= 1 if $active & 4;'."\n";
    $code .= '  $new_action_row->[$cell_i     ] |= 1 if $active & 2;'."\n";
    $code .= '  $new_action_row->[$cell_i + 1 ] |= 1 if $active & 1;'."\n";
    $code .= "}\n";
    $code .= '$active = $arow->['.$last_x_index.'];'."\n";
    $code .= '$new_action_row->['.($last_x_index - 1).'] |= 1 if $active & 4;'."\n";
    $code .= '$new_action_row->['.$last_x_index.']       |= 1 if $active & 2;'."\n";
    $code .= '$new_action_row->[ 0 ] |= 1                     if $active & 1;'."\n" if $settings->{'global'}{'circular_grid'};

    # apply action rules
    $code .= 'for ( 0 ..'.$last_x_index."){\n";
    $code .= '    $new_state_row->[$_] = $state_row->[$_] unless $action_row->[$_];'."\n";
    $code .= "}\n".'($new_state_row, $new_action_row) }'; # return solution
    eval $code; # say $code;
}

1;

# - flexible activity grid
__END__
