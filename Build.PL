use Module::Build;
my $build = Module::Build->new(
	dist_name 			=> 'Net-OpenVPN-ProxyManager-HMA',
	dist_author			=> 'David Farrell <davidnmfarrell@gmail.com>',
	dist_version_from	=> 'lib/Net/OpenVPN/ProxyManager/HMA.pm',
	license				=> 'artistic',
	requires			=> { Moose 		   				=> '2.0603',
							 Test::More    				=> '0.98',
							 LWP::Simple   				=> '6',
							 Net::SSLeay   				=> '1.48',
							 Capture::Tiny 				=> '0.21',
							 perl		   				=> '5.10.0',
							 Net::OpenVPN::ProxyManager => '0.011',
							},
	configure_requires => { 'Module::Build' => 0.40 },
);
$build->create_build_script;
