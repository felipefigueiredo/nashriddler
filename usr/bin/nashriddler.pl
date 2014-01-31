#!/usr/bin/perl

use DBI;
use Switch;
use Config::Tiny;
use Log::Log4perl;
use Log::Dispatch::FileRotate;


eval 'require "/usr/share/nashriddler/queue.pl"';
eval 'require "/usr/share/nashriddler/agent.pl"';
eval 'require "/usr/share/nashriddler/agentqueue.pl"';
eval 'require "/usr/share/nashriddler/gettime.pl"';
eval 'require "/usr/share/nashriddler/createfiles.pl"';
eval 'require "/usr/share/nashriddler/sendfiles.pl"';


system("echo $$ > /var/run/nashriddler.pid");
$SIG{CHLD} = 'IGNORE';


$cfg_path="/usr/share/nashriddler/config.cfg";

$log_time=0;
$log_time=localtime();

# Definição das variáveis
$cfg = Config::Tiny->new;
$cfg = Config::Tiny->read($cfg_path);

# Banco de dados
$db_host = $cfg->{db}->{host};
$db_user = $cfg->{db}->{username};
$db_pwd = $cfg->{db}->{password};
$db_db = $cfg->{db}->{db};

# Selecao da company
$company_id = $cfg->{company}->{id};

# FTP
$ftp_host = $cfg->{ftp}->{host};
$ftp_user = $cfg->{ftp}->{username};
$ftp_pwd = $cfg->{ftp}->{password};
$ftp_path = $cfg->{ftp}->{path};

# Log 
$log_path = $cfg->{log}->{path};
$log_file = $cfg->{log}->{file};
Log::Log4perl->init("$log_path/$log_file");
$log = Log::Log4perl->get_logger("");

#Rsync
$host = $cfg->{rs}->{host};


sub controle_id {
 $dbh = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("Falha ao conectar no banco de dados");
 $log->info("Conexão ok. Iniciando queries");
 ($ano,$hora,$minuto) = &get_time();
 $timecontrol = $dbh->prepare("select NOW(),(NOW() - INTERVAL 15 MINUTE),unix_timestamp(now()),unix_timestamp((now() - interval 15 minute)),(NOW() - INTERVAL 5 DAY)");
 $last_control_id = $dbh->prepare("select control_id from QueueFifteenMinHistory order by control_id desc limit 1");
 
 $timecontrol->execute();
 $last_control_id->execute();
 
 @return_timecontrol=$timecontrol->fetchrow_array;
 @return_control_id=$last_control_id->fetchrow_array;
 
 
 if ($return_control_id[0] eq '') {
  $control_id = 0;
  $dataexec = $return_timecontrol[0];
  $interval = $return_timecontrol[1];
  $now_timestamp = $return_timecontrol[2];
  $interval_timestamp = $return_timecontrol[3];
  $last_fiveday = $return_timecontrol[4];
 } 
 else {
  $control_id = $return_control_id[0] + 1;
  $dataexec = $return_timecontrol[0];
  $interval = $return_timecontrol[1];
  $now_timestamp = $return_timecontrol[2];
  $interval_timestamp = $return_timecontrol[3];
  $last_fiveday = $return_timecontrol[4];
 }
}

&controle_id();
$horalog = localtime();
&agent();
&agentpause();
&agentcdr();
&agentQueue();
&queue();
&queuetalktime();
&createfiles();
&sendfiles();
exit 0;
