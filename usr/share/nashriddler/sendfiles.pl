#!/usr/bin/perl
sub sendfiles {
 my $queuefile = "/usr/share/nashriddler/files/Queue_Statistics_" . "$ano" . "_" . "$hora" . "_" . "$minuto" . ".csv";
 my $agentfile = "/usr/share/nashriddler/files/Agent_Statistics_" . "$ano" . "_" . "$hora" . "_" . "$minuto" . ".csv";
 my $agentqueuefile = "/usr/share/nashriddler/files/AgentQueue_Statistics_" . "$ano" . "_" . "$hora" . "_" . "$minuto" . ".csv";


 system("rsync -a $queuefile $host");
 
 if ($? == 0) {
  $log->info("Arquivo enviado com sucesso");
 } else {
    $log->error("Status de envio: " .$?."\n");
   }

 system("rsync -a $agentfile $host");
 
 if ($? == 0) {
  $log->info("Arquivo enviado com sucesso");
 } else {
    $log->error("Status de envio: " .$?."\n");
   }

 system("rsync -a $agentqueuefile $host");
 
 if ($? == 0) {
  $log->info("Arquivo enviado com sucesso");
 } else {
    $log->error("Status de envio: " .$?."\n");
   }
 
 $log->info("sub sendfiles - Final do script ok");
}
