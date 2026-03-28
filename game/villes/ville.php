<?php
session_start();
require '../../config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../profil/login.php");
    exit;
}

/* ===== USER ===== */
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$_SESSION['user_id']]);
$user = $stmt->fetch();

/* ===== CHECK ID ===== */
if (!isset($_GET['id'])) {
    die("Ville introuvable");
}

$ville_id = intval($_GET['id']);

/* ===== RÉCUP VILLE ===== */
$stmt = $pdo->prepare("SELECT * FROM villes WHERE id = ?");
$stmt->execute([$ville_id]);
$ville = $stmt->fetch();

if (!$ville) {
    die("Ville inexistante");
}

/* ===== RÉCUP BÂTIMENTS ===== */
$stmt = $pdo->prepare("SELECT * FROM batiments WHERE ville_id = ?");
$stmt->execute([$ville_id]);
$points = $stmt->fetchAll();
?>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title><?= htmlspecialchars($ville['nom']) ?> - Les Terres de Couronne</title>

<style>

/* RESET */
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;
    overflow: hidden;
}

/* MAP */
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
}

/* overlay */
.overlay {
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.5);
    z-index: 1;
}

/* UI */
header {
    position: relative;
    z-index: 3;
    text-align: center;
    font-size: 40px;
    color: #d4af37;
    margin-top: 30px;
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
    font-size: 14px;
}

.profile-icon {
    position: absolute;
    top: 20px;
    left: 20px;
    z-index: 3;
    cursor: pointer;
    font-size: 30px;
    background: rgba(0,0,0,0.6);
    padding: 5px 10px;
    border: 1px solid #d4af37;
    border-radius: 5px;
}

.profile-box {
    position: absolute;
    top: 80px;
    left: 20px;
    z-index: 4;
    width: 250px;
    padding: 20px;
    background: #f4e4bc;
    color: #3b2b1a;
    border: 4px solid #8b5a2b;
    display: none;
    box-shadow: 0 10px 30px rgba(0,0,0,0.8);
}

/* MAP POINTS */
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

.point {
    position: absolute;
    transform: translate(-50%, -100%);
}

.btn {
    padding: 10px 18px;
    font-size: 14px;
    color: #d4af37;
    border: 2px solid #d4af37;
    background: rgba(0,0,0,0.7);
    text-decoration: none;
}

/* glow */
.hover-zone {
    position: absolute;
    width: 140px;
    height: 140px;
    transform: translate(-50%, -70%);
    border-radius: 50%;
    filter: blur(20px);
}

.tavern:hover .hover-zone { box-shadow: 0 0 50px rgba(255,180,50,0.7); }
.market:hover .hover-zone { box-shadow: 0 0 50px rgba(255,200,100,0.7); }
.townhall:hover .hover-zone { box-shadow: 0 0 60px rgba(212,175,55,0.8); }
.barracks:hover .hover-zone { box-shadow: 0 0 50px rgba(255,80,80,0.7); }
.bank:hover .hover-zone { box-shadow: 0 0 50px rgba(100,200,255,0.7); }
.map-point:hover .hover-zone { box-shadow: 0 0 50px rgba(100,255,150,0.7); }
.port:hover .hover-zone { box-shadow: 0 0 50px rgba(0,191,255,0.7); }
.forge:hover .hover-zone { box-shadow: 0 0 50px rgba(255,69,0,0.7); }
.temple:hover .hover-zone { box-shadow: 0 0 50px rgba(255,255,255,0.7); }
.academy:hover .hover-zone { box-shadow: 0 0 50px rgba(138,43,226,0.7); }
.druid:hover .hover-zone { box-shadow: 0 0 50px rgba(50,205,50,0.7); }
.mine:hover .hover-zone { box-shadow: 0 0 50px rgba(105,105,105,0.7); }

</style>
</head>

<body>
  
<div class="map-container">
    <img src="../../assets/villes/<?= $ville['image'] ?>" class="map-img">
</div>

<div class="overlay"></div>

<!-- UI -->
<a href="../../logout.php" class="logout">Déconnexion</a>

<div class="profile-icon" onclick="toggleProfile()">👤</div>

<div class="profile-box" id="profileBox">
    <h3 style="margin-top:0"><?= htmlspecialchars($user['username']) ?></h3>
    <hr>
    <p>💰 Argent : <?= $user['argent'] ?></p>
    <p>🍗 Faim : <?= $user['faim'] ?></p>
    <p>⭐ Réputation : <?= $user['reputation'] ?></p>
</div>

<header><?= $ville['emoji'] ?> <?= $ville['nom'] ?></header>

<div class="map">
    <div class="map-points">

        <?php foreach ($points as $p): ?>
            <div class="point <?= $p['class'] ?>" 
                 style="top: <?= $p['pos_y'] ?>; left: <?= $p['pos_x'] ?>;">

                <a href="<?= $p['lien'] ?>" class="btn">
                    <?= $p['icon'] ?> <?= $p['nom'] ?>
                </a>

                <div class="hover-zone"></div>
            </div>
        <?php endforeach; ?>

    </div>
</div>

<script>
function toggleProfile() {
    let box = document.getElementById("profileBox");
    box.style.display = (box.style.display === "block") ? "none" : "block";
}
</script>

</body>
</html>