#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;
use Test::More;

eval { require Test::Perl::Critic; };
plan(skip_all=>'Test::Perl::Critic required to criticise code') if $@;

my $rcfile = File::Spec->catfile( 'xt', 'author', '.perlcriticrc' );
Test::Perl::Critic->import(
    -profile    => $rcfile,
    -verbose    => 9,           # verbose 6 will hide rule name
);
all_critic_ok();
