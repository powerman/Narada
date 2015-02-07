package Narada::Config;

use warnings;
use strict;
use Carp;

our $VERSION = 'v1.4.5';

# update DEPENDENCIES in POD & Build.PL & README
use Perl6::Export::Attrs;
use File::Temp qw( tempfile );

use constant MAXPERM => 0666; ## no critic (ProhibitLeadingZeros)

my $VAR_NAME = qr{\A(?:(?![.][.]?/)[\w.-]+/)*[\w.-]+\z}xms;


sub get_config :Export {
    my ($var) = @_;
    croak 'Usage: get_config(NAME)' if @_ != 1;
    $var =~ /$VAR_NAME/xms              or croak "bad config: $var";
    -f "config/$var"                    or croak "no such config: $var";
    open my $cfg, '<', "config/$var"    or die "open(config/$var): $!\n";
    local $/ = undef;
    my $val = <$cfg>;
    close $cfg                          or die "close: $!\n";
    return $val;
}

sub get_config_line :Export {
    my ($val) = get_config(@_);
    $val =~ s/\n\s*\z//xms;
    croak 'config contain more than one line' if $val =~ /\n/xms;
    return $val;
}

sub get_db_config :Export {
    my %db;
    $db{db} = eval { get_config_line('db/db') };
    if (!defined $db{db} || !length $db{db}) {
        return;
    }
    $db{login}= get_config_line('db/login');
    $db{pass} = get_config_line('db/pass');
    $db{host} = eval { get_config_line('db/host') } || q{};
    $db{port} = eval { get_config_line('db/port') } || q{};
    $db{dsn_nodb}  = 'dbi:mysql:';
    $db{dsn_nodb} .= ';host='.$db{host} if $db{host}; ## no critic
    $db{dsn_nodb} .= ';port='.$db{port} if $db{port}; ## no critic
    $db{dsn} = $db{dsn_nodb}.';database='.$db{db};
    return \%db;
}

sub set_config :Export {
    my ($var, $val) = @_;
    croak 'Usage: set_config(NAME, VALUE)' if @_ != 2;
    $var =~ /$VAR_NAME/xms              or croak "bad config: $var";
    my ($fh, $filename) = tempfile();
    print {$fh} $val;
    close $fh                           or die "close: $!\n";
    system("mkdir -p \$(dirname config/$var)") == 0
                                        or die "mkdir: $!\n";
    rename $filename, "config/$var"     or die "rename to config/${var}: $!\n";
    chmod MAXPERM & ~umask, "config/$var"  or die "chmod config/${var}: $!\n";
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Narada::Config - manage project configuration


=head1 VERSION

This document describes Narada::Config version v1.4.5


=head1 SYNOPSIS

    use Narada::Config;

    my $version = get_config_line("version");
    my $exclude = get_config("backup/exclude");
    set_config("log/output", "/dev/stderr");

    my $db = get_db_config();
    my $dbh = DBI->connect($db->{dsn}, $db->{login}, $db->{pass});


=head1 DESCRIPTION

Project's configuration keept in files under directory 'config/' in
project root directory. Usually single file contain value for single
variable (variable name is file name itself).

While it's possible to manage project configuration with reading/writing
to these files, this module provide easier way to do this.


=head1 INTERFACE 

=over

=item B<get_config>( VARIABLE_NAME )

VARIABLE_NAME must contain only [/A-Za-z0-9._-].
It must not contain "./" or "../".

Return: contents of file 'config/VARIABLE_NAME' as scalar.

=item B<get_config_line>( VARIABLE_NAME )

Suitable for reading files which contain single string (with/without \n at end).

VARIABLE_NAME must contain only [/A-Za-z0-9._-].
It must not contain "./" or "../".

Return: contents of file 'config/VARIABLE_NAME' as scalar without last \n
(if any). Raise exception if file contain more than one line.

=item B<get_db_config>()

Helper for reading database configuration from C<config/db/*>.

Return: nothing if database not configured, or hashref with keys:

    {db}        contents of config/db/db
    {login}     contents of config/db/login
    {pass}      contents of config/db/pass
    {host}      contents of config/db/host
    {port}      contents of config/db/port
    {dsn_nodb}  'dbi:mysql:;host=$host;port=$port'
    {dsn}       'dbi:mysql:;host=$host;port=$port;database=$db'

=item B<set_config>( VARIABLE_NAME, VARIABLE_VALUE )

See limitation for VARIABLE_VALUE above.

Atomically write VARIABLE_VALUE (scalar) to file 'config/VARIABLE_NAME'.
If 'config/VARIABLE_NAME' doesn't exist it will be created (including
parent directories if needed).

Return: nothing.

=back


=head1 DIAGNOSTICS

=over

=item C<< bad config: %s >>

Thrown by set_config() and get_config() on wrong VARIABLE_NAME.

=item C<< no such config: %s >>

Thrown by get_config() if file 'config/VARIABLE_NAME' doesn't exist.

=item C<< open(config/%s): %s >>

=item C<< close: %s >>

=item C<< rename to config/%s: %s >>

Internal errors.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Narada::Config requires configuration files and directories provided by
Narada framework.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/Narada/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/Narada>

    git clone https://github.com/powerman/Narada.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Narada>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Narada>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Narada>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Narada>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Narada>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2015 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut