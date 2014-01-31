#!/usr/bin/perl
sub agentQueue {
$dbhaqueue = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("sub agentQueue - Falha ao conectar com o banco de dados");
$log->info("sub agentQueue - Conexão com banco ok. Iniciando...");

$gagent = $dbhaqueue->prepare("select q.queue_id, qu.name, v.fullName, e.number from queue_agent q, Extension_ e, voipuser v, queue qu 
where e.type ='VoIPUser' 
and e.active=1 
and e.company_id='$company_id' 
and e.id=q.voipuser_id 
and e.id=v.id 
and qu.id=q.queue_id");

$gagent->execute();

while(@hole = $gagent->fetchrow_array) {
 $eagent = $dbhagent->prepare("insert into AgentQueueFifteenMinHistory (control_id,agent_id,agent_name,queue_id,queue_name,refdate,begintime,beginminute) 
 values ('$control_id','$hole[3]','$hole[2]','$hole[0]','$hole[1]','$ano','$hora','$minuto')");
 $eagent->execute();

 $list_action = $dbhagent->prepare("select action,unix_timestamp(datetime) as time from AsteriskQueueLog where agent='SIP/$company_id.ramal$hole[3]' 
 and action in ('CONNECT','COMPLETEAGENT','COMPLETECALLER','TRANSFER') 
 and queue=$hole[0] 
 and datetime > '$interval' and datetime <= '$dataexec' 
 order by datetime asc");
 
 $list_action->execute();
 $lines = $list_action->rows();

 $last_datetime = $interval_timestamp;
 $talktime = 0;

 if ($lines == 0) {
  $get_action = $dbhagent->prepare("select action from AsteriskQueueLog
  where agent = 'SIP/$company_id.ramal$hole[3]' 
  and action in ('CONNECT','COMPLETECALLER','COMPLETEAGENT','TRANSFER')
  and queue=$hole[0] 
  and datetime > '$last_fiveday' and datetime < '$interval' 
  order by datetime desc limit 1");

  $get_action->execute();
  @last_action = $get_action->fetchrow_array; 

  if ($last_action[0] eq 'CONNECT') {
   $talktime = 900;
  } 
 }
  
 @last_element = ();
 while (($action,$time) = $list_action->fetchrow_array()) {
  push (@last_element,$action);
  push (@last_element,$time);
 
 if ($action eq 'COMPLETECALLER' or $action eq 'COMPLETEAGENT' or $action eq 'TRANSFER') {
    $talktime = $talktime + ($time - $last_datetime);
 }  
 $last_datetime = $time;
} 
  if (@last_element[-2] eq 'CONNECT') {
   $talktime = $talktime + ($now_timestamp - @last_element[-1]);
  }
 
 $update_talktime = $dbhagent->prepare("update AgentQueueFifteenMinHistory set totaltalktime=$talktime 
 where control_id=$control_id 
 and agent_id=$hole[3] 
 and queue_id=$hole[0]");
 
 $update_talktime->execute();
 

 ## Calcula o tempo de WrapUp de agentes por filas
 $swrapup = $dbhaqueue->prepare("select count(a.action), a.queue, q.wrapuptime, q.name from AsteriskQueueLog a, queue q 
 where q.id=a.queue 
 and a.agent='SIP/$company_id.ramal$hole[3]' 
 and a.action in ('COMPLETECALLER','COMPLETEAGENT')  
 and a.datetime > '$interval' 
 and a.datetime <= '$dataexec' 
 group by queue;");
 
 $swrapup->execute();
 @asshole = $swrapup->fetchrow_array;

 # Tempo total do wrapup do agente para cada fila
 $awrapup = int($asshole[0])*int($asshole[2]);
 
 if ($asshole[1] ne ''){
  $iwrapup = $dbhaqueue->prepare("update AgentQueueFifteenMinHistory set totalwrapup='$awrapup' 
  where control_id=$control_id 
  and agent_id=$hole[3] 
  and queue_id=$asshole[1]");
  
 $iwrapup->execute();
 }

 # Seleciona o numero total de chamadas atendidas por um agente em cada fila que ele está logado
 $totalans = $dbhaqueue->prepare("select count(a.action),q.name,a.queue from AsteriskQueueLog a, queue q 
 where a.action = 'CONNECT' 
 and a.agent='SIP/$company_id.ramal$hole[3]' 
 and a.queue=q.id and a.datetime > '$interval' 
 and a.datetime <= '$dataexec' 
 group by q.id");
 
$totalans->execute();

 while (@myhole = $totalans->fetchrow_array) {
  $etotalans = $dbhaqueue->prepare("update AgentQueueFifteenMinHistory set answeredcalls='$myhole[0]' 
  where control_id='$control_id' 
  and agent_id='$hole[3]' 
  and queue_id='$myhole[2]'");
  
 $etotalans->execute();
 }
}
$log->info("agentqueue.pl - Final do script ok");
}
