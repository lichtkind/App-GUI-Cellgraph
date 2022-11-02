use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Rules;
use base qw/Wx::ScrolledWindow/;
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
    $self->{'rule_size'} = int @{$rule_in[0]};
    $self->{'sym'} = [0, 4, 2, 6, 1, 5, 3, 7 ];
    $self->{'opp'} = [7, 6, 5, 4, 3, 2, 1, 0 ];
    $self->{'rule_img'} = [ map { App::GUI::Cellgraph::Widget::Rule->new( $self, $rule_cell_size, $_, [$colors->[1]])} @rule_in];
    $self->{'switch'}   = [ map { App::GUI::Cellgraph::Widget::ColorToggle->new( $self, $rule_cell_size, $rule_cell_size, $colors, 0) } 1 .. int @rule_in];
    $self->{'rule_nr'}  = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [ 42, -1], &Wx::wxTE_PROCESS_ENTER );
    $self->{'call_back'} = sub {};
    $_->SetCallBack( sub { $self->{'rule_nr'}->SetValue( $self->get_number );
                           $self->{'call_back'}->() }) for @{$self->{'switch'}};
    
    $self->{'btn'}{'prev'}  = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'btn'}{'next'}  = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'btn'}{'sh_l'}  = Wx::Button->new( $self, -1, '<<', [-1,-1], [35,25] );
    $self->{'btn'}{'sh_r'}  = Wx::Button->new( $self, -1, '>>', [-1,-1], [35,25] );
    $self->{'btn'}{'sym'}   = Wx::Button->new( $self, -1, '<>', [-1,-1], [35,25] );
    $self->{'btn'}{'inv'}   = Wx::Button->new( $self, -1, '!',  [-1,-1], [30,25] );
    $self->{'btn'}{'opp'}   = Wx::Button->new( $self, -1, 'o',  [-1,-1], [30,25] );
    $self->{'btn'}{'rnd'}   = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    $self->{'btn'}{'sym'}->SetToolTip('choose symmetric rule (every rule swaps result with symmetric partner)');
    $self->{'btn'}{'inv'}->SetToolTip('choose inverted rule (every rule that produces white, goes black and vice versa)');
    $self->{'btn'}{'opp'}->SetToolTip('choose opposite rule');
    $self->{'btn'}{'rnd'}->SetToolTip('choose random rule');

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'rule_nr'}, sub { $self->set_data( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'rule_nr'}, sub { $self->set_data( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'prev'}, sub { $self->prev_rule; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'next'}, sub { $self->next_rule; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sh_l'}, sub { $self->shift_rule_left; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sh_r'}, sub { $self->shift_rule_right; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sym'},  sub { $self->symmetric_rule; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'inv'},  sub { $self->invert_rule; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'opp'},  sub { $self->opposite_rule; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'rnd'},  sub { $self->random_rule; $self->{'call_back'}->() }) ;
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 30 );

    my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule_sizer->AddSpacer( 15 );
    $rule_sizer->Add( Wx::StaticText->new( $self, -1, 'Rule : ' ), 0, $all_attr, 10 );        
    $rule_sizer->AddSpacer( 5 );
    $rule_sizer->Add( $self->{'btn'}{'sh_l'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'prev'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'rule_nr'},     0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'next'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'sh_r'}, 0, $all_attr, 5 );
    $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $main_sizer->Add( $rule_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer(20);

    my $rf_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rf_sizer->AddSpacer( 110 );
    $rf_sizer->Add( $self->{'btn'}{'inv'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'sym'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'opp'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'rnd'}, 0, $all_attr, 5 );
    $rf_sizer->AddSpacer(20);
    
    $rf_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $main_sizer->Add( $rf_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer(5);


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
    
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    $self->init();
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

sub init {
    my ($self) = @_;
    $self->set_data( { nr => 18, size => 3 } )
}

sub get_data {
    my ($self) = @_;
    {
        f => [$self->get_function],
        nr => $self->{'rule_nr'}->GetValue,
        size => 3,
    }
}    

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'nr'};
    my $rule = int $data->{'nr'};
    $rule = 255 if $rule > 255;
    $rule =   0 if $rule < 0;
    $self->{'rule_nr'}->SetValue( $rule );
    for my $i ( 0 .. $#{$self->{'rule'}}) {
        $self->{'switch'}[$i]->SetValue($rule & 1);
        $rule >>= 1;
    }
}    

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub prev_rule {
    my ($self) = @_;
    my $rule = $self->{'rule_nr'}->GetValue;
    $rule--;
    $rule = 255 if $rule < 0;
    $self->set_data( $rule );
}

sub next_rule {
    my ($self) = @_;
    my $rule = $self->{'rule_nr'}->GetValue;
    $rule++;    
    $rule =   0 if $rule > 255;
    $self->set_data( $rule );
}

sub invert_rule {
    my ($self) = @_;
    my $rule = 0;
    for my $i (reverse 0 .. $#{$self->{'rule'}}){
        my $v = $self->{'switch'}[$i]->GetValue;
        $v = !$v;
        $self->{'switch'}[$i]->SetValue( $v );
        $rule <<= 1;
        $rule++ if $v;
    }
    $self->{'rule_nr'}->SetValue( $rule );
}

sub symmetric_rule {
    my ($self) = @_;
    my @old_list = $self->get_function;
    my $rule = 0;
    for my $i (reverse 0 .. $#{$self->{'rule'}}){
        my $v = $old_list[ $self->{'sym'}[$i] ];
        $self->{'switch'}[$i]->SetValue( $v );
        $rule <<= 1;
        $rule++ if $v;
    }
    $self->{'rule_nr'}->SetValue( $rule );
}


sub shift_rule_left {
    my ($self) = @_;
    my @old_list = $self->get_function;
    push @old_list, shift @old_list;
    my $rule = 0;
    for my $i (reverse 0 .. $#{$self->{'rule'}}){
        $self->{'switch'}[$i]->SetValue( $old_list[ $i ] );
        $rule <<= 1;
        $rule++ if $old_list[ $i ];
    }
    $self->{'rule_nr'}->SetValue( $rule );
}

sub shift_rule_right {
    my ($self) = @_;
    my @old_list = $self->get_function;
    unshift @old_list, pop @old_list;
    my $rule = 0;
    for my $i (reverse 0 .. $#{$self->{'rule'}}){
        $self->{'switch'}[$i]->SetValue( $old_list[ $i ] );
        $rule <<= 1;
        $rule++ if $old_list[ $i ];
    }
    $self->{'rule_nr'}->SetValue( $rule );
}

sub opposite_rule {
    my ($self) = @_;
    my @old_list = $self->get_function;
    my $rule = 0;
    for my $i (reverse 0 .. $#{$self->{'rule'}}){
        my $v = $old_list[ $self->{'opp'}[$i] ];
        $self->{'switch'}[$i]->SetValue( $v );
        $rule <<= 1;
        $rule++ if $v;
    }
    $self->{'rule_nr'}->SetValue( $rule );
}

sub random_rule {
    my ($self) = @_;
    my $rule = 0;
    for my $i (reverse 0 .. $#{$self->{'rule'}}){
        my $v = int rand 2;
        $self->{'switch'}[$i]->SetValue( $v );
        $rule <<= 1;
        $rule++ if $v;
    }
    $self->{'rule_nr'}->SetValue( $rule );
}

1;
