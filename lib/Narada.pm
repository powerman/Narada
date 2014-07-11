package Narada;

use warnings;
use strict;

use version; our $VERSION = qv('1.3.10');

1; # Magic true value required at end of module
__END__

=head1 NAME

Narada - framework for ease development/deploy/support for medium/big projects


=head1 VERSION

This document describes Narada version 1.3.10


=head1 SYNOPSIS

    # Run narada-* commands.
    # In perl scripts either use Narada::* modules or manually
    # conform Narada interface.
    # In non-perl applications just conform Narada interface.


=head1 DESCRIPTION

Narada designed for ease development, deploy and support for medium and
big projects. It's main goal is to restrict you with B<one way to manage>
your project (which doesn't really depend on your project's nature), and
doesn't restrict your project's implementation in any way. With Narada you
can create any projects using any programming languages - while your
projects conform Narada interface (and developed in *NIX - Windows not
supported).

There are few helper Narada::* modules for perl which helps you to conform
Narada interface in your perl modules/scripts; for other languages you may
want to create similar helpers, but this isn't required - Narada interface
is simple and can be easily conformed without using special helpers.

Typical example of project which wins a lot when managed by Narada is web
or network service, which consists of several scripts (which all should
have common runtime environment, logs, etc.) with different entry points
(cgi, rpc, cron, email).

=head2 Main Features

=over

=item Create files and directory structure for new project.

Project doesn't required to use database, all configuration/logs/etc. are
stored in files.

=item Different project installations have different configuration.

Changes in your local configuration won't be occasionally sent with next
update to production server.

=item Ease project setup after installation/update.

Narada provide helpers to update project environment (cron tasks, qmail
handlers, mysql scheme) according to current project's configuration.

=item Reliable services.

Run your FastCGI or RPC daemons with guaranteed restart after crash.
By default we use tools from L<http://smarden.org/runit/> for supervising
project's services, but other similar supervisors like daemontools also
can be used.

=item All project's applications have common log(s).

By default we use L<http://smarden.org/socklog2/> (syslog-compatible
daemon) to receive logs from project's applications and C<svlogd> tool
from L<http://smarden.org/runit/> to manage logs (rotate, filter, group
records in separate files, etc.).

=item All project's applications have common lock.

This guarantee live project's consistency while backup, update or manual
maintenance.

=item Basic support for team development and versioning project.

Narada make it easier to release and deploy updates on server.
Team members may merge these updates with their working copy of project.
Each update consists of several .patch, .sh, .sql and .tgz files, and can
be easily reviewed/corrected before releasing.

This feature doesn't meant as replacement for VCS - you can use or don't
use any VCS with Narada: VCS is versioning your files, while Narada is
versioning your project. But in simple cases (small team, everyone works
on mostly isolated tasks) this feature can replace needs in VCS (even then
some team members still may use VCS locally, for example to use branches).

=item Consistent and fast project backup.

Narada interface include shared/exclusive project locking, which let us
guarantee backup consistency between project files and database.

Narada backup tool support incremental backups both for files and
database, which makes it possible to backup most projects in few seconds -
your website visitors won't even notice your daily backup!

=back


=head1 INTERFACE 

Narada, as a framework, provide you with some interface (mostly it's just
conventions about some files and directories), and you B<MUST> conform to
that interface of things will break.

=over

For example, let's review interfaces related to "Consistent and fast
project backup" feature.

"Consistent" require using shared/exclusive file locking on file
C<var/.lock>. All Narada does is create that file when generate new
project and acquire exclusive lock on it while executing C<narada-backup>.
But to really have consistent backups B<you> must acquire shared lock on
that file while modifying any project files or database in any of your
scripts! In perl scripts you can use helper module L<Narada::Lock>, and
it's not a big deal to manually use flock(2) in any other language. If you
fail to do this, you backups won't be guaranteed to be consistent anymore!

"Fast" consists of two parts: files and database. To backup project files
fast you should keep large junk files according to Narada's interface -
in directories listed in C<config/backup/exclude>, for ex. in C<tmp/>.
To backup database fast you should try hard to store large amount of data
in append-only tables with auto_increment primary key, and add names of
these tables in C<config/db/dump/incremental>.

