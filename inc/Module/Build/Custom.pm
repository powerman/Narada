package Module::Build::Custom;
use strict;
use warnings;
use parent 'Module::Build';

my $TAR = (grep {-x "$_/gtar"} split /:/, $ENV{PATH}) ? 'gtar' : 'tar';
for my $cmd (qw( bash find chmod ), $TAR) {
    if (!grep {-x "$_/$cmd"} split /:/, $ENV{PATH}) {
        die "command not found: $cmd\n"
    }
}
die "GNU tar required\n" if `$TAR --version` !~ /GNU/ms;

# WARNING:  Empty directories in skel/ MUST contain .keep file to force
#           inclusion of these directories in MANIFEST and module distribution.
#           These files will not be installed by `narada-new`.

sub new {
    my $self = shift->SUPER::new(@_);
    $self->_prompt_db();
    return $self;
}

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build;
    print "Forcing skel/var/patch/ChangeLog to be symlink ...\n";
    unlink 'skel/var/patch/ChangeLog';
    symlink '../../doc/ChangeLog', 'skel/var/patch/ChangeLog' or die "symlink: $!";
    $self->_inject_skel('blib/script/narada-new');
}

sub _inject_skel {
    my ($self, $script) = @_;
    print "Injecting skel/ into $script ...\n";
    use File::Temp qw( mktemp );
    my $new = `cat \Q$script\E`;
    $new =~ s/\s*(^__DATA__\n.*)?\z/\n\n__DATA__\n/ms;
    my $filename = mktemp("$script.XXXXXXXX");
    open my $f, '>', $filename or die "open: $!";
    print {$f} $new;
    system("find skel/ -type f -exec chmod u+w {} +")
        == 0 or die "system: $?\n";
    my $TAR = (grep {-x "$_/gtar"} split /:/, $ENV{PATH}) ? 'gtar' : 'tar';
    open my $tar, '-|', $TAR.' cf - -C skel --exclude .keep ./' or die "open: $!";
    use MIME::Base64;
    local $/;
    print {$f} encode_base64(<$tar>);
    close $f or die "close: $!";
    my ($atime, $mtime) = (stat($script))[8,9];
    utime $atime, $mtime, $filename or die "utime: $!";
    rename $filename, $script or die "rename: $!";
    chmod 0755, $script or die "chmod: $!";
    return;
}

sub _prompt_db {
    my $self= shift;

    my $db  = ($ENV{TEST_MYSQL_DB} // 'test') . '_narada';
    my $user= $ENV{TEST_MYSQL_USER} // q{};
    my $pass= $ENV{TEST_MYSQL_PASS} // q{};

    my $auth= "-u \Q$user\E" . ($pass ne q{} ? " -p\Q$pass\E" : q{});
    if (`mysql $auth \Q$db\E </dev/null 2>&1` !~ /Unknown database/ms) {
        $db = $self->prompt("\nEnter NON-EXISTING database name (empty to skip test):", $db);
        $db =~ s/\s+//msg;
        if ($db ne q{} && $user eq q{}) {
            $user = $self->prompt("Enter username for database '$db':", 'test');
            $pass = $self->prompt("Enter password for username '$user':", q{});
        }
    }

    open my $f, '> t/.answers' or die "open: $!";
    printf {$f} "%s\n%s\n%s\n", $db, $user, $pass;
    close $f or die "close: $!";

    return;
}


1;
