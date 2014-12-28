use strict;
use warnings;
use Test::More;
use Test::Output;

use App::FromUnixtime;

{
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
date        1419702037
_INPUT_
    local *STDIN = *$IN;
    stdout_like(
        sub { App::FromUnixtime->run; },
        qr/date\s+1419702037\([^\)]+\)/
    );
    close $IN;
}

{
    open my $IN, '<', \<<'_INPUT_';
id          1
name        John
created_on  1419692400
_INPUT_
    local *STDIN = *$IN;
    stdout_like(
        sub { App::FromUnixtime->run('--format' => '%Y-%m-%d %H:%M:%S'); },
        qr/created_on\s+1419692400\(\d+-\d+-\d+ \d+:\d+:\d+\)/
    );
    close $IN;
}

done_testing;
