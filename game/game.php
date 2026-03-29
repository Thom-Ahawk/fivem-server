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

// redirection vers la bonne ville (ID correspondant à setup_villes.sql)
$villes_ids = [
    "Durnar"   => 1,
    "Gryceval" => 2,
    "Greshorn" => 3,
    "Aulelve"  => 4,
    "Melrad"   => 5,
];

if (isset($villes_ids[$user['ville']])) {
    $id = $villes_ids[$user['ville']];
    header("Location: villes/ville.php?id=$id");
} else {
    echo "Ville inconnue : " . htmlspecialchars($user['ville']);
}

exit;
