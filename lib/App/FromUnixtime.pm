package App::FromUnixtime;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use IO::Interactive::Tiny;
use POSIX qw/strftime/;
use Config::CmdRC qw/.from_unixtimerc/;

our $VERSION = '0.08';

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
    _get_options($config, \@argv);

    _main($config);
}

sub _main {
    my $config = shift;

    if ( ! IO::Interactive::Tiny::is_interactive(*STDIN) ) {
        while ( my $line = <STDIN> ) {
            chomp $line;
            if ( my $match = _may_replace($line, $config) ) {
                _from_unixtime($match => \$line, $config);
            }
            print "$line\n";
        }
    }
    else {
        for my $unixtime (@{$config->{unixtime}}) {
            _from_unixtime($unixtime => \$unixtime, $config);
            print "$unixtime\n";
        }
    }
}

sub _may_replace {
    my ($line, $config) = @_;

    if ($line =~ m!(?:$MAYBE_UNIXTIME)[^\d]*(\d+)!
                || ($config->{_re} && $line =~ m!(?:$config->{_re})[^\d]*(\d+)!)
                || $line =~ m!^[\s\t\r\n]*(\d+)[\s\t\r\n]*$!
    ) {
        return $1;
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

sub _get_options {
    my ($config, $argv) = @_;

    GetOptionsFromArray(
        $argv,
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

    _validate_options($config, $argv);
}

sub _validate_options {
    my ($config, $argv) = @_;

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
    push @{$config->{unixtime}}, @{$argv};
}

sub _show_usage {
    my $exitval = shift;

    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval => $exitval);
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
