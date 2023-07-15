package LibFYAML::FFI;

use strict;
use warnings;
use experimental 'signatures';
use FFI::Platypus 2.00;
use FFI::C;

my $ffi = FFI::Platypus->new( api => 1 );
FFI::C->ffi($ffi);

$ffi->bundle;

package LibFYAML::FFI::ParseConfigFlags {
    FFI::C->enum( fy_parse_cfg_flags => [qw/
        QUIET
        COLLECT_DIAG
        RESOLVE_DOCUMENT
        DISABLE_MMAP_OPT
        DISABLE_RECYCLING
        PARSE_COMMENTS
        DISABLE_DEPTH_LIMIT
        DISABLE_ACCELERATORS
        DISABLE_BUFFERING
        DEFAULT_VERSION_AUTO
        DEFAULT_VERSION_1_1
        DEFAULT_VERSION_1_2
        DEFAULT_VERSION_1_3
        SLOPPY_FLOW_INDENTATION
        PREFER_RECURSIVE
        JSON_AUTO
        JSON_NONE
        JSON_FORCE
        YPATH_ALIASES
        ALLOW_DUPLICATE_KEYS
    /],
    { rev => 'int', prefix => 'FYPCF_', package => 'LibFYAML::FFI::ParseConfigFlags' }
    );
}

package LibFYAML::FFI::ParseConfig {
    $ffi->type( 'opaque' => 'fy_diag' );
    FFI::C->struct( fy_parse_cfg => [
        search_path => 'opaque',
        flags => 'fy_parse_cfg_flags',
        userdata => 'opaque',
        diag => 'fy_diag',
   ]);
    sub searchpath_str ($self) { $ffi->cast('opaque', 'string', $self->search_path) }
}


package LibFYAML::FFI::event_type {
    FFI::C->enum( fy_event_type => [qw/
        NONE
        STREAM_START STREAM_END
        DOCUMENT_START DOCUMENT_END
        MAPPING_START MAPPING_END
        SEQUENCE_START SEQUENCE_END
        SCALAR ALIAS
    /],
    { rev => 'int', prefix => 'FYET_', package => 'LibFYAML::FFI::event_type' }
    );
}

#package LibFYAML::FFI::StreamStart {
#    FFI::C->struct( fy_event_stream_start_data => [
#        stream_start => 'opaque',
#   ]);
#}

#package LibFYAML::FFI::EventData {
#    FFI::C->union( event_data => [
#        stream_start => 'fy_event_stream_start_data',
#    fy_event_stream_end_data stream_end;
#    fy_event_document_start_data document_start;
#    fy_event_document_end_data document_end;
#    fy_event_alias_data alias;
#    fy_event_scalar_data scalar;
#    fy_event_sequence_start_data sequence_start;
#    fy_event_sequence_end_data sequence_end;
#    fy_event_mapping_start_data mapping_start;
#    fy_event_mapping_end_data mapping_end;
#    ]);
#}

package LibFYAML::FFI::Token {
    $ffi->type('object(LibFYAML::FFI::Token)' => 'fy_token');
    $ffi->attach( fy_token_get_text => [qw/ fy_token size_t* /] => 'string' );
    $ffi->attach( fy_token_get_text0 => [qw/ fy_token /] => 'string' );
# ?????
# unable to find fy_token_free
#    $ffi->attach( [ fy_token_free => 'DESTROY' ] => [ 'fy_token' ] => 'void' );
}

