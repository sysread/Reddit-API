use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker 6.30;

WriteMakefile1(
    NAME                => 'Reddit::Client',
    AUTHOR              => q{"Jeff Ober" <"jeffober@gmail.com">},
    VERSION_FROM        => 'lib/Reddit/Client.pm',
    ABSTRACT_FROM       => 'lib/Reddit/Client.pm',
    'LICENSE' => 'perl',
    MIN_PERL_VERSION => '5.008001',
    META_MERGE => {
        resources => {
            repository => 'git://github.com/jsober/Reddit-API.git',
        },
    },
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

    TEST_REQUIRES => {
        'IO::Capture::Stderr' => 0,
        'Test::More'          => 0,
        'Test::MockModule'    => 0,
    }
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}

