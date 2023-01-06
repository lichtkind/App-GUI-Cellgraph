use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Color;
use base qw/Wx::Panel/;

use App::GUI::Cellgraph::Frame::Part::ColorBrowser;
use App::GUI::Cellgraph::Frame::Part::ColorPicker;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $state, $act_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'call_back'}  = sub {};
    $self->{'rule_square_size'} = 20;
    $self->{'state_count'} = 2;

    $self->{'browser'}  = App::GUI::Cellgraph::Frame::Part::ColorBrowser->new( $self, 'state', {red => 0, green => 0, blue => 0} );
    $self->{'picker'}  = App::GUI::Cellgraph::Frame::Part::ColorPicker->new( $self, $self->GetParent->GetParent, 'Color Store:', );


    #$self->{'btn'}{'sym'}->SetToolTip('choose symmetric rule (every partial rule swaps result with symmetric partner)');

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;

    #~ my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    #~ $rule_sizer->AddSpacer( 20 );
    #~ $rule_sizer->Add( Wx::StaticText->new( $self, -1, 'Rule :' ), 0, $all_attr, 10 );
    #~ $rule_sizer->AddSpacer( 15 );
    #~ $rule_sizer->Add( $self->{'btn'}{'sh_l'}, 0, $all_attr, 5 );
    #~ $rule_sizer->Add( $self->{'btn'}{'prev'}, 0, $all_attr, 5 );
    #~ $rule_sizer->Add( $self->{'rule_nr'},     0, $all_attr, 5 );
    #~ $rule_sizer->Add( $self->{'btn'}{'next'}, 0, $all_attr, 5 );
    #~ $rule_sizer->Add( $self->{'btn'}{'sh_r'}, 0, $all_attr, 5 );
    #~ $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);


    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add(  $self->{'browser'}, 1, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add(  $self->{'picker'}, 1, $std_attr, 0);
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

sub update_settings {

}

1;
