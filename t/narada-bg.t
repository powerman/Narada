use t::share; guard my $guard;
use Time::HiRes qw( sleep );


my $pfx = sprintf 'some_script_%d_%d_', time, $$;
my $fpfx = cwd().'/'.$pfx;
for (1 .. 3) {
    my $script = path($pfx.$_);
    $script->spew("#!/bin/sh\nsleep 5");
    $script->chmod(0755);
}


stderr_like { isnt system('narada-bg'), 0, 'no params' } qr/usage/msi, 'got usage';

is   system("./\Q${pfx}\E1 &"),                             0, '1 started';
is   system("narada-bg ./\Q${pfx}\E2 &"),                   0, '2 started';
is   system("narada-bg ./\Q${pfx}\E3 &"),                   0, '3 started';
sleep 0.5;
is   system("pgrep -x -f '/bin/sh ./${pfx}1' >/dev/null"),  0, '1 is running';
is   system("pgrep -x -f '/bin/sh ${fpfx}2' >/dev/null"),   0, '2 is running';
is   system("pgrep -x -f '/bin/sh ${fpfx}3' >/dev/null"),   0, '3 is running';
is   system('narada-bg-killall'),                           0, 'narada-bg-killall';
sleep 0.5;
is   system("pgrep -x -f '/bin/sh ./${pfx}1' >/dev/null"),  0, '1 is running';
isnt system("pgrep -x -f '/bin/sh ${fpfx}2' >/dev/null"),   0, '2 is not running';
isnt system("pgrep -x -f '/bin/sh ${fpfx}3' >/dev/null"),   0, '3 is not running';
chdir 'tmp' or die "chdir(tmp): $!";
is   system('fuser -k .. >/dev/null 2>&1'),                 0, 'kill processes using .';
chdir '..' or die "chdir(..): $!";

stderr_like { isnt system('narada-bg-killall 1'), 0, 'too many params' } qr/usage/msi, 'got usage';


done_testing();
