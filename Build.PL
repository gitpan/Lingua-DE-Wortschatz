#!/usr/bin/perl
#$Id: Build.PL 1039 2008-01-25 20:23:48Z schroeer $

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name => 'Lingua::DE::Wortschatz',
    dist_version=> '1.25',
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
    dist_author     	=> 'Daniel Schroeer <schroeer@cpan.org>');
$build->create_build_script;
