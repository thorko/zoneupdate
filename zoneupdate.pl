#!/usr/bin/perl
#
use strict;
use warnings;
use Config::Simple;
use Getopt::Long;

my $config //= "/etc/zoneupdate.conf";
my %cfg;
my $help = 0;
my $debug = 0;
my $record_name;
my $zone;
my $ttl //= 300;
my $operation //= "add";
my $record;
my $value;
our $update_file = "/tmp/nsupdate.txt";

sub help_msg {
   print <<'EOF'
Usage: ./zoneupdate.pl [-c /etc/zoneupdate.conf] [-h] [-d] -z <zone> -o <operation> -n <record name> -t <ttl> -r <record type> -v <value>
-c, --config   your config file to use
-o, --operation  add or delete, default: add
-z, --zone     your zone, ex: thorko.de
-n, --name     the record name to use: pt.thorko.de
-t, --ttl      the ttl: default 300
-r, --record   record type: A, CNAME, AAAA, TXT, TLSA, MX
-v, --value    value: 127.0.0.1
-h, --help     print this help message
-d, --debug

Example:
./zoneupdate.pl -o add -z thorko.de -t 300 -r TLSA -v "3 0 1 8cb0fc6c527506a053f4f14c8464bebbd6dede2738d11468dd953d7d6a3021f1" -n _443.tcp.www.thorko.de
EOF
}

sub write_nsupdate_file {
  my $ops = shift;
  my $rn = shift;
  my $ttl = shift;
  my $record = shift;
  my $value = shift;
  my $zone = shift;
  my $server = shift;

  open(my $fh, '>', $update_file) or die "Couldn't write to file: $update_file $!";
  print $fh "server $server\nzone $zone\n";
  print $fh "update $ops $rn $ttl $record $value\n";
  print $fh "send\n";
  close $fh;
}

Getopt::Long::Configure ("bundling");
GetOptions(
  "c|config=s" => \$config,
  "o|operation=s" => \$operation,
  "z|zone=s" => \$zone,
  "n|name=s" => \$record_name,
  "t|ttl=s" => \$ttl,
  "r|record=s" => \$record,
  "v|value=s" => \$value,
  "h|help" => \$help,
  "d|debug" => \$debug
);

if ( $help ) {
	help_msg;
	exit 0;
}


if ( ! defined $record_name || ! defined $record || ! defined $value || ! defined $zone ) {
  help_msg;
  exit 1;
}

# read config
Config::Simple->import_from($config, \%cfg);

if ( $record !~ /A|CNAME|AAAA|TXT|TLSA|MX/ ) {
  print "Record Type: $record not supported!\n";
  exit 1;
}


write_nsupdate_file($operation, $record_name, $ttl, $record, $value, $zone, $cfg{'conf.server'});

my $opts = "-k $cfg{'keys.updatekey'}";
if ( $debug ) {
  $opts .= " -d ";
}
qx{nsupdate $opts $update_file};
qx{rndc -k $cfg{'keys.rndckey'} -c $cfg{'conf.rndcconf'} sync};

exit 0;
