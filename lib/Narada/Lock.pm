package Narada::Lock;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('1.3.4');

# update DEPENDENCIES in POD & Build.PL & README
use Time::HiRes qw( sleep );
use Perl6::Export::Attrs;
use Fcntl qw(:DEFAULT :flock F_SETFD FD_CLOEXEC);
use Errno;


use constant LOCKNEW    => 'var/.lock.new';
use constant LOCKFILE   => 'var/.lock';
use constant TICK       => 0.1;
my $f_lock;

sub shared_lock :Export {
    my $timeout = shift;
    return 1 if $ENV{NARADA_SKIP_LOCK};
    sysopen $f_lock, LOCKFILE, O_RDONLY|O_CREAT         or croak "open: $!";
    while (1) {
        next            if -e LOCKNEW;
        last            if flock $f_lock, LOCK_SH|LOCK_NB;
        $!{EWOULDBLOCK}                                 or croak "flock: $!";
    } continue {
        return          if defined $timeout and (($timeout-=TICK) < TICK);
        sleep TICK;
    }
    return 1;
}

sub exclusive_lock :Export {
    return if $ENV{NARADA_SKIP_LOCK};
    sysopen $f_lock, LOCKFILE, O_WRONLY|O_CREAT         or croak "open: $!";
    while (1) {
        last if flock $f_lock, LOCK_EX|LOCK_NB;
        $!{EWOULDBLOCK}                                 or croak "flock: $!";
        system('touch', LOCKNEW) == 0                   or croak "touch: $!/$?";
        sleep TICK;
    }
    system('touch', LOCKNEW) == 0                       or croak "touch: $!/$?";
    return;
}

sub unlock_new :Export {
    return if $ENV{NARADA_SKIP_LOCK};
    unlink LOCKNEW;
    return;
}

sub unlock :Export {
    return if $ENV{NARADA_SKIP_LOCK};
    if ($f_lock) {
        flock $f_lock, LOCK_UN                          or croak "flock: $!";
    }
    return;
}

sub child_inherit_lock :Export {
    my ($is_inherit) = @_;
    return if $ENV{NARADA_SKIP_LOCK};
    if ($f_lock) {
        fcntl $f_lock, F_SETFD, $is_inherit ? 0 : FD_CLOEXEC or croak "fcntl: $!";
    }
    return;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Narada::Lock - manage project locks


=head1 VERSION

This document describes Narada::Lock version 1.3.4


=head1 SYNOPSIS

    use Narada::Lock qw( shared_lock unlock child_inherit_lock );
    use Narada::Lock qw( exclusive_lock unlock_new unlock );

    shared_lock();
    unlock();
    shared_lock(0) or die "can't get lock right now";
    unlock();
    shared_lock(5) or die "can't get lock in 5 seconds";
    unlock();

    shared_lock();
    system('sleep 1');
    child_inherit_lock(1);
    system('sleep 10 &');
    child_inherit_lock(0);
    system('sleep 1');
    unlock();

    exclusive_lock();
    # do critical operations, reboot-safe
    unlock_new();
    # do non-critical operations, still in exclusive mode
    unlock();


=head1 DESCRIPTION

To allow safe backup/update/maintenance of project, there should be
possibility to guarantee consistent state of project, at some point.
To reach this goal, ALL operations which modify project data on disk
(including both project files and database) must be done under shared lock,
and all operations which require consistent project state must be done
under exclusive lock.

This module contain helper functions to manage project locks, but all
operations required for these locks can be implemented using any
programming language, so all applications in project (including non-perl
applications) are able to manage project locks.

Shared lock is set using flock(2) LOCK_SH on file 'var/.lock'.
Exclusive lock is set using flock(2) LOCK_EX on file 'var/.lock'.

=head2 FREEZE NEW TASKS

There exists scenario when it's impossible to set exclusive lock:
if new tasks will start and set shared lock before old tasks will drop shared
lock (and so shared lock will be set all of time).

To work around this scenario another file 'var/.lock.new' should be used
as semaphore - it should be created before trying to set exclusive lock,
and new tasks shouldn't try to set shared lock while this file exists.

This file should be removed after finishing critical operations - this
guarantee project data will not change even if system will be rebooted,
because after reboot existence of file 'var/.lock.new' will prevent from
starting new tasks with shared locks but not prevent from placing
exclusive lock again and continue these critical operations.


=head1 INTERFACE 

=over

=item B<shared_lock>( $timeout )

Try to get shared lock which is required to modify any project data (files or
database).

If $timeout undefined - will wait forever until lock will be granted.
If $timeout >=1 will try to get lock every 1 second until $timeout expire.

Use unlock() to free this lock.

Return: true if able to get lock.


=item B<exclusive_lock>()

Try to get exclusive lock which is required to guarantee consistent project
state (needed while backup/update/maintenance operations).

Set two locks: create file 'var/.lock.new' which signal other scripts to
not try to set shared lock while this file exists and get LOCK_EX on file
'var/.lock' to be sure all current tasks finished and unlocked their
shared locks.

Will delay until get lock.

Use unlock_new() in combination with exit() or unlock() to free these locks.

Return: nothing.


=item B<unlock_new>()

Free first lock set by exclusive_lock() (i.e. remove file 'var/.lock.new').
This allow other tasks to get shared_lock() after this process exit or
call unlock().

Return: nothing.


=item B<unlock>()

Free lock set by shared_lock() (or second lock set by exclusive_lock()).

Return: nothing.


=item B<child_inherit_lock>( $is_inherit )

By default, child processes don't inherit our FD with lock.
This is acceptable only if we don't run child in background or if
child will get own locks on start.

In other cases you should call child_inherit_lock() with true value in
$is_inherit to force child to inherit our lock (just like djb's `setlock`
or Pepe's `chpst -[lL]` do).
Calling child_inherit_lock() with false value in $is_inherit will switch
back to default behaviour (new child will not inherit FD with lock).

Examples:

 # OK: not in background
 system("rm -rf var/something");

 # OK: in background, but this is our script,
 # which will get lock on it's own
 system("./another_script_of_this_project &");

 # ERROR: in background, no lock
 system("( sleep 5; rm -rf var/something ) &");

 # OK: in background, inherit lock
 child_inherit_lock(1); # from now all childs will inherit lock
 system("( sleep 5; rm -rf var/something ) &");
 child_inherit_lock(0); # next child will not inherit lock

Return: nothing.


=back


=head1 DIAGNOSTICS

=over

=item C<< open: %s >>

=item C<< flock: %s >>

=item C<< fcntl: %s >>

=item C<< touch: %s >>

Probably directory 'var/' or files 'var/.lock' and 'var/.lock.new' doesn't
exists or has wrong permissions.


=back


=head1 CONFIGURATION AND ENVIRONMENT

Narada::Lock requires configuration files and directories provided by
Narada framework.

If $ENV{NARADA_SKIP_LOCK} is set to any true value then shared_lock(),
exclusive_lock(), unlock_new(), unlock() and child_inherit_lock() will do
nothing (shared_lock() will return true).


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
