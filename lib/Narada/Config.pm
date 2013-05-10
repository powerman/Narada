package Narada::Config;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('1.3.4');

# update DEPENDENCIES in POD & Build.PL & README
use Perl6::Export::Attrs;
use File::Temp qw( tempfile );

use constant MAXPERM => 0666; ## no critic (ProhibitLeadingZeros)

my $VAR_NAME = qr{\A(?:(?![.][.]?/)[\w.-]+/)*[\w.-]+\z}xms;


sub get_config :Export { ## no critic (RequireArgUnpacking)
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

sub get_config_line :Export { ## no critic (RequireArgUnpacking)
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

sub set_config :Export { ## no critic (RequireArgUnpacking)
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

=head1 NAME

Narada::Config - manage project configuration


=head1 VERSION

This document describes Narada::Config version 1.3.4


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


=head1 DEPENDENCIES

 Perl6::Export::Attrs


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-narada@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Alex Efros  C<< <powerman@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2013 Alex Efros C<< <powerman@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
