use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Global;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::Rule;
use App::GUI::Cellgraph::Widget::ColorToggle;
use App::GUI::Cellgraph::Widget::SliderCombo;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1);
    
    
    $self->{'grid_lbl'} = Wx::StaticText->new( $self, -1, 'Grid :');
    $self->{'state_ab_lbl'} = Wx::StaticText->new( $self, -1, 'Cell State Count :');
    $self->{'action_ab_lbl'} = Wx::StaticText->new( $self, -1, 'Action Values :');
    $self->{'threshhold_lbl'} = Wx::StaticText->new( $self, -1, 'Threshold :');
    $self->{'cell_size_lbl'} = Wx::StaticText->new( $self, -1, 'Size :');
    $self->{'data_keys'} = [qw/grid_type cell_size state_count action_values action_threshold/];
    $self->{'grid_type'} = Wx::ComboBox->new( $self, -1, 'lines', [-1,-1],[95, -1], ['lines', 'gaps', 'no']);
    $self->{'cell_size'} = Wx::ComboBox->new( $self, -1, '3', [-1,-1],[75, -1], [qw/1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 25 30/], &Wx::wxTE_READONLY);
    $self->{'state_count'} = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[75, -1], [qw/2 3 4 5 6 7 8 9/], &Wx::wxTE_READONLY);
    $self->{'action_values'} = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[75, -1], [qw/2 3 4 5 6 7 8 9/], &Wx::wxTE_READONLY);
    $self->{'action_threshold'} = Wx::ComboBox->new( $self, -1, '1', [-1,-1],[75, -1], [qw/0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2/], &Wx::wxTE_READONLY);
    $self->{'call_back'} = sub {};
    
    $self->{'grid_type'}->SetToolTip('how to display the cell map');
    $self->{'cell_size'}->SetToolTip('visual size of the cells');
    $self->{'state_count'}->SetToolTip('how many states a cell can have?');
    $self->{'action_values'}->SetToolTip('how many action values between 0 and 1 a cell can emit to itself and neighbours?');
    $self->{'action_threshold'}->SetToolTip('when action value of a cell is equal or higher the cell will be active?');
    
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_}, sub { $self->{'call_back'}->() }) for @{$self->{'data_keys'}};
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;

    my $grid_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $grid_sizer->AddSpacer( 23 );
    $grid_sizer->Add( $self->{'grid_lbl'}, 0, $all_attr, 7);
    $grid_sizer->Add( $self->{'grid_type'}, 0, $row_attr, 8);
    $grid_sizer->AddSpacer( 31 );
    $grid_sizer->Add( $self->{'cell_size_lbl'}, 0, $all_attr, 7);
    $grid_sizer->AddSpacer( 3 );
    $grid_sizer->Add( $self->{'cell_size'}, 0, $row_attr, 8);
    $grid_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $state_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $state_sizer->AddSpacer( 23 );
    $state_sizer->Add( $self->{'state_ab_lbl'}, 0, $all_attr, 7);
    $state_sizer->Add( $self->{'state_count'}, 0, $row_attr, 8);
    $state_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $action_sizer->AddSpacer( 23 );
    $action_sizer->Add( $self->{'action_ab_lbl'}, 0, $all_attr, 7);
    $action_sizer->Add( $self->{'action_values'}, 0, $row_attr, 8);
    $action_sizer->AddSpacer( 18 );
    $action_sizer->Add( $self->{'threshhold_lbl'}, 0, $all_attr, 7);
    $action_sizer->Add( $self->{'action_threshold'}, 0, $row_attr, 8);
    $action_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
   
    my $row_spce = 25;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( $row_spce );
    $main_sizer->Add( $grid_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_spce );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, $row_spce );
    $main_sizer->AddSpacer( $row_spce );
    $main_sizer->Add( $state_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_spce );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, $row_spce );
    $main_sizer->AddSpacer( $row_spce );
    $main_sizer->Add( $action_sizer, 0, $std_attr, 0);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub init        { $_[0]->set_data({ grid_type => 'lines', cell_size => 3,
                                    state_count => 2, action_values => 2, action_threshold => 1 }) }

sub get_data {
    my ($self) = @_;
    my $data = { map { $_ => $self->{$_}->GetValue } @{$self->{'data_keys'}} };
    $data;
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    $self->{$_}->SetValue( $data->{$_} ) for @{$self->{'data_keys'}};
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}


1;
