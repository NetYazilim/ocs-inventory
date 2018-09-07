<?php

if (rename('install.php' , 'install.bak')) {
    echo "install.php renemad to install.bak";
} else echo "error";
