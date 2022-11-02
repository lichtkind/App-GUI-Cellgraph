use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::RuleGenerator;

sub new {
    my ($pkg, $size, $states) = @_;
    my $self = {size => $size, states => $states, in_list => [], };
    $self->{'count'} = 2 ** $size;
    $self->{'max_nr'} = (2 ** $self->{'count'}) - 1;
    #$self->{'nr'} = (2 ** $self->{'count'}) - 1;
    my $pattern = '%0'.$size.'b';
    for my $rule (0 .. $self->{'count'} - 1) {
        my $bin = sprintf $pattern, $rule;
        push @{$self->{'in_list'}}, [split "", $bin];
    }
    bless $self;
}

1;

__END__

    for my $i (reverse 0 .. $#{$self->{'rules'}}){
        my $v = $old_list[ $self->{'opp'}[$i] ];
        $self->{'switch'}[$i]->SetValue( $v );
        $rule <<= 1;
        $rule++ if $v;
    }

    my @rule_in = ([0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 1, 1], [1, 0, 0], [1, 0, 1], [1, 1, 0], [1, 1, 1], );
    $self->{'rules'} = \@rule_in;
    
    $self->{'sym'} = [0, 4, 2, 6, 1, 5, 3, 7 ];
    $self->{'opp'} = [7, 6, 5, 4, 3, 2, 1, 0 ];

    my @rule_in = ([0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 1, 1], [1, 0, 0], [1, 0, 1], [1, 1, 0], [1, 1, 1], );
    $self->{'rules'} = \@rule_in;
