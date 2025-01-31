
# action rules panel

package App::GUI::Cellgraph::Frame::Panel::Action;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::RuleInput;
use App::GUI::Cellgraph::Widget::Action;
use App::GUI::Cellgraph::Widget::ColorToggle;
use Graphics::Toolkit::Color qw/color/;

# undo redo

sub new {
    my ( $class, $parent, $subrule_calculator ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'subrules'} = $subrule_calculator;
    $self->{'rule_square_size'} = 20;
    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'rule_plate'}->ShowScrollbars(0,1);
    $self->{'rule_plate'}->EnableScrolling(0,1);
    $self->{'rule_plate'}->SetScrollRate( 1, 1 );
    $self->{'call_back'} = sub {};
    $self->{'input_size'} = 0;
    $self->{'state_count'} = 0;
    $self->{'rule_mode'} = '';

    $self->{'action_nr'} = Wx::TextCtrl->new( $self, -1, 22222222, [-1,-1], [ 145, -1], &Wx::wxTE_PROCESS_ENTER );

    $self->{'btn'}{'1'}  = Wx::Button->new( $self, -1, '1',  [-1,-1], [30,25] );
    $self->{'btn'}{'2'}  = Wx::Button->new( $self, -1, '2',  [-1,-1], [30,25] );
    $self->{'btn'}{'!'}  = Wx::Button->new( $self, -1, '!',  [-1,-1], [30,25] );
    $self->{'btn'}{'?'}  = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    $self->{'btn'}{'1'}->SetToolTip('cells always in active action state (default)');
    $self->{'btn'}{'2'}->SetToolTip('cells always in toggeling action state');
    $self->{'btn'}{'!'}->SetToolTip('toggle resulting action states');
    $self->{'btn'}{'?'}->SetToolTip('set resulting action states to random new values');

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;

    my $act_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $act_sizer->AddSpacer( 10 );
    $act_sizer->Add( Wx::StaticText->new( $self, -1, 'Rule :' ), 0, $all_attr, 10 );
    $act_sizer->AddSpacer( 0 );
    $act_sizer->Add( $self->{'action_nr'},   0, $all_attr, 5 );
    $act_sizer->AddSpacer( 10 );
    $act_sizer->Add( $self->{'btn'}{'!'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'1'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'2'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'?'}, 0, $all_attr, 5 );
    $act_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $act_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr | &Wx::wxALL|&Wx::wxRIGHT, 20 );
    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $self->SetSizer( $main_sizer );

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'1'},sub { $self->init_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'2'},sub { $self->grid_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'?'},sub { $self->random_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'!'},sub { $self->invert_action; $self->{'call_back'}->() } );

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'action_nr'}, sub { $self->set_action( $self->{'action_nr'}->GetValue ); $self->{'call_back'}->() });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'action_nr'}, sub { $self->set_action( $self->{'action_nr'}->GetValue ); $self->{'call_back'}->() });
    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'action_nr'}, sub {
        my ($self, $cmd) = @_;
        my $new_nr = $cmd->GetString;
        my $old_nr = $self->action_nr_from_results;
        return if $new_nr == $old_nr;
        $self->set_action( $new_nr );
        $self->{'call_back'}->();
    });

    $self->regenerate_rules( 3, 2, color('white')->gradient_to('black', 2) );
    $self->init;
    $self;
}

