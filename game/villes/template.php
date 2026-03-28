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

/* ===== ID VILLE ===== */
if (!isset($_GET['id'])) {
    die("Ville introuvable");
}

$ville_id = intval($_GET['id']);

/* ===== VILLE ===== */
$stmt = $pdo->prepare("SELECT * FROM villes WHERE id = ?");
$stmt->execute([$ville_id]);
$ville = $stmt->fetch();

if (!$ville) {
    die("Ville inexistante");
}

/* ===== BATIMENTS ===== */
$stmt = $pdo->prepare("SELECT * FROM batiments WHERE ville_id = ?");
$stmt->execute([$ville_id]);
$points = $stmt->fetchAll();
?>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title><?= $ville['nom'] ?> - Les Terres de Couronne</title>

<style>

/* ===== RESET ===== */
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;
    overflow: hidden;
}

/* ===== MAP ===== */
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

.overlay {
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.5);
    z-index: 1;
}

/* ===== UI ===== */
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
}

.profile-icon {
    position: absolute;
    top: 20px;
    left: 20px;
    z-index: 3;
    cursor: pointer;
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
    display: none;
}

/* ===== MAP POINTS ===== */
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

.hover-zone {
    position: absolute;
    width: 140px;
    height: 140px;
    transform: translate(-50%, -70%);
    border-radius: 50%;
    filter: blur(20px);
}

/* ===== GLOW ===== */
.tavern:hover .hover-zone { box-shadow: 0 0 50px rgba(255,180,50,0.7); }
.bank:hover .hover-zone { box-shadow: 0 0 50px rgba(100,200,255,0.7); }
.barracks:hover .hover-zone { box-shadow: 0 0 50px rgba(255,80,80,0.7); }
.map-point:hover .hover-zone { box-shadow: 0 0 50px rgba(100,255,150,0.7); }
.market:hover .hover-zone { box-shadow: 0 0 50px rgba(255,200,100,0.7); }
.townhall:hover .hover-zone { box-shadow: 0 0 60px rgba(212,175,55,0.8); }

footer {
    position: fixed;
    bottom: 0;
    width: 100%;
    z-index: 3;
    text-align: center;
}

</style>
</head>

<body>

<!-- MAP -->
<div class="map-container">
    <img src="../../assets/villes/<?= $ville['image'] ?>" class="map-img">
</div>

<div class="overlay"></div>

<!-- UI -->
<a href="../../logout.php" class="logout">Déconnexion</a>

<header><?= $ville['emoji'] ?> <?= $ville['nom'] ?></header>

<div class="profile-icon" onclick="toggleProfile()">👤</div>

<div class="profile-box" id="profileBox">
    <h3><?= htmlspecialchars($user['username']) ?></h3>
    <p>💰 <?= $user['argent'] ?></p>
    <p>🍗 <?= $user['faim'] ?></p>
    <p>⭐ <?= $user['reputation'] ?></p>
</div>

<!-- MAP -->
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