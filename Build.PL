#!/usr/bin/perl
#$Id: Build.PL,v 1.5 2005/11/03 23:28:53 wolfgang Exp $

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name => 'Lingua::DE::Wortschatz',
    dist_version=> '1.22',
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
    dist_author     	=> 'Daniel Schroeer <daniel@daimla1.de>');
$build->create_build_script;
