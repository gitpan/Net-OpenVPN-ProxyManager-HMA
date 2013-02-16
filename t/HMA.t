use Cwd;
my $cwd = cwd;
unshift @INC, $cwd .= '/lib';

use Test::More tests => 3;

use_ok ('Net::OpenVPN::ProxyManager::HMA');
ok (my $pm_hma = Net::OpenVPN::ProxyManager::HMA->new, 'Instantiate ProxyManager::HMA object');
ok (my $servers = $pm_hma->get_servers({ name => 'usa', proto => 'tcp'}), 'Check get_servers method');
