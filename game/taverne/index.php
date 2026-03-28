<?php
session_start();
require '../../config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../../profil/login.php");
    exit;
}
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Tavernes de Rouen</title>

<style>
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;

    background: url('../../assets/ville.jpg') no-repeat center center fixed;
    background-size: cover;
}

body::before {
    content: "";
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.6);
}

.container {
    position: relative;
    z-index: 2;
    text-align: center;
    margin-top: 120px;
}

h1 {
    color: #d4af37;
}

/* cartes */
.taverne {
    display: inline-block;
    margin: 20px;
    padding: 20px;
    width: 260px;

    background: rgba(0,0,0,0.7);
    border: 2px solid #d4af37;
    border-radius: 10px;
}

.btn {
    display: inline-block;
    margin-top: 10px;
    padding: 10px 15px;
    color: #d4af37;
    border: 1px solid #d4af37;
    text-decoration: none;
}

.btn:hover {
    background: #d4af37;
    color: black;
}
</style>
</head>

<body>

<div class="container">

    <h1>🍺 Tavernes de Rouen</h1>

    <!-- Taverne principale -->
    <div class="taverne">
        <h3>Taverne Municipale</h3>
        <p>Le cœur de la ville, où tous se rencontrent.</p>
        <a href="municipal.php" class="btn">Entrer</a>
    </div>

    <!-- future -->
    <div class="taverne">
        <h3>Le Sanglier Noir</h3>
        <p>Un lieu sombre fréquenté par des âmes douteuses.</p>
        <a href="#" class="btn">Bientôt</a>
    </div>

    <br><br>
    <a href="../game.php" class="btn">← Retour ville</a>

</div>

</body>
</html>