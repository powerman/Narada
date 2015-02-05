# NAME

Narada - framework for ease development/deploy/support for medium/big projects

# VERSION

This document describes Narada version 1.3.15

# SYNOPSIS

    # Run narada-* commands.
    # In perl scripts either use Narada::* modules or manually
    # conform Narada interface.
    # In non-perl applications just conform Narada interface.

# DESCRIPTION

Narada designed for ease development, deploy and support for medium and
big projects. It's main goal is to restrict you with __one way to manage__
your project (which doesn't really depend on your project's nature), and
doesn't restrict your project's implementation in any way. With Narada you
can create any projects using any programming languages - while your
projects conform Narada interface (and developed in \*NIX - Windows not
supported).

There are few helper Narada::\* modules for perl which helps you to conform
Narada interface in your perl modules/scripts; for other languages you may
want to create similar helpers, but this isn't required - Narada interface
is simple and can be easily conformed without using special helpers.

Typical example of project which wins a lot when managed by Narada is web
or network service, which consists of several scripts (which all should
have common runtime environment, logs, etc.) with different entry points
(cgi, rpc, cron, email).

## Main Features

- Create files and directory structure for new project.

    Project doesn't required to use database, all configuration/logs/etc. are
    stored in files.

- Different project installations have different configuration.

    Changes in your local configuration won't be occasionally sent with next
    update to production server.

- Ease project setup after installation/update.

    Narada provide helpers to update project environment (cron tasks, qmail
    handlers, mysql scheme) according to current project's configuration.