=back

New project created in separate directory using C<narada-new>.
This directory become "project root" directory (also called "project
dir"). All project applications and C<narada-*> commands must be executed
in this directory (so they will be able to find all project files/dirs
using relative path).

These directories will be created in project root:

=over

=item C<config/>

Project's configuration (both predefined by Narada and custom settings
related to your project). May differ between different installations
of this project (by default project updates include only new and deleted
settings, but not changed settings).

=item C<doc/>

Contain C<ChangeLog>. Put your documentation here.

=item C<service/>

This directory should be used to setup project's services (daemons)
and run them using service supervisor (runit, daemontools, etc.).

=item C<t/>

Put your tests here.

=item C<tmp/>

Files stored in this directory won't be included in backups and updates.

=item C<var/>

Variable files required for Narada and your project. Will be included in
backup, but not in updates.

=back

=head2 Team development and versioning project

=over

=item C<config/version>

Project name and version in flexible format: one string, which must
contain at least one digit, and doesn't contain whitespace or C</>).
Example: "App-0.1.000" (without quotes).

C<narada-new> will create this file with content "PROJECTNAME-0.0.000"
where PROJECTNAME is name of project root directory.

Last number in this string will be automatically incremented by
C<narada-release> unless this file was manually modified since previous
C<narada-release> run.

=item C<config/version.*>

Name and version of installed addons.

=item C<config/patch/send/*>

Each file contain one line with email of team member, who wanna receive
emails with project updates. Used by C<narada-patch-send>. File names are
not important, but usually they match team member's $USER.

If $NARADA_USER is set, then C<narada-new> will put it value into
C<config/patch/send/$USER>.

=item C<config/patch/exclude>

PCRE regex (one per line) for files/dirs which shouldn't be included in
project update. C<config/> directory handled in special way and shouldn't
be listed in this file.

=item C<doc/ChangeLog>

Project's change log, in standard format. C<narada-release> will ask you
to enter changes using $EDITOR and then automatically insert/update line
with date/version.

=item C<doc/ChangeLog.*>

Change logs of installed addons.

=item C<var/patch/>

Contains all project updates (patches). C<narada-diff> will create new
update candidate in this directory for manual review; C<narada-release>
will turn candidate into released update; C<narada-patch> will apply
updates found this this directory to project; etc.

=item C<var/patch/PENDING.*>

You should put into these files custom sql/sh commands which should be
included with next update.

=item C<var/patch/ChangeLog>

Symlink to C<doc/ChangeLog> for convenience.

=item C<var/patch/.mc.menu>

Shortcuts for convenience (to run C<narada-*> in project root without
leaving C<var/patch/> where you now reviewing current patch).

=item C<var/patch/.prev/>

Contains "master" copy of current project's version (VCS keeps it in .git
or .hg), for internal use by C<narada-diff>. Should never be modified
manually!

=item C<var/patch/*/>

Contains "addon" patches.

=back

=head2 Backup

=over

=item C<config/backup/exclude>

Shell patterns (one per line) for files/dirs which shouldn't be included
in backup. Must contain at least these lines:

    ./var/.lock.new     to avoid project in locked state after restore
                        from backup
    ./var/backup/*      to avoid recursively including old backups in new
    ./var/patch/.prev/* harmless, but it always can be restored by
                        applying all released updates on empty project

=item C<config/db/dump/incremental>

List of database tables (one per line) which can be dumped incrementally
(according to their auto_increment primary key field). C<narada-backup>
will dump only new records in these tables (dumps for older records will
be available in existing files in C<var/backup/> or C<var/sql/>).

=item C<config/db/dump/empty>

List of database tables (one per line) which records shouldn't be included in
backup, only scheme.

=item C<config/db/dump/ignore>

List of database tables (one per line) which shouldn't be included in
backup at all (even scheme).

=item C<var/sql/>

Contains files with last database dump (usually made while last backup).

=item C<var/backup/>

Contains helper files required for incremental backups and backups itself.

=back

=head2 Logging

=over

=item C<config/log/type>

Define type of logging: C<syslog> (default if this file not exists) or
C<file>. If set to C<syslog> then C<config/log/output> should contain path
to syslog's unix socket (like C<var/log.sock> or C</dev/log>).
C<narada-new> initialize this file with C<syslog> value.

=item C<config/log/output>

File name where project applications should write their logs: either unix
socket (to syslog-compatible daemon) or usual file (or C</dev/stdout>).
C<narada-new> initialize this file with C<var/log.sock> value.

=item C<config/log/level>

Current log level, should be one of these strings:

    ERR WARN NOTICE INFO DEBUG DUMP

C<narada-new> set it to C<DEBUG>.

=item C<service/log/>

Syslog-compatible service listening to C<var/log.sock> and saving logs
into C<var/log/>. Can be switched off only if you doesn't write logs to
C<var/log.sock>.

=item C<var/log/>

This directory contains project log files.

=back

=head2 Services

=over

=item C<service/*/>

