use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Color;
use base qw/Wx::Panel/;

use App::GUI::Cellgraph::Frame::Part::ColorBrowser;
use App::GUI::Cellgraph::Frame::Part::ColorPicker;
use App::GUI::Cellgraph::Frame::Part::ColorSetPicker;
use App::GUI::Cellgraph::Widget::ColorDisplay;

use Graphics::Toolkit::Color qw/color/;

our $default_color_def = $App::GUI::Cellgraph::Frame::Part::ColorSetPicker::default_color;

sub new {
    my ( $class, $parent, $config ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'call_back'}  = sub {};
    $self->{'config'}     = $config;
    $self->{'rule_square_size'} = 20;
    $self->{'state_count'} = 2;
    $self->{'current_state'} = 1;

    $self->{'state_colors'}       = [ color('white')->gradient_to('black', $self->{'state_count'}) ];
    $self->{'state_colors'}[$_]   = color( $default_color_def ) for $self->{'state_count'} .. 8;
    $self->{'state_selector'}[0]  = Wx::RadioButton->new($self, -1, '0', [-1,-1], [-1,-1], &Wx::wxRB_GROUP);
    $self->{'state_selector'}[$_] = Wx::RadioButton->new($self, -1, ' '.$_, [-1,-1], [-1,-1], 0, ) for 1 .. 8;
    $self->{'state_selector'}[1]->SetValue(1);
    $self->{'state_pic'}[$_]      = App::GUI::Cellgraph::Widget::ColorDisplay->new($self, 20, 25, $_, $self->{'state_colors'}[$_]->rgb_hash) for 0 .. 8;
    $self->{'color_set_store_lbl'} = Wx::StaticText->new($self, -1, 'Color Set Store' );
    $self->{'color_set_f_lbl'}   = Wx::StaticText->new($self, -1, 'Colors Set Function' );
    $self->{'state_color_lbl'}   = Wx::StaticText->new($self, -1, 'Currently Used State Colors' );
    $self->{'curr_color_lbl'}    = Wx::StaticText->new($self, -1, 'Selected State Color' );
    $self->{'color_store_lbl'}   = Wx::StaticText->new($self, -1, 'Color Store' );

    $self->{'dynamics'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[75, -1], [ 0.33, 0.5, 0.66, 0.83, 1, 1.2, 1.5, 2, 3 ]);
    $self->{'Sdelta'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [50,-1], &Wx::wxTE_RIGHT);
    $self->{'Ldelta'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [50,-1], &Wx::wxTE_RIGHT);


    $self->{'btn'}{'gray'}       = Wx::Button->new( $self, -1, 'Gray',       [-1,-1], [45, 35] );
    $self->{'btn'}{'gradient'}   = Wx::Button->new( $self, -1, 'Gradient',   [-1,-1], [70, 35] );
    $self->{'btn'}{'complement'} = Wx::Button->new( $self, -1, 'Complement', [-1,-1], [90, 35] );
    $self->{'btn'}{'gray'}->SetToolTip("reset to default grey scale color pallet");
    $self->{'btn'}{'gradient'}->SetToolTip("create gradient between first and current color");
    $self->{'btn'}{'complement'}->SetToolTip("set from first up to current color as complementary colors");
    $self->{'dynamics'}->SetToolTip("dynamics of gradient (1 = linear) and also of gray scale");
    $self->{'Sdelta'}->SetToolTip("max. satuaration deviation when computing complement colors ( -100 .. 100)");
    $self->{'Ldelta'}->SetToolTip("max. lightness deviation when computing complement colors ( -100 .. 100)");


    $self->{'picker'}  = App::GUI::Cellgraph::Frame::Part::ColorPicker->new( $self, $config->get_value('color') );
    $self->{'setpicker'}  = App::GUI::Cellgraph::Frame::Part::ColorSetPicker->new( $self, $config->get_value('color_set'));
    $self->{'browser'}  = App::GUI::Cellgraph::Frame::Part::ColorBrowser->new( $self, 'state', {red => 0, green => 0, blue => 0} );
    $self->{'browser'}->SetCallBack( sub { $self->set_current_color( $_[0] ) });

    Wx::Event::EVT_RADIOBUTTON( $self->{'state_selector'}[$_], $self->{'state_selector'}[$_], sub {
        $self->select_state( $_[0]->GetLabel+0 );
    }) for 0 .. $self->{'state_count'} - 1;

    Wx::Event::EVT_LEFT_DOWN( $self->{'state_pic'}[$_], sub { $self->select_state( $_[0]->get_nr ) }) for 0 .. 8;

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'gray'}, sub {
        $self->{'state_colors'} = [ color('white')->gradient_to('black', $self->{'state_count'}) ];
        $self->{'state_colors'}[$_] = color( $default_color_def ) for $self->{'state_count'} .. 8;
        $self->{'state_pic'}[$_]->set_color( $self->{'state_colors'}[$_]->rgb_hash ) for 0 .. 8;
        $self->select_state();
    });

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW ;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL;

    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->AddSpacer( 10 );
    $f_sizer->Add( $self->{'btn'}{'gray'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'btn'}{'gradient'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'dynamics'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'btn'}{'complement'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'Sdelta'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'Ldelta'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $state_sizer = $self->{'state_sizer'} = Wx::BoxSizer->new(&Wx::wxHORIZONTAL); # $self->{'plate_sizer'}->Clear(1);
    $state_sizer->AddSpacer( 7 );
    my @option_sizer;
    for my $state (0 .. 8){
        $option_sizer[$state] = Wx::BoxSizer->new( &Wx::wxVERTICAL );
        $option_sizer[$state]->AddSpacer( 2 );
        $option_sizer[$state]->Add( $self->{'state_pic'}[$state], 0, $all_attr, 3);
        $option_sizer[$state]->Add( $self->{'state_selector'}[$state], 0, $all_attr, 3);
        $state_sizer->Add( $option_sizer[$state], 0, $all_attr, 5);
    }
    $state_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'color_set_store_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $self->{'setpicker'}, 0, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'color_set_f_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $f_sizer, 0, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'state_color_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->Add( $state_sizer, 0, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'curr_color_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $self->{'browser'}, 0, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'color_store_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->Add( $self->{'picker'}, 0, $std_attr, 0);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->SetSizer( $main_sizer );
    #$self->init;
    $self->select_state;
    $self;
}

sub regenerate_states {
    my ($self, $count) = @_;

}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub init { $_[0]->set_data( { value => ['FFFFFF', '000000'], dynamics => 1, delta_S => 0, delta_L => 0 } ) }

sub get_data {
    my ($self) = @_;
    {
        value => [],
        dynamics => 1,
        delta_S => 0,
        delta_L => 0
    }
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'nr'};
    #$self->set_rule( $data->{'nr'} );
}

