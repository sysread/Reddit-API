use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Reddit::API',
    AUTHOR              => q{"Jeff Ober" <"jeffober@gmail.com">},
    VERSION_FROM        => 'lib/Reddit/API.pm',
    ABSTRACT_FROM       => 'lib/Reddit/API.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'HTTP::Request' => 0,
	'JSON'		=> 0,
	'List::Util'	=> 0,
	'LWP::UserAgent'=> 0,
        'Test::More' 	=> 0,
	'URI::Encode'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Reddit-API-*' },
);
