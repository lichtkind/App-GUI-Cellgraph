
# panel to change the values that control cell activity dependent on current subrule

package App::GUI::Cellgraph::Frame::Panel::Action;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::RuleInput;
use App::GUI::Cellgraph::Widget::SliderCombo;
use Graphics::Toolkit::Color qw/color/;

# undo redo

sub new {
    my ( $class, $parent, $subrule_calculator ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'subrules'} = $subrule_calculator;
    $self->{'rule_square_size'} = 20;
    $self->{'input_size'} = 0;
    $self->{'state_count'} = 0;
    $self->{'rule_mode'} = '';
    $self->{'call_back'} = sub {};

    $self->{'label'}{'action'} = Wx::StaticText->new( $self, -1, 'Gain :' );
    $self->{'label'}{'action'}->SetToolTip('Functions to change all the turn based activity gain values');
    $self->{'label'}{'spread'} = Wx::StaticText->new( $self, -1, 'Spread :' );
    $self->{'label'}{'spread'}->SetToolTip('Functions to change all the turn based activity spread values');

    my $btn_data = {action => [
        ['init', '1',15, 'put all activity gain value to default'],
        ['copy', '=',10, 'set all activity gains to the value of the first subrule'],
        ['add',  '+',20, 'increase all activity value gains by 0.05'],
        ['sub',  '-', 0, 'decrease all activity value gains by 0.05'],
        ['mul',  '*',10, 'increase large and decrease small values of activity gains'],
        ['div',  '/', 0, 'decrease large and increase small values of activity gains'],
        ['wave', '%',20, 'increase activity gain of odd numbered subrules and decrease them of even the numbered'],
        ['+rnd', '~',20, 'change all activity gains by a small random value'],
        ['rnd',  '?',10, 'set all activity gains to a random value'],
    ], spread => [
        ['init', '1', 0, 'put all activity spread value on default'],
        ['copy', '=',10, 'set all activity spread to the value of the first subrule'],
        ['add',  '+',20, 'increase all activity spread by 0.05'],
        ['sub',  '-', 0, 'decrease all activity spread by 0.05'],
        ['mul',  '*',10, 'increase large and decrease small values of activity spread'],
        ['div',  '/', 0, 'decrease large and increase small values of activity spread'],
        ['wave', '%',20, 'increase activity spread of odd numbered subrules and decrease them of even the numbered'],
        ['+rnd', '~',20, 'change all activity spread by a small random value'],
        ['rnd',  '?',10, 'set all activity spread to a random value'],
    ]};


    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_VERTICAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_VERTICAL;
    my $sizer;

    for my $type (qw/action spread/){
        next unless exists $btn_data->{$type} and ref $btn_data->{$type} eq 'ARRAY';
        $sizer->{ $type } = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        $sizer->{ $type }->AddSpacer( 10 );
        $sizer->{ $type }->Add( $self->{'label'}{ $type }, 0, $all_attr, 10 );

        for my $btn_data (@{$btn_data->{$type}}){
            my $button = Wx::Button->new( $self, -1, $btn_data->[1], [-1,-1], [30,25] );
            $button->SetToolTip( $btn_data->[3] );
            my $ID = $btn_data->[0];
            Wx::Event::EVT_BUTTON( $self, $button, sub { $self->change_values_command( $ID, $type); $self->{'call_back'}->() } );
            $sizer->{ $type }->AddSpacer( $btn_data->[2] );
            $sizer->{ $type }->Add( $button, 0, $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM, 5 );
        }
        $sizer->{ $type }->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    }

    $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'rule_plate'}->ShowScrollbars(0,1);
    $self->{'rule_plate'}->EnableScrolling(0,1);
    $self->{'rule_plate'}->SetScrollRate( 1, 1 );
    $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $sizer->{'action'}, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $sizer->{'spread'}, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT, 20 );
    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $self->SetSizer( $main_sizer );

    $self->regenerate_rules( 3, 2, color('white')->gradient_to('black', 2) );
    $self->init;
    $self;
}

