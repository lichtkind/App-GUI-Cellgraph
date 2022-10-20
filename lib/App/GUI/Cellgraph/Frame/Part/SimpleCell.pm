use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Part::SimpleCell;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::Rule;
use App::GUI::Cellgraph::Widget::ColorToggle;

sub new {
    my ( $class, $parent, $state, $act_state ) = @_;
    # my $x = 10;
    # my $y = 10;
    my $self = $class->SUPER::new( $parent, -1);
    
    my $colors = [[255,255,255], [0,0,0]];
    my $rule_cell_size = 20;
    my @rule_in = ([0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 1, 1], [1, 0, 0], [1, 0, 1], [1, 1, 0], [1, 1, 1], );
    $self->{'rule'} = \@rule_in;
    $self->{'rule_img'} = [ map { App::GUI::Cellgraph::Widget::Rule->new( $self, $rule_cell_size, $_, [$colors->[1]])} @rule_in];
    $self->{'switch'}   = [ map { App::GUI::Cellgraph::Widget::ColorToggle->new( $self, $rule_cell_size, $rule_cell_size, $colors, 0) } 1 .. int @rule_in];
    $self->{'rule_nr'}  = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [ 42, -1], &Wx::wxTE_READONLY );
    $self->{'start'}  = Wx::TextCtrl->new( $self, -1, 1, [-1,-1], [ 142, -1],  );
    $self->{'start'}->SetToolTip('content of start row');
    $_->SetCallBack( sub { $self->{'rule_nr'}->SetValue( $self->get_number ); }) for @{$self->{'switch'}};
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 5);

    my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule_sizer->AddSpacer(30);
    $rule_sizer->Add( Wx::StaticText->new( $self, -1, 'Rule: ' ), 0, &Wx::wxGROW | &Wx::wxALL, 10 );        
    $rule_sizer->AddSpacer(20);
    $rule_sizer->Add( $self->{'rule_nr'}, 0, &Wx::wxGROW | &Wx::wxLEFT | &Wx::wxALIGN_CENTER_HORIZONTAL, 10 );
    $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $main_sizer->Add( $rule_sizer, 0, $std_attr, 20);

    for my $rule_index (1 .. @{$self->{'rule_img'}}){
        my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        $row_sizer->AddSpacer(30);
        $row_sizer->Add( $self->{'rule_img'}[$rule_index-1], 0, &Wx::wxGROW);
        $row_sizer->AddSpacer(15);
        $row_sizer->Add( Wx::StaticText->new( $self, -1, ' => ' ), 0, &Wx::wxGROW | &Wx::wxLEFT );        
        $row_sizer->AddSpacer(15);
        $row_sizer->Add( $self->{'switch'}[$rule_index-1], 0, &Wx::wxGROW | &Wx::wxLEFT );
        $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
        $main_sizer->AddSpacer(30);
        $main_sizer->Add( $row_sizer, 0, $std_attr, 10);
    }
    my $start_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $start_sizer->AddSpacer(30);
    
    $start_sizer->Add( Wx::StaticText->new( $self, -1, 'Start: ' ), 0, &Wx::wxGROW | &Wx::wxALL, 10 );        
    $start_sizer->AddSpacer(15);
    $start_sizer->Add( $self->{'start'}, 0, &Wx::wxGROW);
    $start_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    
    $main_sizer->Add( $start_sizer, 0, &Wx::wxGROW | &Wx::wxTOP, 40);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    $self;
}

sub get_number {
    my ($self) = @_;
    my $number = 0;
    for (reverse $self->get_function){
        $number <<= 1;
        $number++ if $_;
    }
    $number;
}

sub get_function {
    my ($self) = @_;
    map { $self->{'switch'}[$_]->GetValue } 0 .. $#{$self->{'rule'}};
}

sub get_data {
    my ($self) = @_;
    {
        f => [$self->get_function],
        start => [split ',', $self->{'start'}->GetValue],
    };
}    

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $_->SetCallBack( sub { $self->{'rule_nr'}->SetValue( $self->get_number ); $code->() }) for @{$self->{'switch'}};
}

1;
