#!/usr/bin/perl
use DBI;
use Switch;
use Config::Tiny;
use Log::Log4perl;
use Log::Dispatch::FileRotate;

eval 'require "/usr/share/nashriddler/retroactive/queue.pl"';
eval 'require "/usr/share/nashriddler/retroactive/agent.pl"';
eval 'require "/usr/share/nashriddler/retroactive/agentqueue.pl"';
eval 'require "/usr/share/nashriddler/retroactive/gettime.pl"';
eval 'require "/usr/share/nashriddler/retroactive/createfiles.pl"';
eval 'require "/usr/share/nashriddler/retroactive/sendfiles.pl"';

$SIG{CHLD} = 'IGNORE';

$cfg_path="/usr/share/nashriddler/retroactive/config.cfg";

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


START:

print "Digite 1 para escolher mês específico ou 2 para um intervalo de dias dentro do mes: \n";
chomp ($date_opt = <STDIN>);


if ($date_opt == 1) {
 print "Digite o mes a ser recuperado (Janeiro: 01, Fevereiro: 02 ... )\n";
 chomp($in_month = <STDIN>);
 
 my $year = 2013;
 my $month = $in_month;
 my @month_31 = qw(01 03 05 07 08 10 12);
 my @month_30 = qw(04 06 11);
 
 if ($month ~~ @month_31) {
  my @days = (1..31);
  foreach $day (@days) {
   my @hours = (0..23);
   foreach $hour (@hours) {
    if ($hour < 10) {
     $hour = "0".$hour;
    }
    my @intervals = qw(00 15 30 45);
    foreach $interval (@intervals) {
     $dataexec = $year."-".$month."-".$day." ".$hour.":".$interval."\n";
     &controle_id();
     $horalog = localtime();
     $log->info(" ***** Recuperacao dos dados da data: $dataexec ***** Control id: $control_id");
     &agent();
     &agentpause();
     &agentcdr();
     &agentQueue();
     &queue();
     &queuetalktime();
     &createfiles();
    }
   }
  }
 }
 
 elsif ($month ~~ @month_30) {
  my @days = (1..30);
  foreach $day (@days) {
   my @hours = (0..23);
   foreach $hour (@hours) {
    if ($hour < 10) {
     $hour = "0".$hour;
    }
    my @intervals = qw(00 15 30 45);
    foreach $interval (@intervals) {
     $dataexec = $year."-".$month."-".$day." ".$hour.":".$interval."\n";
     &controle_id();
     $horalog = localtime();
     $log->info(" ***** Recuperacao dos dados da data: $dataexec ***** Control id: $control_id");
     &agent();
     &agentpause();
     &agentcdr();
     &agentQueue();
     &queue();
     &queuetalktime();
     &createfiles();
    }
   }
  }
 }
 
 else {
  @days = (1..28);
  foreach $day (@days) {
   if ($day < 10) {
    $day = "0".$day;
   }
   my @hours = (0..23);
   foreach $hour (@hours) {
    if ($hour < 10) {
     $hour = "0".$hour;
    }
    my @intervals = qw(00 15 30 45);
    foreach $interval (@intervals) {
     $dataexec = $year."-".$month."-".$day." ".$hour.":".$interval;
     &controle_id();
     $horalog = localtime();
     $log->info(" ***** Recuperacao dos dados da data: $dataexec ***** Control id: $control_id");
     &agent();
     &agentpause();
     &agentcdr();
     &agentQueue();
     &queue();
     &queuetalktime();
     &createfiles();
    }
   }
  }
 }
}

if ($date_opt == 2) {
 my $year = 2013;
 
 print "Digite o mes a ser recuperado (Janeiro: 01, Fevereiro: 02 ... )\n";
 chomp ($month = <STDIN>);

 print "Escolha o dia inicial (1 a 31): \n";
 chomp ($begin_day = <STDIN>);

 print "Escolha o dia final (1 a 31): \n";
 chomp ($end_day = <STDIN>);

 my @days = ($begin_day..$end_day);
 foreach $day (@days) {
  if ($day < 10) {
   $day = "0".$day;
  }
  my @hours = (0..23);
  foreach $hour (@hours) {
   if ($hour < 10) {
    $hour = "0".$hour;
   }
   my @intervals = qw(00 15 30 45);
   foreach $interval (@intervals) {
    $dataexec = $year."-".$month."-".$day." ".$hour.":".$interval;
    &controle_id();
    $horalog = localtime();
    $log->info(" ***** Recuperacao dos dados da data: $dataexec ***** Control id: $control_id");
    &agent();
    &agentpause();
    &agentcdr();
    &agentQueue();
    &queue();
    &queuetalktime();
    &createfiles();
   }
  }
 }
}

else {
 print $date_opt. " nao e uma opcao valida.\n";
 goto START;
}

sub controle_id {
 ($ano,$hora,$minuto) = &get_time();
 $dbh = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("Falha ao conectar no banco de dados");
 $timecontrol = $dbh->prepare("select substring(date_sub('$dataexec',INTERVAL 15 MINUTE),1,16),unix_timestamp('$dataexec'),unix_timestamp(date_sub('$dataexec',interval 15 minute)),substring(date_sub('$dataexec',INTERVAL 5 DAY),1,16)");
 $last_control_id = $dbh->prepare("select control_id from QueueFifteenMinHistory order by control_id desc limit 1");
 
 $timecontrol->execute();
 $last_control_id->execute();
 
 @return_timecontrol=$timecontrol->fetchrow_array;
 @return_control_id=$last_control_id->fetchrow_array;
 
  $control_id = $return_control_id[0] + 100;
  $interval = $return_timecontrol[0];
  $now_timestamp = $return_timecontrol[1];
  $interval_timestamp = $return_timecontrol[2];
  $last_fiveday = $return_timecontrol[3];
}
