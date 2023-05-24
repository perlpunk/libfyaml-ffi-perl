use ExtUtils::MakeMaker;
use FFI::Build::MM;
my $fbmm = FFI::Build::MM->new;
WriteMakefile(
  $fbmm->mm_args(
    NAME     => 'LibFYAML::FFI',
    DISTNAME => 'LibFYAML-FFI',
    VERSION  => '1.00',
    PREREQ_PM => {
        'FFI::C' => 0,
        'FFI::Platypus' => 0,
    },
  )
);

sub MY::postamble {
    $fbmm->mm_postamble;
}
