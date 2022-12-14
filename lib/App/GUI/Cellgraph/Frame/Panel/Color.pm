use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Color;
use base qw/Wx::Panel/;

use App::GUI::Cellgraph::Frame::Part::ColorBrowser;
use App::GUI::Cellgraph::Frame::Part::ColorPicker;
use App::GUI::Cellgraph::Widget::ColorDisplay;

use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $state, $act_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'call_back'}  = sub {};
    $self->{'rule_square_size'} = 20;
    $self->{'state_count'} = 2;
    $self->{'current_state'} = 1;

    $self->{'state_colors'} = [ color('white')->gradient_to('black', $self->{'state_count'}) ];
    $self->{'state_selector'}[0] = Wx::RadioButton->new($self, -1, '  0', [-1,-1], [-1,-1], &Wx::wxRB_GROUP);
    $self->{'state_selector'}[$_] = Wx::RadioButton->new($self, -1, '  '.$_, [-1,-1], [-1,-1], 0, ) for 1 .. $self->{'state_count'} - 1;
    $self->{'state_selector'}[1]->SetValue(1);
    $self->{'state_pic'}[$_] = App::GUI::Cellgraph::Widget::ColorDisplay->new($self, 25, 25, $self->{'state_colors'}[$_]->rgb_hash) for 0 .. $self->{'state_count'} - 1;
    $self->{'state_col_lbl'}  = Wx::StaticText->new($self, -1, 'State Colors' );
    $self->{'curr_col_lbl'}  = Wx::StaticText->new($self, -1, 'Selected State Color' );

    $self->{'picker'}  = App::GUI::Cellgraph::Frame::Part::ColorPicker->new( $self, $self->GetParent->GetParent, 'Color Store:' );
    $self->{'browser'}  = App::GUI::Cellgraph::Frame::Part::ColorBrowser->new( $self, 'state', {red => 0, green => 0, blue => 0} );
    $self->{'browser'}->SetCallBack( sub { $self->set_current_color( $_[0] ) });

    Wx::Event::EVT_RADIOBUTTON( $self->{'state_selector'}[$_], $self->{'state_selector'}[$_], sub {
        $self->{'current_state'} = $_[0]->GetLabel+0;
        $self->{'browser'}->set_data( $self->{'state_colors'}[$self->{'current_state'}]->rgb_hash );
    }) for 0 .. $self->{'state_count'} - 1;

    #$self->{'btn'}{'sym'}->SetToolTip('choose symmetric rule (every partial rule swaps result with symmetric partner)');

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW ;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL;

    my $state_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $state_sizer->AddSpacer( 20 );
    my @option_sizer;
    for my $state (0 .. $self->{'state_count'} - 1){
        $option_sizer[$state] = Wx::BoxSizer->new( &Wx::wxVERTICAL );
        $option_sizer[$state]->AddSpacer( 2 );
        $option_sizer[$state]->Add( $self->{'state_pic'}[$state], 0, $all_attr, 5);
        $option_sizer[$state]->Add( $self->{'state_selector'}[$state], 0, $all_attr, 5);
        $state_sizer->Add( $option_sizer[$state], 0, $all_attr, 5);
    }
    $state_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'state_col_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->Add( $state_sizer, 1, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'curr_col_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->Add( $self->{'browser'}, 1, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'picker'}, 1, $std_attr, 0);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    #$main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );

    $self->SetSizer( $main_sizer );
    #$self->init;
    $self;
}

sub regenerate_color_picker {
    my ($self, $data) = @_;
    #~ return if ref $data eq 'HASH' and $self->{'state_count'} == $data->{'global'}{'state_count'}
                                  #~ and $self->{'input_size'} == $data->{'global'}{'input_size'};
    #~ $self->{'state_count'} = $data->{'global'}{'state_count'} if ref $data eq 'HASH';
    #~ $self->{'input_size'} = $data->{'global'}{'input_size'} if ref $data eq 'HASH';
    #~ $self->{'state_colors'} = [map {[$_->rgb]} color('white')->gradient_to('black', $self->{'state_count'})];
    #~ my @input_colors = map {[map { $self->{'state_colors'}[$_] } @$_ ]} @{$self->{'rules'}{'input_list'}};

    #~ my $refresh = 0;
    #~ if (exists $self->{'rule_img'}){
        #~ $self->{'plate_sizer'}->Clear(1);
        #~ $self->{'rule_img'} = [];
        #~ $self->{'arrow'} = [];
        #~ $self->{'rule_result'} = [];
        #~ # map { $_->Destroy} @{$self->{'rule_img'}}, @{$self->{'rule_result'}}, @{$self->{'arrow'}};
        #~ $refresh = 1;
    #~ } else {
        #~ $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
        #~ $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );
    #~ }
    #~ my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    #~ for my $rule_index ($self->{'rules'}->part_rule_iterator){
        #~ $self->{'rule_img'}[$rule_index] = App::GUI::Cellgraph::Widget::RuleInput->new(
                                           #~ $self->{'rule_plate'}, $self->{'rule_square_size'}, $input_colors[$rule_index] );
        #~ $self->{'rule_img'}[$rule_index]->SetToolTip('input pattern of partial rule Nr.'.($rule_index+1));

        #~ $self->{'rule_result'}[$rule_index] = App::GUI::Cellgraph::Widget::ColorToggle->new(
                                         #~ $self->{'rule_plate'}, $self->{'rule_square_size'}, $self->{'rule_square_size'},
                                         #~ $self->{'state_colors'}, 0 );
        #~ $self->{'rule_result'}[$rule_index]->SetCallBack( sub {
                #~ $self->{'rule_nr'}->SetValue( $self->get_rule_number ); $self->{'call_back'}->()
        #~ });
        #~ $self->{'rule_result'}[$rule_index]->SetToolTip('result of partial rule '.($rule_index+1));

        #~ $self->{'arrow'}[$rule_index] = Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' );
    #~ }
    #~ for my $rule_index ($self->{'rules'}->part_rule_iterator){
        #~ my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        #~ $row_sizer->AddSpacer(30);
        #~ $row_sizer->Add( $self->{'rule_img'}[$rule_index], 0, &Wx::wxGROW);
        #~ $row_sizer->AddSpacer(15);
        #~ $row_sizer->Add( $self->{'arrow'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
        #~ $row_sizer->AddSpacer(15);
        #~ $row_sizer->Add( $self->{'rule_result'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
        #~ $row_sizer->AddSpacer(40);
        #~ $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
        #~ $self->{'plate_sizer'}->AddSpacer(15);
        #~ $self->{'plate_sizer'}->Add( $row_sizer, 0, $std_attr, 10); # ->Insert(4,
    #~ }
    #~ $self->Layout if $refresh;
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
}

sub update_settings {

}

1;
