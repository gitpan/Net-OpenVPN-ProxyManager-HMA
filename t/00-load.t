#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::OpenVPN::ProxyManager::HMA' ) || print "Bail out!\n";
}

diag( "Testing Net::OpenVPN::ProxyManager::HMA $Net::OpenVPN::ProxyManager::HMA::VERSION, Perl $], $^X" );
