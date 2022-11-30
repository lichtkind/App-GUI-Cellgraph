use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Mobile;
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
    $self->{'state_count'} = 2;
    $self->generate_rules();
    my $colors = [[255,255,255], [0,0,0]];
    
    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'call_back'} = sub {};

    $self->{'action_nr'} = Wx::TextCtrl->new( $self, -1, 22222222, [-1,-1], [ 85, -1], &Wx::wxTE_PROCESS_ENTER );
    
    $self->{'btn'}{'1'}  = Wx::Button->new( $self, -1, '1',  [-1,-1], [30,25] );
    $self->{'btn'}{'2'}  = Wx::Button->new( $self, -1, '2',  [-1,-1], [30,25] );
    $self->{'btn'}{'!'}  = Wx::Button->new( $self, -1, '!',  [-1,-1], [30,25] );
    $self->{'btn'}{'?'}  = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );

    #$self->{'btn'}{'sym'}->SetToolTip('choose symmetric rule (every rule swaps result with symmetric partner)');
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;

    my $act_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $act_sizer->AddSpacer( 12 );
    $act_sizer->Add( Wx::StaticText->new( $self, -1, 'Active :' ), 0, $all_attr, 10 );        
    $act_sizer->AddSpacer( 15 );
    $act_sizer->Add( $self->{'btn'}{'!'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'1'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'2'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'?'}, 0, $all_attr, 5 );
    $act_sizer->AddSpacer( 15 );
    $act_sizer->Add( $self->{'action_nr'},   0, $all_attr, 5 );
    $act_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $plate_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    for my $rule_index ($self->{'rules'}->input_iterator){
        my $in_img = App::GUI::Cellgraph::Widget::Rule->new( $self->{'rule_plate'}, $rule_cell_size, 
                                                             $self->{'rules'}{'input_list'}[$rule_index], [$colors->[1]] );
        $in_img->SetToolTip('input pattern of partial rule Nr.'.($rule_index+1));
                                                             
        $self->{'action'}[$rule_index] = App::GUI::Cellgraph::Widget::Action->new( $self->{'rule_plate'}, $rule_cell_size, [255, 255, 255] );
        
        $self->{'action'}[$rule_index]->SetCallBack( sub { 
                $self->{'action_nr'}->SetValue( $self->get_action_number ); $self->{'call_back'}->() 
        });
        $self->{'action'}[$rule_index]->SetToolTip('transfer of activity by partial rule Nr.'.($rule_index+1));
        
        my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        $row_sizer->AddSpacer(30);
        $row_sizer->Add( $in_img, 0, &Wx::wxGROW);
        $row_sizer->AddSpacer(15);
        $row_sizer->Add( Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' ), 0, &Wx::wxGROW | &Wx::wxLEFT );        
        $row_sizer->AddSpacer(15);
        $row_sizer->Add( $self->{'action'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
        $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
        $plate_sizer->AddSpacer(15);
        $plate_sizer->Add( $row_sizer, 0, $std_attr, 10);
    }
    $self->{'rule_plate'}->SetSizer( $plate_sizer );
    
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $act_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr | &Wx::wxALL|&Wx::wxRIGHT, 20 );
    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    
    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'action_nr'}, sub { $self->set_data( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'action_nr'}, sub { $self->set_data( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'1'},sub { $self->init_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'2'},sub { $self->grid_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'?'},sub { $self->random_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'!'},sub { $self->invert_action; $self->{'call_back'}->() } );

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'action_nr'}, sub {
        my ($self, $cmd) = @_;
        my $new_value = $cmd->GetString;
        my $old_value = $self->nr_from_action_list( $self->get_action_list );
        return if $new_value == $old_value;
        $self->set_action( $new_value );
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

sub init { $_[0]->set_data( { nr => 22222222 } ) }

sub get_data {
    my ($self) = @_;
    {
        nr => $self->{'action_nr'}->GetValue,
        f => [$self->get_action_list],
    }
}    

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'nr'};
    $self->set_action( $data->{'nr'} );
}    

sub get_action_number { join '', reverse $_[0]->get_action_list }
sub get_action_list {
    my ($self) = @_;
    map { $self->{'action'}[$_]->GetValue } $self->{'rules'}->input_iterator;
}

sub set_action {
    my ($self) = shift;
    my ($nr, @list);
    if (@_ == 1) {
        $nr = shift;
        @list = $self->list_from_action_nr( $nr );
    } else {
        @list = @_;
        $nr = $self->nr_from_action_list( @list );
    }
    $self->{'action_nr'}->SetValue( $nr );
    $self->{'action'}[$_]->SetValue( $list[$_] ) for 0 .. $#list;
}

sub init_action {
    my ($self) = @_;
    my @list = map { $self->{'action'}[$_]->init } $self->{'rules'}->input_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub grid_action {
    my ($self) = @_;
    my @list = map { $self->{'action'}[$_]->grid } $self->{'rules'}->input_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub random_action {
    my ($self) = @_;
    my @list =  map { $self->{'action'}[$_]->rand } $self->{'rules'}->input_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub invert_action {
    my ($self) = @_;
    my @list = map { $self->{'action'}[$_]->invert } $self->{'rules'}->input_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub list_from_action_nr { reverse split '', $_[1]}
sub nr_from_action_list { shift @_; join '', reverse @_ }

sub generate_rules {
    my ($self, $data) = @_;
    return if ref $data eq 'HASH' and $self->{'state_count'} == $data->{'global'}{'state_count'};
    $self->{'state_count'} = $data->{'global'}{'state_count'} if ref $data eq 'HASH';
    $self->{'rules'} = App::GUI::Cellgraph::RuleGenerator->new( $self->{'rule_size'}, $self->{'state_count'} );

    #$self->{'state_count'}
}

1;