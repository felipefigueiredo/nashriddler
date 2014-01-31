#!/usr/bin/perl
sub agent {
$dbhagent = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("sub agent - Falha ao conectar com o banco de dados");

$log->info("sub agent - Conexão com o banco ok. Iniciando...");

$gagent = $dbhagent->prepare("select v.fullName, e.number from voipuser v, Extension_ e 
where v.agent = 1 
and e.id=v.id 
and e.company_id='$company_id' 
and e.active=1");

$gagent->execute();

while (@hole=$gagent->fetchrow_array) {
 $eagent = $dbhagent->prepare("insert into AgentFifteenMinHistory (control_id,agent_id,agent_name,refdate,begintime,beginminute) 
 values ('$control_id','$hole[1])','$hole[0]','$ano','$hora','$minuto')");
 $eagent->execute();

 # Verificação de eventos de login dentro da janela
 $cnt_action = $dbhagent->prepare("select distinct(action),unix_timestamp(datetime) from AsteriskQueueLog 
 where agent='SIP/$company_id.ramal$hole[1]' 
 and action in ('ADDMEMBER','REMOVEMEMBER','CONNECT','COMPLETEAGENT','COMPLETECALLER') 
 and datetime > '$interval' 
 and datetime <= '$dataexec' 
 order by datetime asc");
 $cnt_action->execute();

 $lines = $cnt_action->rows();

 $last_datetime = $interval_timestamp; 
 $workdurtime = 0;

  $talking_action = $dbhagent->prepare("select action from AsteriskQueueLog 
  where agent = 'SIP/$company_id.ramal$hole[1]' 
  and action in ('CONNECT','COMPLETEAGENT','COMPLETECALLER') 
  and datetime < '$interval'
  and datetime > '$last_fiveday'
  order by datetime desc limit 1");
  $talking_action->execute();

  @talking = $talking_action->fetchrow_array;

  $last_login_action = $dbhagent->prepare("select action from AsteriskQueueLog 
  where agent = 'SIP/$company_id.ramal$hole[1]' 
  and action in ('ADDMEMBER','REMOVEMEMBER') 
  and datetime < '$interval'
  and datetime > '$last_fiveday'
  order by datetime desc limit 1");
  $last_login_action->execute();

  @login_list = $last_login_action->fetchrow_array;

  $connected = 0;
  $removed = 0;
  $logged = 0;

  if ($talking[0] eq 'CONNECT') {
   $connected = 1;
  }
  if ($login_list[0] eq 'ADDMEMBER') {
   $logged = 1;
  }

  if ($lines == 0) {
    if ($logged == 1) { 
     $workdurtime = 900;
    }
    elsif ($logged == 0 and $connected == 1) { 
     $workdurtime = 900;
    }
  }

  else {
   while (($action,$time) = $cnt_action->fetchrow_array()) {
   if ($action eq 'CONNECT') {
    if ($removed == 0) {
     $logged = 1;
     $connected = 1;
    }
   }
   elsif ($action eq 'COMPLETEAGENT' or $action eq 'COMPLETECALLER') {
    $logged = 1;
    $connected = 0;
    if ($logged == 0) {
     $workdurtime = $workdurtime + ($time - $last_datetime);
    }
   }
   if ($action eq 'ADDMEMBER') {
    $removed = 0;
    $logged = 1;
    $last_datetime = $time;
   }
   elsif ($action eq 'REMOVEMEMBER') {
    $logged = 0;
    if ($connected == 0 and $removed == 0) {
     $removed = 1;
     $workdurtime = $workdurtime + ($time - $last_datetime);
    } 
   }
  }

  if ($logged == 0 and $connected == 1) {
   $workdurtime = $workdurtime + ($now_timestamp - $last_datetime);
  }
  if ($logged == 1) {
   $workdurtime = $workdurtime + ($now_timestamp - $last_datetime);
  } 
 }

 $update_workdurtime = $dbhagent->prepare("update AgentFifteenMinHistory set totworkdur=$workdurtime 
 where control_id=$control_id 
 and agent_id=$hole[1]");
 $update_workdurtime->execute();
 }
}

sub agentpause{
 $dbhagent = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("sub agentpause - Falha ao conectar com o banco de dados");
 $log->info("sub agentpause - Conexão com o banco ok. Iniciando...");
 $gagent = $dbhagent->prepare("select v.fullName, e.number from voipuser v, Extension_ e 
 where v.agent = 1 
 and e.id=v.id 
 and e.company_id='$company_id' 
 and e.active=1");
 $gagent->execute();

 while (@hole=$gagent->fetchrow_array) {
  # Verificação de eventos de pausa dentro da janela
  $pause_action = $dbhagent->prepare("select distinct(action),unix_timestamp(datetime) from AsteriskQueueLog 
  where agent='SIP/$company_id.ramal$hole[1]' 
  and action in ('PAUSEALL','UNPAUSEALL','CONNECT','COMPLETEAGENT','COMPLETECALLER','REMOVEMEMBER') 
  and datetime > '$interval' 
  and datetime <= '$dataexec' 
  order by datetime asc");
  $pause_action->execute();
 
  $lines = $pause_action->rows();
 
  $last_datetime = $interval_timestamp;
  $totalpause = 0;

  $talking_action = $dbhagent->prepare("select action from AsteriskQueueLog 
  where agent = 'SIP/$company_id.ramal$hole[1]' 
  and action in ('CONNECT','COMPLETEAGENT','COMPLETECALLER','REMOVEMEMBER') 
  and datetime < '$interval'
  and datetime > '$last_fiveday'
  order by datetime desc limit 1");
  $talking_action->execute();

  @talking = $talking_action->fetchrow_array;

  $last_pause_action = $dbhagent->prepare("select action from AsteriskQueueLog 
  where agent = 'SIP/$company_id.ramal$hole[1]' 
  and action in ('PAUSE','PAUSEALL','UNPAUSEALL','REMOVEMEMBER') 
  and datetime < '$interval'
  and datetime > '$last_fiveday'
  order by datetime desc, queue desc limit 2");
  $last_pause_action->execute();

  @paused_list = ();
  while ($action = $last_pause_action->fetchrow_array()) {
   push (@paused_list,$action);
  }

  $connected = 0;
  $removed = 0;
  $paused = 0; 


  if ($talking[0] eq 'CONNECT') {
   $connected = 1;
  }
  if ($paused_list[-1] eq 'PAUSE' and $paused_list[-2] eq 'PAUSEALL') { 
   $paused = 1;
  }
  if ($talking[0] eq 'REMOVEMEMBER') {
   $removed = 1;
  }

  if ($lines == 0) {
   if ($paused == 1 and $connected == 0) {
    $totalpause = 900;
   }
  }
 
  else {
  @is_logged = ();
  while (($action,$time) = $pause_action->fetchrow_array()) { 
   push (@is_logged,$action);
   if ($action eq 'CONNECT') {
    $connected = 1;
   }
  
   elsif ($action eq 'COMPLETEAGENT' or $action eq 'COMPLETECALLER') {
    $connected = 0;
    if ($paused == 1) {
     $last_datetime = $time;
    }
   }
  
   if ($action eq 'PAUSEALL') {
    if ($removed == 0 and $paused == 0) {
     $paused = 1;
     $last_datetime = $time;
    }
    $paused = 0;
   }
  
   elsif ($action eq 'UNPAUSEALL') {
    $paused = 0;
    if ($connected == 0 and $removed == 0) {
     $totalpause = $totalpause + ($time - $last_datetime);
    }
    $paused = 0;
   }

   elsif($action eq 'REMOVEMEMBER') {
    if($paused == 1 and $connected == 0 and $removed == 0){
     $paused = 0;
     $removed = 1;
     $totalpause = $totalpause + ($time - $last_datetime);
    }
   }
   if ($paused == 1 and $connected == 0) {
    $last_datetime = $time;
   }
  
  }
  
  if ($paused == 1 and $connected == 0) {
   $totalpause = $totalpause + ($now_timestamp - $last_datetime);
  }
 } 

 $update_pausedur = $dbhagent->prepare("update AgentFifteenMinHistory set totalpause=$totalpause 
 where control_id=$control_id 
 and agent_id=$hole[1]");
 $update_pausedur->execute();
 }
}

sub agentcdr{
 $dbhagent = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("sub agentcdr - Falha ao conectar com o banco de dados");
 $log->info("sub agentcdr - Conexão com o banco ok. Iniciando...");
 $gagent = $dbhagent->prepare("select v.fullName, e.number from voipuser v, Extension_ e where 
 v.agent = 1 
 and e.id=v.id 
 and e.company_id='$company_id' 
 and e.active=1");
 $gagent->execute();
 
 while (@hole=$gagent->fetchrow_array) {
  # Calculo de availdur (Tempo disponível do agente dentro do intervalo)
  $get_avail = $dbhagent->prepare("select totworkdur,totalpause from AgentFifteenMinHistory where 
  control_id=$control_id 
  and agent_id=$hole[1]");
  $get_avail->execute();
  @return_avail = $get_avail->fetchrow_array;
  
  $avail=0;
  $avail = $return_avail[0] - $return_avail[1];
  $update_availdur = $dbhagent->prepare("update AgentFifteenMinHistory set availdur=$avail where 
  control_id=$control_id 
  and agent_id=$hole[1]");
  $update_availdur->execute();
  
  
  ## Seleciona o total de chamadas efetuadas de um agente (não se incluem chamdas para outras filas)
  $noqueueout = $dbhagent->prepare("select count(*) from cdr where 
  src = $hole[1] 
  and (lastapp != 'Queue' and lastapp != 'Busy') 
  and calldate > '$interval' 
  and calldate <= '$dataexec'");
  $noqueueout->execute();
  @thehole = $noqueueout->fetchrow_array;
  
  ## Escreve no banco a quantidade de chamadas realizadas pelo agente
  $enoqueueout = $dbhagent->prepare("update AgentFifteenMinHistory set totaloutcnt=$thehole[0] where 
  agent_id=$hole[1] 
  and control_id=$control_id");
  $enoqueueout->execute();
          
  ## Seleciona a duração total das chamadas efetuadas de um agente (não se incluem chamadas para outras filas)
  $noqueueoutdur = $dbhagent->prepare("select sum(duration) from cdr where 
  src = $hole[1] 
  and (lastapp != 'Queue' and lastapp != 'Busy') 
  and calldate > '$interval' 
  and calldate <= '$dataexec'");
  $noqueueoutdur->execute();
  @whathole = $noqueueoutdur->fetchrow_array;
          
  ## Escreve no banco a duração total das chamadas realizadas pelo agente
  $enoqueueoutdur = $dbhagent->prepare("update AgentFifteenMinHistory set totaloutdur='$whathole[0]' where 
  agent_id=$hole[1] 
  and control_id=$control_id");
  $enoqueueoutdur->execute();
  
  ## Seleciona o total de chamadas recebidas por um agente (não se incluem chamdas para outras filas)
  $noqueueout = $dbhagent->prepare("select count(*) from cdr where 
  dst = 'ramal$hole[1]' 
  and (lastapp != 'Queue' and lastapp != 'Busy') 
  and calldate > '$interval' 
  and calldate <= '$dataexec'");
  $noqueueout->execute();
  @thehole = $noqueueout->fetchrow_array;
          
  ## Escreve no banco a quantidade de chamadas realizadas pelo agente
  $enoqueueout = $dbhagent->prepare("update AgentFifteenMinHistory set totalincnt=$thehole[0] where 
  agent_id=$hole[1] 
  and control_id=$control_id");
  $enoqueueout->execute();
          
  
  ## Seleciona a duração total das chamadas efetuadas de um agente (não se incluem chamadas para outras filas)
  $noqueueoutdur = $dbhagent->prepare("select sum(duration) from cdr where 
  dst = 'ramal$hole[1]' 
  and (lastapp != 'Queue' and lastapp != 'Busy') 
  and calldate > '$interval' 
  and calldate <= '$dataexec'");
  $noqueueoutdur->execute();
  @whathole = $noqueueoutdur->fetchrow_array;
          
  ## Escreve no banco a duração total das chamadas realizadas pelo agente
  $enoqueueoutdur = $dbhagent->prepare("update AgentFifteenMinHistory set totalindur='$whathole[0]' where 
  agent_id=$hole[1] 
  and control_id=$control_id");
  $enoqueueoutdur->execute();
 }
 $log->info("agent.pl - Final do script ok");
}
