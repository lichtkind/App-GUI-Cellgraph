
# global settings panel

package App::GUI::Cellgraph::Frame::Panel::Global;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1);
    $self->{'call_back'} = sub {};

    $self->create_label( 'logicals', 'Logical Settings' );
    $self->create_label( 'visuals',  'Visual Settings' );
    $self->create_label( 'input_size',  'Input Size:', 'Size of neighbourhood - from how many cells compute new cell state ?' );
    $self->create_label( 'state_count', 'Cell States :','How many states a cell can have ?' );
    $self->create_label( 'rule_count',  'Rules :',      'Amount of rules resulting current from settings.' );
    $self->create_label( 'grid',        'Grid Style:',  'How to paint gaps between cell squares ?' );
    $self->create_label( 'cell_size',   'Size :',       'Visual size of the cells in pixel.' );
    $self->create_label( 'direction',   'Direction :',  'painting direction and pattern mirroring style' );
    # $self->{'action_ab_lbl'} = Wx::StaticText->new( $self, -1, 'Action Values :');
    # $self->{'threshhold_lbl'} = Wx::StaticText->new( $self, -1, 'Threshold :');

    $self->{'widget'}{'circular_grid'} = Wx::CheckBox->new( $self, -1, '  Circular');
    $self->{'widget'}{'rule_rount'}  = Wx::TextCtrl->new( $self, -1, 8, [-1,-1], [ 80, -1], &Wx::wxTE_READONLY );

    $self->{'widget'}{'input_size'}  = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[65, -1], [qw/2 3 4 5 6 7/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'state_count'} = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[65, -1], [qw/2 3 4 5 6 7 8 9/], &Wx::wxTE_READONLY);
    # $self->{'widget'}{'action_values'} = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[75, -1], [qw/2 3 4 5 6 7 8 9/], &Wx::wxTE_READONLY);
    # $self->{'widget'}{'action_threshold'} = Wx::ComboBox->new( $self, -1, '1', [-1,-1],[75, -1], [qw/0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'grid_type'}   = Wx::ComboBox->new( $self, -1, 'lines', [-1,-1],[90, -1], ['lines', 'gaps', 'no']);
    $self->{'widget'}{'cell_size'}   = Wx::ComboBox->new( $self, -1, '3', [-1,-1],[65, -1], [qw/1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 25 30/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'paint_direction'} = Wx::ComboBox->new( $self, -1, 'top_down', [-1,-1],[120, -1], [qw/top_down outside_in inside_out/], &Wx::wxTE_READONLY);

    $self->{'widget'}{'input_size'}->SetToolTip('Size of neighbourhood (how many cells) to compute new cell state from ?');
    $self->{'widget'}{'state_count'}->SetToolTip('How many states a cell can have?');
    $self->{'widget'}{'rule_rount'}->SetToolTip('amount of rules resulting current from settings');
    # $self->{'widget'}{'action_values'}->SetToolTip('how many action values between 0 and 1 a cell can emit to itself and neighbours?');
    # $self->{'widget'}{'action_threshold'}->SetToolTip('when action value of a cell is equal or higher the cell will be active?');
    $self->{'widget'}{'grid_type'}->SetToolTip('how to paint gaps between cell squares');
    $self->{'widget'}{'cell_size'}->SetToolTip('visual size of the cells in pixel');
    $self->{'widget'}{'paint_direction'}->SetToolTip('painting direction');
    $self->{'widget'}{'circular_grid'}->SetToolTip('cells on the edges become neighbours to each other');

    Wx::Event::EVT_CHECKBOX( $self, $self->{'widget'}{$_}, sub { $self->{'call_back'}->() }) for qw/circular_grid/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{'widget'}{$_},
        sub { $self->compute_cell_count; $self->{'call_back'}->() }) for qw/state_count input_size grid_type cell_size paint_direction/;

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;

    my $logic1_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $logic1_sizer->AddSpacer( 15 );
    $logic1_sizer->Add( $self->{'label'}{'input_size'}, 0, $all_attr, 8);
    $logic1_sizer->Add( $self->{'widget'}{'input_size'}, 0, $row_attr, 8);
    $logic1_sizer->AddSpacer( 21 );
    $logic1_sizer->Add( $self->{'label'}{'state_count'}, 0, $all_attr, 7);
    $logic1_sizer->Add( $self->{'widget'}{'state_count'}, 0, $row_attr, 8);
    $logic1_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $logic2_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $logic2_sizer->AddSpacer( 15 );
    $logic2_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $logic3_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $logic3_sizer->AddSpacer( 15 );
    $logic3_sizer->Add( $self->{'label'}{'rule_count'}, 0, $all_attr, 7);
    $logic3_sizer->Add( $self->{'widget'}{'rule_rount'}, 0, $row_attr, 8);
    $logic3_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    #~ $action_sizer->AddSpacer( 23 );
    #~ $action_sizer->Add( $self->{'action_ab_lbl'}, 0, $all_attr, 7);
    #~ $action_sizer->Add( $self->{'action_values'}, 0, $row_attr, 8);
    #~ $action_sizer->AddSpacer( 18 );
    #~ $action_sizer->Add( $self->{'threshhold_lbl'}, 0, $all_attr, 7);
    #~ $action_sizer->Add( $self->{'action_threshold'}, 0, $row_attr, 8);
    $action_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $visual1_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $visual1_sizer->AddSpacer( 15 );
    $visual1_sizer->Add( $self->{'label'}{'grid'}, 0, $all_attr, 7);
    $visual1_sizer->Add( $self->{'widget'}{'grid_type'}, 0, $row_attr, 8);
    $visual1_sizer->AddSpacer( 33 );
    $visual1_sizer->Add( $self->{'label'}{'cell_size'}, 0, $all_attr, 7);
    $visual1_sizer->AddSpacer( 3 );
    $visual1_sizer->Add( $self->{'widget'}{'cell_size'}, 0, $row_attr, 8);
    $visual1_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $visual2_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $visual2_sizer->AddSpacer( 15 );
    $visual2_sizer->Add( $self->{'label'}{'direction'}, 0, $all_attr, 7);
    $visual2_sizer->Add( $self->{'widget'}{'paint_direction'}, 0, $row_attr, 8);
    $visual2_sizer->AddSpacer( 40 );
    $visual2_sizer->Add( $self->{'widget'}{'circular_grid'}, 0, $row_attr, 8);
    $visual2_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $row_space = 10;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $self->{'label'}{'logicals'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $logic1_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $logic2_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $logic3_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, $row_space );
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $self->{'label'}{'visuals'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $visual1_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $visual2_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, $row_space );
    $main_sizer->Add( $action_sizer, 0, $std_attr, 0);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub init        {
    $_[0]->set_settings({
        grid_type => 'lines', cell_size => 3, paint_direction => 'top_down',
        state_count => 2, input_size => 3, circular_grid => 0, rule_rount => 8,
    }); # action_values => 2, action_threshold => 1
}

sub get_settings {
    my ($self) = @_;
    my $settings = { map { $_ => $self->{'widget'}{$_}->GetValue } keys %{$self->{'widget'}} };
    $settings;
}
sub get_state { $_[0]->get_settings() }

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH';
    $self->{'widget'}{$_}->SetValue( $settings->{$_} ) for keys %{$self->{'widget'}};
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub create_label {
    my ($self, $id, $text, $help) = @_;
    return unless defined $text and $text and not exists $self->{'label'}{ $id };
    $self->{'label'}{ $id } = Wx::StaticText->new( $self, -1, $text );
    $self->{'label'}{ $id }->SetToolTip('how to paint gaps between cell squares') if defined $help and $help;
    $self->{'label'}{ $id }
}

sub compute_cell_count {
    my ($self) = @_;
}

1;
