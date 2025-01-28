
# compute sub_rule_nr (by input) and rule_nr (by output)

use v5.12;
use warnings;
use Wx;
package App::GUI::Cellgraph::Compute::Rule;

sub new {
    my ($pkg, $input_size, $state_count, $mode) = @_;
    return unless defined $state_count and $state_count;
    $mode //= 'all';
    bless compute_subrules( {}, $input_size, $state_count, $mode );
}
sub renew {
    my ($self, $input_size, $state_count, $mode) = @_;
    return unless defined $state_count and $state_count;
    $mode //= 'all';
    $self->compute_subrules( $input_size, $state_count, $mode );
}

sub compute_subrules {
    my ($self, $input_size, $state_count, $mode) = @_;
    $self->{'input_size'} = $input_size;
    $self->{'state_count'} = $state_count;
    $self->{'mode'} = $mode;

    $self->{'subrule_count'} = $state_count ** $input_size;
    $self->{'independent_subrules'} = $self->{'subrule_count'};
    $self->{'input_list'} = [];
    $self->{'input_pattern'} = [];
    $self->{'input_pattern_index'} = {};
    $self->{'input_symmetric_partner'} = [];
    $self->{'subrule_mapping'} = [];
    $self->{'input_indy_pattern'} = [];
    $self->{'result'} = [];
    $self->{'output_list'} = [];
    $self->{'output_pattern'} = [];
    $self->{'output_pattern_index'} = {};
    $self->{'next_rule_number'} = [] unless exists $self->{'next_rule_number'};
    $self->{'last_rule_number'} = [] unless exists $self->{'last_rule_number'};
    $self->{'rule_number'} = 0;
    $self->{'next_rule_number'} = [];

    my @input = (0) x $input_size;
    $self->{'input_list'}[0] = [@input];
    $self->{'input_pattern'}[0] = join '', @input;
    $self->{'input_pattern_index'}{ $self->{'input_pattern'}[0] } = 0;
    for my $i (1 .. $self->{'subrule_count'} - 1){
        for my $cell_pos (0 .. $input_size - 1) {
            $input[$cell_pos]++;
            last if $input[$cell_pos] < $state_count;
            $input[$cell_pos] = 0;
        }
        $self->{'input_list'}[$i]    = [reverse @input];
        $self->{'input_pattern'}[$i] = join '', @input;
        $self->{'input_pattern_index'}{ $self->{'input_pattern'}[$i] } = $i;
    }
    for my $i (0 .. $self->{'subrule_count'} - 1) {
        my $l = $self->{'input_list'}[$i];
        my $rev_pattern = join '', reverse(@$l);
        $self->{'input_symmetric_partner'}[$i] = $self->{'input_pattern_index'}{$rev_pattern};
    }

    if ($mode eq 'all' ) {
        $self->{'subrule_mapping'}[$_] = $_ for 0 .. $self->{'subrule_count'} - 1;
        $self->{'input_indy_pattern'} = [ @{$self->{'input_pattern'}} ];
    } elsif ($mode eq 'symmetric' ) {
        my $map_nr = 0;
        for my $i (0 .. $self->{'subrule_count'} - 1) {
            if ($self->{'input_symmetric_partner'}[$i] > $i) {
                $self->{'subrule_mapping'}[$i] = $self->{'subrule_mapping'}[ $self->{'input_symmetric_partner'}[$i] ];
                $self->{'independent_subrules'}--;
            } else {
                $self->{'subrule_mapping'}[$i] = $map_nr;
                $self->{'input_indy_pattern'}[$map_nr++] = $self->{'input_pattern'}[$i];
            }
        }
    } else {
        $self->{'independent_subrules'} = ($state_count-1) * $input_size + 1;
        for my $i (0 .. $self->{'subrule_count'} - 1) {
            my $sum = 0;
            map {$sum += $_} @{$self->{'input_list'}[$i]};
            $self->{'subrule_mapping'}[$i] = $sum;
        }
        my $pre_pattern = join '', (0) x ($input_size - 1);
        my $last_state = $state_count - 1;
        $self->{'input_indy_pattern'}[$_] = $pre_pattern.$_ for 0 .. $last_state;
        for my $i ($state_count .. $last_state + $input_size) {
            $self->{'input_indy_pattern'}[$i] = substr($self->{'input_indy_pattern'}[$i-1], 1) . $last_state;
        }
    }

    $self->{'max_rule_nr'} = ($state_count ** $self->{'independent_subrules'}) - 1;
    if ($self->{'max_rule_nr'} < $self->{'rule_number'}) {
        safe_rule_number( $self );
        $self->{'rule_number'} = $self->{'max_rule_nr'}
    }
    my @output = (0) x $self->{'independent_subrules'};
    $self->{'output_list'}[0] = [@output];
    $self->{'output_pattern'}[0] = join '', @output;
    $self->{'output_pattern_index'}{ $self->{'output_pattern'}[0] } = 0;
    for my $i (1 .. $self->{'max_rule_nr'} - 1){
        for my $cell_pos (0 .. $self->{'independent_subrules'} - 1) {
            $output[$cell_pos]++;
            last if $output[$cell_pos] < $state_count;
            $output[$cell_pos] = 0;
        }
        $self->{'output_list'}[$i]    = [reverse @output];
        $self->{'output_pattern'}[$i] = join '', @output;
        $self->{'output_pattern_index'}{ $self->{'output_pattern'}[$i] } = $i;
    }

    $self;
}

########################################################################