sub regenerate_rules {
    my ($self, @colors) = @_;
    return if @colors < 2;
    my $do_regenerate = 0;
    my $do_recolor = 0;
    $do_regenerate += ($self->{'input_size'} != $self->{'subrules'}->input_size);
    $do_regenerate += ($self->{'state_count'} != $self->{'subrules'}->state_count);
    $do_regenerate += ($self->{'rule_mode'} ne $self->{'subrules'}->mode);
    for my $i (0 .. $#colors) {
        return unless ref $colors[$i] eq 'Graphics::Toolkit::Color';
        if (exists $self->{'state_colors'}[$i]) {
            my @rgb = $colors[$i]->values('rgb');
            $do_recolor += !( $rgb[$_] == $self->{'state_colors'}[$i][$_]) for 0 .. 2;
        } else { $do_recolor++ }
    }
    return unless $do_regenerate or $do_recolor;
    $self->{'input_size'} = $self->{'subrules'}->input_size;
    $self->{'state_count'} = $self->{'subrules'}->state_count;
    $self->{'rule_mode'}   = $self->{'subrules'}->mode;
    $self->{'state_colors'} = [map {[$_->rgb]} @colors];
    my @sub_rule_pattern = $self->{'subrules'}->independent_input_patterns;

    if ($do_regenerate){
        my $refresh = 0;# set back refresh flag

        if (exists $self->{'rule_input'}){
            $self->{'plate_sizer'}->Clear(1);
            $self->{'rule_input'} = [];
            $self->{'arrow'} = [];
            $self->{'action_result'} = []; # was action before
            $refresh = 1;
        } else {
            $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
            $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );
        }
        my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
        for my $rule_index ($self->{'subrules'}->index_iterator){
            $self->{'rule_input'}[$rule_index]
                = App::GUI::Cellgraph::Widget::RuleInput->new (
                    $self->{'rule_plate'}, $self->{'rule_square_size'},
                    $sub_rule_pattern[$rule_index], $self->{'state_colors'} );

            $self->{'rule_input'}[$rule_index]->SetToolTip('input pattern of partial rule Nr.'.($rule_index+1));
            $self->{'action_result'}[$rule_index] = App::GUI::Cellgraph::Widget::Action->new( $self->{'rule_plate'}, $self->{'rule_square_size'}, [255, 255, 255] );
            $self->{'action_result'}[$rule_index]->SetCallBack( sub {
                    $self->set_action( $self->action_nr_from_results ); $self->{'call_back'}->();
            });
            $self->{'action_result'}[$rule_index]->SetToolTip('transfer of activity by partial rule Nr.'.($rule_index+1));

            $self->{'arrow'}[$rule_index] = Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' );
            $self->{'arrow'}[$rule_index]->SetToolTip('partial action rule '.($rule_index+1).' input left, output right');
        }
        my $label_length = length $self->{'subrules'}->independent_count;
        for my $rule_index ($self->{'subrules'}->index_iterator){
            my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
            $row_sizer->AddSpacer(30);
            $row_sizer->Add( Wx::StaticText->new( $self->{'rule_plate'}, -1, sprintf('%0'.$label_length.'u',$rule_index+1).' :  ' ), 0, &Wx::wxGROW);
            $row_sizer->Add( $self->{'rule_input'}[$rule_index], 0, &Wx::wxGROW);
            $row_sizer->AddSpacer(15);
            $row_sizer->Add( $self->{'arrow'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
            $row_sizer->AddSpacer(15);
            $row_sizer->Add( $self->{'action_result'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
            $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
            $self->{'plate_sizer'}->AddSpacer(15);
            $self->{'plate_sizer'}->Add( $row_sizer, 0, $std_attr, 10);
        }
        $self->Layout if $refresh;
    } elsif ($do_recolor) {
        my @rgb = map {[$_->rgb]} @colors;
        $self->{'rule_input'}[$_]->SetColors( @rgb ) for $self->{'subrules'}->index_iterator;
    }
}

sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub init { $_[0]->set_settings( { nr => 22222222 } ) }

sub get_settings {
    my ($self) = @_;
    {
        nr => $self->{'action_nr'}->GetValue,
        sum => 0,
        threshold => 1,
    }
}
sub get_state {
    my ($self) = @_;
    my $state = $self->get_settings;
    $state->{'f'} = [$self->get_action_results];
    $state
}

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'nr'};
    $self->set_action( $settings->{'nr'} );
}

sub action_nr_from_results {
    $_[0]->nr_from_action_list( $_[0]->get_action_results )
}
sub get_action_results {
    map { $_[0]->{'action_result'}[$_]->GetValue } $_[0]->{'subrules'}->index_iterator
}

sub set_action {
    my ($self) = shift;
    my ($nr, @aresult);
    my $srule_count = $self->{'subrules'}->{'independent_subrules'};
    if (@_ == 1) {
        $nr = shift;
        @aresult = $self->list_from_action_nr( $nr );
        push @aresult, $self->{'action_result'}[int @aresult]->GetValue while @aresult < $srule_count-1;
        $nr = $self->nr_from_action_list( @aresult );
    } else {
        @aresult = @_;
        push @aresult, $self->{'action_result'}[int @aresult]->GetValue while @aresult < $srule_count-1;
        pop @aresult  while @aresult >= $srule_count;
        $nr = $self->nr_from_action_list( @aresult );
    }
    $self->{'action_nr'}->SetValue( $nr );
    return unless ref $self->{'action_result'}[0];
    $self->{'action_result'}[$_]->SetValue( $aresult[$_] ) for 0 .. $#aresult;
    $nr;
}

########################################################################
sub init_action {
    my ($self) = @_;
    my @list = map { $self->{'action_result'}[$_]->init } $self->{'subrules'}->index_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub grid_action {
    my ($self) = @_;
    my @list = map { $self->{'action_result'}[$_]->grid } $self->{'subrules'}->index_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub random_action {
    my ($self) = @_;
    my @list =  map { $self->{'action_result'}[$_]->rand } $self->{'subrules'}->index_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub invert_action {
    my ($self) = @_;
    my @list = map { $self->{'action_result'}[$_]->invert } $self->{'subrules'}->index_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub list_from_action_nr { reverse split '', $_[1]}
sub nr_from_action_list { shift @_; join '', reverse @_ }


1;
