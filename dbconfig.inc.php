<?php
define("DB_NAME", getenv('OCS_DBNAME'));
define("SERVER_READ", getenv('OCS_DBHOST'));
define("SERVER_WRITE", getenv('OCS_DBHOST'));
define("COMPTE_BASE", getenv('OCS_DBUSER'));
define("PSWD_BASE", getenv('OCS_DBPASS'));
$_SESSION["PSWD_BASE"]=PSWD_BASE;
?>
