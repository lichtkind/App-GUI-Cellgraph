use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Start;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::ColorToggle;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'state_count'} = 2;
    $self->{'length'} = my $length = 20;
    $self->{'max_value'} = $self->{'state_count'} ** $self->{'length'};
    $self->{'call_back'} = sub {};

    $self->{'state_colors'} = [map {[$_->rgb]} color('white')->gradient_to('black', $self->{'state_count'})];
    my $rule_cell_size = 20;
    $self->{'state_switches'}   = [ map { App::GUI::Cellgraph::Widget::ColorToggle->new( $self, $rule_cell_size, $rule_cell_size, $self->{'state_colors'}, 0) } 1 .. $length];
    $self->{'state_switches'}[$_]->SetToolTip('click with left or right to change state of this cell in starting row') for 0 .. $self->{'length'} - 1;
    # $self->{'state_switches'}[0]->Enable(0);
    $self->{'widget'}{'state_int'}  = Wx::TextCtrl->new( $self, -1, 1, [-1,-1], [ 180, -1] );
    $self->{'widget'}{'state_int'}->SetToolTip('condensed content of start row states');
    $self->{'widget'}{'action_int'}  = Wx::TextCtrl->new( $self, -1, 1, [-1,-1], [ 180, -1] );
    $self->{'widget'}{'state_int'}->SetToolTip('condensed content of start row activity values');
    $self->{'widget'}{'repeat_states'} = Wx::CheckBox->new( $self, -1, '  Repeat');
    $self->{'widget'}{'repeat_action'} = Wx::CheckBox->new( $self, -1, '  Repeat');
    $self->{'widget'}{'repeat_states'}->SetToolTip('repeat this pattern as the starting row is long');
    $self->{'btn'}{'prev'}  = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'btn'}{'next'}  = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'btn'}{'one'}   = Wx::Button->new( $self, -1, '1',  [-1,-1], [30,25] );
    $self->{'btn'}{'rnd'}   = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    $self->{'label'}{'state_rules'}  = Wx::StaticText->new( $self, -1, 'Cell States' );
    $self->{'label'}{'action_rules'}  = Wx::StaticText->new( $self, -1, 'Activity Values' );
    $self->{'label'}{'state_int'} = Wx::StaticText->new( $self, -1, 'Summary:' );
    $self->{'label'}{'action_int'} = Wx::StaticText->new( $self, -1, 'Summary:' );

    $self->{'action_colors'} = [map {[$_->rgb]} color('orange')->gradient_to('white', 6)];
    $self->{'action_switches'}   = [ map { App::GUI::Cellgraph::Widget::ColorToggle->new( $self, $rule_cell_size, $rule_cell_size, $self->{'action_colors'}, 0) } 1 .. $length];

    $self->{'btn'}{'one'}->SetToolTip('reset cell states in starting row to initial values');
    $self->{'btn'}{'rnd'}->SetToolTip('choose random cell states in starting row');
    $self->{'btn'}{'next'}->SetToolTip('increment number that summarizes all cell states of starting row');
    $self->{'btn'}{'prev'}->SetToolTip('decrement number that summarizes all cell states of starting row');
    $self->{'label'}{'state_int'}->SetToolTip('ID of current starting row configuration');
    $self->{'label'}{'action_int'}->SetToolTip('ID of the configuration of activity values');

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'prev'}, sub { $self->prev_start;  $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'next'}, sub { $self->next_start;  $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'one'},  sub { $self->init;        $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'rnd'},  sub { $self->random_start;$self->{'call_back'}->() }) ;
    Wx::Event::EVT_CHECKBOX( $self, $self->{'widget'}{$_}, sub { $self->{'call_back'}->() }) for qw/repeat_states repeat_action/;
    $_->SetCallBack( sub { $self->{'widget'}{'state_int'}->SetValue( $self->get_number ); $self->{'call_back'}->() }) for @{$self->{'state_switches'}};

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL;
    my $sep_attr = $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT | &Wx::wxGROW;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;
    my $tb_attr  = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $indent   = 15;


    my $state_int_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $state_int_sizer->AddSpacer( 10 );
    $state_int_sizer->Add( $self->{'label'}{'state_int'}, 0, &Wx::wxGROW | &Wx::wxALL, 10 );
    $state_int_sizer->Add( $self->{'widget'}{'state_int'}, 0, $all_attr, 5 );
    $state_int_sizer->AddSpacer( 10 );
    $state_int_sizer->Add( $self->{'btn'}{'prev'}, 0, $tb_attr, 5 );
    $state_int_sizer->Add( $self->{'btn'}{'next'}, 0, $tb_attr, 5 );
    $state_int_sizer->AddSpacer( 5 );
    $state_int_sizer->Add( $self->{'btn'}{'one'}, 0, $all_attr, 5 );
    $state_int_sizer->Add( $self->{'btn'}{'rnd'}, 0, $all_attr, 5 );
    $state_int_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $io_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $io_sizer->AddSpacer(20);
    $io_sizer->Add( $self->{'state_switches'}[$_-1], 0, &Wx::wxGROW ) for 1 .. $self->{'length'};
    $io_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $aio_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $aio_sizer->AddSpacer(20);
    $aio_sizer->Add( $self->{'action_switches'}[$_-1], 0, &Wx::wxGROW ) for 1 .. $self->{'length'};
    $aio_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action_int_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $action_int_sizer->AddSpacer( 10 );
    $action_int_sizer->Add( $self->{'label'}{'action_int'}, 0, &Wx::wxGROW | &Wx::wxALL, 10 );
    $action_int_sizer->Add( $self->{'widget'}{'action_int'}, 0, $all_attr, 5 );
    $action_int_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);


    my $row_space = 15;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'label'}{'state_rules'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $state_int_sizer, 0, $std_attr, 10);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $io_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'widget'}{'repeat_states'}, 0, $row_attr, 23);
    $main_sizer->AddSpacer(10);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, 20 );
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $sep_attr, $row_space );
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'label'}{'action_rules'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 0);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $action_int_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $aio_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'widget'}{'repeat_action'}, 0, $row_attr, 23);
    $main_sizer->AddSpacer( 10 );

    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub init        { $_[0]->set_settings({ value => 1, repeat_states => 0,
                                                    repeat_action => 1 }) }

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH';
    $self->set_number( $settings->{'value'} );
    $self->{'widget'}{$_}->SetValue( $settings->{$_} ) for qw/repeat_states repeat_action/;
}
sub get_settings {
    my ($self) = @_;
    {
        value => $self->{'widget'}{'state_int'}->GetValue ? $self->{'widget'}{'state_int'}->GetValue : 0,
        repeat_states => $self->{'widget'}{'repeat_states'}->GetValue ? 1 : 0,
        repeat_action => $self->{'widget'}{'repeat_action'}->GetValue ? 1 : 0,
    }
}
sub get_state {
    my ($self) = @_;
    my $state = $self->get_settings;
    $state->{'list'} = [$self->cell_state_list];
    $state->{'action_list'} = [$self->cell_action_list];
    $state;
}

