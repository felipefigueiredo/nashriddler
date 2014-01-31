#!/usr/bin/perl
sub createfiles {
 $dbhcreate = DBI->connect("DBI:mysql:database=$db_db;host=$db_host", "$db_user", "$db_pwd" ) or  die $log->error("sub createfiles - Falha ao conectar com o banco de dados");
 $log->info("sub createfles - Conexão com o banco ok. Iniciando...");
 my $queuefile = "/usr/share/nashriddler/files/Queue_Statistics_" . "$ano" . "_" . "$hora" . "_" . "$minuto" . ".csv";
 my $agentfile = "/usr/share/nashriddler/files/Agent_Statistics_" . "$ano" . "_" . "$hora" . "_" . "$minuto" . ".csv";
 my $agentqueuefile = "/usr/share/nashriddler/files/AgentQueue_Statistics_" . "$ano" . "_" . "$hora" . "_" . "$minuto" . ".csv";
 
 ## Criando arquivos para armazenar dados
 system("touch", "$queuefile");
 system("touch", "$agentfile");
 system("touch", "$agentqueuefile");
 
 ## Escrevendo primeiras linhas do arquivo
 unless (open FILE, ">>$queuefile") {die};
 print FILE "Teleopti.Queue.Data\n\n";
 print FILE "interval;date_form;time;queue;queue_name;offd_direct_call_cnt;overflow_in_call_cnt;aband_call_cnt;overflow_out_call_cnt;answ_call_cnt;queued_and_answ_call_dur;queued_and_aband_cal l_dur;talking_call_dur;wrap_up_dur;queued_answ_longest_queue_dur;queued_aband_longest_queue_dur;avg_avail_member_cnt
 ;ans_servicelevel_cnt;wait_dur;aband_short_call_cnt;aband_within_sl_cnt\n";
 close FILE;
 
 unless (open FILE, ">>$agentfile") {die};
 print FILE "Teleopti.Agent.Data\n\n";
 print FILE "interval;date_form;time;agent_id;agent_name;avail_dur;tot_work_dur;pause_dur;wait_dur;admin_dur;direct_out_call_cnt;direct_out_call_dur;direct_in_call_cnt;direct_in_call_dur\n";
 close FILE;
 
 unless (open FILE, ">>$agentqueuefile") {die};
 print FILE "Teleopti.AgentQueue.Data\n\n";
 print FILE "interval;date_form;time;agent_id;agent_name;queue;queue_name;talking_call_dur;wrap_up_dur;answ_call_cnt;transfer_out_call_cnt\n";
 close FILE;
 
 ## Escrevendo arquivo Queue.Data
 unless(open FILE,">>$queuefile") {die};
 $queuedb = $dbhcreate->prepare("select * from QueueFifteenMinHistory where control_id=$control_id");
 $queuedb->execute();

 while (@hole = $queuedb->fetchrow_array) {
  &fix_hour($hole[6]);
  print FILE "15;" .$hole[5]. ";" .$time . ":" . $hole[7] .";" .$hole[2]. ";" .$hole[3]. ";" .$hole[8] . ";" . $hole[13] . ";" . $hole[11] . ";" . $hole[14] . ";" . $hole[12] . ";" . $hole[10] . ";" . $hole[9] . ";" . $hole[26] . ";" . $hole[17] . ";" . $hole[18] . ";" .$hole[19] . ";" .$hole[22] . ";" .$hole[23] . ";" .$hole[24] . ";" .$hole[27] . ";" .$hole[28] . "\n";
 }
 close FILE;
 
 ## Escrevendo arquivo Agent.Data
 unless (open FILE,">>$agentfile") {die};
 $agentdb = $dbhcreate->prepare("select * from AgentFifteenMinHistory where control_id=$control_id");
 $agentdb->execute();
 
 while (@asshole = $agentdb->fetchrow_array) {
  &fix_hour($asshole[5]);
  if ($asshole[7] > 900) {
   $log->info("Incoerencia encontrada para o agente $asshole[2] : Availdur maior que 900 - Intervalo: $hora:$minuto");
  }
  if ($asshole[9] > 900) {
   $log->info("Incoerencia encontrada para o agente $asshole[2] : Workdurdur maior que 900 - Intervalo: $hora:$minuto");
  }
  if ($asshole[10] > 900) {
   $log->info("Incoerencia encontrada para o agente $asshole[2] : Pausedur maior que 900 - Intervalo: $hora:$minuto");
  }
  if ($asshole[10] > $asshole[9]) {
   $log->info("Incoerencia encontrada para o agente $asshole[2] : Pausedur maior que Workdur - Intervalo: $hora:$minuto");
  }
  if ($asshole[10] > $asshole[7] and $asshole[10] > $asshole[9]) {
   $log->info("Incoerencia encontrada para o agente $asshole[2] : Pausedur maior Availdur - Intervalo: $hora:$minuto");
  }

  print FILE "15;" . $asshole[4]. ";" .$time. ":" . $asshole[6] . ";" .$asshole[2]. ";" .$asshole[3]. ";" .$asshole[7]. ";" .$asshole[9]. ";" .$asshole[10]. ";" .$asshole[13]. ";" .$asshole[12]. ";" .$asshole[14]. ";" .$asshole[15]. ";" .$asshole[16]. ";" .$asshole[17]. "\n";
 }
 close FILE;
 
 ## Escrevendo arquivo AgentQueue.Data 
 unless(open FILE,">>$agentqueuefile") {die};
 $agqueue = $dbhcreate->prepare("select * from AgentQueueFifteenMinHistory where control_id=$control_id");
 $agqueue->execute();
 
 while (@myhole = $agqueue->fetchrow_array) {
  &fix_hour($myhole[3]);
  if ($myhole[9] > 900) {
   $log->info("Incoerencia encontrada para o agente $myhole[6] : Totalworkdur maior que 900 - Intervalo: $hora:$minuto");
  }

  print FILE "15;" . $myhole[2]. ";" .$time. ":" . $myhole[4] . ";" .$myhole[5]. ";" .$myhole[6]. ";" .$myhole[7]. ";" .$myhole[8]. ";" .$myhole[9]. ";" .$myhole[11]. ";" .$myhole[12]. ";" .$myhole[13] . "\n";
 }
 
 close FILE;
 $log->info("createfiles.pl - Final do script ok");
}

sub fix_hour {
 $time = $_[0];
 $len_time = length($time);
 if ($len_time == 2) {
  return $time;
 }
 else {
  $time = "0$time";
  return $time;
 }
}
