<?php
session_start();

// vider la session
$_SESSION = [];

// détruire
session_destroy();

// redirection accueil
header("Location: index.php");
exit;