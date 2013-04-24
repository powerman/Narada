package Narada::Log;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('1.3.0');

# update DEPENDENCIES in POD & Build.PL & README
use Narada::Config qw( get_config_line );
use Log::Fast;


_init_log();


sub import {
    my @args = @_;
    my $pkg = caller 0;
    no strict 'refs';
    for (@args) {
        next if !m/\A\$(.*)/xms;
        *{$pkg.q{::}.$1} = \Log::Fast->global();
    }
    return;
}

sub _init_log {
    my $type = eval { get_config_line('log/type') } || 'syslog';
    my $path = get_config_line('log/output');
    if ($type eq 'syslog') {
        Log::Fast->global()->config({
            level   => get_config_line('log/level'),
            prefix  => q{},
            type    => 'unix',
            path    => $path,
        });
    }
    elsif ($type eq 'file') {
        open my $fh, '>>', $path or croak "open: $!"; ## no critic (InputOutput::RequireBriefOpen)
        Log::Fast->global()->config({
            level   => get_config_line('log/level'),
            prefix  => q{},
            type    => 'fh',
            fh      => $fh,
        });
    }
    else {
        croak "unsupported value '$type' in config/log/type";
    }
    return;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Narada::Log - setup project log


=head1 VERSION

This document describes Narada::Log version 1.3.0


=head1 SYNOPSIS

    use Narada::Log qw( $LOG );

    $LOG->INFO("ready to work");


=head1 DESCRIPTION

While loading, this module will configure Log::Fast->global() object
according to configuration in C<config/log/type>, C<config/log/output> and
C<config/log/level>.

If any scalar variable names will be given as parameters while loading
module it will export Log::Fast->global() as given variable names.

See L<Log::Fast> for more details.


=head1 INTERFACE 

None.


=head1 DIAGNOSTICS

=over

=item C<< open: %s >>

File config/log/output contain file name, and error happens while trying to
open this file.


=back


=head1 CONFIGURATION AND ENVIRONMENT

Narada::Log requires configuration files and directories provided by
Narada framework.


=head1 DEPENDENCIES

 Log::Fast


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-narada@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Alex Efros  C<< <powerman.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2013 Alex Efros C<< <powerman.org> >>. All rights reserved.

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