Services (daemons) of this project.
Most projects have just one (C<log>) or two (C<log> and C<fastcgi>) services.

=back

=head2 Cron Tasks

=over

=item C<config/crontab>

Settings for project's cron tasks, in crontab format.

When these settings will be installed to system's cron, each command will
be automatically prefixed by:

    cd /path/to/project/root || exit;

C<narada-new> create it with single task - run service supervisor and thus
start all project services in C<service/*/>. This way project services
will be restarted even after OS reboot.

C<narada-setup-cron> update system's cron using settings from this file.

=back

=head2 Processing Incoming Emails

Only qmail supported at this time.

=over

=item C<config/qmail/*>

Files with qmail configuration (in .qmail format).
Commands listed in these files (lines beginning with C<|>) will be
executed in project root directory, instead of user's home directory
(qmail's default behavour).

=item C<var/qmail/*>

Internally used by C<narada-setup-qmail>.

=back

=head2 Database

Only MySQL supported at this time.

=over

=item C<config/db/db>

Contains one line - name of MySQL database. If this file doesn't exists or
empty - Narada won't use database.

=item C<config/db/login>

=item C<config/db/pass>

Login/pass for database.

=item C<config/db/host>

Host name of database server. if this file doesn't exists or empty unix
socket will be used to connect to MySQL server.

=item C<config/db/port>

TCP port of database server.

=back

=head2 Locking

=over

=item C<var/.lock>

This file should be shared-locked using flock(2) or Narada::Lock or
C<narada-lock> before modifying any project's files or database by usual
applications, and exclusive-locked while project's backup, update or
manual maintenance.

=item C<var/.lock.new>

This file created before trying to exclusive-lock C<var/.lock>. All
applications wanted to shared-lock C<var/.lock> should first check is
C<var/.lock.new> exists and if yes then delay/avoid locking C<var/.lock>.
After exclusive lock will be acquired C<var/.lock.new> will be removed.
This is needed to guarantee exclusive lock will be acquired as soon as
possible.

If server will be rebooted while waiting for exclusive lock then file
C<var/.lock.new> won't be removed and project applications won't continue
working after booting server until this file will be removed manually.

=back


=head1 Tools

All tools (except C<narada-new>) must be executed in project root.
Read man pages of these tools for details.

    narada-new
    narada-setup-cron
    narada-setup-mysql
    narada-setup-qmail
    narada-shutdown-services

    narada-backup
    narada-mysqldump

    narada-diff
    narada-release
    narada-patch-remote
    narada-patch-send
    narada-patch-pull
    narada-patch

    narada-remote
    narada-upload
    narada-download

    narada-viewlog
    narada-mysql
    narada-emu

    narada-lock
    narada-lock-exclusive


=head1 CONFIGURATION AND ENVIRONMENT

$NARADA_USER optionally can be set to user's email. If set, it will be
used by C<narada-new> to initialize C<config/patch/send/$USER>; by
C<narada-patch-send> to avoid sending email to yourself; by
C<narada-release> when adding header lines into C<doc/ChangeLog>.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-narada@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Alex Efros  C<< <powerman@cpan.org> >>


=head1 CONTRIBUTORS

Nick Levchenko C<< <project129@yandex.ru> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2014 Alex Efros C<< <powerman@cpan.org> >>. All rights reserved.

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
