use strict;
use warnings;
use Module::Build;

die "Windows not supported\n" if $^O =~ /Win/;

# WARNING:  Empty directories in skel/ MUST contain .keep file to force
#           inclusion of these directories in MANIFEST and module distribution.
#           These files will not be installed by `narada-new`.

my $class = Module::Build->subclass(
    class => 'Module::Build::Custom',
    code => <<'SUBCLASS' );

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
    close $f;
    system("find skel/ -type f -exec chmod u+w {} +");
    system("tar cf - -C skel --exclude .keep ./ | base64 >> \Q$filename\E");
    my ($atime, $mtime) = (stat($script))[8,9];
    utime $atime, $mtime, $filename or die "utime: $!";
    rename $filename, $script or die "rename: $!";
    chmod 0755, $script or die "chmod: $!";
    return;
}

sub dist_version {
    my $self = shift;
    my $v = $self->SUPER::dist_version;
    $v =~ s/\Av//ms;
    return $v;
}
SUBCLASS

my $builder = $class->new(
    module_name         => 'Narada',
    license             => 'perl',
    dist_author         => 'Alex Efros <powerman-asdf@ya.ru>',
    requires => {
        'perl'                  => '5.10.0',
        'version'               => '0.77',
        'Test::Differences'     => 0,
        'Test::Exception'       => 0,
        'Test::MockModule'      => 0,
        'Perl6::Export::Attrs'  => 0,
        'Log::Fast'             => 0,
        'DBI'                   => 0,
    },
    recommends => {
        'Test::CheckManifest'   => '0.9',
        'Test::Perl::Critic'    => 0,
        'Test::Pod::Coverage'   => '1.08',
        'Pod::Coverage'         => '0.18',
        'Test::Pod'             => '1.22',
    },
    add_to_cleanup      => [ 'Narada-*' ],
);
$builder->create_build_script;

my ($db, $login, $pass) = (q{}, q{}, q{});
$db = $builder->prompt("\nEnter NON-EXISTING database name (empty to skip test):", 'test_nosuch');
if ($db ne q{}) {
    $login = $builder->prompt("Enter login for database '$db':", 'test');
    $pass  = $builder->prompt("Enter pass for login '$login':", '');
}
open my $f, '> t/.answers' or die "open: $!";
printf {$f} "%s\n%s\n%s\n", $db, $login, $pass;
close $f or die "close: $!";

