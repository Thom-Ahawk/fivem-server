<?php
session_start();
require '../config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../profil/login.php");
    exit;
}

// 🔹 Récupération joueur
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$_SESSION['user_id']]);
$user = $stmt->fetch();

// 🔹 Liste des villes + positions (%)
$villes = [
    "Durnar"   => [34, 44],
    "Gryceval" => [34, 83],
    "Greshorn" => [71, 40],
    "Melrad"   => [67, 81],
    "Aulelve"  => [81, 92],
];

$error = "";

// 🔹 Gestion voyage
if (isset($_GET['ville'])) {
    $destination = $_GET['ville'];
    $cout = 10;

    if (array_key_exists($destination, $villes)) {

        if ($destination === $user['ville']) {
            $error = "Vous êtes déjà dans cette ville.";
        } elseif ($user['argent'] < $cout) {
            $error = "Vous n'avez pas assez d'argent.";
        } else {

            $stmt = $pdo->prepare("
                UPDATE users 
                SET ville = ?, argent = argent - ? 
                WHERE id = ?
            ");
            $stmt->execute([$destination, $cout, $user['id']]);

            header("Location: game.php");
            exit;
        }
    }
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Carte du Royaume</title>

<style>

/* ===== GLOBAL ===== */
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;
}

/* ===== MAP ===== */
.map {
    position: relative;
    width: 100%;
    height: 100vh;

    background: url('../assets/map.jpg') center top no-repeat;
    background-size: 100% auto; /* ← clé */
}
/* ===== HEADER ===== */
.title {
    position: absolute;
    top: 20px;
    width: 100%;
    text-align: center;
    color: #d4af37;
    text-shadow: 0 0 15px black;
    z-index: 2;
}

/* ===== CITY ===== */
.city {
    position: absolute;
    transform: translate(-50%, -50%);
}

/* point lumineux */
.city::before {
    content: "";
    position: absolute;
    width: 8px;
    height: 8px;
    background: #d4af37;
    border-radius: 50%;
    top: -6px;
    left: 50%;
    transform: translateX(-50%);
    box-shadow: 0 0 10px #d4af37;
}

/* label */
.city-label {
    text-decoration: none;
    color: #fff;
    background: rgba(0,0,0,0.8);
    padding: 6px 10px;
    border: 1px solid #d4af37;
    border-radius: 6px;
    font-size: 13px;
    transition: 0.3s;
    white-space: nowrap;
}

/* hover */
.city-label:hover {
    background: #d4af37;
    color: black;
    transform: scale(1.1);
}

/* ville actuelle */
.current .city-label {
    background: rgba(212,175,55,0.25);
    border: 1px dashed #d4af37;
    cursor: default;
}

/* ===== BACK BUTTON ===== */
.back {
    position: absolute;
    bottom: 20px;
    left: 20px;
    text-decoration: none;
    color: #fff;
    background: rgba(0,0,0,0.7);
    padding: 10px 15px;
    border: 1px solid #d4af37;
    border-radius: 6px;
}

/* ===== ERROR ===== */
.error {
    position: absolute;
    bottom: 20px;
    right: 20px;
    color: red;
}

/* ===== MOBILE ===== */
@media (max-width: 768px) {
    .city-label {
        font-size: 11px;
        padding: 5px 8px;
    }
}

</style>
</head>

<body>

<div class="map">

    <!-- TITRE -->
    <div class="title">
        <h1>🗺️ Royaume de Chalor</h1>
        <p>Choisissez votre destination. Les routes sont dangereuses...</p>
    </div>

    <!-- VILLES -->
    <?php foreach ($villes as $ville => $pos): ?>
        <div class="city <?= ($ville === $user['ville']) ? 'current' : '' ?>"
             style="left: <?= $pos[0] ?>%; top: <?= $pos[1] ?>%;">

            <?php if ($ville === $user['ville']): ?>
                <span class="city-label">📍 <?= $ville ?></span>
            <?php else: ?>
                <a href="?ville=<?= urlencode($ville) ?>" class="city-label">
                    🏇 <?= $ville ?>
                </a>
            <?php endif; ?>

        </div>
    <?php endforeach; ?>

    <!-- RETOUR -->
    <a href="game.php" class="back">← Retour</a>

    <!-- ERREUR -->
    <?php if (!empty($error)): ?>
        <div class="error"><?= $error ?></div>
    <?php endif; ?>

</div>

</body>
</html>