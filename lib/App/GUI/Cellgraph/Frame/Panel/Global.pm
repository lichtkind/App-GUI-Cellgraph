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
    
    my $colors = [[255,255,255], [0,0,0]];
    
    #$self->{'repeat_start'} = Wx::CheckBox->new( $self, -1, '  Repeat');
    #$self->{'btn'}{'prev'}  = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'grid_lbl'} = Wx::StaticText->new( $self, -1, 'Grid :');
    #$self->{'rule_size_lbl'} = Wx::StaticText->new( $self, -1, 'Size :');
    #$self->{'rule_type_lbl'} = Wx::StaticText->new( $self, -1, 'Rules :');
    $self->{'cell_size_lbl'} = Wx::StaticText->new( $self, -1, 'Size :');
    $self->{'grid'}      = Wx::ComboBox->new( $self, -1, 'lines', [-1,-1],[95, -1], ['lines', 'gaps', 'no']);
    #$self->{'rule_size'} = Wx::ComboBox->new( $self, -1, 3,        [-1,-1],[65, -1], [2, 3, 4, 5], &Wx::wxTE_READONLY);
    #$self->{'rule_type'} = Wx::ComboBox->new( $self, -1, 'pattern', [-1,-1],[110, -1], [qw/pattern average median/], &Wx::wxTE_READONLY);
    $self->{'cell_size'} = Wx::ComboBox->new( $self, -1, '3', [-1,-1],[75, -1], [qw/1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 25 30/], &Wx::wxTE_READONLY);
    $self->{'call_back'} = sub {};
    
    #$self->{'rule_type'}->SetToolTip('set rule type');
    
    #Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'prev'}, sub { $self->prev_start;  $self->{'call_back'}->() }) ;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_}, sub { $self->{'call_back'}->() }) for qw/grid cell_size /;# rule_size rule_type
    #Wx::Event::EVT_CHECKBOX( $self, $self->{$_}, sub { $self->{'call_back'}->() }) for qw/repeat_start/;
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;

    my $grid_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $grid_sizer->AddSpacer( 23 );
    $grid_sizer->Add( $self->{'grid_lbl'}, 0, $all_attr, 7);
    $grid_sizer->Add( $self->{'grid'}, 0, $row_attr, 8);
    $grid_sizer->AddSpacer( 31 );
    $grid_sizer->Add( $self->{'cell_size_lbl'}, 0, $all_attr, 7);
    $grid_sizer->AddSpacer( 3 );
    $grid_sizer->Add( $self->{'cell_size'}, 0, $row_attr, 8);
    $grid_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

   
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 20 );
    $main_sizer->Add( $grid_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 25 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, 20 );
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub init        { $_[0]->set_data({ grid_type => 'lines', cell_size => 3 }) }

sub get_data {
    my ($self) = @_;
    {
        cell_size => $self->{'cell_size'}->GetValue,
        grid_type => $self->{'grid'}->GetValue,
    }
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    $self->{'grid'}->SetValue( $data->{'grid_type'} );
    $self->{'cell_size'}->SetValue( $data->{'cell_size'} );
}


sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

1;
