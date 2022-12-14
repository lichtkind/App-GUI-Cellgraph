use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Part::ColorPicker;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::ColorDisplay;

sub new {
    my ( $class, $parent, $frame, $label, $target, $length, $space ) = @_;
    #return unless defined $max;
    $length //= 170;
    $space //= 0;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->{'colors'} = { %{$frame->{'config'}->get_value('color')} };
    $self->{'color_names'} = [ sort keys %{$self->{'colors'}} ];
    $self->{'color_index'} = 0;

    my $btnw = 50; my $btnh = 40;# button width and height
    $self->{'label'}  = Wx::StaticText->new($self, -1, $label );
    $self->{'select'} = Wx::ComboBox->new( $self, -1, $self->current_color_name, [-1,-1], [$length, -1], $self->{'color_names'});
    $self->{'<'}    = Wx::Button->new( $self, -1, '<',       [-1,-1], [ 30, 20] );
    $self->{'>'}    = Wx::Button->new( $self, -1, '>',       [-1,-1], [ 30, 20] );
    $self->{'load'} = Wx::Button->new( $self, -1, 'Load',    [-1,-1], [$btnw, $btnh] );
    $self->{'del'}  = Wx::Button->new( $self, -1, 'Del',     [-1,-1], [$btnw, $btnh] );
    $self->{'save'} = Wx::Button->new( $self, -1, 'Save',    [-1,-1], [$btnw, $btnh] );
    $self->{'display'} = App::GUI::Cellgraph::Widget::ColorDisplay->new( $self, 25, 10, $self->get_current_color );

    $self->{'label'}->SetToolTip("access to internal color storage for setting state colors");
    $self->{'select'}->SetToolTip("select color in list directly");
    $self->{'<'}->SetToolTip("go to previous color in list");
    $self->{'>'}->SetToolTip("go to next color in list");
    $self->{'load'}->SetToolTip("use displayed color on the right side as color of selected state");
    $self->{'save'}->SetToolTip("copy selected state color into color storage");
    $self->{'del'}->SetToolTip("delete displayed color from storage");
    $self->{'display'}->SetToolTip("color monitor");

    Wx::Event::EVT_COMBOBOX( $self, $self->{'select'}, sub {
        my ($win, $evt) = @_;                            $self->{'color_index'} = $evt->GetInt; $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'<'},    sub { $self->{'color_index'}--;  $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'>'},    sub { $self->{'color_index'}++;  $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'load'}, sub { $self->GetParent->set_current_color( $self->get_current_color ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'del'},  sub {
        delete $self->{'colors'}{ $self->current_color_name };
        $self->update_select();
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'save'}, sub {
        my $dialog = Wx::TextEntryDialog->new ( $self, "Please insert the color name", 'Request Dialog');
        return if $dialog->ShowModal == &Wx::wxID_CANCEL;
        my $name = $dialog->GetValue();
        return $self->GetParent->SetStatusText( "color name '$name' already taken ") if exists $self->{'colors'}{ $name };
        $self->{'colors'}{ $name } = [ $self->GetParent->get_current_color->rgb ];
        $self->update_select();
        for (0 .. $#{$self->{'color_names'}}){
            $self->{'color_index'} = $_ if $name eq $self->{'color_names'}[$_];
        }
        $self->update_display();
    });

    my $vset_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxGROW | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $all_attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxGROW | &Wx::wxALL;
    my $row1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    my $row2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row1->Add( $self->{'label'}, 0, $all_attr,  20 );
    $row1->AddSpacer( $space );
    $row1->Add( $self->{'select'}, 0, $vset_attr, 10 );
    $row1->Add( $self->{'<'},      0, $vset_attr, 10 );
    $row1->Add( $self->{'>'},      0, $vset_attr, 10 );
    $row1->AddSpacer( 20 );
    $row1->Add( $self->{'display'},  0, $vset_attr, 15);
    $row1->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    $row2->AddSpacer( 120 );
    $row2->Add( $self->{'load'}, 0, $all_attr,  10 );
    $row2->Add( $self->{'del'},  0, $all_attr,  10 );
    $row2->Add( $self->{'save'}, 0, $all_attr,  10 );
    $row2->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $row1, 0, $all_attr, 0 );
    $sizer->Add( $row2, 0, $all_attr, 0 );
    $self->SetSizer($sizer);

    $self;
}

sub get_data { $_[0]->{'colors'} }

sub current_color_name { $_[0]->{'color_names'}->[ $_[0]->{'color_index'} ] }

sub get_current_color {
    my ( $self ) = @_;
    my $cc = $self->{'colors'}->{ $self->current_color_name };
    {red=> $cc->[0], green=> $cc->[1], blue=> $cc->[2] };
}

sub update_select {
    my ( $self ) = @_;
    $self->{'color_names'} = [ sort keys %{$self->{'colors'}} ];
    $self->{'select'}->Clear ();
    $self->{'select'}->Append( $_) for @{$self->{'color_names'}};
    $self->update_display();
}

sub update_display {
    my ( $self ) = @_;
    $self->{'color_index'} = $#{$self->{'color_names'}} if $self->{'color_index'} < 0;
    $self->{'color_index'} = 0                          if $self->{'color_index'} > $#{$self->{'color_names'}};
    $self->{'select'}->SetSelection( $self->{'color_index'} );
    $self->{'display'}->set_color( $self->get_current_color );
}

1;