package LibFYAML::FFI::Event {
    use YAML::PP::Common qw/ :STYLES /;
    $ffi->type('object(LibFYAML::FFI::Event)' => 'fy_event');
#    FFI::C->struct( fy_event => [
#        type => 'fy_event_type',
#   ]);
    use constant {
        FYNS_ANY => -1,
        FYNS_FLOW => 0,
        FYNS_BLOCK => 1,
        FYNS_PLAIN => 2,
        FYNS_SINGLE_QUOTED => 3,
        FYNS_DOUBLE_QUOTED => 4,
        FYNS_LITERAL => 5,
        FYNS_FOLDED => 6,
    };
#    $ffi->type( 'opaque' => 'fy_token' );
#    $ffi->attach( fy_event_data => [qw/ fy_event /] => 'opaque' );
    $ffi->attach( fy_event_get_type => [qw/ fy_event /] => 'fy_event_type' );
    $ffi->attach( fy_event_get_node_style => [qw/ fy_event /] => 'int' );
    $ffi->attach( fy_event_get_anchor_token => [qw/ fy_event /] => 'fy_token' );
    $ffi->attach( fy_event_get_tag_token => [qw/ fy_event /] => 'fy_token' );
    $ffi->attach( fy_event_get_token => [qw/ fy_event /] => 'fy_token' );
    $ffi->attach( [ noop => 'DESTROY' ] => [ 'fy_event' ] => 'void' );
    my %styles = (
        FYNS_PLAIN() => ':',
        FYNS_SINGLE_QUOTED() => "'",
        FYNS_DOUBLE_QUOTED() => '"',
        FYNS_LITERAL() => '|',
        FYNS_FOLDED() => '>',
    );
    my %scalar_style_to_ypp = (
        FYNS_PLAIN() => YAML_PLAIN_SCALAR_STYLE(),
        FYNS_SINGLE_QUOTED() => YAML_SINGLE_QUOTED_SCALAR_STYLE(),
        FYNS_DOUBLE_QUOTED() => YAML_DOUBLE_QUOTED_SCALAR_STYLE(),
        FYNS_LITERAL() => YAML_LITERAL_SCALAR_STYLE(),
        FYNS_FOLDED() => YAML_FOLDED_SCALAR_STYLE(),
    );
    sub as_string {
        my ($self) = @_;
        my $str = '';
        my $type = $self->fy_event_get_type;
        if ($type == LibFYAML::FFI::event_type::FYET_STREAM_START()) {
            $str = '+STR';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_STREAM_END()) {
            $str = '-STR';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_DOCUMENT_START()) {
            $str = '+DOC';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_DOCUMENT_END()) {
            $str = '-DOC';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_ALIAS()) {
            $str = '=ALI';
            if (my $anchor = $self->fy_event_get_token) {
                $str .= " *" . $anchor->fy_token_get_text0;
            }
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_SCALAR()) {
            $str = '=VAL';
            if (my $anchor = $self->fy_event_get_anchor_token) {
                $str .= " &" . $anchor->fy_token_get_text0;
            }
            if (my $tag = $self->fy_event_get_tag_token) {
                $str .= " " . $tag->fy_token_get_text0;
            }
            my $style = $self->fy_event_get_node_style;
            $str .= ' ' . $styles{$style};
            if (my $scalar = $self->fy_event_get_token) {
                $str .= $scalar->fy_token_get_text0;
            }
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_SEQUENCE_START()) {
            $str = '+SEQ';
            if (my $anchor = $self->fy_event_get_anchor_token) {
                $str .= " &" . $anchor->fy_token_get_text0;
            }
            if (my $tag = $self->fy_event_get_tag_token) {
                $str .= " " . $tag->fy_token_get_text0;
            }
            if ($self->fy_event_get_node_style == 0) {
                $str .= ' []';
            }
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_SEQUENCE_END()) {
            $str = '-SEQ';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_MAPPING_START()) {
            $str = '+MAP';
            if (my $anchor = $self->fy_event_get_anchor_token) {
                $str .= " &" . $anchor->fy_token_get_text0;
            }
            if (my $tag = $self->fy_event_get_tag_token) {
                $str .= " " . $tag->fy_token_get_text0;
            }
            if ($self->fy_event_get_node_style == 0) {
                $str .= ' {}';
            }
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_MAPPING_END()) {
            $str = '-MAP';
        }
        return $str;
    }
    sub to_hash {
        my ($self) = @_;
        my %hash = ();
        my $type = $self->fy_event_get_type;
        if ($type == LibFYAML::FFI::event_type::FYET_STREAM_START()) {
            $hash{name} = 'stream_start_event';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_STREAM_END()) {
            $hash{name} = 'stream_end_event';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_DOCUMENT_START()) {
            $hash{name} = 'document_start_event';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_DOCUMENT_END()) {
            $hash{name} = 'document_end_event';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_ALIAS()) {
            $hash{name} = 'alias_event';
            if (my $anchor = $self->fy_event_get_token) {
                $hash{value} = $anchor->fy_token_get_text0;
            }
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_SCALAR()) {
            $hash{name} = 'scalar_event';
            if (my $scalar = $self->fy_event_get_token) {
                $hash{value} = $scalar->fy_token_get_text0;
            }
            if (my $anchor = $self->fy_event_get_anchor_token) {
                $hash{anchor} = $anchor->fy_token_get_text0;
            }
            if (my $tag = $self->fy_event_get_tag_token) {
                $hash{tag} = $tag->fy_token_get_text0;
            }
            $hash{style} = $scalar_style_to_ypp{ $self->fy_event_get_node_style };
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_SEQUENCE_START()) {
            $hash{name} = 'sequence_start_event';
            if (my $anchor = $self->fy_event_get_anchor_token) {
                $hash{anchor} = $anchor->fy_token_get_text0;
            }
            if (my $tag = $self->fy_event_get_tag_token) {
                $hash{tag} = $tag->fy_token_get_text0;
            }
            $hash{style} = $self->fy_event_get_node_style;
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_SEQUENCE_END()) {
            $hash{name} = 'sequence_end_event';
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_MAPPING_START()) {
            $hash{name} = 'mapping_start_event';
            $hash{style} = $self->fy_event_get_node_style;
            if (my $anchor = $self->fy_event_get_anchor_token) {
                $hash{anchor} = $anchor->fy_token_get_text0;
            }
            if (my $tag = $self->fy_event_get_tag_token) {
                $hash{tag} = $tag->fy_token_get_text0;
            }
        }
        elsif ($type == LibFYAML::FFI::event_type::FYET_MAPPING_END()) {
            $hash{name} = 'mapping_end_event';
        }
        return \%hash;
    }
}

