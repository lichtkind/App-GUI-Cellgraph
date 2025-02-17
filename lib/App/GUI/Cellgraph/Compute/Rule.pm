
# compute rule_nr (by output)

package App::GUI::Cellgraph::Compute::Rule;
use v5.12;
use bigint;
use warnings;
use Wx;
use App::GUI::Cellgraph::Compute::History;

sub new {
    my ($pkg, $subrules) = @_;
    return unless ref $subrules eq 'App::GUI::Cellgraph::Compute::Subrule';

    my $rules = $subrules->independent_count;
    my $states = $subrules->state_count;
    bless { subrules => $subrules, subrule_result => [],
            max_rule_nr => ($states ** $rules), rule_nr => -1,
            history => App::GUI::Cellgraph::Compute::History->new(),
    };
}
sub renew {
    my ($self) = @_;
    $self->{'history'}->reset;
    $self->{'subrule_result'} = [];
    $self->{'max_rule_nr'} = ($self->{'subrules'}->state_count ** $self->{'subrules'}->independent_count);
    $self->{'rule_nr'} = $self->{'max_rule_nr'}-1 unless $self->{'rule_nr'} < $self->{'max_rule_nr'};
    $self->set_rule_nr( $self->{'rule_nr'} );
}

########################################################################

sub subrules { $_[0]->{'subrules'} }

sub get_rule_nr { $_[0]->{'rule_nr'} }
sub set_rule_nr {
    my ($self, $number) = @_;
    return unless defined $number and $number > -1 and $number < $self->{'max_rule_nr'} and $number != $self->{'rule_nr'};
    $self->_update_results_from_rule_nr( $number );
    $self->safe_rule_nr( );
}
sub _update_results_from_rule_nr {
    my ($self, $rule_nr) = @_;
    $rule_nr = $self->get_rule_nr unless defined $rule_nr;
    $self->{'rule_nr'} = $rule_nr;
    $self->{'subrule_result'} = [ $self->result_list_from_rule_nr( $rule_nr ) ];
    $rule_nr;
}
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
    my ($self, $nr) = @_;
    $self->{'history'}->add_value( $nr //= $self->get_rule_nr );
}
sub undo_rule_nr {
    my ($self) = @_;
    my $rule_number = $self->{'history'}->undo // return;
    $self->_update_results_from_rule_nr( $rule_number );
}
sub redo_rule_nr {
    my ($self) = @_;
    my $rule_number = $self->{'history'}->redo // return;
    $self->_update_results_from_rule_nr( $rule_number );
}
sub can_undo { $_[0]->{'history'}->can_undo }
sub can_redo { $_[0]->{'history'}->can_redo }

####rule nr functions ##################################################
sub prev_rule_nr {
    my ($self) = @_;
    my $nr = $self->get_rule_nr;
    $nr = ($nr < 2) ? ($self->{'max_rule_nr'}-1) : $nr - 1;
    $self->set_rule_nr( $nr );
}
sub next_rule_nr {
    my ($self) = @_;
    my $nr = $self->get_rule_nr;
    $nr++;
    $nr = 1 if $nr >= $self->{'max_rule_nr'};
    $self->set_rule_nr( $nr );
}
sub shift_rule_nr_left {
    my ($self) = @_;
    my @result = @{$self->{'subrule_result'}};
    unshift @result, pop @result;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @result ) ) // $self->get_rule_nr;
}
sub shift_rule_nr_right {
    my ($self) = @_;
    my @result = @{$self->{'subrule_result'}};
    push @result, shift @result;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @result ) ) // $self->get_rule_nr;
}
sub opposite_rule_nr {
    my ($self) = @_;
    my $sub_rules = $self->{'subrules'}->independent_count;
    my @old_result = @{$self->{'subrule_result'}};
    my @new_result = map { $old_result[ $sub_rules - $_ - 1] }
        $self->{'subrules'}->index_iterator;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @new_result ) ) // $self->get_rule_nr;
}
sub symmetric_rule_nr {
    my ($self) = @_;
    return $self->{'rule_nr'} unless $self->{'subrules'}->mode eq 'all';
    my @old_result = @{$self->{'subrule_result'}};
    my @new_result = map { $old_result[ $self->{'subrules'}{'input_symmetric_partner'}[$_] ] }
        $self->{'subrules'}->index_iterator;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @new_result ) ) // $self->get_rule_nr;
}
sub inverted_rule_nr {
    my ($self) = @_;
    my $max_state = $self->{'subrules'}->state_count -1;
    my @new_result = map { $max_state - $_ } @{$self->{'subrule_result'}};
    $self->set_rule_nr( $self->rule_nr_from_result_list( @new_result ) );
}
sub random_rule_nr {
    my ($self) = @_;
    my @result = map {int rand $self->{'subrules'}->state_count} $self->{'subrules'}->index_iterator;
    $self->set_rule_nr( $self->rule_nr_from_result_list( @result ) )
}

1;
