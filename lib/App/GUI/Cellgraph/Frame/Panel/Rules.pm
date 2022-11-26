use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Rules;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::RuleGenerator;
use App::GUI::Cellgraph::Widget::Rule;
use App::GUI::Cellgraph::Widget::Action;
use App::GUI::Cellgraph::Widget::ColorToggle;
use Graphics::Toolkit::Color;

sub new {
    my ( $class, $parent, $state, $act_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1);
   
    my $rule_cell_size = 20;
    $self->{'rule_size'} = 3;
    $self->{'alphabet_size'} = 2;
    my $colors = [[255,255,255], [0,0,0]];
    
    $self->{'rules'} = App::GUI::Cellgraph::RuleGenerator->new( $self->{'rule_size'}, $self->{'alphabet_size'} );
    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'call_back'} = sub {};

    $self->{'rule_nr'}   = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [ 50, -1], &Wx::wxTE_PROCESS_ENTER );
    
    $self->{'btn'}{'prev'}   = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'btn'}{'next'}   = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'btn'}{'sh_l'}   = Wx::Button->new( $self, -1, '<<', [-1,-1], [35,25] );
    $self->{'btn'}{'sh_r'}   = Wx::Button->new( $self, -1, '>>', [-1,-1], [35,25] );
    $self->{'btn'}{'sym'}    = Wx::Button->new( $self, -1, '<>', [-1,-1], [35,25] );
    $self->{'btn'}{'inv'}    = Wx::Button->new( $self, -1, '!',  [-1,-1], [30,25] );
    $self->{'btn'}{'opp'}    = Wx::Button->new( $self, -1, '%',  [-1,-1], [30,25] );
    $self->{'btn'}{'rnd'}    = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );

    $self->{'btn'}{'sym'}->SetToolTip('choose symmetric rule (every rule swaps result with symmetric partner)');
    $self->{'btn'}{'inv'}->SetToolTip('choose inverted rule (every rule that produces white, goes black and vice versa)');
    $self->{'btn'}{'opp'}->SetToolTip('choose opposite rule');
    $self->{'btn'}{'rnd'}->SetToolTip('choose random rule');
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;

    my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule_sizer->AddSpacer( 20 );
    $rule_sizer->Add( Wx::StaticText->new( $self, -1, 'Rule :' ), 0, $all_attr, 10 );        
    $rule_sizer->AddSpacer( 15 );
    $rule_sizer->Add( $self->{'btn'}{'sh_l'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'prev'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'rule_nr'},     0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'next'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'sh_r'}, 0, $all_attr, 5 );
    $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rf_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rf_sizer->AddSpacer( 125 );
    $rf_sizer->Add( $self->{'btn'}{'inv'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'sym'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'opp'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'rnd'}, 0, $all_attr, 5 );
    $rf_sizer->AddSpacer(20);
    $rf_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $plate_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    for my $rule_index (@{$self->{'rules'}{'input_nr'}}){
        my $in_img = App::GUI::Cellgraph::Widget::Rule->new( $self->{'rule_plate'}, $rule_cell_size, 
                                                             $self->{'rules'}{'in_list'}[$rule_index], [$colors->[1]] );
        $in_img->SetToolTip('input pattern of partial rule Nr.'.($rule_index+1));
                                                             
        $self->{'result'}[$rule_index] = App::GUI::Cellgraph::Widget::ColorToggle->new( 
                                                             $self->{'rule_plate'}, $rule_cell_size, $rule_cell_size, $colors, 0);
                                                             
        $self->{'result'}[$rule_index]->SetCallBack( sub { 
                $self->{'rule_nr'}->SetValue( $self->get_rule_number ); $self->{'call_back'}->() 
        });
        $self->{'result'}[$rule_index]->SetToolTip('result of partial rule Nr.'.($rule_index+1));

        my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        $row_sizer->AddSpacer(30);
        $row_sizer->Add( $in_img, 0, &Wx::wxGROW);
        $row_sizer->AddSpacer(15);
        $row_sizer->Add( Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' ), 0, &Wx::wxGROW | &Wx::wxLEFT );        
        $row_sizer->AddSpacer(15);
        $row_sizer->Add( $self->{'result'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
        $row_sizer->AddSpacer(40);
        $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
        $plate_sizer->AddSpacer(15);
        $plate_sizer->Add( $row_sizer, 0, $std_attr, 10);
    }
    $self->{'rule_plate'}->SetSizer( $plate_sizer );
    
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $rule_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $rf_sizer, 0, $std_attr, 20);
    #$main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL|&Wx::wxRIGHT, 20 );

    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    
    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'rule_nr'}, sub { $self->set_data( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'rule_nr'}, sub { $self->set_data( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'prev'}, sub { $self->prev_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'next'}, sub { $self->next_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sh_l'}, sub { $self->shift_rule_left; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sh_r'}, sub { $self->shift_rule_right; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sym'},  sub { $self->symmetric_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'inv'},  sub { $self->invert_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'opp'},  sub { $self->opposite_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'rnd'},  sub { $self->random_rule; $self->{'call_back'}->() } );

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'rule_nr'}, sub {
        my ($self, $cmd) = @_;
        my $new_value = $cmd->GetString;
        my $old_value = $self->{'rules'}->nr_from_list( $self->get_list );
        return if $new_value == $old_value;
        $self->set_rule( $new_value );
        $self->{'call_back'}->();
        
    });

    $self->init();
    $self;
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub get_list {
    my ($self) = @_;
    map { $self->{'result'}[$_]->GetValue } @{$self->{'rules'}{'input_nr'}};
}
sub get_rule_number { $_[0]->{'rules'}->nr_from_list( $_[0]->get_list ) }

sub set_rule {
    my ($self) = shift;
    my ($rule, @list);
    if (@_ == 1) {
        $rule = shift;
        @list = $self->{'rules'}->list_from_nr( $rule );
    } else {
        @list = @_;
        $rule = $self->{'rules'}->nr_from_list( @list );
    }
    $self->{'result'}[$_]->SetValue( $list[$_] ) for 0 .. $#list;
    $self->{'rule_nr'}->SetValue( $rule );
}

sub init { $_[0]->set_data( { nr => 18, size => 3, action => 22222222 } ) }

sub get_data {
    my ($self) = @_;
    {
        f => [$self->get_list],
        nr => $self->{'rule_nr'}->GetValue,
        size => 3,
    }
}    

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'nr'};
    $self->set_rule( $data->{'nr'} );
}    

sub prev_rule      { $_[0]->set_rule( $_[0]->{'rules'}->prev_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub next_rule      { $_[0]->set_rule( $_[0]->{'rules'}->next_nr( $_[0]->{'rule_nr'}->GetValue ) ) }

sub shift_rule_left  { $_[0]->set_rule( $_[0]->{'rules'}->shift_nr_left( $_[0]->{'rule_nr'}->GetValue ) ) }
sub shift_rule_right { $_[0]->set_rule( $_[0]->{'rules'}->shift_nr_right( $_[0]->{'rule_nr'}->GetValue ) ) }

sub opposite_rule  { $_[0]->set_rule( $_[0]->{'rules'}->opposite_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub symmetric_rule { $_[0]->set_rule( $_[0]->{'rules'}->symmetric_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub invert_rule    { $_[0]->set_rule( $_[0]->{'rules'}->inverted_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub random_rule    { $_[0]->set_rule( $_[0]->{'rules'}->random_nr ) }

sub get_action_number { join '', reverse $_[0]->get_action_list }
sub get_action_list {
    my ($self) = @_;
    map { $self->{'action'}[$_]->GetValue } @{$self->{'rules'}{'input_nr'}};
}


sub generate_rules {
    
}

1;
