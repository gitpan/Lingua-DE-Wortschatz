#!/usr/bin/perl
#$Id: Build.PL,v 1.7 2005/12/07 22:03:16 wolfgang Exp $

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name => 'Lingua::DE::Wortschatz',
    dist_version=> '1.23',
    license     => 'perl',
    requires    => {
        'SOAP::Lite'        => 0,
        'HTML::Entities'    => 0,
        'Text::Autoformat'  => 0,
        'Encode'            => 0,
        'Exporter'          => 0,
    },
    script_files    	=> ['wsws.pl'],
    create_readme   	=> 0,
    create_makefile_pl	=> 'passthrough',
    dist_author     	=> 'Daniel Schroeer <daniel.schroeer@physik.uni-muenchen.de>');
$build->create_build_script;