package LibFYAML::FFI::Parser {
    $ffi->type('object(LibFYAML::FFI::Parser)' => 'fy_parser');
    $ffi->attach( fy_parser_create => [qw/ fy_parse_cfg /] => 'fy_parser' );
    $ffi->attach( fy_parser_get_cfg => [qw/ fy_parser /] => 'fy_parse_cfg' );
    $ffi->attach( fy_parser_set_string => [qw/ fy_parser string size_t /] => 'int' );
    $ffi->attach( fy_parser_parse => [qw/ fy_parser /] => 'fy_event' );
    $ffi->attach( fy_parser_event_free => [ qw/ fy_parser fy_event / ] => 'void' );
    $ffi->attach( [ fy_parser_destroy => 'DESTROY' ] => [ 'fy_parser' ] => 'void' );
}


1;
__END__

package LibYAML::FFI::YamlEncoding {
    FFI::C->enum( yaml_encoding_t => [qw/
        ANY_ENCODING
        UTF8_ENCODING
        UTF16LE_ENCODING
        UTF16BE_ENCODING
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlEncoding' }
    );
}


package LibYAML::FFI::YamlScalarStyle {
    FFI::C->enum( yaml_scalar_style_t => [qw/
        ANY_SCALAR_STYLE
        PLAIN_SCALAR_STYLE
        SINGLE_QUOTED_SCALAR_STYLE
        DOUBLE_QUOTED_SCALAR_STYLE
        LITERAL_SCALAR_STYLE
        FOLDED_SCALAR_STYLE
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlScalarStyle' }
    );
}

package LibYAML::FFI::YamlSequenceStyle {
    FFI::C->enum( yaml_sequence_style_t => [qw/
        ANY_SEQUENCE_STYLE
        BLOCK_SEQUENCE_STYLE
        FLOW_SEQUENCE_STYLE
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlSequenceStyle' }
    );
}
package LibYAML::FFI::YamlMappingStyle {
    FFI::C->enum( yaml_mapping_style_t => [qw/
        ANY_MAPPING_STYLE
        BLOCK_MAPPING_STYLE
        FLOW_MAPPING_STYLE
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlMappingStyle' }
    );
}

package LibYAML::FFI::YamlErrorType {
    FFI::C->enum( yaml_error_type_t => [qw/
    NO_ERROR
    MEMORY_ERROR
    READER_ERROR
    SCANNER_ERROR
    PARSER_ERROR
    COMPOSER_ERROR
    WRITER_ERROR
    EMITTER_ERROR
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlErrorType' }
    );
}

package LibYAML::FFI::YamlParserState {
    FFI::C->enum( yaml_parser_state_t => [qw/
    PARSE_STREAM_START_STATE
    PARSE_IMPLICIT_DOCUMENT_START_STATE
    PARSE_DOCUMENT_START_STATE
    PARSE_DOCUMENT_CONTENT_STATE
    PARSE_DOCUMENT_END_STATE
    PARSE_BLOCK_NODE_STATE
    PARSE_BLOCK_NODE_OR_INDENTLESS_SEQUENCE_STATE
    PARSE_FLOW_NODE_STATE
    PARSE_BLOCK_SEQUENCE_FIRST_ENTRY_STATE
    PARSE_BLOCK_SEQUENCE_ENTRY_STATE
    PARSE_INDENTLESS_SEQUENCE_ENTRY_STATE
    PARSE_BLOCK_MAPPING_FIRST_KEY_STATE
    PARSE_BLOCK_MAPPING_KEY_STATE
    PARSE_BLOCK_MAPPING_VALUE_STATE
    PARSE_FLOW_SEQUENCE_FIRST_ENTRY_STATE
    PARSE_FLOW_SEQUENCE_ENTRY_STATE
    PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_KEY_STATE
    PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_VALUE_STATE
    PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_END_STATE
    PARSE_FLOW_MAPPING_FIRST_KEY_STATE
    PARSE_FLOW_MAPPING_KEY_STATE
    PARSE_FLOW_MAPPING_VALUE_STATE
    PARSE_FLOW_MAPPING_EMPTY_VALUE_STATE
    PARSE_END_STATE
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlParserState' }
    );
}

package LibYAML::FFI::StreamStart {
    FFI::C->struct( YAML_StreamStart => [
        encoding => 'yaml_encoding_t',
   ]);
}

package LibYAML::FFI::Scalar {
    FFI::C->struct( YAML_Scalar => [
        anchor => 'opaque',
        tag => 'opaque',
        value => 'opaque',
        length => 'size_t',
        plain_implicit => 'int',
        quoted_implicit => 'int',
        style => 'yaml_scalar_style_t',
    ]);
    sub anchor_str ($self) { $ffi->cast('opaque', 'string', $self->anchor) }
    sub tag_str ($self) { $ffi->cast('opaque', 'string', $self->tag) }
    sub value_str ($self) { $ffi->cast('opaque', 'string', $self->value) }
}

package LibYAML::FFI::Alias {
    FFI::C->struct( YAML_Alias => [
        anchor => 'opaque',
    ]);
    sub anchor_str ($self) { $ffi->cast('opaque', 'string', $self->anchor) }
}

package LibYAML::FFI::SequenceStart {
    FFI::C->struct( YAML_SequenceStart => [
        anchor => 'opaque',
        tag => 'opaque',
        implicit => 'int',
        style => 'yaml_sequence_style_t',
    ]);
    sub anchor_str ($self) { $ffi->cast('opaque', 'string', $self->anchor) }
    sub tag_str ($self) { $ffi->cast('opaque', 'string', $self->tag) }
}

package LibYAML::FFI::MappingStart {
    FFI::C->struct( YAML_MappingStart => [
        anchor => 'opaque',
        tag => 'opaque',
        implicit => 'int',
        style => 'yaml_mapping_style_t',
    ]);
    sub anchor_str ($self) { $ffi->cast('opaque', 'string', $self->anchor) }
    sub tag_str ($self) { $ffi->cast('opaque', 'string', $self->tag) }
}

package LibYAML::FFI::EventData {
    FFI::C->union( yaml_event_data_t => [
        stream_start => 'YAML_StreamStart',
        alias => 'YAML_Alias',
        scalar => 'YAML_Scalar',
        sequence_start => 'YAML_SequenceStart',
        mapping_start => 'YAML_MappingStart',
    ]);
}

package LibYAML::FFI::YamlMark {
    use overload
        '""' => sub { shift->as_string };
    FFI::C->struct( yaml_mark_t => [
        index => 'size_t',
        line =>'size_t',
        column => 'size_t',
    ]);
    sub as_string {
        my ($self) = @_;
        sprintf "(%2d):[L:%2d C:%2d]", $self->index, $self->line, $self->column;
    }
}

package LibYAML::FFI::Event {
    FFI::C->struct( yaml_event_t => [
        type => 'yaml_event_type_t',
        data => 'yaml_event_data_t',
        start_mark => 'yaml_mark_t',
        end_mark => 'yaml_mark_t',
    ]);

    sub to_hash {
        my ($self) = @_;
        my %hash = ();
        my $type = $self->yaml_event_type;
        if ($type == LibYAML::FFI::event_type::YAML_STREAM_START_EVENT()) {
            $hash{name} = 'stream_start_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_STREAM_END_EVENT()) {
            $hash{name} = 'stream_end_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_DOCUMENT_START_EVENT()) {
            $hash{name} = 'document_start_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_DOCUMENT_END_EVENT()) {
            $hash{name} = 'document_end_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_ALIAS_EVENT()) {
            $hash{name} = 'alias_event';
            if (my $anchor = $self->data->alias->anchor_str) {
                $hash{value} = $anchor;
            }
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_SCALAR_EVENT()) {
            $hash{name} = 'scalar_event';
            my $val = $self->yaml_event_scalar_value;
            $hash{value} = $val;
            if (my $anchor = $self->yaml_event_scalar_anchor) {
                $hash{anchor} = $anchor;
            }
            if (my $tag = $self->yaml_event_scalar_tag) {
                $hash{tag} = $tag;
            }
            $hash{style} = $self->yaml_event_scalar_style;
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_SEQUENCE_START_EVENT()) {
            $hash{name} = 'sequence_start_event';
            if (my $anchor = $self->yaml_event_sequence_anchor) {
                $hash{anchor} = $anchor;
            }
            if (my $tag = $self->yaml_event_sequence_tag) {
                $hash{tag} = $tag;
            }
            $hash{style} = $self->yaml_event_sequence_style;
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_SEQUENCE_END_EVENT()) {
            $hash{name} = 'sequence_end_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_MAPPING_START_EVENT()) {
            $hash{name} = 'mapping_start_event';
            $hash{style} = $self->yaml_event_mapping_style;
            if (my $anchor = $self->yaml_event_mapping_anchor) {
                $hash{anchor} = $anchor;
            }
            if (my $tag = $self->yaml_event_mapping_anchor) {
                $hash{tag} = $tag;
            }
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_MAPPING_END_EVENT()) {
            $hash{name} = 'mapping_end_event';
        }
        return \%hash;
    }
    sub as_string {
        my ($self) = @_;
        my $str = sprintf "(%2d) ",
            $self->type;
        if ($self->type == LibYAML::FFI::event_type::YAML_STREAM_START_EVENT()) {
            $str .= "+STR";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_STREAM_END_EVENT()) {
            $str .= "-STR";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_DOCUMENT_START_EVENT()) {
            $str .= "+DOC";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_DOCUMENT_END_EVENT()) {
            $str .= "-DOC";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_ALIAS_EVENT()) {
            $str .= "=ALI";
            $str .= " " . $self->data->alias->anchor_str;
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_SCALAR_EVENT()) {
            my $scalar = $self->data->scalar;
            my $val = $scalar->value_str;
            my $anchor = $scalar->anchor;
            my $length = $scalar->length;
            my $plain_implicit = $scalar->plain_implicit;
            $str .= sprintf "=VAL >%s< (%d) plain_implicit: %d", $val, $length, $plain_implicit;
            $scalar = $self->data->scalar;
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_SEQUENCE_START_EVENT()) {
            my $style = $self->data->sequence_start->style;
            $str .= "+SEQ";
            if ($style == LibYAML::FFI::YamlSequenceStyle::YAML_FLOW_SEQUENCE_STYLE()) {
                $str .= " []";
            }
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_SEQUENCE_END_EVENT()) {
            $str .= "-SEQ";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_MAPPING_START_EVENT()) {
            my $style = $self->data->sequence_start->style;
            $str .= "+MAP";
            if ($style == LibYAML::FFI::YamlMappingStyle::YAML_FLOW_MAPPING_STYLE()) {
                $str .= " {}";
            }
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_MAPPING_END_EVENT()) {
            $str .= "-MAP";
        }
        $str = $self->start_mark . ' ' . $self->end_mark . ' ' . $str;
        return $str;
    }
    $ffi->attach( [ yaml_event_delete => 'DESTROY' ] => [ 'yaml_event_t' ] => 'void'   );
    $ffi->attach( yaml_scalar_event_initialize => [qw/
        yaml_event_t string string string int int int yaml_scalar_style_t
    /] => 'int' );
    $ffi->attach( yaml_sequence_start_event_initialize => [qw/
        yaml_event_t string string int yaml_scalar_style_t
    /] => 'int' );
    $ffi->attach( yaml_stream_start_event_initialize => [qw/
        yaml_event_t yaml_encoding_t
    /] => 'int' );
    $ffi->attach( yaml_event_type => [qw/ yaml_event_t /] => 'yaml_event_type_t' );

    $ffi->attach( yaml_event_scalar_style => [qw/ yaml_event_t /] => 'yaml_scalar_style_t' );
    $ffi->attach( yaml_event_scalar_value => [qw/ yaml_event_t /] => 'string' );
    $ffi->attach( yaml_event_scalar_anchor => [qw/ yaml_event_t /] => 'string' );
    $ffi->attach( yaml_event_scalar_tag => [qw/ yaml_event_t /] => 'string' );

    $ffi->attach( yaml_event_mapping_style => [qw/ yaml_event_t /] => 'yaml_mapping_style_t' );
    $ffi->attach( yaml_event_mapping_anchor => [qw/ yaml_event_t /] => 'string' );
    $ffi->attach( yaml_event_mapping_tag => [qw/ yaml_event_t /] => 'string' );

    $ffi->attach( yaml_event_sequence_style => [qw/ yaml_event_t /] => 'yaml_sequence_style_t' );
    $ffi->attach( yaml_event_sequence_anchor => [qw/ yaml_event_t /] => 'string' );
    $ffi->attach( yaml_event_sequence_tag => [qw/ yaml_event_t /] => 'string' );
}

package LibYAML::FFI::ParserInputString {
    FFI::C->struct( Parser_input_string => [
        start => 'opaque',
        end => 'opaque',
        current => 'opaque',
    ]);
}

package LibYAML::FFI::ParserBuffer {
    FFI::C->struct( Parser_buffer => [
        start => 'opaque',
        end => 'opaque',
        pointer => 'opaque',
        last => 'opaque',
    ]);
}

package LibYAML::FFI::ParserTokens {
    FFI::C->struct( Parser_tokens => [
        start => 'opaque',
        end => 'opaque',
        head => 'opaque',
        tail => 'opaque',
    ]);
}
package LibYAML::FFI::ParserIndents {
    FFI::C->struct( Parser_indents => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserSimpleKeys {
    FFI::C->struct( Parser_simple_keys => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserInput {
    FFI::C->union( Parser_input => [
        string => 'Parser_input_string',
        file => 'opaque',
    ]);
}

package LibYAML::FFI::ParserStates {
    FFI::C->struct( Parser_states => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserMarks {
    FFI::C->struct( Parser_marks => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserTagDirectives {
    FFI::C->struct( Parser_tag_directives => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserAliases {
    FFI::C->struct( Parser_aliases => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::TagDirective {
    FFI::C->struct( yaml_tag_directive_t => [
        handle => 'opaque',
        prefix => 'opaque',
    ]);
}

package LibYAML::FFI::VersionDirective {
    FFI::C->struct( yaml_version_directive_t => [
        major => 'int',
        minor => 'int',
    ]);
}

package LibYAML::FFI::DocumentTagDirectives {
    FFI::C->struct( document_tag_directives => [
        start => 'yaml_tag_directive_t',
        end => 'yaml_tag_directive_t',
    ]);
}

package LibYAML::FFI::YamlDocument {
    $ffi->type( 'opaque' => 'document_nodes' );
    FFI::C->struct( yaml_document_t => [
        nodes => 'document_nodes',
        version_directive => 'yaml_version_directive_t',
        tag_directives => 'document_tag_directives',
        start_implicit => 'int',
        end_implicit => 'int',
        start_mark => 'yaml_mark_t',
        end_mark => 'yaml_mark_t',
    ]);
}

package LibYAML::FFI::Parser {
    $ffi->type( 'opaque' => 'yaml_read_handler_t' );
    FFI::C->struct( yaml_parser_t => [
        error => 'yaml_error_type_t',
        problem => 'opaque',
        problem_offset => 'size_t',
        problem_value => 'int',
        problem_mark => 'yaml_mark_t',
        context => 'opaque',
        context_mark => 'yaml_mark_t',

        read_handler => 'yaml_read_handler_t',
        read_handler_data => 'opaque',

        input => 'Parser_input',
        eof => 'int',

        buffer => 'Parser_buffer',
        unread => 'size_t',
        raw_buffer => 'Parser_buffer',

        encoding => 'yaml_encoding_t',

        offset => 'size_t',
        mark => 'yaml_mark_t',

        stream_start_produced => 'int',
        stream_end_produced => 'int',
        flow_level => 'int',

        tokens => 'Parser_tokens',

        tokens_parsed => 'size_t',
        token_available => 'int',

        indents => 'Parser_indents',
        indent => 'int',
        simple_key_allowed => 'int',
        simple_keys => 'Parser_simple_keys',

        states => 'Parser_states',
        state => 'yaml_parser_state_t',
        marks => 'Parser_marks',

        tag_directives => 'Parser_tag_directives',

        aliases => 'Parser_aliases',

        document => 'yaml_document_t',
    ]);

    $ffi->attach( [ yaml_parser_delete => 'DESTROY' ] => [ 'yaml_parser_t' ] => 'void'   );

    $ffi->attach( yaml_parser_initialize => [qw/
        yaml_parser_t
    /] => 'int' );
    $ffi->attach( yaml_parser_set_input_string => [qw/
        yaml_parser_t string size_t
    /] => 'void' );
    $ffi->attach( yaml_parser_parse => [qw/
        yaml_parser_t yaml_event_t
    /] => 'int' );
#    $ffi->attach( yaml_parser_delete => [qw/ yaml_parser_t /] => 'void' );


}






1;
