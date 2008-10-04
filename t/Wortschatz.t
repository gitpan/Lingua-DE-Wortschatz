#!/usr/bin/perl
#$Id: 2_visa-instrument.t 201 2005-11-19 00:21:02Z schroeer $

use strict;
use Test::More tests => 2;

BEGIN { use_ok('Lingua::DE::Wortschatz') };

ok(Lingua::DE::Wortschatz::help gt "","Help function returns something");

#like(join(" ",map {@$_} Lingua::DE::Wortschatz::use_service('Thesaurus','Test')->data()),qr/Probe/,"Service Thesaurus by full name");
#like(join(" ",map {@$_} Lingua::DE::Wortschatz::use_service('T','Test')->data()),qr/Probe/,"Service Thesaurus by abbreviated name");

#ok(join("",map {@$_} Lingua::DE::Wortschatz::use_service('ServiceOverview')->data()) gt "","Service ServiceOverview returns something");

#ok((Lingua::DE::Wortschatz::use_service('Co','Test')->data)[0]->[0] eq 'Test','Service Cooccurrences returns something');
