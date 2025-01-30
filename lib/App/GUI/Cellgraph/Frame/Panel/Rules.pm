
# rules panel

package App::GUI::Cellgraph::Frame::Panel::Rules;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::RuleInput;
use App::GUI::Cellgraph::Widget::ColorToggle;
use App::GUI::Cellgraph::Compute::Rule;
use Graphics::Toolkit::Color qw/color/;

# undo redo

sub new {
    my ( $class, $parent, $subrule_calculator ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'subrules'} = $subrule_calculator;
    $self->{'rules'}    = App::GUI::Cellgraph::Compute::Rule->new( $subrule_calculator );
    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'rule_plate'}->ShowScrollbars(0,1);
    $self->{'rule_plate'}->EnableScrolling(0,1);
    $self->{'rule_plate'}->SetScrollRate( 1, 1 );
    $self->{'rule_square_size'} = 20;
    $self->{'input_size'} = 0;
    $self->{'state_count'} = 0;
    $self->{'call_back'}  = sub {};

    $self->{'rule_nr'}   = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [ 85, -1], &Wx::wxTE_PROCESS_ENTER );
    $self->{'rule_nr'}->SetToolTip('number of currently displayed rule');
    $self->{'btn'}{'prev'}   = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'btn'}{'next'}   = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'btn'}{'sh_l'}   = Wx::Button->new( $self, -1, '<<', [-1,-1], [35,25] );
    $self->{'btn'}{'sh_r'}   = Wx::Button->new( $self, -1, '>>', [-1,-1], [35,25] );
    $self->{'btn'}{'sym'}    = Wx::Button->new( $self, -1, '<>', [-1,-1], [35,25] );
    $self->{'btn'}{'inv'}    = Wx::Button->new( $self, -1, '!',  [-1,-1], [30,25] );
    $self->{'btn'}{'opp'}    = Wx::Button->new( $self, -1, '%',  [-1,-1], [30,25] );
    $self->{'btn'}{'rnd'}    = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    $self->{'btn'}{'undo'}   = Wx::Button->new( $self, -1, '<=',  [-1,-1], [30,25] );
    $self->{'btn'}{'redo'}   = Wx::Button->new( $self, -1, '=>',  [-1,-1], [30,25] );

    $self->{'btn'}{'prev'}->SetToolTip('decrease rule number by one');
    $self->{'btn'}{'next'}->SetToolTip('increase rule number by one');
    $self->{'btn'}{'sh_l'}->SetToolTip('shift binary rule number one to left');
    $self->{'btn'}{'sh_r'}->SetToolTip('shift binary rule number one to right');
    $self->{'btn'}{'sym'}->SetToolTip('choose symmetric rule (every partial rule swaps result with symmetric partner)');
    $self->{'btn'}{'inv'}->SetToolTip('choose inverted rule (every partial rule that produces white, goes black and vice versa)');
    $self->{'btn'}{'opp'}->SetToolTip('choose opposite rule ()');
    $self->{'btn'}{'rnd'}->SetToolTip('choose random rule');
    $self->{'btn'}{'undo'}->SetToolTip('undo the last rule changes');
    $self->{'btn'}{'redo'}->SetToolTip('redo - take back the rule change undo');

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $tb_attr  = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;

    my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule_sizer->AddSpacer( 10 );
    $rule_sizer->Add( Wx::StaticText->new( $self, -1, 'Rule :' ), 0, $all_attr, 10 );
    #$rule_sizer->AddSpacer( 5 );
    $rule_sizer->Add( $self->{'rule_nr'},     0, $all_attr, 5 );
    $rule_sizer->AddSpacer( 5 );
    $rule_sizer->Add( $self->{'btn'}{'prev'}, 0, $tb_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'next'}, 0, $tb_attr, 5 );
    $rule_sizer->AddSpacer( 10 );
    $rule_sizer->Add( $self->{'btn'}{'sh_l'}, 0, $tb_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'sh_r'}, 0, $tb_attr, 5 );
    $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rf_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rf_sizer->AddSpacer( 63 );
    $rf_sizer->Add( $self->{'btn'}{'inv'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'sym'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'opp'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'rnd'}, 0, $all_attr, 5 );
    $rf_sizer->AddSpacer( 15 );
    $rf_sizer->Add( $self->{'btn'}{'undo'}, 0, $tb_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'redo'}, 0, $tb_attr, 5 );
    $rf_sizer->AddSpacer(20);
    $rf_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $rule_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $rf_sizer, 0, $std_attr, 20);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );

    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $self->SetSizer( $main_sizer );

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'rule_nr'}, sub { $self->set_rule( $self->{'rule_nr'}->GetValue ) });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'rule_nr'}, sub { $self->set_rule( $self->{'rule_nr'}->GetValue ) });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'prev'}, sub { $self->set_rule( $self->{'rules'}->prev_rule_nr ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'next'}, sub { $self->set_rule( $self->{'rules'}->next_rule_nr ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sh_l'}, sub { $self->set_rule( $self->{'rules'}->shift_rule_nr_left ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sh_r'}, sub { $self->set_rule( $self->{'rules'}->shift_rule_nr_right ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sym'},  sub { $self->set_rule( $self->{'rules'}->symmetric_rule_nr ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'inv'},  sub { $self->set_rule( $self->{'rules'}->inverted_rule_nr ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'opp'},  sub { $self->set_rule( $self->{'rules'}->opposite_rule_nr ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'rnd'},  sub { $self->set_rule( $self->{'rules'}->random_rule_nr ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'undo'}, sub { $self->set_rule( $self->{'rules'}->undo_rule_nr ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'redo'}, sub { $self->set_rule( $self->{'rules'}->redo_rule_nr ) });

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'rule_nr'}, sub {
        my ($self, $cmd) = @_;
        my $new_value = $cmd->GetString;
        my $old_value = $self->{'rules'}->nr_from_output_list( $self->get_output_list );
        return if $new_value == $old_value;
        $self->set_rule( $new_value );
        $self->{'call_back'}->();

    });
    $self->regenerate_rules( 3, 2, color('white')->gradient_to('black', 2));
    $self->init;
    $self;
}

sub regenerate_rules {
    my ($self, $input_size, $state_count, @colors) = @_;
    return if @colors < 2;
    my $do_regenerate = 0;
    my $do_recolor = 0;
    $do_regenerate += !($self->{'state_count'} == $state_count);
    $do_regenerate += !($self->{'input_size'} == $input_size);
    for my $i (0 .. $#colors) {
        return unless ref $colors[$i] eq 'Graphics::Toolkit::Color';
        if (exists $self->{'state_colors'}[$i]) {
            my @rgb = $colors[$i]->rgb;
            $do_recolor += !( $rgb[$_] == $self->{'state_colors'}[$i][$_]) for 0 .. 2;
        } else { $do_recolor++ }
    }
    return unless $do_regenerate or $do_recolor;
    $self->{'state_count'} = $state_count;
    $self->{'input_size'} = $input_size;
    $self->{'state_colors'} = [map {[$_->rgb]} @colors];
    my @sub_rule_pattern = $self->{'subrules'}->independent_input_patterns;

    if ($do_regenerate){
        my $refresh = 0;
        if (exists $self->{'rule_input'}){
            $self->{'plate_sizer'}->Clear(1);
            $self->{'rule_input'} = [];
            $self->{'arrow'} = [];
            $self->{'rule_result'} = [];
            map { $_->Destroy} @{$self->{'rule_input'}}, @{$self->{'rule_result'}}, @{$self->{'arrow'}};
            $refresh = 1;
        } else {
            $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
            $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );
        }
        my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
        for my $rule_index ($self->{'subrules'}->index_iterator){
            $self->{'rule_input'}[$rule_index]
                = App::GUI::Cellgraph::Widget::RuleInput->new ( $self->{'rule_plate'}, $self->{'rule_square_size'},
                                                                $sub_rule_pattern[$rule_index], $self->{'state_colors'} );
            $self->{'rule_input'}[$rule_index]->SetToolTip('input pattern of partial rule Nr.'.($rule_index+1));
            $self->{'rule_result'}[$rule_index]
                = App::GUI::Cellgraph::Widget::ColorToggle->new( $self->{'rule_plate'}, $self->{'rule_square_size'},
                                                                 $self->{'rule_square_size'}, $self->{'state_colors'}, 0 );
            $self->{'rule_result'}[$rule_index]->SetCallBack( sub { $self->update_rule_from_output });
            $self->{'rule_result'}[$rule_index]->SetToolTip('result of partial rule '.($rule_index+1));
            $self->{'arrow'}[$rule_index] = Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' );
        }
        for my $rule_index ($self->{'subrules'}->index_iterator){
            my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
            $row_sizer->AddSpacer(30);
            $row_sizer->Add( $self->{'rule_input'}[$rule_index], 0, &Wx::wxGROW);
            $row_sizer->AddSpacer(15);
            $row_sizer->Add( $self->{'arrow'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
            $row_sizer->AddSpacer(15);
            $row_sizer->Add( $self->{'rule_result'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
            $row_sizer->AddSpacer(40);
            $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
            $self->{'plate_sizer'}->AddSpacer(15);
            $self->{'plate_sizer'}->Add( $row_sizer, 0, $std_attr, 10);
        }
        $self->Layout if $refresh;
    } elsif ($do_recolor) {
        my @rgb = map {[$_->rgb]} @colors;
        $self->{'rule_input'}[$_]->SetColors( @rgb ) for $self->{'rules'}->part_rule_iterator;
        $self->{'rule_result'}[$_]->SetColors( @rgb ) for $self->{'rules'}->part_rule_iterator;
    }
}

sub init { $_[0]->set_settings( { nr => 18 } ) }

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'nr'};
    $self->set_rule( $settings->{'nr'} );
}
sub get_settings {
    my ($self) = @_;
    {
        nr => $self->{'rule_nr'}->GetValue,
    }
}
sub get_state {
    my ($self) = @_;
    {
        calc => $self->{'rules'},
        nr => $self->{'rule_nr'}->GetValue,
    }
}

sub get_output_list {
    my ($self) = @_;
    map { $self->{'rule_result'}[$_]->GetValue } $self->{'subrules'}->index_iterator;
}
sub update_rule_from_output {  $_[0]->set_rule( $_[0]->get_output_list ) }

sub set_rule {
    my ($self) = shift;
    my ($rule_nr, @list);
    if (@_ == 1) {
        $rule_nr = shift;
        @list = $self->{'rules'}->output_list_from_rule_nr( $rule_nr );
    } else {
        @list = @_;
        $rule_nr = $self->{'rules'}->rule_nr_from_output_list( @list );
    }
    $self->{'rule_result'}[$_]->SetValue( $list[$_] ) for 0 .. $#list;
    $self->{'rule_nr'}->SetValue( $rule_nr );
    $self->{'rules'}->set_rule_number( $rule_nr );
}

sub prev_rule      { $_[0]->set_rule( $_[0]->{'rules'}->prev_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub next_rule      { $_[0]->set_rule( $_[0]->{'rules'}->next_nr( $_[0]->{'rule_nr'}->GetValue ) ) }

sub shift_rule_left  { $_[0]->set_rule( $_[0]->{'rules'}->shift_nr_left( $_[0]->{'rule_nr'}->GetValue ) ) }
sub shift_rule_right { $_[0]->set_rule( $_[0]->{'rules'}->shift_nr_right( $_[0]->{'rule_nr'}->GetValue ) ) }

sub opposite_rule  { $_[0]->set_rule( $_[0]->{'rules'}->opposite_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub symmetric_rule { $_[0]->set_rule( $_[0]->{'rules'}->symmetric_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub invert_rule    { $_[0]->set_rule( $_[0]->{'rules'}->inverted_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub random_rule    { $_[0]->set_rule( $_[0]->{'rule_calc'}->random_nr ) }

sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

1;
