### NAME

    App-GUI-Cellgraph - draw pattern by cellular automata

### VERSION

    0.74

[Home on CPAN](https://metacpan.org/pod/App::GUI::Cellgraph)

    This is the landing page for the user documentation on github.
    Please use the link above to visit the de facto homepage of the project.
    There is also a download link on the left side under "Tools".


### BUILDING

    The git repository contains much more than the software package itself.
    If you check out sources here, you have to build the package yourself.
    In order to do that you need perl and the module Dist::Zilla.

    cpan install Dist::Zilla
        or
    cpanm Dist::Zilla


    Then you have to check which further the Dist::Zilla plugins you miss:

    dzil authordeps

    and pipe them into your preferred installer:

    dzil authordeps | cpanm


    Than you can build a release yourself:

    dzil build

    Which gives you basically the same tgz file as under the download link
    from CPAN (as describes under HOME), just with more up to date
    (and maybe buggy) sources. Don't forget to:

    dzil clean


### INSTALLING

    Once you downloaded or created a build, you unzip it and do the usual:

        perl Makefile.PL
        make
        make test
        make install

    This should install to your site_perl directory.


### PREREQUISITES

    Perl 5.12 including some core modules
    FindBin 1
    File::Spec 3
    File::HomeDir 1
    Graphics::Toolkit::Color 1.71
    WxPerl (Wx) 0.9

[SEE ALSO](https://lichtkind.de/code)

[CHANGES](https://github.com/lichtkind/App-GUI-Cellgraph/blob/main/Changes) (with roadmap)

[CONTRIBUTING](https://github.com/lichtkind/App-GUI-Cellgraph/blob/main/CONTRIBUTING)

### COPYRIGHT

    Copyright(c) 2022-25 Herbert Breunung,

    All rights reserved.  This program is free software;
    you can redistribute it and/or modify it under GPL version 3
