use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker 6.30;

WriteMakefile(
    NAME                => 'Reddit::Client',
    AUTHOR              => q{"Jeff Ober" <"jeffober@gmail.com">},
    VERSION_FROM        => 'lib/Reddit/Client.pm',
    ABSTRACT_FROM       => 'lib/Reddit/Client.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : ()),
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Reddit-Client-*' },

    PREREQ_PM => {
        'HTTP::Request'       => 0,
        'JSON'                => 0,
        'List::Util'          => 0,
        'LWP::UserAgent'      => 0,
        'URI::Encode'         => 0,
        'File::Path::Expand'  => 1.02,
    },

    BUILD_REQUIRES => {
        'IO::Capture::Stderr' => 0,
        'Test::More'          => 0,
        'Test::MockModule'    => 0,
    }
);
