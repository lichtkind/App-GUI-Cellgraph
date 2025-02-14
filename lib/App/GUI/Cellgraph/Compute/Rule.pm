
# compute rule_nr (by output)

package App::GUI::Cellgraph::Compute::Rule;
use v5.12;
use bigint;
use warnings;
use Wx;

sub new {
    my ($pkg, $subrules) = @_;
    return unless ref $subrules eq 'App::GUI::Cellgraph::Compute::Subrule';

    my $rules = $subrules->independent_count;
    my $states = $subrules->state_count;
    bless { subrules => $subrules, subrule_result => [],
            max_rule_nr => ($states ** $rules), rule_nr => -1,
            last_rule_nr => [], next_rule_nr => [],
    };
}
sub renew {
    my ($self) = @_;
    $self->{'next_rule_nr'} = [];
    $self->{'last_rule_nr'} = [];
    $self->{'subrule_result'} = [];
    $self->{'max_rule_nr'} = ($self->{'subrules'}->state_count ** $self->{'subrules'}->independent_count);
    $self->{'rule_nr'} = $self->{'max_rule_nr'}-1 unless $self->{'rule_nr'} < $self->{'max_rule_nr'};
    $self->set_rule_nr( $self->{'rule_nr'} );
    $self->_update_results_from_rule_nr( );
    $self;
}

########################################################################

sub subrules { $_[0]->{'subrules'} }

sub get_rule_nr { $_[0]->{'rule_nr'} }
sub set_rule_nr {
    my ($self, $number) = @_;
    return unless defined $number and $number > -1 and $number < $self->{'max_rule_nr'} and $number != $self->{'rule_nr'};
    $self->safe_rule_nr;
    $self->{'rule_nr'} = $number;
    $self->_update_results_from_rule_nr;
    $number;
}
sub _update_results_from_rule_nr { $_[0]->{'subrule_result'} = [$_[0]->result_list_from_rule_nr( $_[0]->{'rule_nr'} ) ] }
sub _update_rule_nr_from_results { $_[0]->{'rule_nr'} = $_[0]->rule_nr_from_result_list( @{$_[0]->{'subrule_result'}} ) }
sub _is_state { (@_ == 2 and $_[1] >= 0 and $_[1] < $_[0]->{'subrules'}->state_count) ? 1 : 0 }
sub _is_index { (@_ == 2 and $_[1] >= 0 and $_[1] < $_[0]->{'subrules'}->independent_count) ? 1 : 0 }


sub get_subrule_result {
    my ($self, $index) = @_;
    return unless $self->_is_index( $index );
    $self->{'subrule_result'}[$index];
}
sub set_subrule_result {
    my ($self, $index, $result) = @_;
    return unless $self->_is_index( $index ) and $self->_is_state( $result );
    $self->{'subrule_result'}[$index] = int $result;
    $self->_update_rule_nr_from_results();
}

sub result_from_pattern {
    my ($self, $pattern) = @_;
    my $nr = $self->{'subrules'}->effective_pattern_nr( $pattern );
    return unless defined $nr;
    $self->get_subrule_result( $nr );
}
sub result_from_input_list {
    my ($self) = shift;
    $self->get_result_from_pattern( join '', reverse @_ );
}


sub rule_nr_from_result_list {
    my ($self, @results) = @_;
    return unless @results == $self->{'subrules'}->independent_count;
    my $sts = $self->{'subrules'}->state_count;
    my $rule_nr = 0;
    for my $result (reverse @results){
        $rule_nr *= $sts;
        $rule_nr += $result;
    }
    return $rule_nr;
}

sub result_list_from_rule_nr {
    my ($self, $nr) = @_;
    return unless defined $nr and $nr >= 0 and $nr < $self->{'max_rule_nr'};
    my $sts = $self->{'subrules'}->state_count;
    my @result = ();
    while ($nr){
        my $rest = $nr % $sts;
        push @result, $rest;
        $nr -= $rest;
        $nr /= $sts;
    }
    while (@result < $self->{'subrules'}->independent_count){ push @result, 0 }
    return @result;
}

####rule nr history ####################################################
sub safe_rule_nr {
    my ($self) = @_;
    $self->{'next_rule_nr'} = [];
    return if $self->{'rule_nr'} == -1;
    push @{$self->{'last_rule_nr'}}, $self->{'rule_nr'};
    $self->{'rule_nr'};
}
sub undo_rule_nr {
    my ($self) = @_;
    return unless @{$self->{'last_rule_nr'}};
    push @{$self->{'next_rule_nr'}}, $self->{'rule_nr'};
    $self->{'rule_number'} = pop @{$self->{'last_rule_nr'}};
    $self->_update_results_from_rule_nr;
    $self->{'rule_nr'};
}
sub redo_rule_nr {
    my ($self) = @_;
    return unless @{$self->{'next_rule_nr'}};
    push @{$self->{'last_rule_nr'}}, $self->{'rule_nr'};
    $self->{'rule_nr'} = pop @{$self->{'next_rule_nr'}};
    $self->_update_results_from_rule_nr;
    $self->{'rule_nr'};
}
sub can_undo { int (@{$_[0]->{'last_rule_nr'}}) > 0 }
sub can_redo { int (@{$_[0]->{'next_rule_nr'}}) > 0 }

####rule nr functions ##################################################
sub prev_rule_nr {
    my ($self) = @_;
    my $nr = $self->safe_rule_nr;
    $nr = ($nr < 2) ? ($self->{'max_rule_nr'}-1) : $nr - 1;
    $self->set_rule_nr( $nr );
}
sub next_rule_nr {
    my ($self) = @_;
    my $nr = $self->safe_rule_nr;
    $nr++;
    $nr = 1 if $nr >= $self->{'max_rule_nr'};
    $self->set_rule_nr( $nr );
}
sub shift_rule_nr_left {
    my ($self) = @_;
    my $nr = $self->safe_rule_nr;
    my @result = @{$self->{'subrule_result'}};
    unshift @result, pop @result;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @result ) ) // $nr;
}
sub shift_rule_nr_right {
    my ($self) = @_;
    my $nr = $self->safe_rule_nr;
    my @result = @{$self->{'subrule_result'}};
    push @result, shift @result;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @result ) ) // $nr;
}
sub opposite_rule_nr {
    my ($self) = @_;
    my $sub_rules = $self->{'subrules'}->independent_count;
    my $nr = $self->safe_rule_nr;
    my @old_result = @{$self->{'subrule_result'}};
    my @new_result = map { $old_result[ $sub_rules - $_ - 1] }
        $self->{'subrules'}->index_iterator;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @new_result ) ) // $nr;
}
sub symmetric_rule_nr {
    my ($self) = @_;
    return $self->{'rule_nr'} unless $self->{'subrules'}->mode eq 'all';
    my $nr = $self->safe_rule_nr;
    my @old_result = @{$self->{'subrule_result'}};
    my @new_result = map { $old_result[ $self->{'subrules'}{'input_symmetric_partner'}[$_] ] }
        $self->{'subrules'}->index_iterator;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @new_result ) ) // $nr;
}
sub inverted_rule_nr {
    my ($self) = @_;
    my $nr = $self->safe_rule_nr;
    $self->set_rule_nr( $self->{'max_rule_nr'} - $nr - 1 ) // $nr;# swap color
}

sub random_rule_nr {
    my ($self) = @_;
    $self->safe_rule_nr;
    $self->set_rule_nr( int rand( $self->{'max_rule_nr'} ) );
}

1;
