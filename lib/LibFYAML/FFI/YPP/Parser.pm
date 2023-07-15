package LibFYAML::FFI::YPP::Parser;
use strict;
use warnings;

use LibFYAML::FFI;
use LibFYAML::FFI::YPP;
use base 'YAML::PP::Parser';

sub parse {
    my ($self) = @_;
    my $reader = $self->reader;
    my $parser;
    my $events = [];
    if (0 and $reader->can('open_handle')) {
    }
    else {
        my $cfg = LibFYAML::FFI::ParseConfig->new({
            search_path => 0,
            flags => 0,
        });
        $parser = LibFYAML::FFI::Parser::fy_parser_create($cfg);
        warn __PACKAGE__.':'.__LINE__.": !!!!!!!!!!!!! created $parser\n";
        my $yaml = $reader->read;
        my $ok = $parser->fy_parser_set_string($yaml, length($yaml));
        while (1) {
            my $event = $parser->fy_parser_parse;
            my $type = $event->fy_event_get_type;
            my $event_hash = $event->to_hash;
            $parser->fy_parser_event_free($event);
            my $name = $event_hash->{name};
            $self->callback->( $self, $name => $event_hash );
            last if $ok;
            last if $type == LibFYAML::FFI::event_type::FYET_STREAM_END;
        }
    }
}

1;
