use v5.12;
use warnings;
use Wx;
use utf8;
use FindBin;

package App::GUI::Cellgraph;
our $NAME = __PACKAGE__;
our $VERSION = '0.01_0';

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

App::GUI::Cellgraph - draw pattern by cellular automaton

=head1 SYNOPSIS 

=over 4

=item 1.

start the program (cellgraph)

=item 2.

push buttons and see patterns change

=item 3.

choose "Save" in Image menu (or Ctrl+S) to store image in a PNG / JPEG / SVG file
(choose image size  in menu beforehand)

=back

=head1 DESCRIPTION

An Harmonograph is an apparatus with several connected pendula,
creating together spiraling pictures :


=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/126.jpg"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/30.jpg"    alt=""  width="300" height="300">
</p>


This is a row of cellular automata as escribed in Steve Wolframs book
"A new kind of schience"

enhancements:

=over 4

=item *

third pendulum can rotate

=item *

pendula can oscillate at none integer frequencies

=item *

changeable amplitude and damping

=item *

changeable dot density and dot size

=item *

3 types of color changes with changeable speed and polynomial dynamics

=back


=head1 Mechanics




=head1 GUI

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/GUI.png"    alt=""  width="630" height="410">
</p>

The general layout of the program has three parts,
which flow from the position of the drawing board.

=over 4

=item 1

In the left upper corner is the drawing board - showing the result of the Harmonograph.

=item 2

The whole right half of the window contains the settings, which guide the drawing operation.
These are divided into two tabs - roughly devided in form and decoration.

=item 3

The lower left side contains buttons which are a few commands, 
but most are in the main menu.

=back

Please mind the tool tips - short help texts which appear if the mouse
stands still over a button or slider. Also helpful are messages in the
status bar at the bottom: on left regarding images and right about settings.
When holting the Alt key you can see which Alt + letter combinations
trigger which button.


=head2 Rule

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


=head2 Start

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/GUI2.png"   alt=""  width="630" height="410">
</p>

The second tab on the right side has knobs that set the properties of the pen.
First how many rotations will be drawn. Secondly the distance between dots. 
Greater distances, together with color changes, help to clearify
muddled up drawings. The third selector sets the dot size in pixel.


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


=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved. 
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
