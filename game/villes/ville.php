<?php
session_start();
require '../../config.php';

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
<head>
<meta charset="UTF-8">
<title><?= $ville['nom'] ?></title>

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

</style>
</head>
</head>

<body>
  
<div class="map-container">
    <img src="../../assets/villes/<?= $ville['image'] ?>" class="map-img">
</div>

<div class="overlay"></div>

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

</body>
</html>