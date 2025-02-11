
# global settings panel

package App::GUI::Cellgraph::Frame::Panel::Global;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Compute::Subrule;

# action threshhold , value

sub new {
    my ( $class, $parent, $subrule_calc ) = @_;
    return unless ref $subrule_calc eq 'App::GUI::Cellgraph::Compute::Subrule';
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'subrules'} = $subrule_calc;
    $self->{'call_back'} = sub {};

    $self->create_label( 'logicals', 'State Rules' );
    $self->create_label( 'actions', 'Action Rules' );
    $self->create_label( 'visuals',  'Visual Settings' );
    $self->create_label( 'input_size',  'Input Size:',  'Size of neighbourhood - from how many cells compute new cell state ?' );
    $self->create_label( 'state_count', 'Cell States :','How many states a cell can have ?' );
    $self->create_label( 'rule_kind',   'Kind:',        'Which subset of rules get bundled ?' );
    $self->create_label( 'application', 'Result:', 'Result of a subrule should replace previous value (insert) or be added to it ?' );
    $self->create_label( 'rule_count',  'Sub - Rules :','Amount of subrules and possible rules resulting from current settings.' );
    $self->create_label( 'grid',        'Grid Style:',  'How to paint gaps between cell squares ?' );
    $self->create_label( 'cell_size',   'Size :',       'Visual size of the cells in pixel.' );
    $self->create_label( 'direction',   'Direction :',  'painting direction and pattern mirroring style' );

    $self->{'widget'}{'circular_grid'}   = Wx::CheckBox->new( $self, -1, '  Circular');
    $self->{'widget'}{'use_action_rules'}= Wx::CheckBox->new( $self, -1, '  Active');
    $self->{'widget'}{'fill_cells'}      = Wx::CheckBox->new( $self, -1, '  Fill');

    $self->{'widget'}{'rule_count'}      = Wx::TextCtrl->new( $self, -1, 8, [-1,-1], [ 105, -1], &Wx::wxTE_READONLY );
    $self->{'widget'}{'subrule_count'}   = Wx::TextCtrl->new( $self, -1, 8, [-1,-1], [ 45, -1], &Wx::wxTE_READONLY );

    $self->{'widget'}{'input_size'}      = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[65, -1], [qw/2 3 4 5 6 7/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'state_count'}     = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[65, -1], [qw/2 3 4 5 6 7 8 9/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'rule_kind'}       = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[120, -1], [qw/all symmetric summing/], &Wx::wxTE_READONLY); # median
    $self->{'widget'}{'application'}     = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[110, -1], [qw/insert add subtract multiply/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'grid_type'}       = Wx::ComboBox->new( $self, -1, 'lines', [-1,-1],[90, -1], ['lines', 'gaps', 'no']);
    $self->{'widget'}{'cell_size'}       = Wx::ComboBox->new( $self, -1, '3', [-1,-1],[65, -1], [qw/1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 25 30/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'paint_direction'} = Wx::ComboBox->new( $self, -1, 'top_down', [-1,-1],[120, -1], [qw/top_down outside_in inside_out/], &Wx::wxTE_READONLY);

    $self->{'widget'}{'rule_count'}->SetToolTip('Count of subrules that a rule sonsists of with current settings?');
    $self->{'widget'}{'subrule_count'}->SetToolTip('Count of possible rules with current amount of subrules?');
    $self->{'widget'}{'input_size'}->SetToolTip('Size of neighbourhood (how many cells) to compute new cell state from ?');
    $self->{'widget'}{'state_count'}->SetToolTip('How many states a cell can have?');
    $self->{'widget'}{'rule_count'}->SetToolTip('Count of Rules resulting from current settings');
    $self->{'widget'}{'subrule_count'}->SetToolTip('Count of Subrules resulting from current settings');
    $self->{'widget'}{'rule_kind'}->SetToolTip("symmetric = an asymetric rule and its mirror have same result\nsumming = all rules with same sum of input states have same result");
    $self->{'widget'}{'application'}->SetToolTip("Result of a subrule should replace previous value (insert) or be added to it ?");
    $self->{'widget'}{'use_action_rules'}->SetToolTip( "should action rules determine if a (state) rule gets applied this round");
    $self->{'widget'}{'grid_type'}->SetToolTip('How to paint gaps between cell squares');
    $self->{'widget'}{'cell_size'}->SetToolTip('visual size of the cells in pixel');
    $self->{'widget'}{'paint_direction'}->SetToolTip('painting direction');
    $self->{'widget'}{'circular_grid'}->SetToolTip('cells on the edges become neighbours to each other');
    $self->{'widget'}{'fill_cells'}->SetToolTip('fill cell squares with color, or just pain rectangles');

    Wx::Event::EVT_CHECKBOX( $self, $self->{'widget'}{$_}, sub { $self->{'call_back'}->() }) for qw/circular_grid use_action_rules fill_cells/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{'widget'}{$_}, sub { $self->{'call_back'}->() }) for qw/grid_type cell_size paint_direction/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{'widget'}{$_}, sub { $self->compute_subrule_count; $self->{'call_back'}->() }) for qw/state_count input_size rule_kind/;

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;

    my $rule1_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule1_sizer->AddSpacer( 15 );
    $rule1_sizer->Add( $self->{'label'}{'input_size'}, 0, $all_attr, 8);
    $rule1_sizer->Add( $self->{'widget'}{'input_size'}, 0, $row_attr, 8);
    $rule1_sizer->AddSpacer( 21 );
    $rule1_sizer->Add( $self->{'label'}{'state_count'}, 0, $all_attr, 7);
    $rule1_sizer->Add( $self->{'widget'}{'state_count'}, 0, $row_attr, 8);
    $rule1_sizer->AddSpacer( 20 );
    $rule1_sizer->Add( $self->{'widget'}{'circular_grid'}, 0, $row_attr, 8);
    $rule1_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rule2_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule2_sizer->AddSpacer( 15 );
    $rule2_sizer->Add( $self->{'label'}{'rule_kind'}, 0, $all_attr, 7);
    $rule2_sizer->Add( $self->{'widget'}{'rule_kind'}, 0, $row_attr, 8);
    $rule2_sizer->AddSpacer( 15 );
    $rule2_sizer->Add( $self->{'label'}{'rule_count'}, 0, $all_attr, 7);
    $rule2_sizer->Add( $self->{'widget'}{'subrule_count'}, 0, $row_attr, 8);
    $rule2_sizer->Add( $self->{'widget'}{'rule_count'}, 0, $row_attr, 8);
    $rule2_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rule3_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule3_sizer->AddSpacer( 15 );
    $rule3_sizer->Add( $self->{'label'}{'application'}, 0, $all_attr, 7);
    $rule3_sizer->Add( $self->{'widget'}{'application'}, 0, $row_attr, 8);
    $rule3_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $action_sizer->AddSpacer( 15 );
    $action_sizer->Add( $self->{'widget'}{'use_action_rules'}, 0, $all_attr, 7);
    $action_sizer->AddSpacer( 15 );
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
    $visual2_sizer->AddSpacer( 55 );
    $visual2_sizer->Add( $self->{'widget'}{'fill_cells'}, 0, $all_attr, 7);
    $visual2_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $row_space = 10;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $self->{'label'}{'logicals'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $rule1_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $rule2_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $rule3_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, $row_space );
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $self->{'label'}{'actions'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $action_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, $row_space );
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $self->{'label'}{'visuals'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $visual2_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $visual1_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub init        {
    $_[0]->set_settings({
        input_size => 3, state_count => 2, circular_grid => 0,
        rule_kind => 'all', subrule_count => 8, rule_count => 256,
        application => 'insert',
        use_action_rules => 0,
        grid_type => 'lines', cell_size => 3, paint_direction => 'top_down',
        fill_cells => 1,
    });
}
sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub get_settings {
    my ($self) = @_;
    my $settings = { map { $_ => $self->{'widget'}{$_}->GetValue } keys %{$self->{'widget'}} };
}
sub get_state   { $_[0]->get_settings() }
sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH';
    my $change = 0;
    for my $key (keys %{$self->{'widget'}}) {
        next if $settings->{$key} eq $self->{'widget'}{$key}->GetValue;
        $self->{'widget'}{$key}->SetValue( $settings->{$key} );
        $change++;
    }
    $self->compute_subrule_count if $change;
}

sub compute_subrule_count {
    my ($self) = @_;
    $self->{'subrules'}->renew(
        $self->{'widget'}{'input_size'}->GetValue,
        $self->{'widget'}{'state_count'}->GetValue,
        $self->{'widget'}{'rule_kind'}->GetValue
    );
    $self->{'widget'}{'subrule_count'}->SetValue( $self->{'subrules'}->independent_count );
    $self->{'widget'}{'rule_count'}->SetValue( $self->{'subrules'}->state_count ** $self->{'subrules'}->independent_count );
}

sub create_label {
    my ($self, $id, $text, $help) = @_;
    return unless defined $text and $text and not exists $self->{'label'}{ $id };
    $self->{'label'}{ $id } = Wx::StaticText->new( $self, -1, $text );
    $self->{'label'}{ $id }->SetToolTip( $help ) if defined $help and $help;
    $self->{'label'}{ $id }
}

1;
