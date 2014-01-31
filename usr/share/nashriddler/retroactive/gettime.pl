#!/usr/bin/perl
sub get_time {
 $gettime = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("gettime.pl - Falha ao conectar com o banco de dados");
 $log->info("gettime.pl - Conexão com o banco ok. Iniciando...");


 $getdate=$gettime->prepare("select '$dataexec',
  substring(date_sub('$dataexec',interval 15 minute),1,4),
  substring(date_sub('$dataexec',interval 15 minute),6,2),
  substring(date_sub('$dataexec',interval 15 minute),9,2),
  substring(date_sub('$dataexec',interval 15 minute),12,2),
  substring(date_sub('$dataexec',interval 15 minute),15,2)");
 $getdate->execute();
 
 while (@datain = $getdate->fetchrow_array) {
  $dias = $datain[1] . $datain[2] . $datain[3];
  return($dias,$datain[4],$datain[5]);   
 }
 $log->info("gettime - Final do script ok");
}
