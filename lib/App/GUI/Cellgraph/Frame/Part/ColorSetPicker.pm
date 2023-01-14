use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Part::ColorSetPicker;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $color_sets) = @_;
    return unless ref $parent and ref $color_sets eq 'HASH';

    my $self = $class->SUPER::new( $parent, -1 );

    $self->{'colors'} = { %$color_sets };
    $self->{'color_names'} = [ sort keys %{$self->{'colors'}} ];
    $self->{'color_index'} = 0;

    my $btnw = 50; my $btnh = 20;# button width and height
    $self->{'select'} = Wx::ComboBox->new( $self, -1, $self->current_color_name, [-1,-1], [170, -1], $self->{'color_names'});
    $self->{'<'}    = Wx::Button->new( $self, -1, '<',       [-1,-1], [ 30, 20] );
    $self->{'>'}    = Wx::Button->new( $self, -1, '>',       [-1,-1], [ 30, 20] );
    $self->{'load'} = Wx::Button->new( $self, -1, 'Load',    [-1,-1], [$btnw, $btnh] );
    $self->{'del'}  = Wx::Button->new( $self, -1, 'Del',     [-1,-1], [$btnw, $btnh] );
    $self->{'save'} = Wx::Button->new( $self, -1, 'Save',    [-1,-1], [$btnw, $btnh] );
    $self->{'new'}  = Wx::Button->new( $self, -1, 'New',     [-1,-1], [$btnw, $btnh] );

    $self->{'select'}->SetToolTip("select color set in list directly");
    $self->{'<'}->SetToolTip("go to previous color set name in list");
    $self->{'>'}->SetToolTip("go to next color set name in list");
    $self->{'load'}->SetToolTip("use displayed color on the right side as color of selected state");
    $self->{'save'}->SetToolTip("copy selected state color into color storage");
    $self->{'del'}->SetToolTip("delete color set of displayed name from storage");
    $self->{'new'}->SetToolTip("save");

    Wx::Event::EVT_COMBOBOX( $self, $self->{'select'}, sub {
        my ($win, $evt) = @_;                            $self->{'color_index'} = $evt->GetInt; });
    Wx::Event::EVT_BUTTON( $self, $self->{'<'},    sub { $self->{'color_index'}--;  });
    Wx::Event::EVT_BUTTON( $self, $self->{'>'},    sub { $self->{'color_index'}++;  });
    Wx::Event::EVT_BUTTON( $self, $self->{'load'}, sub { });
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
    $row1->AddSpacer( 10 );
    $row1->Add( $self->{'select'}, 0, $vset_attr, 5 );
    $row1->Add( $self->{'<'},      0, $vset_attr, 5 );
    $row1->Add( $self->{'>'},      0, $vset_attr, 5 );
    $row1->AddSpacer( 5 );
    $row1->Add( $self->{'load'}, 0, $all_attr,  3 );
    $row1->Add( $self->{'del'},  0, $all_attr,  3 );
    $row1->Add( $self->{'save'}, 0, $all_attr,  3 );
    $row1->Add( $self->{'new'},  0, $all_attr,  3 );
    $row1->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $row1, 0, $all_attr, 0 );
    $self->SetSizer($sizer);

    $self;
}

sub current_color_name { $_[0]->{'color_names'}->[ $_[0]->{'color_index'} ] }

sub get_current_color_set {
    my ( $self ) = @_;
    my $color = $self->{'colors'}->{ $self->current_color_name };
    {red=> $color->[0], green=> $color->[1], blue=> $color->[2] };
}

sub update_select {
    my ( $self ) = @_;
    $self->{'color_names'} = [ sort keys %{$self->{'colors'}} ];
    $self->{'select'}->Clear ();
    $self->{'select'}->Append( $_) for @{$self->{'color_names'}};
}

sub get_config { $_[0]->{'colors'} }


1;
