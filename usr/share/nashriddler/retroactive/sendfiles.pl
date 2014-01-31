#!/usr/bin/perl
use Net::FTP;

my $file = $ARGV[0];
 
$ftp = Net::FTP->new("lw135169093950912187.provisorio.ws",Debug=>0,Passive=>1) or die $log->error("sub sendfiles - Conexão com o servidor ok. Iniciando");
$ftp->login("lw135169093950912187","kfg34@HGrd");
$ftp->cwd("/nashriddler");
$ftp->put("$file");
$ftp->quit;
$log->info("sub sendfiles - Final do script ok");
