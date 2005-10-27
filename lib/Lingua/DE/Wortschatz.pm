#$Id: Wortschatz.pm,v 1.6 2005/10/27 16:56:23 manonegra Exp $

package Lingua::DE::Wortschatz;

use strict;
use SOAP::Lite;# +trace=>'all';
use HTML::Entities;
use Text::Autoformat;
use Exporter 'import';

our @EXPORT_OK = qw(use_service help);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
 
our $VERSION = sprintf("1.%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

my $BASE_URL = 'http://anonymous:anonymous@pcai055.informatik.uni-leipzig.de:8100/axis/services/';
my $LIMIT    = 10;
my $MINSIG   = 1;

#description of available services and their corpus, in and out parameters
my %services=( # service_name => [ 'corpus', [ 'inparam<=default>', .. ], [ 'outparam', .. ] )
    ServiceOverview => [ 'webservice', ['Name='], ['Name','Id','Status','Description','AuthorizationLevel','InputFields'] ],
    Cooccurrences   => [ 'de', ['Wort',"Mindestsignifikanz=$MINSIG","Limit=$LIMIT"], ['Wort','Kookkurrenz','Signifikanz'] ],
    Baseform        => [ 'de', ['Wort'], ['Grundform','Wortart'] ],
    Sentences       => [ 'de', ['Wort',"Limit=$LIMIT"], ['Satz'] ],
    RightNeighbours => [ 'de', ['Wort',"Limit=$LIMIT"], ['Wort','Nachbar','Signifikanz'] ],
    LeftNeighbours  => [ 'de', ['Wort',"Limit=$LIMIT"], ['Nachbar','Wort','Signifikanz'] ],
    Frequencies     => [ 'de', ['Wort',"Limit=$LIMIT"], ['Anzahl','Frequenzklasse'] ],
    Synonyms        => [ 'de', ['Wort',"Limit=$LIMIT"], ['Synonym'] ],
    Thesaurus       => [ 'de', ['Wort',"Limit=$LIMIT"], ['Synonym'] ],
    Wordforms       => [ 'de', ['Word',"Limit=$LIMIT"], ['Form'] ], #find their nice trap
    Similarity      => [ 'de', ['Wort',"Limit=$LIMIT"], ['Wort','Verwandter','Signifikanz'] ],
    LeftCollocationFinder
                    => [ 'de', ['Wort','Wortart',"Limit=$LIMIT"], ['Kollokation','Wortart','Wort'] ],
    RightCollocationFinder
                    => [ 'de', ['Wort','Wortart',"Limit=$LIMIT"], ['Wort','Kollokation','Wortart'] ],
);

sub use_service {
    #returns a Lingua::DE::Wortschatz::Result object

    #get input parameters and set defaults or return undef if necessary
    my $service=cmd(shift);
    my %params;
    for (@{$services{$service}->[1]}) {
        if (/([^=]+)=(.*)/) { $params{$1}=shift || $2}
        else                { $params{$_}=shift || undef($service) }
    }
    return undef unless ($service);
    my $corpus=$services{$service}->[0];
    my @resultnames=@{$services{$service}->[2]};

    # perform the actual soap query and bring results into shape
    # wortschatz has two different kind of return types; kind of scalar and list
    my $soap = SOAP::Lite->proxy($BASE_URL.$service); 
    my @res=$soap->execute(make_params($corpus,\%params))
                 ->valueof('//result/'.((@resultnames > 1) ? '*' : 'dataVectors').'/*');
    my $result=Lingua::DE::Wortschatz::Result->new($service,@resultnames);
    $result->add(splice @res,0,@resultnames) while (@res);
    return $result;
}

sub help {
    my $cmd=shift || 'list';
    $cmd = cmd($cmd);
    my @so=use_service('ServiceOverview')->hashrefs();
    my $help="";
    for my $so (@so) {
        my $sn=$so->{Name};
        if ($services{$sn} && (($sn =~ /^$cmd/) || ($cmd =~ /(list)|(full)/))) {
            $help.=sprintf "* %s %s %s %s\n",$sn,@{$services{$sn}->[1]},"","","";
            unless ($cmd eq 'list') {
                my $t="\n  ".decode_entities($so->{Description})."\n\n";
                $help.=autoformat($t,{all=>1})."\n";
            }
        }
    }
    return $help;
}

sub make_params {
    # create the soap request parameters by hand
    # not the idea of soap, but everything else failed (see manpage)
    my ($corpus,$params)=@_;
    my $ns='http://datatypes.webservice.wortschatz.uni-leipzig.de';
    my $xml="<objRequestParameters><corpus>$corpus</corpus><parameters>";
    my $num=1;
    for (keys %$params) {
        $xml.=q (<dataVectors>).
              qq(<ns$num:dataRow xmlns:ns$num="$ns">$_</ns$num:dataRow>).
              qq(<ns$num:dataRow xmlns:ns$num="$ns">$$params{$_}</ns$num:dataRow>).
              q (</dataVectors>);
        $num++;
    }
    $xml.='</parameters></objRequestParameters>';
    SOAP::Data->type(xml=>$xml);
}

sub cmd {
    my ($service)=grep(/^$_[0]/,keys %services);
    return $service || $_[0];
}

package Lingua::DE::Wortschatz::Result;
use strict;

our $VERSION = sprintf("1.%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

sub new {
    my ($proto,$service,@names) = @_;
    my $class = ref($proto) || $proto;
    return bless { service => $service, names => \@names, data => [] }, $class;
}

sub add {
    my ($self,@values)=@_;
    push(@{$self->{data}},\@values);
}

sub dump {
    my $self=shift;
    print "Service ",$self->service,"\n\n";
    my @lengths;
    for my $row ($self->data,$self->{names}) {
        for (0..$#$row) {
            my $l=length($row->[$_]);
            $lengths[$_]=$l unless ($lengths[$_] && ($lengths[$_] > $l));
        }
    }
    my $form=(join "",map {'%-'.($_+1).'s'} @lengths)."\n";
    printf $form,@{$self->{names}};
    print join " ",map {"-"x$_} @lengths;print "\n";
    printf $form,@$_ for (@{$self->{data}});
}

sub service { shift->{service} }
    
sub names { @{shift->{names}} }
    
sub data { @{shift->{data}} }
    
sub hashrefs {
    my $self=shift;
    my @res=();
    for (@{$self->{data}}) {
        my %hash;
        @hash{@{$self->{names}}}=@$_;
        push(@res,\%hash);
    }
    return @res;
}

1;

__END__

=head1 NAME

Lingua::DE::Wortschatz - wortschatz.uni-leipzig.de webservice client

=head1 SYNOPSIS

    use Lingua::DE::Wortschatz;
    
    my $result=Lingua::DE::Wortschatz::use_service('T','toll');
    $result->dump;
    
    @lines=$result->hashrefs();
    for (@lines) {
        print $_->{Synonym},"\n";
    }

    print Lingua::DE::Wortschatz::help('T');
    print Lingua::DE::Wortschatz::help('full');

=head1 DESCRIPTION

This is a full featured client for the webservices
at L<http://wortschatz.uni-leipzig.de>.
The script C<wsws.pl> is a full featured command line
client that uses this lib. It is contained in this distribution.

=head1 FUNCTIONS

The following functions can be exported or used via the full name.

=head2 use_service($name,@args)

Uses the webservice named C<$name> with the arguments C<@args>.
Returns undef if not enough arguments for the desired
service are supplied. Otherwise it returns a result object (see below).

All public services at L<http://wortschatz.uni-leipzig.de> are
available. Below is a list of service names and their parameters.
Any parameter with = is optional and defaults to the given value.
Service names can be abbreviated to the shortest unique form.

  * ServiceOverview Name=
  * Cooccurrences Wort Mindestsignifikanz=1 Limit=10
  * Baseform Wort
  * Sentences Wort Limit=10
  * RightNeighbours Wort Limit=10
  * LeftNeighbours Wort Limit=10
  * Frequencies Wort Limit=10
  * Synonyms Wort Limit=10
  * Thesaurus Wort Limit=10
  * Wordforms Word Limit=10
  * Similarity Wort Limit=10
  * LeftCollocationFinder Wort Wortart Limit=10
  * RightCollocationFinder Wort Wortart Limit=10

A full list of available services, their parameters
and additional information on what each service does
can be obtained with the help function.

=head2 help(?$service)

Returns a string containing information about the service
with name C<$service>. If no service name is given,
a short list of all available services is returned. If
C<$service eq 'full'> a more detailed list is created.

=head1 THE RESULT OBJECT

The C<use_service> function returns a result object of class
C<Lingua::DE::Wortschatz::Result> that holds the results.

This object offers methods to conveniently access the data.

=head2 dump()

 $result->dump();

Pretty prints the data to STDOUT.

=head2 service()

 $service_name=$result->service();

Returns the name of the service that was used to obtain the data.

=head2 names()

 @column_headers=$result->names();

Returns a list of the names of the data columns.

=head2 data()

 @rows=$result->data();

Returns a list of datasets. Each dataset is a reference to a list of values.

=head2 hashrefs()

 @lines=$result->hashrefs();

Returns a list of datasets. Each dataset is a references to
a hash. The hashkeys are the names of the return values and
the values are the data.

=head1 CAVEATS/BUGS

I wrote this to understand SOAP better. It took me way too long, due to
the lack of documentation.

I couldn't figure out how to make SOAP::Lite and SOAP::Data create the
request parameters in the correct way. It appears to me that this would
require me to create custom as_Datatype functions for all the used types.

I could neither make it work using the WSDL file. I think with the data
format that wortschatz.u-l requires, WSDL is pretty useless.

So I decided to use a straightforward approach and create the XML request
parameters myself. This is probably not the idea of that whole SOAP thing,
but it's short and it works. But see it as a hack.

=head1 SEE ALSO

=over

=item L<http://wortschatz.uni-leipzig.de>

=item L<SOAP::Lite>

=back

=head1 AUTHOR/COPYRIGHT

This is C<$Id: Wortschatz.pm,v 1.6 2005/10/27 16:56:23 manonegra Exp $>.

Copyright 2005 Daniel Schröer (L<daniel@daimla1.de>).

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut  
