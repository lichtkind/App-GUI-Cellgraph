
# general purpose undo and redo functionality

package App::GUI::Cellgraph::Compute::History;
use v5.12;


sub new {
    my ($pkg, ) = @_;
    bless { present => undef, past => [], future => [], guard => ''  };
}

sub reset {
    my ($self) = @_;
    $self->{'past'} = [];
    $self->{'future'} = [];
}

sub set_guard {
    my ($self, $guard) = @_;
    return unless ref $guard eq 'CODE';
    $self->{'guard'} = $guard;
}

sub add_value {
    my ($self, $value) = @_;
    return unless defined $value;
    return if $self->{'guard'} and not $self->{'guard'}->($value);
    $self->{'future'} = [];
    push @{$self->{'past'}}, $self->{'present'} if defined $self->{'present'};
say "add $value ";
    $self->{'present'} = $value;
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
