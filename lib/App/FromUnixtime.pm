package App::FromUnixtime;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use POSIX qw/strftime/;
use Config::CmdRC qw/.from_unixtimerc/;

our $VERSION = '0.07';

our $MAYBE_UNIXTIME = join '|', (
    'created_(?:at|on)',
    'updated_(?:at|on)',
    'date',
    'unixtime',
    '_time',
);

our $DEFAULT_DATE_FORMAT = '%a, %d %b %Y %H:%M:%S %z';

sub run {
    my $self = shift;
    my @argv = @_;

    my $config = +{};
    _merge_opt($config, @argv);

    _main($config);
}

sub _main {
    my $config = shift;

    while ( my $line = <STDIN> ) {
        chomp $line;
        if ($line =~ m!(?:$MAYBE_UNIXTIME)[^\d]*(\d+)!
                || ($config->{_re} && $line =~ m!(?:$config->{_re})[^\d]*(\d+)!)
                || $line =~ m!^[\s\t\r\n]*(\d+)[\s\t\r\n]*$!
        ) {
            _from_unixtime($1 => \$line, $config);
        }
        print "$line\n";
    }
}

sub _from_unixtime {
    my ($maybe_unixtime, $line_ref, $config) = @_;

    if ($maybe_unixtime > 2**31-1) {
        return;
    }

    my $date = strftime($config->{format}, localtime($maybe_unixtime));
    my $replaced_unixtime = sprintf(
        "%s%s%s%s",
        $maybe_unixtime,
        $config->{'start-bracket'},
        $date,
        $config->{'end-bracket'},
    );

    $$line_ref =~ s/$maybe_unixtime/$replaced_unixtime/;
}

sub _merge_opt {
    my ($config, @argv) = @_;

    _get_options($config, @argv);
    _validate_options($config);
}

sub _get_options {
    my ($config, @argv) = @_;

    GetOptionsFromArray(
        \@argv,
        'f|format=s'      => \$config->{format},
        'start-bracket=s' => \$config->{'start-bracket'},
        'end-bracket=s'   => \$config->{'end-bracket'},
        're=s@'           => \$config->{re},
        'h|help' => sub {
            _show_usage(1);
        },
        'v|version' => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or _show_usage(2);
}

sub _validate_options {
    my ($config) = @_;

    $config->{format} ||= RC->{format} || $DEFAULT_DATE_FORMAT;
    $config->{'start-bracket'} ||= RC->{'start-bracket'} || '(';
    $config->{'end-bracket'}   ||= RC->{'end-bracket'}   || ')';
    if (ref RC->{re} eq 'ARRAY') {
        push @{$config->{re}}, @{RC->{re}};
    }
    elsif (RC->{re}) {
        push @{$config->{re}}, RC->{re};
    }
    if ($config->{re}) {
        $config->{_re} = join '|', map { quotemeta $_;  } @{$config->{re}};
    }
}

sub _show_usage {
    my $exitval = shift;

    require Pod::Usage;
    Pod::Usage::pod2usage($exitval);
}

1;

__END__

=head1 NAME

App::FromUnixtime - to convert from unixtime to date suitably


=head1 SYNOPSIS

    use App::FromUnixtime;

    App::FromUnixtime->run(@ARGV);


=head1 DESCRIPTION

See the L<from_unixtime> command for more detail.


=head1 METHOD

=head2 run

run to convert process


=head1 REPOSITORY

App::FromUnixtime is hosted on github: L<http://github.com/bayashi/App-FromUnixtime>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<from_unixtime>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
