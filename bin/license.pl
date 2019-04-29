#!/usr/bin/perl
use v5.20;
use warnings;
use Data::Dumper 'Dumper';
use lib 'c:/richcode/github/Chef-ServerAPI/lib';

use Chef::ServerAPI;

my $client = Chef::ServerAPI->new(
    host => "http://192.168.3.81:8889",
    pem => '',
    userId => 'cheffie'
);

my $license = $client->license;

say "License: ".Dumper($license);