sub get_current_color {
    my ($self) = @_;
    $self->{'state_colors'}[$self->{'current_state'}];
}

sub set_current_color {
    my ($self, $color) = @_;
    return unless ref $color eq 'HASH';
    $self->{'state_colors'}[$self->{'current_state'}] = color( $color );
    $self->{'state_pic'}[$self->{'current_state'}]->set_color( $color );
    $self->{'browser'}->set_data( $color );
}

sub set_all_colors {
    my ($self, @color) = @_;
    return unless @color == 9;
    map { return if ref $_ ne 'Graphics::Toolkit::Color' } @color;
    @{$self->{'state_colors'}} = @color;
    $self->{'state_colors'}[$_] = color( $default_color_def ) for $self->{'state_count'} .. 8;
    $self->{'state_pic'}[$_]->set_color( $self->{'state_colors'}[$_]->rgb_hash ) for 0 .. 8;
    $self->select_state;
}

sub select_state {
    my ($self, $state) = @_;
    $state //= $self->{'current_state'};
    $self->{'current_state'} = $state > $self->{'state_count'} - 1 ? $self->{'state_count'} - 1 : $state;
    $self->{'state_selector'}[$self->{'current_state'}]->SetValue(1);
    $self->{'browser'}->set_data( $self->{'state_colors'}[$self->{'current_state'}]->rgb_hash );
}

sub update_settings {

}

sub update_config {
    my ($self) = @_;
    $self->{'config'}->set_value('color',     $self->{'picker'}->get_config);
    $self->{'config'}->set_value('color_set', $self->{'setpicker'}->get_config);
}



1;
