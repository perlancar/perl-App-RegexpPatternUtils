package App::RegexpPatternUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Regexp::Pattern;

our %SPEC;

our %args_common_pattern = (
    pattern => {
        summary => "Name of pattern, with module prefix but without the 'Regexp::Pattern'",
        schema => 'regexppattern::name*',
        req => 1,
        pos => 0,
    },
    gen_args => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'gen_arg',
        summary => 'Supply generator arguments',
        description => <<'_',

If pattern is a dynamic pattern (generated on-demand) and the generator requires
some arguments, you can supply them here.

_
        cmdline_aliases => {A=>{}},
        schema => ['hash*', of=>'str*'],
    },
);

our %args_common_get_pattern = (
    %args_common_pattern,
    anchor => {
        summary => 'Generate an anchored version of the pattern',
        schema => 'bool*',
    },
);

$SPEC{get_regexp_pattern_pattern} = {
    v => 1.1,
    summary => 'Get a Regexp::Pattern::* pattern',
    args => {
        %args_common_pattern,
    },
    examples => [
        {
            args => {pattern=>'YouTube/video_id'},
        },
        {
            summary=>"Generate variant A of Example::re3",
            argv => ['Example::re3', '--gen-arg', 'variant=A'],
        },
        {
            summary=>"Generate variant B of Example::re3",
            argv => ['Example::re3', '--gen-arg', 'variant=B'],
        },
    ],
    links => [
    ],
};
sub get_regexp_pattern_pattern {
    my %args = @_;

    my $name = $args{pattern};
    $name =~ s!(/|\.)!::!g;

    my $re = re($name, $args{gen_args} // {});

    if (-t STDOUT && $args{-cmdline} &&
            ($args{-cmdline_r}{format} // 'text') =~ /text/) {
        require Data::Dump::Color;
        return [200, "OK", Data::Dump::Color::dump($re) . "\n",
                {'cmdline.skip_format'=>1}];
    } else {
        return [200, "OK", "$re"];
    }
}

$SPEC{list_regexp_pattern_modules} = {
    v => 1.1,
    summary => 'List all installed Regexp::Pattern::* modules',
};
sub list_regexp_pattern_modules {
    require Module::List::Tiny;

    my $res = Module::List::Tiny::list_modules(
        'Regexp::Pattern::', {list_modules=>1, recurse=>1});
    my @rows;
    for (sort keys %$res) {
        s/\ARegexp::Pattern:://;
        push @rows, $_;
    }
    [200, "OK", \@rows];
}

$SPEC{match_with_regexp_pattern} = {
    v => 1.1,
    summary => 'Match a string against a Regexp::Pattern pattern',
    args => {
        %args_common_get_pattern,
        string => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
        captures => {
            summary => 'Return array of captures instead of just a boolean status',
            schema => 'bool*',
        },
        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },
    examples => [
        {
            summary => 'A non-match',
            args => {pattern=>'YouTube/video_id', string=>'foo'},
        },
        {
            summary => 'A match',
            args => {pattern=>'YouTube/video_id', string=>'Yb4EGj4_uS0'},
        },
    ],
    links => [
        {url=>'prog:get-regexp-pattern-pattern'},
        {url=>'prog:rpgrep'},
    ],
};
sub match_with_regexp_pattern {
    my %args = @_;

    my $name = $args{pattern};
    $name =~ s!(/|\.)!::!g;

    my %gen_args = %{ $args{gen_args} // {} };
    $gen_args{-anchor} = 1 if $args{anchor};

    my $re = re($name, \%gen_args);

    my $matches;
    my @captures;
    if ($args{string} =~ $re) {
        $matches = 1;
        if ($args{captures}) {
            # for perls that do not have @{^CAPTURE}
            for (1..@- - 1) {
                push @captures, ${$_};
            }
        }
    }

    my $msg = "String ".($matches ? "matches" : "DOES NOT match")." regexp pattern $name";
    [
        200, "OK",
        $args{captures} ? \@captures : $args{quiet} ? undef : $msg,
        {"cmdline.exit_code"=>$matches ? 0:1},
    ];
}

1;
# ABSTRACT: CLI utilities related to Regexp::Pattern

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to L<Regexp::Pattern>:

#INSERT_EXECS_LIST