- Reliable services.

    Run your FastCGI or RPC daemons with guaranteed restart after crash.
    By default we use tools from [http://smarden.org/runit/](http://smarden.org/runit/) for supervising
    project's services, but other similar supervisors like daemontools also
    can be used.

- All project's applications have common log(s).

    By default we use [http://smarden.org/socklog2/](http://smarden.org/socklog2/) (syslog-compatible
    daemon) to receive logs from project's applications and `svlogd` tool
    from [http://smarden.org/runit/](http://smarden.org/runit/) to manage logs (rotate, filter, group
    records in separate files, etc.).

- All project's applications have common lock.

    This guarantee live project's consistency while backup, update or manual
    maintenance.

- Basic support for team development and versioning project.

    Narada make it easier to release and deploy updates on server.
    Team members may merge these updates with their working copy of project.
    Each update consists of several .patch, .sh, .sql and .tgz files, and can
    be easily reviewed/corrected before releasing.

    This feature doesn't meant as replacement for VCS - you can use or don't
    use any VCS with Narada: VCS is versioning your files, while Narada is
    versioning your project. But in simple cases (small team, everyone works
    on mostly isolated tasks) this feature can replace needs in VCS (even then
    some team members still may use VCS locally, for example to use branches).

- Consistent and fast project backup.

    Narada interface include shared/exclusive project locking, which let us
    guarantee backup consistency between project files and database.

    Narada backup tool support incremental backups both for files and
    database, which makes it possible to backup most projects in few seconds -
    your website visitors won't even notice your daily backup!

# INTERFACE

Narada, as a framework, provide you with some interface (mostly it's just
conventions about some files and directories), and you __MUST__ conform to
that interface of things will break.

> For example, let's review interfaces related to "Consistent and fast
> project backup" feature.
>
> "Consistent" require using shared/exclusive file locking on file
> `var/.lock`. All Narada does is create that file when generate new
> project and acquire exclusive lock on it while executing `narada-backup`.
> But to really have consistent backups __you__ must acquire shared lock on
> that file when accessing any project files or database in any of your
> scripts! In perl scripts you can use helper module [Narada::Lock](https://metacpan.org/pod/Narada::Lock), and
> it's not a big deal to manually use flock(2) in any other language. If you
> fail to do this, you backups won't be guaranteed to be consistent anymore!
>
> "Fast" consists of two parts: files and database. To backup project files
> fast you should keep large junk files according to Narada's interface -
> in directories listed in `config/backup/exclude`, for ex. in `tmp/`.
> To backup database fast you should try hard to store large amount of data
> in append-only tables with auto\_increment primary key, and add names of
> these tables in `config/db/dump/incremental`.

New project created in separate directory using `narada-new`.
This directory become "project root" directory (also called "project
dir"). All project applications and `narada-*` commands must be executed
in this directory (so they will be able to find all project files/dirs
using relative path).

These directories will be created in project root:

- `config/`

    Project's configuration (both predefined by Narada and custom settings
    related to your project). May differ between different installations
    of this project (by default project updates include only new and deleted
    settings, but not changed settings).

- `doc/`

    Contain `ChangeLog`. Put your documentation here.

- `service/`

    This directory should be used to setup project's services (daemons)
    and run them using service supervisor (runit, daemontools, etc.).

- `t/`

    Put your tests here.

- `tmp/`

    Files stored in this directory won't be included in backups and updates.

- `var/`

    Variable files required for Narada and your project. Will be included in
    backup, but not in updates.

## Team development and versioning project

- `config/version`

    Project name and version in flexible format: one string, which must
    contain at least one digit, and doesn't contain whitespace or `/`).
    Example: "App-0.1.000" (without quotes).

    `narada-new` will create this file with content "PROJECTNAME-0.0.000"
    where PROJECTNAME is name of project root directory.

    Last number in this string will be automatically incremented by
    `narada-release` unless this file was manually modified since previous
    `narada-release` run.

- `config/version.*`

    Name and version of installed addons.

- `config/patch/send/*`

    Each file contain one line with email of team member, who wanna receive
    emails with project updates. Used by `narada-patch-send`. File names are
    not important, but usually they match team member's $USER.

    If $NARADA\_USER is set, then `narada-new` will put it value into
    `config/patch/send/$USER`.

- `config/patch/exclude`

    PCRE regex (one per line) for files/dirs which shouldn't be included in
    project update. `config/` directory handled in special way and shouldn't
    be listed in this file.

- `doc/ChangeLog`

    Project's change log, in standard format. `narada-release` will ask you
    to enter changes using $EDITOR and then automatically insert/update line
    with date/version.

- `doc/ChangeLog.*`

    Change logs of installed addons.

- `var/patch/`

    Contains all project updates (patches). `narada-diff` will create new
    update candidate in this directory for manual review; `narada-release`
    will turn candidate into released update; `narada-patch` will apply
    updates found this this directory to project; etc.

- `var/patch/PENDING.*`

    You should put into these files custom sql/sh commands which should be
    included with next update.

- `var/patch/ChangeLog`

    Symlink to `doc/ChangeLog` for convenience.

- `var/patch/.mc.menu`

    Shortcuts for convenience (to run `narada-*` in project root without
    leaving `var/patch/` where you now reviewing current patch).

- `var/patch/.prev/`

    Contains "master" copy of current project's version (VCS keeps it in .git
    or .hg), for internal use by `narada-diff`. Should never be modified
    manually!

- `var/patch/*/`

    Contains "addon" patches.

## Backup

- `config/backup/exclude`

    Shell patterns (one per line) for files/dirs which shouldn't be included
    in backup. Must contain at least these lines:

        ./var/.lock.new     to avoid project in locked state after restore
                            from backup
        ./var/backup/*      to avoid recursively including old backups in new
        ./var/patch/.prev/* harmless, but it always can be restored by
                            applying all released updates on empty project

- `config/db/dump/incremental`

    List of database tables (one per line) which can be dumped incrementally
    (according to their auto\_increment primary key field). `narada-backup`
    will dump only new records in these tables (dumps for older records will
    be available in existing files in `var/backup/` or `var/sql/`).

- `config/db/dump/empty`

    List of database tables (one per line) which records shouldn't be included in
    backup, only scheme.

- `config/db/dump/ignore`

    List of database tables (one per line) which shouldn't be included in
    backup at all (even scheme).

- `var/sql/`

    Contains files with last database dump (usually made while last backup).

- `var/backup/`

    Contains helper files required for incremental backups and backups itself.

## Logging

- `config/log/type`

    Define type of logging: `syslog` (default if this file not exists) or
    `file`. If set to `syslog` then `config/log/output` should contain path
    to syslog's unix socket (like `var/log.sock` or `/dev/log`).
    `narada-new` initialize this file with `syslog` value.

- `config/log/output`

    File name where project applications should write their logs: either unix
    socket (to syslog-compatible daemon) or usual file (or `/dev/stdout`).
    `narada-new` initialize this file with `var/log.sock` value.

- `config/log/level`

    Current log level, should be one of these strings:

        ERR WARN NOTICE INFO DEBUG DUMP

    `narada-new` set it to `DEBUG`.

- `service/log/`

    Syslog-compatible service listening to `var/log.sock` and saving logs
    into `var/log/`. Can be switched off only if you doesn't write logs to
    `var/log.sock`.

- `var/log/`

    This directory contains project log files.

- `var/log/config`

    Optional configuration for logger service (filtering, rotation, etc.).

## Services

- `service/*/`

    Services (daemons) of this project.
    Most projects have just one (`log`) or two (`log` and `fastcgi`) services.

## Cron Tasks

- `config/crontab`

    Settings for project's cron tasks, in crontab format.

    When these settings will be installed to system's cron, each command will
    be automatically prefixed by:

        cd /path/to/project/root || exit;

    `narada-new` create it with single task - run service supervisor and thus
    start all project services in `service/*/`. This way project services
    will be restarted even after OS reboot.

    `narada-setup-cron` update system's cron using settings from this file.

## Processing Incoming Emails

Only qmail supported at this time.

- `config/qmail/*`

    Files with qmail configuration (in .qmail format).
    Commands listed in these files (lines beginning with `|`) will be
    executed in project root directory, instead of user's home directory
    (qmail's default behavour).

- `var/qmail/*`

    Internally used by `narada-setup-qmail`.

## Database

Only MySQL supported at this time.

- `config/db/db`

    Contains one line - name of MySQL database. If this file doesn't exists or
    empty - Narada won't use database.

- `config/db/login`
- `config/db/pass`

    Login/pass for database.

- `config/db/host`

    Host name of database server. if this file doesn't exists or empty unix
    socket will be used to connect to MySQL server.

- `config/db/port`

    TCP port of database server.

## Locking

- `var/.lock`

    This file should be shared-locked using flock(2) or Narada::Lock or
    `narada-lock` before accessing any project's files or database by usual
    applications, and exclusive-locked while project's backup, update or
    manual maintenance.

- `var/.lock.new`

    This file created before trying to exclusive-lock `var/.lock`. All
    applications wanted to shared-lock `var/.lock` should first check is
    `var/.lock.new` exists and if yes then delay/avoid locking `var/.lock`.
    This is needed to guarantee exclusive lock will be acquired as soon as
    possible.

    After exclusive lock will be acquired and critical operations requiring it
    will be completed - `var/.lock.new` will be removed.

    If server will be rebooted while waiting for exclusive lock or in the
    middle of critical operations requiring it then file `var/.lock.new`
    won't be removed and project applications won't continue working after
    booting server until this file will be removed manually or another
    operation requiring exclusive lock will be started and successfully
    finished.

# Tools

All tools (except `narada-new`) must be executed in project root.
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

# CONFIGURATION AND ENVIRONMENT

$NARADA\_USER optionally can be set to user's email. If set, it will be
used by `narada-new` to initialize `config/patch/send/$USER`; by
`narada-patch-send` to avoid sending email to yourself; by
`narada-release` when adding header lines into `doc/ChangeLog`.

# DEPENDENCIES

None.

# INCOMPATIBILITIES

None reported.

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
`bug-narada@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org](http://rt.cpan.org).

# AUTHOR

Alex Efros <powerman@cpan.org>

# CONTRIBUTORS

Nick Levchenko <project129@yandex.ru>

# LICENSE AND COPYRIGHT

Copyright (c) 2008-2015 Alex Efros <powerman@cpan.org>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

# DISCLAIMER OF WARRANTY

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
