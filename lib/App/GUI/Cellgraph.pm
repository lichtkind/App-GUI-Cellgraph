use v5.12;
use warnings;
use Wx;
use utf8;
use FindBin;

package App::GUI::Cellgraph;
our $NAME = __PACKAGE__;
our $VERSION = '0.02';

use base qw/Wx::App/;
use App::GUI::Cellgraph::Frame;

sub OnInit {
    my $app   = shift;
    my $frame = App::GUI::Cellgraph::Frame->new( undef, 'Cellgraph '.$VERSION);
    $frame->Show(1);
    $frame->CenterOnScreen();
    $app->SetTopWindow($frame);
    1;
}
sub OnQuit { my( $self, $event ) = @_; $self->Close( 1 ); }
sub OnExit { my $app = shift;  1; }


1;

__END__

=pod

=head1 NAME

App::GUI::Cellgraph - draw pattern by cellular automata

=head1 SYNOPSIS 

=over 4

=item 1.

start the program (cellgraph)

=item 2.

push buttons and see patterns change

=item 3.

choose I<"Save"> in Image menu (or C<Ctrl+S>) to store image in a PNG / JPEG / SVG file
(choose image size  in menu beforehand)

=item 4.

choose I<Write> in settings menu (C<Ctrl+W>) to save settings into an
INI file for tweaking them later

=back

=head1 DESCRIPTION

This is a row (one dimensional arrangement) of cellular automata.
Their starting state can be seen in the first row. Each subsequent row
below reflects the following state (Y is time axis). 

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/126.png"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/30.png"    alt=""  width="300" height="300">
</p>


=head1 Mechanics

One automaton is called cell and works like described in I<Steve Wolfram>s
book  I<"A new kind of schience">. Each cell can be in one of several states.
The most simple cells have only two: 0 and 1 (pictured as white and black).
The state of each cell may change each round (think of processor cycles).
How exactly they change s defined by a transfer function. The input of
that function are the states of neighbours left and right and the cell
itself. Other neighbourhoods are possible. For every combination of states
in the neighbourhood there is one rule that defines the next state of the
cell. If neighbourhoods get greater - the number of rules grows exponentially.
To reduce again the rule count one might only take the average value of
the neighbourhood as input.

=head1 GUI

The general layout is very simple: the settings are on the right and 
the drawing board is left. The settings are devided into several tabs.

Please mind the tool tips - short help texts which appear if the mouse
stands still over a button. Also helpful are messages in the status bar
at the bottom that appear while browsing the menu.

=head2 Start

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/GUIstart.png"   alt=""  width="630" height="410">
</p>

The first tab contains the general settings and content of the staring
row.


=head2 Rules

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/GUIrule.png"   alt=""  width="630" height="410">
</p>

The content of the first tab are the settings that define the properties
of the 4 pendula (X, Y, Z and R), which determine the shape of the drawing.
X moves the pen left - right (on the x axis), Y moves up - down,
Z does a circling movement, R is a rotation ( around Z's axis).
Each pendulum has the same three rows of controls. 

The first row contains from left to ritght an on/off switch.
After that follows the pendulum's amplitude and damping.
Amplitudes define the size of the drawing and damping just means:
the drawings will spiral toward the center with time (line length).

The second row lets you dial in the speed (frequency).
For instance 2 means that the pendulum swings back and fourt twice 
as fast. The second combo control adds decimals for more complex drawings.

The third row has switches to invert (1/x) frequency or direction 
and can also change the starting position.
2 = 180 degree offset, 4 = 90 degree (both can be combined). 
The last slider adds an additional fine tuned offset between 0 and 90 degree.



=head2 Menu

The upmost menu bar has only three very simple menus.
Please not that each menu shows which key combination triggers the same
command and while hovering over an menu item you see a short help text
the left status bar field.

The first menu is for loading and storing setting files with arbitrary 
names. Also a sub menu allows a quick load of the recently used files.
The first entry lets you reset the whole program to the starting state
and the last is just to exit (safely with saving the configs).

The second menu has only two commands for drawing an complete image
and saving it in an arbitrary named PNG, JPG or SVG file (the file ending decides).
The submenu above onle set the preferred format, which is the format
of serial images and the first wild card in dialog. Above that is another
submenu for setting the image size.

The third menu has some dialogs with documentation and additional information.

=head1 SEE ALSO

L<App::GUI::Harmonograph>

L<App::GUI::Dynagraph>


=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved. 
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
