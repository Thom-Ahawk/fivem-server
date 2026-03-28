<?php
session_start();
require '../config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../profil/login.php");
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$_SESSION['user_id']]);
$user = $stmt->fetch();

// redirection vers la bonne ville
switch ($user['ville']) {

    case "Durnar":
        header("Location: villes/durnar.php");
        break;

    case "Gryceval":
        header("Location: villes/gryceval.php");
        break;

    case "Greshorn":
        header("Location: villes/greshorn.php");
        break;

    case "Melrad":
        header("Location: villes/melrad.php");
        break;

    case "Aulelve":
        header("Location: villes/aulelve.php");
        break;

    default:
        echo "Ville inconnue";
}

exit;