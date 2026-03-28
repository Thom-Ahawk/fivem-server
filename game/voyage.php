<?php
session_start();
require '../config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../profil/login.php");
    exit;
}

// récupérer joueur
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$_SESSION['user_id']]);
$user = $stmt->fetch();

// liste des villes
$villes = [
    "Durnar",
    "Gryceval",
    "Valombre",
    "Greshorn",
    "Melrad",
    "Aulelve"
];

$error = "";

// voyage
if (isset($_GET['ville'])) {
    $destination = $_GET['ville'];
    $cout = 10;

    if (in_array($destination, $villes)) {

        if ($destination == $user['ville']) {
            $error = "Vous êtes déjà dans cette ville.";
        } elseif ($user['argent'] < $cout) {
            $error = "Vous n'avez pas assez d'argent.";
        } else {

            $stmt = $pdo->prepare("UPDATE users SET ville = ?, argent = argent - ? WHERE id = ?");
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
<title>Voyager</title>

<style>
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;

    background: url('../assets/ville.jpg') center/cover no-repeat fixed;
    height: 100vh;
}

/* overlay sombre */
body::before {
    content: "";
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.6);
    z-index: 0;
}

.container {
    position: relative;
    z-index: 2;
    text-align: center;
    margin-top: 80px;
}

h1 {
    color: #d4af37;
    text-shadow: 0 0 15px black;
}

/* villes */
.ville {
    display: inline-block;
    margin: 10px;
    padding: 15px 25px;
    border: 2px solid #d4af37;
    background: rgba(0,0,0,0.7);
    color: #d4af37;
    text-decoration: none;
    border-radius: 8px;
    transition: 0.3s;
}

.ville:hover {
    background: #d4af37;
    color: black;
    transform: scale(1.05);
}

/* ville actuelle */
.current {
    background: rgba(212,175,55,0.2);
    color: #fff;
    border: 2px dashed #d4af37;
    cursor: default;
}

/* bouton retour */
.btn {
    display: inline-block;
    margin-top: 30px;
    padding: 12px 25px;
    border: 2px solid #d4af37;
    color: #d4af37;
    text-decoration: none;
    background: rgba(0,0,0,0.7);
}

.btn:hover {
    background: #d4af37;
    color: black;
}

/* erreur */
.error {
    color: red;
    margin-top: 20px;
}

/* mobile */
@media (max-width: 768px) {
    .ville {
        display: block;
        width: 80%;
        margin: 10px auto;
    }
}
</style>
</head>

<body>

<div class="container">

    <h1>🗺️ Voyager depuis <?= htmlspecialchars($user['ville']) ?></h1>

    <p style="color:#ccc;">
        Choisissez votre destination. Le voyage coûte <strong>10 pièces</strong>.
    </p>

    <?php foreach ($villes as $ville): ?>

        <?php if ($ville == $user['ville']): ?>

            <span class="ville current">
                📍 <?= $ville ?> (actuel)
            </span>

        <?php else: ?>

            <a href="?ville=<?= urlencode($ville) ?>" class="ville">
                🚶 <?= $ville ?> (10💰)
            </a>

        <?php endif; ?>

    <?php endforeach; ?>

    <?php if (!empty($error)): ?>
        <div class="error"><?= $error ?></div>
    <?php endif; ?>

    <br>

    <a href="game.php" class="btn">← Retour à la ville</a>

</div>

</body>
</html>