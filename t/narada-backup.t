#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 13;
use Test::Exception;
use Test::Differences;

use File::Temp qw( tempdir );
chomp(my $cwd=`pwd`);
$ENV{PATH} = "$cwd/blib/script:$ENV{PATH}";
$ENV{PERL5LIB} ||= q{};
$ENV{PERL5LIB} = "$cwd/blib:$ENV{PERL5LIB}";

my $dir1 = narada_new();
my $dir2 = narada_new();

sub narada_new {
    my $dir = tempdir( CLEANUP => 1 );
    chdir $dir
        and system('narada-new') == 0
        or die "Unable to create project: $!";
    $dir =~ m{([^/]+)\z};
    unlink "var/patch/$1-0.0.000.tar", 'var/backup/snap'
        or die "Unable to remove backup: $!";
    return $dir;
}

sub filldir {
    my ($dir) = @_;
    system("
        cd \Q$dir\E             &&
        touch .hidden           &&
        echo ok > file          &&
        mkdir .hiddendir        &&
        mkdir dir               &&
        echo ok > dir/file      &&
        touch dir/.hidden
    ") == 0 or die "system: $?";
    return;
}

sub check_backup {
    my (@files) = @_;
    chdir tempdir( CLEANUP => 1 ) or die "chdir: $!";
    for my $file (@files) {
        system("tar -x -p -g /dev/null -f \Q$file\E &>/dev/null");
    }
    # looks like dir size on raiserfs differ and break this test (ext3 works ok)
    my $wait = `
        cd \Q$dir2\E
        find -not -path './var/patch/.prev/*' -type d -printf "%M        %p %l\n" | sort
        find -not -path './var/patch/.prev/*' -type f -printf "%M %6s %p %l\n" | sort
        `;
    my $list = `
        find -type d -printf "%M        %p %l\n" | sort
        find -type f -printf "%M %6s %p %l\n" | sort
        `;
    eq_or_diff $list, $wait, 'backup contents ok';
    return;
}


# $dir1 is test directory
# $dir2 is etalon directory
for my $dir ($dir1, $dir2) {
    filldir($dir);
    system("
        cd \Q$dir\E
        echo val > config/var   &&
        touch var/data          &&
        echo test >> var/log/current
    ") == 0 or die "system: $?";
}
filldir("$dir1/tmp/");
filldir("$dir1/var/backup/");

is system("cd \Q$dir1\E; narada-backup"), 0, 'first backup';
ok -e "$dir1/var/backup/full.tar", 'full.tar created';
ok ! -e "$dir1/var/backup/incr.tar", 'incr.tar not created';
check_backup("$dir1/var/backup/full.tar");
system("cd \Q$dir1\E; cp var/backup/full.tar tmp/full1.tar") == 0 or die "system: $?";

my $old_size = -s "$dir1/var/backup/full.tar";
is system("cd \Q$dir1\E; narada-backup"), 0, 'second backup';
ok $old_size < -s "$dir1/var/backup/full.tar", 'full.tar grow up';
ok -e "$dir1/var/backup/incr.tar", 'incr.tar created';
system("cd \Q$dir1\E; cp var/backup/incr.tar tmp/incr1.tar") == 0 or die "system: $?";

sleep 1;    # tar will detect changes based on mtime
for my $dir ($dir1, $dir2) {
    filldir("$dir/t/");
    system("
        cd \Q$dir\E         &&
        rm config/var       &&
        rmdir .hiddendir    &&
        chmod 0712 var/data
    ");
}
filldir("$dir1/var/patch/.prev/");
system("cd \Q$dir1\E && rm tmp/file && rmdir tmp/.hiddendir");

is system("cd \Q$dir1\E; narada-backup"), 0, 'third backup';
system("cd \Q$dir1\E; cp var/backup/incr.tar tmp/incr2.tar") == 0 or die "system: $?";
check_backup("$dir1/var/backup/full.tar");
check_backup("$dir1/tmp/full1.tar", "$dir1/tmp/incr1.tar", "$dir1/tmp/incr2.tar");

unlink "$dir1/var/backup/full.tar";
is system("cd \Q$dir1\E; narada-backup"), 0, 'force full backup';
ok -e "$dir1/var/backup/full.tar", 'full.tar created';
ok ! -e "$dir1/var/backup/incr.tar", 'incr.tar not created';

chdir '/';  # work around warnings in File::Temp CLEANUP handler