sub set_number {
    my ($self, $number) = @_;
    my $max = ($self->{'state_count'} ** $self->{'length'}) - 1;
    $number = $self->{'max_value'} if $number > $self->{'max_value'};
    $number =    0 if $number < 0;
    $self->{'widget'}{'state_int'}->SetValue( $number );
    for my $i ( 0 .. $self->{'length'} - 1 ) {
        my $v = $number % $self->{'state_count'};
        $self->{'state_switches'}[$i]->SetValue( $v );
        $number -= $v;
        $number /= $self->{'state_count'};
    }
}

sub get_number {
    my ($self) = @_;
    my $number = 0;
    for (reverse $self->cell_state_list){
        $number *= $self->{'state_count'};
        $number += $_;
    }
    $number;
}

sub cell_state_list {
    my ($self) = @_;
    my @list = map { $self->{'state_switches'}[$_]->GetValue } 0 .. $self->{'length'} - 1;
    pop @list while @list and not $list[-1];    # remove zeros in suffix
    unless ($self->{'widget'}{'repeat_states'}->GetValue){ shift @list while @list and not $list[0] }
    @list;
}

sub cell_action_list {
    my ($self) = @_;
    my @list = map { $self->{'action_switches'}[$_]->GetValue } 0 .. $self->{'length'} - 1;
    pop @list while @list and not $list[-1];    # remove zeros in suffix
    unless ($self->{'widget'}{'repeat_action'}->GetValue){ shift @list while @list and not $list[0] }
    @list;
}

sub update_cell_colors {
    my ($self, @colors) = @_;
    return if @colors < 2;
    my $do_recolor = @colors == $self->{'state_count'} ? 0 : 1;
    for my $i (0 .. $#colors) {
        return unless ref $colors[$i] eq 'Graphics::Toolkit::Color';
        if (exists $self->{'state_colors'}[$i]) {
            my @rgb = $colors[$i]->rgb;
            $do_recolor += !( $rgb[$_] == $self->{'state_colors'}[$i][$_]) for 0 .. 2;
        } else { $do_recolor++ }
    }
    return unless $do_recolor;
    my @rgb = map {[$_->rgb]} @colors;
    $self->{'state_switches'}[$_]->SetColors( @rgb ) for 0 .. $self->{'length'} - 1;
    $self->{'state_count'} = @colors;
    $self->{'max_value'} = $self->{'state_count'} ** $self->{'length'};
}

sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub random_start { $_[0]->set_number( int rand $_[0]->{'max_value'} ) }
sub next_start { $_[0]->set_number( $_[0]->{'widget'}{'state_int'}->GetValue + 1 ) }
sub prev_start {
    my ($self) = @_;
    my $int = $self->{'widget'}{'state_int'}->GetValue;
    $int-- if $int > 1;
    $self->set_number( $int );
}

1;
