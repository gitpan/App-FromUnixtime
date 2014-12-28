package App::FromUnixtime;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use POSIX qw/strftime/;

our $VERSION = '0.01';

our $MAYBE_UNIXTIME = join '|', (
    'created_(?:at|on)',
    'updated_(?:at|on)',
    'date',
    'unixtime',
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
        if ($line =~ m!(?:$MAYBE_UNIXTIME)!) {
            $line =~ s/(\d+)/&_from_unixtime($1, $config)/eg;
        }
        print "$line\n";
    }
}

sub _from_unixtime {
    my ($maybe_unixtime, $config) = @_;

    if ($maybe_unixtime > 2**31-1) {
        return $maybe_unixtime;
    }

    my $date = eval { strftime($config->{format}, localtime($maybe_unixtime)) };
    return $@ ? $maybe_unixtime : "$maybe_unixtime($date)";
}

sub _merge_opt {
    my ($config, @argv) = @_;

    GetOptionsFromArray(
        \@argv,
        'f|format=s'    => \$config->{format},
        'h|help'        => sub {
            _show_usage(1);
        },
        'v|version'   => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or _show_usage(2);

    $config->{format} ||= $DEFAULT_DATE_FORMAT;
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
