
# general purpose undo and redo functionality

package App::GUI::Cellgraph::Compute::History;
use v5.12;


sub new {
    my ($pkg, ) = @_;
    bless { present => undef, past => [], future => [],
            guard => '', merge => '',  last_condition => [] };
}

sub reset {
    my ($self) = @_;
    $self->{'past'} = [];
    $self->{'future'} = [];
}

sub set_guard_condition {
    my ($self, $condition) = @_;
    return unless ref $condition eq 'CODE';
    $self->{'guard'} = $condition;
}
sub set_merge_condition {
    my ($self, $condition) = @_;
    return unless ref $condition eq 'CODE';
    $self->{'merge'} = $condition;
}

sub add_value {
    my ($self, $value, @cond) = @_;
    return unless defined $value;
    return if defined $self->{'present'} and $value eq $self->{'present'};
    return if $self->{'guard'} and not $self->{'guard'}->($value);
    if ($self->{'merge'} and @cond) {
        my $do_merge = $self->{'merge'}->( [@cond], $self->{'last_condition'} );
        $self->{'last_condition'} = [@cond];
        if (not $do_merge and defined $self->{'present'}) {
            push @{$self->{'past'}}, $self->{'present'} ;
        }
    }
    $self->{'future'} = [];
    $self->{'present'} = $value;
    $value;
}

sub undo {
    my ($self) = @_;
    return unless $self->can_undo;
    unshift @{ $self->{'future'} }, $self->{'present'};
    $self->{'present'} = pop @{ $self->{'past'} };
}

sub redo {
    my ($self) = @_;
    return unless $self->can_redo;
    push @{ $self->{'past'} }, $self->{'present'};
    $self->{'present'} = shift @{ $self->{'future'} };
}

########################################################################
sub current_value { $_[0]->{'present'} if defined $_[0]->{'present'}; }
sub prev_value { $_[0]->{'past'}[-1] if $_[0]->can_undo; }
sub next_value { $_[0]->{'future'}[0] if $_[0]->can_redo; }

sub can_undo { int (@{$_[0]->{'past'}}) > 0 }
sub can_redo { int (@{$_[0]->{'future'}}) > 0 }

1;
