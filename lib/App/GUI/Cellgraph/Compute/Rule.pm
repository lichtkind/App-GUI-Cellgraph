
# compute rule_nr (by output)

use v5.12;
use warnings;
use Wx;
package App::GUI::Cellgraph::Compute::Rule;

sub new {
    my ($pkg, $subrules) = @_;
    return unless ref $subrules eq 'App::GUI::Cellgraph::Compute::Subrule';

    my $rules = $subrules->independent_count;
    my $states = $subrules->state_count;
    my $self = { subrules => $subrules, subrule_result => [],
            output_list => [], output_pattern_index => {},
            rule_number => -1, max_rule_nr => ($states ** $rules),
            last_rule_number => [], next_rule_number => [],
    };

    $self->{'output_list'} = [ $self->{'subrules'}->permutations( $rules, $states )];
    for my $i (0 .. $self->{'max_rule_nr'} - 1){
        $self->{'output_pattern'}[$i] = join '', reverse @{$self->{'output_list'}[$i]};
        $self->{'output_pattern_index'}{ $self->{'output_pattern'}[$i] } = $i;
    }

    bless $self;
}
sub renew {
    my ($self) = @_;

    $self->{'result'} = [];
    $self->{'output_list'} = [];
    $self->{'output_pattern'} = [];
    $self->{'output_pattern_index'} = {};
    $self->{'next_rule_number'} = [];
    $self->{'last_rule_number'} = [];
    $self->{'max_rule_nr'} = ($self->{'subrules'}->state_count ** $self->{'subrules'}->independent_count);
    $self->{'rule_number'} = $self->{'max_rule_nr'} if $self->{'max_rule_nr'} > $self->{'rule_number'};
    $self->set_rule_number( $self->{'rule_number'} );

    $self->{'output_list'} =
        [ $self->{'subrules'}->permutations( $self->{'subrules'}->independent_count,
                                             $self->{'subrules'}->state_count        )];
    for my $i (0 .. $self->{'max_rule_nr'} - 1){
        $self->{'output_pattern'}[$i] = join '', reverse @{$self->{'output_list'}[$i]};
        $self->{'output_pattern_index'}{ $self->{'output_pattern'}[$i] } = $i;
    }

    $self;
}

########################################################################

sub result_from_pattern {
    my ($self, $pattern) = @_;
    return unless exists $self->{'index_from_pattern'}{$pattern};
    my $nr = $self->{'subrules'}->independent_pattern_number( $pattern );
    return unless defined $nr;
    $self->get_subrule_result( $nr );
}
sub result_from_input_list {
    my ($self) = shift;
    $self->get_result_from_pattern( join '', reverse @_ );
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
    return unless defined $number and $number > -1 and $number < $self->{'max_rule_nr'}
        and $number != $self->{'rule_number'};
    $self->safe_rule_number( $number );
    $self->{'rule_number'} = $number;
    $self->{'result'} = [@{$self->{'output_list'}[$number]}];
    $number;
}

sub rule_nr_from_output_list {
    my ($self, @l) = @_;
    return unless @l == $self->{'subrules'}->independent_count;
    my $pattern = join '', @l;
    $self->{'output_pattern_index'}{ $pattern } if exists $self->{'output_pattern_index'}{ $pattern };
}

sub output_list_from_rule_nr {
    my ($self, $nr) = @_;
    return unless exists $self->{'output_list'}[$nr];
    reverse @{$self->{'output_list'}[$nr]}
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
########################################################################

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
    my $sub_rules = {'subrules'}->independent_count;
    my $nr = $self->safe_rule_number;
    my @old_list = $self->output_list_from_rule_nr( $nr );
    my @new_list = map { $old_list[ $sub_rules - $_ - 1] } 0 .. $sub_rules - 1;
    $self->set_rule_number( $self->rule_nr_from_output_list( @new_list ) );
}
sub symmetric_rule_nr {
    my ($self) = @_;
    return $self->{'rule_number'} unless $self->{'subrules'}{'mode'} eq 'all';
    my $nr = $self->safe_rule_number;
    my @old_list = $self->output_list_from_rule_nr( $nr );
    my @new_list = map { $old_list[ $self->{'subrules'}{'input_symmetric_partner'}[$_] ] } 0 .. $self->{'subrules'}->independent_count - 1;
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