sub get_result_from_pattern {
    my ($self, $pattern) = @_;
    return unless exists $self->{'index_from_pattern'}{$pattern};
    my $i = $self->{'index_from_pattern'}{$pattern};
    $i = $self->{'subrule_mapping'}[$i];
    $self->get_subrule_result( $i );
}
sub get_subrule_result {
    my ($self, $index) = @_;
    return unless defined $index and $index < $self->independent_subrules and $index > -1;
    $self->{'result'}[$index];
}
sub set_subrule_result {
    my ($self, $index, $result) = @_;
    return unless defined $result and $index < $self->independent_subrules and $index > -1;
    $self->{'result'}[$index] = $result;
}

sub get_rule_number { $_[0]->{'rule_number'} }
sub set_rule_number {
    my ($self, $number) = @_;
    return unless defined $number and $number > -1 and $number < $self->{'max_rule_nr'};
    $self->{'rule_number'} = $number;
    $self->{'result'} = [@{$self->{'output_list'}[$number]}];
    $number;
}

sub subrule_count        { $_[0]->{'subrule_count'} }
sub independent_subrules { $_[0]->{'independent_subrules'} }
sub input_patterns       { @{$_[0]->{'input_pattern'}} }
sub independent_input_patterns { @{$_[0]->{'indy_pattern'}} }

sub input_list_from_index {
    my ($self, $index) = @_;
    @{$self->{'input_list'}[$index]} if exists $self->{'input_list'}[$index];
}
sub index_from_input_list {
    my ($self) = shift;
    my $pattern = join '', reverse @_;
    $self->{'input_pattern_index'}{ $pattern } if exists $self->{'input_pattern_index'}{ $pattern };
}
sub result_from_input_list {
    my ($self) = shift;
    $self->get_result_from_pattern( join '', reverse @_ );
}

sub input_pattern_from_subrule_nr {
    my ($self, $sub_rule_nr) = @_;
    $self->{'input_indy_pattern'}[$sub_rule_nr] if exists $self->{'input_indy_pattern'}[$sub_rule_nr];
}

sub rule_nr_from_output_list {
    my ($self, @l) = shift;
    return unless $#l == $self->{'independent_subrules'};
    my $pattern = join '', reverse @l;
    $self->{'output_pattern_index'}{ $pattern } if exists $self->{'output_pattern_index'}{ $pattern };
}

sub output_list_from_rule_nr {
    my ($self, $nr) = @_;
    return unless exists $self->{'output_list'}[$nr];
    @{$self->{'output_list'}[$nr]}
}

########################################################################

sub safe_rule_number {
    my ($self) = @_;
    $self->{'next_rule_number'} = [];
    push @{$self->{'last_rule_number'}}, $self->{'rule_number'};
}
sub undo_rule_number {
    my ($self) = @_;
    return unless @{$self->{'last_rule_number'}};
    push @{$self->{'next_rule_number'}}, $self->{'rule_number'};
    $self->set_rule_number( pop @{$self->{'last_rule_number'}} );
}
sub redo_rule_number {
    my ($self) = @_;
    return unless @{$self->{'next_rule_number'}};
    push @{$self->{'last_rule_number'}}, $self->{'rule_number'};
    $self->set_rule_number( pop @{$self->{'next_rule_number'}} );
}

sub prev_rule_nr {
    my ($self) = @_;
    my $nr = $self->safe_rule_number;
    $nr = ($nr < 0) ? ($self->{'max_rule_nr'}-1) : $nr - 1;
    $self->set_rule_number( $nr );
}
sub next_rule_nr {
    my ($self) = @_;
    my $nr = $self->safe_rule_number;
    $nr = ($nr >= $self->{'max_rule_nr'}) ? 0 : $nr + 1;
    $self->set_rule_number( $nr );
}
sub shift_rule_nr_left {
    my ($self) = @_;
    my $nr = $self->safe_rule_number;
    $nr = $nr << 1;
    $nr = 0 if $nr >= $self->{'max_rule_nr'};
    $self->set_rule_number( $nr );
}
sub shift_rule_nr_right {
    my ($self) = @_;
    my $nr = $self->safe_rule_number;
    $nr = ($nr == 0) ? ($self->{'max_rule_nr'}-1) : $nr >> 1;
    $self->set_rule_number( $nr );
}

sub opposite_rule_nr {
    my ($self) = @_;
    my $nr = $self->safe_rule_number;
    my @old_list = $self->output_list_from_rule_nr( $nr );
    my @new_list = map { $old_list[ $self->{'independent_subrules'} - $_ - 1] } 0 .. $self->{'independent_subrules'} - 1;
    $self->set_rule_number( $self->rule_nr_from_output_list( @new_list ) );
}
sub symmetric_rule_nr {
    my ($self) = @_;
    return $self->{'rule_number'} unless $self->{'mode'} eq 'all';
    my $nr = $self->safe_rule_number;
    my @old_list = $self->output_list_from_rule_nr( $nr );
    my @new_list = map { $old_list[ $self->{'input_symmetric_partner'}[$_] ] } 0 .. $self->{'subrule_count'} - 1;
    $self->set_rule_number( $self->rule_nr_from_output_list( @new_list ) );
}
sub inverted_rule_nr {
    my ($self) = @_;
    my $nr = $self->safe_rule_number;
    $self->set_rule_number( $self->{'max_rule_nr'} - $nr );# swap color
}

sub random_nr {
    my ($self) = @_;
    $self->safe_rule_number;
    my $nr = int rand $self->{'max_rule_nr'} + 1;
    $self->set_rule_number( $nr );
}

1;
