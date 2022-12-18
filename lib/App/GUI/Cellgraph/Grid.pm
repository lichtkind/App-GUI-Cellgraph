use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Grid;


sub get {
    my ($size, $config) = @_;
    return unless ref $config eq 'HASH';
    my $rule_size = $config->{'global'}{'input_size'};
    my $cylinder_grid = $config->{'global'}{'circular_grid'};
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
    my $iterator = compile_iterator($config, $comp_size_x);
    
    my @start_states = @{ $config->{'start'}{'list'} }; # init state values
    if ($config->{'start'}{'repeat'}) {
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
    for my $row_i (1 .. $size_y - 1) { # compute next rows
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
    my ($config, $comp_size_x) = @_;
    my $transfer_function = $config->{'rules'}{'f'}; # state transfer
    my $action_function = $config->{'mobile'}{'f'};  # 
    my $rule_size = $config->{'global'}{'input_size'};
    my $act_size = 3;
    my $states = $config->{'global'}{'state_count'};
    my $rule_count = $states ** $rule_size;
    my $xskew_factor = int $rule_size / 2;
    my $askew_factor = 1;
    # code head
    my $code = 'sub { my ($state_row, $action_row) = @_;';
    # $code .= 'say int @$state_row;';
    $code .= 'my ($new_srow, $new_arow) = ([],[(0) x $comp_size_x]); my $state = 0; my $active = 0;';
    # row start
    my $shift_val = '$state *= '.$states.';';
    my $crop_val = '$state %= '.$rule_count.';';
    if ($config->{'global'}{'circular_grid'}){
        if ($config->{'rules'}{'avg'}){
            $code .= '$state += $state_row->['.($comp_size_x - $_).'];' for reverse 1 .. $xskew_factor; 
        } else {
            $code .= $shift_val.'$state += $state_row->['.($comp_size_x - $_).'];' for reverse 1 .. $xskew_factor; 
        }
    }
    if ($rule_size % 2){
        $code .= $shift_val unless $config->{'rules'}{'avg'}; 
        $code .= '$state += $state_row->[0];'; 
    }
    if ($config->{'rules'}{'avg'}){
        $code .= '$state += $state_row->['.$_.'];' for 1 .. $xskew_factor; 
    } else {
        $code .= $shift_val.'$state += $state_row->['.$_.'];' for reverse 1 .. $xskew_factor; 
    }
    $code .= '$new_srow->[0] = $transfer_function->[$state];';
    $code .= '$new_arow->[0] = $action_function->[$active];'; 
    my $plus_factor = $states ** ($xskew_factor);
    my $minus_factor = $states ** ($xskew_factor-1);
    my $row_stop = $comp_size_x - 1 - $xskew_factor;
    # main loop
    $code .= 'for my $cell_i'." ($xskew_factor .. $row_stop){"; 
   
    unless ($rule_size % 2){
        $code .= $config->{'rules'}{'avg'}
               ? '$state += $state_row->[$cell_i - 1] - $state_row->[$cell_i];'
               : '$state += ( $state_row->[$cell_i - 1] * $plus_factor) - ($state_row->[$cell_i] * $minus_factor);';
    }
    $code .= $shift_val unless $config->{'rules'}{'avg'}; 
    $code .= '$state += $state_row->[$cell_i + '.$xskew_factor.'];'; 
    $code .= $config->{'rules'}{'avg'} ? '$state -= $state_row->[$cell_i - $xskew_factor - 1];' : $crop_val;
    $code .= '$new_srow->[$cell_i] = $transfer_function->[$state];'; 
    $code .= '$new_arow->[$cell_i] = $action_function->[$active];'; 
    $code .= '}';
    # loop tail
    for my $cell_i( $comp_size_x - $xskew_factor .. $comp_size_x - 1){
        $code .= $config->{'rules'}{'avg'} 
              ? '$state -= $state_row->['.($cell_i - $xskew_factor - 1).'];'
              : $shift_val . $crop_val;
        unless ($rule_size % 2){
            $code .= $config->{'rules'}{'avg'}
                   ? '$state += $state_row->[$cell_i - 1] - $state_row->[$cell_i];'
                   : '$state += ( $state_row->[$cell_i - 1] * $plus_factor) - ($state_row->[$cell_i] * $minus_factor);';
        }
        $code .= '$state += $state_row->['.($cell_i - $comp_size_x + $xskew_factor).'];' if $config->{'global'}{'circular_grid'};
        $code .= '$new_srow->['.$cell_i.'] = $transfer_function->[$state];'; 
        $code .= '$new_arow->['.$cell_i.'] = $action_function->[$active];'; 
    }; # say $code;

    eval $code.'($new_srow, $new_arow) }';
}

1;


__END__


        #~ my $row = $state_grid->[$row_i] = [];
                #~ my $act = $action_grid->[$row_i]  = [(0) x $comp_size_x];
                #~ my $val = $brow->[0];          # prerun for rule size
                #~ $val <<= 1;
                #~ $val += $brow->[1];
                #~ $val %= 8;
                #~ $row->[0]  = $bact->[0] ? $transfer_function->[ $val ] : $brow->[0];
                #~ $act->[0] |= 1 if $action_function->[ $val ] & 2;
                #~ $act->[1] |= 1 if $action_function->[ $val ] & 1;            
                #~ for my $cell_i (1 .. $size_x - 2){
                    #~ $val <<= 1;
                    #~ $val += $brow->[$cell_i+1];
                    #~ $val %= 8;
                    #~ $row->[$cell_i] = $bact->[$cell_i] ? $transfer_function->[ $val ] : $brow->[$cell_i];
                    #~ $act->[$cell_i-1] |= 1 if $action_function->[ $val ] & 4;
                    #~ $act->[$cell_i  ] |= 1 if $action_function->[ $val ] & 2;
                    #~ $act->[$cell_i+1] |= 1 if $action_function->[ $val ] & 1;            
                #~ }
                #~ # for (1 .. $rule_size - 1)
                #~ {
                    #~ $val <<= 1; # last two elements are special
                    #~ $val %= 8;
                    #~ my $cell_i = $size_x - 1;
                    #~ $row->[$cell_i] = $bact->[$cell_i] ? $transfer_function->[ $val ] : $brow->[$cell_i];
                    #~ $act->[$cell_i-1] |= 1 if $action_function->[ $val ] & 4;
                    #~ $act->[$cell_i  ] |= 1 if $action_function->[ $val ] & 2;
                #~ }



sub { 
    my ($state_row, $action_row) = @_;
    my ($new_srow, $new_arow) = ([],[]); 
    my $state = 0;
    $state *= 2;
    $state += $state_row->[198];
    $state *= 2;
    $state += $state_row->[0];
    $state *= 2;
    $state += $state_row->[1];
    $new_srow->[0] = $state;
    for my $cell_i (1 .. 197){
        $state *= 2;
        $state += $state_row->[$cell_i + 1];
        $state %= 8;
        $new_srow->[$cell_i] = $state;
    }
    ($new_srow, $new_arow) 
}
