libfyaml-ffi-perl

cpanm FFI::Platypus FFI::C Test2::V0 YAML::PP

perl Makefile.PL
make test


time perl -Mblib ./yamlpp-events -M LibFYAML::FFI::YPP < bench-simple.yaml
time perl -Mblib ./yamlpp-events -M LibFYAML::FFI::YPP < githubcl-openapi.yaml
