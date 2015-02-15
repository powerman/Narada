#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

eval { require Test::Perl::Critic; };
plan(skip_all=>'Test::Perl::Critic required to criticise code') if $@;

Test::Perl::Critic->import(
    -verbose    => 9,           # verbose 6 will hide rule name
);
all_critic_ok();