sub regenerate_rules {
    my ($self, @colors) = @_;
    return if @colors < 2;
    my $do_regenerate = 0;
    my $do_recolor = 0;
    $do_regenerate += ($self->{'input_size'} != $self->{'subrules'}->input_size);
    $do_regenerate += ($self->{'state_count'} != $self->{'subrules'}->state_count);
    $do_regenerate += ($self->{'rule_mode'} ne $self->{'subrules'}->mode);
    for my $i (0 .. $#colors) {
        return unless ref $colors[$i] eq 'Graphics::Toolkit::Color';
        if (exists $self->{'state_colors'}[$i]) {
            my @rgb = $colors[$i]->values('rgb');
            $do_recolor += !( $rgb[$_] == $self->{'state_colors'}[$i][$_]) for 0 .. 2;
        } else { $do_recolor++ }
    }
    return unless $do_regenerate or $do_recolor;
    $self->{'input_size'} = $self->{'subrules'}->input_size;
    $self->{'state_count'} = $self->{'subrules'}->state_count;
    $self->{'rule_mode'}   = $self->{'subrules'}->mode;
    $self->{'state_colors'} = [map {[$_->rgb]} @colors];
    my @sub_rule_pattern = $self->{'subrules'}->independent_input_patterns;

    if ($do_regenerate){
        my $refresh = 0;# set back refresh flag

        if (exists $self->{'rule_input'}){
            $self->{'plate_sizer'}->Clear(1);
            $self->{'rule_input'} = [];
            $self->{'arrow'} = [];
            $self->{'action_result'} = []; # was action before
            $refresh = 1;
        } else {
            $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
            $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );
        }
        my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
        for my $i ($self->{'subrules'}->index_iterator){
            $self->{'rule_input'}[$i] = App::GUI::Cellgraph::Widget::RuleInput->new (
                $self->{'rule_plate'}, $self->{'rule_square_size'}, $sub_rule_pattern[$i], $self->{'state_colors'}
            );
            $self->{'rule_input'}[$i]->SetToolTip('input pattern of partial rule Nr.'.($i+1));
            $self->{'arrow'}[$i] = Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' );
            $self->{'arrow'}[$i]->SetToolTip('partial action rule Nr.'.($i+1).' input left, output right');

            my $help_text = 'turn based gain of activity value at partial rule Nr.'.($i+1);
            $self->{'action_result'}[$i] = App::GUI::Cellgraph::Widget::SliderCombo->new
                    ( $self->{'rule_plate'}, 80, '', $help_text, -1, 1, 0.7, 0.05, 'turn based activity value gain');
            $self->{'action_result'}[$i]->SetToolTip( $help_text );
            $self->{'action_result'}[$i]->SetCallBack( sub {
#                    $self->set_action_summary( $self->action_nr_from_results ); $self->{'call_back'}->();
            });

            my $help_txt = 'spread of activity value to neighbouring cells from partial rule Nr.'.($i+1);
            $self->{'action_spread'}[$i] = App::GUI::Cellgraph::Widget::SliderCombo->new
                    ( $self->{'rule_plate'}, 0, '', $help_txt, -1, 1, 0.3, 0.05, 'spread of activity value');
            $self->{'action_spread'}[$i]->SetToolTip( $help_txt );
            $self->{'action_spread'}[$i]->SetCallBack( sub {
#                    $self->set_action_summary( $self->action_nr_from_results ); $self->{'call_back'}->();
            });

        }
        my $label_length = length $self->{'subrules'}->independent_count;
        my $v_attr = &Wx::wxALIGN_CENTER_VERTICAL;
        for my $i ($self->{'subrules'}->index_iterator){
            my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
            $row_sizer->AddSpacer(20);
            $row_sizer->Add( Wx::StaticText->new( $self->{'rule_plate'}, -1, sprintf('%0'.$label_length.'u',$i+1).' :  ' ), 0, $v_attr);
            $row_sizer->Add( $self->{'rule_input'}[$i], 0, $v_attr );
            $row_sizer->AddSpacer(15);
            $row_sizer->Add( $self->{'arrow'}[$i], 0, $v_attr );
            $row_sizer->AddSpacer(0);
            $row_sizer->Add( $self->{'action_result'}[$i], 0, $v_attr );
            $row_sizer->Add( $self->{'action_spread'}[$i], 0, $v_attr );
            $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
            $self->{'plate_sizer'}->AddSpacer(15);
            $self->{'plate_sizer'}->Add( $row_sizer, 0, $std_attr, 0);
        }
        $self->Layout if $refresh;
    } elsif ($do_recolor) {
        my @rgb = map {[$_->rgb]} @colors;
        $self->{'rule_input'}[$_]->SetColors( @rgb ) for $self->{'subrules'}->index_iterator;
    }
}

sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

########################################################################
sub init { $_[0]->set_settings( { nr => 22222222 } ) }

sub get_state {
    my ($self) = @_;
    my $state = $self->get_settings;
    #~ $state->{'f'} = [$self->get_action_results];
    #~ $state;
    #~ {
        #~ nr => 1,
        #~ sum => 0,

    #~ }
}

sub get_settings {
    my ($self) = @_;
    {
        nr => 1,
        sum => 0,

    }
}

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'nr'};
    #$self->set_action_summary( $settings->{'nr'} );
}


sub get_action_results { map { $_[0]->{'action_result'}[$_]->GetValue } $_[0]->{'subrules'}->index_iterator }
sub get_action_spreads { map { $_[0]->{'action_spread'}[$_]->GetValue } $_[0]->{'subrules'}->index_iterator }
sub set_action_result {
    my ($self, $nr, $result) = @_;
    return unless defined $result;
}
sub set_all_action_results {
    my ($self, @result) = @_;
    return unless @result == $self->{'subrules'}->independent_count;
}
sub set_action_spread {
    my ($self, $nr, $spread) = @_;
    return unless defined $spread;
}
sub set_all_action_spreads {
    my ($self, @spread) = @_;
    return unless @spread == $self->{'subrules'}->independent_count;
}

sub result_summary {
    my ($self) = @_;
}

sub spread_summary {
    my ($self) = @_;
}

sub list_from_summary { split ',', $_[1] }
sub summary_from_list { shift @_; join ',', @_ }

########################################################################
sub init_action {
    my ($self) = @_;
    my @list = map { $self->{'action_result'}[$_]->init } $self->{'subrules'}->index_iterator;
    #$self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub grid_action {
    my ($self) = @_;
    my @list = map { $self->{'action_result'}[$_]->grid } $self->{'subrules'}->index_iterator;
    #$self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub random_action {
    my ($self) = @_;
    my @list =  map { $self->{'action_result'}[$_]->rand } $self->{'subrules'}->index_iterator;
    #$self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub invert_action {
    my ($self) = @_;
    my @list = map { $self->{'action_result'}[$_]->invert } $self->{'subrules'}->index_iterator;
    #$self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub change_values_command {
    my ($self, $command, $type) = @_;

}

1;
