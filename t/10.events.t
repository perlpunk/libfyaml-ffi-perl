#!/usr/bin/env perl
use Test2::V0;
use Test::More ();
use LibFYAML::FFI;
use Data::Dumper;

subtest event_type => sub {
    my $et = LibFYAML::FFI::event_type::FYET_DOCUMENT_START;
    is $et, 3;
};

subtest parse => sub {
    my $cfg = LibFYAML::FFI::ParseConfig->new({
        search_path => 0,
        flags => 3,
    });
    my $parser = LibFYAML::FFI::Parser::fy_parser_create($cfg);
    my $getcfg = $parser->fy_parser_get_cfg;
    my $flags = $getcfg->flags;
    is $flags, 3, "flags";

    my $yaml = <<"EOM";
- &ANCHOR !sc bar
- &M !map { "x": *ANCHOR }
- &S !seq []
EOM
    my $exp = [
        '+STR',
        '+DOC',
        '+SEQ',
        '=VAL &ANCHOR !sc :bar',
        '+MAP &M !map {}',
        '=VAL "x',
        '=ALI *ANCHOR',
        '-MAP',
        '+SEQ &S !seq []',
        '-SEQ',
        '-SEQ',
        '-DOC',
        '-STR',
    ];
    my $ok = $parser->fy_parser_set_string($yaml, length($yaml));
    is $ok, 0;
    my @got;
    for (1..13) {
        my $event = $parser->fy_parser_parse;
        my $type = $event->fy_event_get_type;
        my $hash = $event->to_hash;
        my $str = $event->as_string;
#        diag Test::More::explain($hash);
#        diag $str;
        $parser->fy_parser_event_free($event);
        push @got, $str;
    }
    is \@got, $exp;
};

done_testing;
exit;
