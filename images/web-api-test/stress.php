<?php
    echo "start stressing";
    flush();
    
    $data = str_repeat('a',1024*1024);
    sleep(5); //needed, else this finishes too quickly
    echo $data;
    flush();

    echo "stressing finished";
    flush();
?>