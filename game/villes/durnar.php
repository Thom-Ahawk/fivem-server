<?php
session_start();
require '../../config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../profil/login.php");
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$_SESSION['user_id']]);
$user = $stmt->fetch();
?>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Ville - Les Terres de Couronne</title>

<style>

/* RESET */
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;
    overflow: hidden;
}

/* ================= MAP ================= */

.map-container {
    position: fixed;
    inset: 0;
    overflow: hidden;
    z-index: 0;
}

.map-img {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) scale(0.85);
    min-width: 100%;
    min-height: 100%;
    transition: transform 0.3s ease;
}

/* overlay sombre */
.overlay {
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.5);
    z-index: 1;
}

/* ================= UI ================= */

header {
    position: relative;
    z-index: 3;
    text-align: center;
    font-size: 40px;
    color: #d4af37;
    margin-top: 30px;
    text-shadow: 0 0 15px #000;
}

.logout {
    position: absolute;
    top: 20px;
    right: 20px;
    z-index: 3;

    padding: 8px 15px;
    color: #d4af37;
    border: 1px solid #d4af37;
    background: rgba(0,0,0,0.6);
    text-decoration: none;
}

.logout:hover {
    background: #d4af37;
    color: black;
}

/* profil */
.profile-icon {
    position: absolute;
    top: 20px;
    left: 20px;
    z-index: 3;

    font-size: 24px;
    cursor: pointer;

    background: rgba(0,0,0,0.7);
    padding: 8px 12px;
    border: 1px solid #d4af37;
    border-radius: 50%;
}

.profile-box {
    position: absolute;
    top: 80px;
    left: 20px;
    z-index: 3;

    width: 320px;
    padding: 20px;

    background: #f4e4bc;
    color: #3b2b1a;

    border: 4px solid #8b5a2b;
    border-radius: 10px;

    display: none;
}

/* ================= MAP POINTS ================= */

.map {
    position: relative;
    width: 100%;
    height: 100vh;
    z-index: 2;
}

.map-points {
    position: absolute;
    inset: 0;
}

/* boutons */
.point {
    position: absolute;
    transform: translate(-50%, -50%);
}

.btn {
    padding: 10px 18px;
    font-size: 14px;
    color: #d4af37;
    border: 2px solid #d4af37;
    border-radius: 8px;
    background: rgba(0,0,0,0.7);
    text-decoration: none;
    transition: 0.3s;
    backdrop-filter: blur(4px);
}

.btn:hover {
    background: #d4af37;
    color: black;
    box-shadow: 0 0 20px #d4af37;
    transform: scale(1.1);
}

/* footer */
footer {
    position: fixed;
    bottom: 0;
    width: 100%;
    z-index: 3;
    text-align: center;
    padding: 10px;
    background: linear-gradient(transparent, rgba(0,0,0,0.8));
}

  /* position du bouton (au-dessus du bâtiment) */
.point {
    position: absolute;
    transform: translate(-50%, -100%);
}

/* zone glow */
.hover-zone {
    position: absolute;
    width: 140px;
    height: 140px;
    top: 0;
    left: 0;
    transform: translate(-50%, -70%);
    border-radius: 50%;
    filter: blur(20px);
    pointer-events: none;
    transition: 0.3s;
}

/* GLOW PAR BÂTIMENT */

.tavern:hover .hover-zone {
    box-shadow: 0 0 50px 25px rgba(255, 180, 50, 0.7);
}

.bank:hover .hover-zone {
    box-shadow: 0 0 50px 25px rgba(100, 200, 255, 0.7);
}

.barracks:hover .hover-zone {
    box-shadow: 0 0 50px 25px rgba(255, 80, 80, 0.7);
}

.map-point:hover .hover-zone {
    box-shadow: 0 0 50px 25px rgba(100, 255, 150, 0.7);
}
  
/* Marché → chaud / vivant */
.market:hover .hover-zone {
    box-shadow: 0 0 50px 25px rgba(255, 200, 100, 0.7);
}

/* Mairie → doré / important */
.townhall:hover .hover-zone {
    box-shadow: 0 0 60px 30px rgba(212, 175, 55, 0.8);
}
</style>
</head>

<body>

<!-- MAP -->
<div class="map-container">
    <img src="../../assets/ville.jpg" class="map-img">
</div>

<div class="overlay"></div>

<!-- UI -->
<a href="../../logout.php" class="logout">Déconnexion</a>

<header>🏰 Durnar</header>

<div class="profile-icon" onclick="toggleProfile()">👤</div>

<div class="profile-box" id="profileBox">
    <h3><?= htmlspecialchars($user['username']) ?></h3>
    <p>💰 <?= $user['argent'] ?></p>
    <p>🍗 <?= $user['faim'] ?></p>
    <p>⭐ <?= $user['reputation'] ?></p>
</div>

<!-- MAP INTERACTIVE -->
<div class="map">
    <div class="map-points">

        <!-- 🍺 Taverne -->
        <div class="point tavern" style="top: 38%; left: 30%;">
            <a href="../taverne/" class="btn">🍺 Taverne</a>
            <div class="hover-zone"></div>
        </div>

        <!-- 🏦 Banque -->
        <div class="point bank" style="top: 72%; left: 57%;">
            <a href="#" class="btn">🏦 Banque</a>
            <div class="hover-zone"></div>
        </div>

        <!-- ⚔️ Caserne -->
        <div class="point barracks" style="top: 48%; left: 70%;">
            <a href="#" class="btn">⚔️ Caserne</a>
            <div class="hover-zone"></div>
        </div>

        <!-- 🗺️ Carte -->
        <div class="point map-point" style="top: 79%; left: 75%;">
            <a href="../map.php" class="btn">🗺️ Carte</a>
            <div class="hover-zone"></div>
        </div>

       <!-- 🛒 Marché -->
<div class="point market" style="top: 62%; left: 34%;">
    <a href="#" class="btn">🛒 Marché</a>
    <div class="hover-zone"></div>
</div>

<!-- 🏛️ Mairie -->
<div class="point townhall" style="top: 45%; left: 52%;">
    <a href="#" class="btn">🏛️ Mairie</a>
    <div class="hover-zone"></div>
</div>
      
    </div>
</div>

<footer>
    © <?= date('Y') ?> - Les Terres de Couronne
</footer>

<script>
function toggleProfile() {
    let box = document.getElementById("profileBox");
    box.style.display = (box.style.display === "block") ? "none" : "block";
}
</script>

</body>
</html>