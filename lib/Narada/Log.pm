package Narada::Log;

use warnings;
use strict;
use Carp;

our $VERSION = 'v1.4.4';

# update DEPENDENCIES in POD & Build.PL & README
use Narada::Config qw( get_config_line );
use Log::Fast;


if (-f 'config/version') {
    _init_log();
}


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

=encoding utf8

=head1 NAME

Narada::Log - setup project log


=head1 VERSION

This document describes Narada::Log version v1.4.4


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

Alex Efros  C<< <powerman@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2008-2015 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
