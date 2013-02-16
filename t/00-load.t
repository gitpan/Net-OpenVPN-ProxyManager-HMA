#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OpenVPN::ProxyManager' ) || print "Bail out!\n";
}

diag( "Testing OpenVPN::ProxyManager $OpenVPN::ProxyManager::VERSION, Perl $], $^X" );
