#!/usr/bin/perl

sub queue_name {
my $values = "q.id,q.name";
my $fromtable = "queue q, Extension_ e";
my $conditions = "e.company_id='$company_id' and q.id=e.id";
$sth = $dbhqueue->prepare("select $values from $fromtable where $conditions");
$sth->execute();
 while(@hole = $sth->fetchrow_array) {
  $ith = $dbhqueue->prepare("insert into QueueFifteenMinHistory (control_id,queue_id,queue_name,company_id,refdate,begintime,beginminute) 
  values ('$control_id','$hole[0]','$hole[1]','$company_id','$ano','$hora','$minuto')");
  $ith->execute();
 }
}

sub queue {
 $dbhqueue = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("sub queue - Falha ao conectar com o banco de dados");
 $log->info("sub queue - Conexão com o banco ok. Iniciando...");
 &queue_name();
 $sth = $dbhqueue->prepare("select id, wrapupTime, name from queue order by id");
 $sth->execute();
 
 while (@hole = $sth->fetchrow_array) {
  ## Seleciona chamadas recebidas para todas as filas
  $tth = $dbhqueue->prepare("select count(action) from AsteriskQueueLog where 
  queue=$hole[0] and action = 'ENTERQUEUE' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'"); 
  $tth->execute();
  @result = $tth->fetchrow_array;

  ## Escreve no banco as informações lidas de chamadas recebidas
  $uth = $dbhqueue->prepare("update QueueFifteenMinHistory set receivedcalls=$result[0] where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $uth->execute(); 
 
  ## Seleciona chamadas abandonadas para todas as filas
  $aband = $dbhqueue->prepare("select count(action) from AsteriskQueueLog where 
  queue=$hole[0] and action = 'ABANDON' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $aband->execute();
  @result = $aband->fetchrow_array;

  ## Escreve no banco as informações lidas de abandonos
  $eaband = $dbhqueue->prepare("update QueueFifteenMinHistory set abandonedcalls=$result[0] where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $eaband->execute();
  ## Seleciona chamadas atendidas por algum agente, separados por fila
  $atend = $dbhqueue->prepare("select count(action) from AsteriskQueueLog where   
  queue=$hole[0] 
  and action = 'CONNECT' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $atend->execute();
  @result = $atend->fetchrow_array;
 
  ## Escreve as chamadas atendidas no banco
  $eatend = $dbhqueue->prepare("update QueueFifteenMinHistory set answeredcalls=$result[0] where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $eatend->execute();
 
  ## Seleciona quantidade de chamadas transbordadas para outras filas
  $overout = $dbhqueue->prepare("select count(action) from AsteriskQueueLog where 
  queue=$hole[0] 
  and action = 'OVERFLOW' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $overout->execute();
  @result = $overout->fetchrow_array;
 
  ## Escreve as chamadas transbordadas no banco
  $eoverout = $dbhqueue->prepare("update QueueFifteenMinHistory set queueoverflowout=$result[0] where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $eoverout->execute();
 
  ## Seleciona quantidade de chamadas transbordadas de outras filas
  $overin = $dbhqueue->prepare("select count(info1),info1,queue from AsteriskQueueLog where 
  info1=$hole[0] 
  and action = 'OVERFLOW' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $overin->execute();
  @result = $overin->fetchrow_array;
 
  $abc = $dbhqueue->prepare("select count(id) from queue where 
  id='$result[2]'");
  $abc->execute();
  @result = $abc->fetchrow_array;
 
  if ($result eq 0) {} else {
   ## Escreve as chamadas transbordadas no banco
   $eoverin = $dbhqueue->prepare("update QueueFifteenMinHistory set queueoverflowin=$result[0] where 
   queue_id='$result[1]' 
   and control_id=$control_id");
   $eoverin->execute();
  }
 
  ## Seleciona o tempo de espera das chamadas atendidas
  $wans = $dbhqueue->prepare("select sum(info1) from AsteriskQueueLog where 
  queue=$hole[0] 
  and action = 'CONNECT' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $wans->execute();
  @result = $wans->fetchrow_array;
 
  ## Escrever o total do tempo de espera das chamadas atendidas
  $ewans = $dbhqueue->prepare("update QueueFifteenMinHistory set totalanswaittime='$result[0]' where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $ewans->execute();
 
  ## Seleciona o tempo de espera das chamadas abandonadas
  $waband = $dbhqueue->prepare("select sum(info3) from AsteriskQueueLog where 
  queue=$hole[0] and action = 'ABANDON' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $waband->execute();
  @result = $waband->fetchrow_array;
 
  ## Escrever o total do tempo de espera das chamadas abandonadas
  $ewaband = $dbhqueue->prepare("update QueueFifteenMinHistory set totalabandwaittime='$result[0]' where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $ewaband->execute();
 
  ## Seleciona o maior tempo de espera das chamadas atendidas
  $mans = $dbhqueue->prepare("select max(cast(info1 as unsigned)) from AsteriskQueueLog where 
  queue=$hole[0] 
  and action = 'CONNECT' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $mans->execute();
  @result = $mans->fetchrow_array;
 
  ## Escrever o maior tempo de espera das chamadas atendidas
  $emans = $dbhqueue->prepare("update QueueFifteenMinHistory set longestanswaittime='$result[0]' where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $emans->execute();
 
  ## Seleciona o maior tempo de espera das chamadas abandonadas
  $waband = $dbhqueue->prepare("select max(cast(info3 as unsigned)) from AsteriskQueueLog where 
  queue=$hole[0] 
  and action = 'ABANDON' 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $waband->execute();
  @result = $waband->fetchrow_array;
 
  ## Escrever o maior do tempo de espera das chamadas abandonadas
  $ewaband = $dbhqueue->prepare("update QueueFifteenMinHistory set longestabndwaittime='$result[0]' where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $ewaband->execute();
 
  ## Seleciona a média de disponibilidade dos agentes dentro da fila
  ## Escreve no banco a média de disponibilidade dos agentes dentro da fila
  ## Seleciona o total de chamadas atendidas dentro do Service Level(default = 60s)
  $anssl = $dbhqueue->prepare("select count(cast(info1 as unsigned)) from AsteriskQueueLog where 
  queue=$hole[0] 
  and action = 'CONNECT' 
  and info1 <= 60 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $anssl->execute();
  @result = $anssl->fetchrow_array;
 
  ## Escrever o maior do tempo de espera das chamadas abandonadas
  $eanssl = $dbhqueue->prepare("update QueueFifteenMinHistory set answithinsl='$result[0]' where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $eanssl->execute();
 
  ## Seleciona o total de chamadas curtas abandonadas (default = 5s)
  $anssl = $dbhqueue->prepare("select count(cast(info3 as unsigned)) from AsteriskQueueLog where 
  queue=$hole[0] 
  and action = 'ABANDON' 
  and cast(info3 as unsigned) <= 5 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $anssl->execute();
  @result = $anssl->fetchrow_array;
 
  ## Escrever o total no banco
  $eanssl = $dbhqueue->prepare("update QueueFifteenMinHistory set totalshortabandon='$result[0]' where
  queue_id=$hole[0]
  and control_id=$control_id");
  $eanssl->execute();
 
  ## Seleciona o total de chamadas abandonadas dentro do Service Level(default = 60s)
  $abnssl = $dbhqueue->prepare("select count(cast(info3 as unsigned)) from AsteriskQueueLog where 
  queue=$hole[0] 
  and action = 'ABANDON' 
  and cast(info3 as unsigned) <= 60 
  and cast(info3 as unsigned) > 5 
  and datetime > '$interval' 
  and datetime <= '$dataexec'");
  $abnssl->execute();
  @result = $abnssl->fetchrow_array;
 
  ## Escrever o maior do tempo de espera das chamadas abandonadas
  $eabnssl = $dbhqueue->prepare("update QueueFifteenMinHistory set totalabandonwithinsl='$result[0]' where
  queue_id=$hole[0] 
  and control_id=$control_id");
  $eabnssl->execute();
 
  ## Calcula o tempo de wrapup para a fila
  $qwrapup = $dbhqueue->prepare("select count(a.action), q.wrapuptime from AsteriskQueueLog a, queue q where 
  q.id=a.queue 
  and a.queue=$hole[0] 
  and (a.action = 'COMPLETECALLER' or a.action = 'COMPLETEAGENT' ) 
  and a.datetime > '$interval' 
  and a.datetime <= '$dataexec'");
  $qwrapup->execute();
  @qwtime = $qwrapup->fetchrow_array;
 
  # Cálculo do tempo de wrapup para a fila
  $qwrapuptime = int($qwtime[0])*int($qwtime[1]);
 
  # Grana no banco o tempo de wrapup para a fila
  $wqwrapup = $dbhqueue->prepare("update QueueFifteenMinHistory set totalwrapup=$qwrapuptime where 
  queue_id=$hole[0] 
  and control_id=$control_id");
  $wqwrapup->execute();
 }
 $log->info("queue.pl - Final do script ok");
}

sub queuetalktime{
 $dbhqueue = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("sub queuetalktime - Falha ao conectar com o banco de dados");
 $log->info("sub queuetalktime - Conexão ok. Iniciando...");
 ## Roda fila por fila inserindo o tempo tota de conversa dessa fila
 $sth = $dbhqueue->prepare("select queue_id from queue_agent group by queue_id");
 $sth->execute();
 
 while (@hole = $sth->fetchrow_array) {
 ## insere o valor na abela QueueFifteenMinHistory
 $gravatempo = $dbhqueue->prepare("update QueueFifteenMinHistory set totaltalktime=(select sum(totaltalktime) from AgentQueueFifteenMinHistory where 
 control_id = $control_id and queue_id=$hole[0]) 
 where queue_id=$hole[0] and control_id=$control_id");
 $gravatempo->execute();
 }
 $log->info("queuetalktime.pl - Final do script ok");
}

