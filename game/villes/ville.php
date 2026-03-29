<?php
session_start();
require '../../config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../../profil/login.php");
    exit;
}

/* ===== RÉCUP JOUEUR ===== */
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
<title><?= $ville['nom'] ?> - Les Terres de Couronne</title>

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
    transition: 0.3s;
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
    transition: 0.3s;
}

.profile-icon:hover {
    background: rgba(0,0,0,0.9);
    box-shadow: 0 0 10px #d4af37;
}

.profile-box {
    position: absolute;
    top: 80px;
    left: 20px;
    z-index: 3;

    width: 250px;
    padding: 20px;

    background: #f4e4bc;
    color: #3b2b1a;

    border: 4px solid #8b5a2b;
    border-radius: 10px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.5);

    display: none;
}

.profile-box h3 {
    margin-top: 0;
    border-bottom: 1px solid #8b5a2b;
    padding-bottom: 5px;
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
    text-align: center;
    transition: transform 0.3s ease;
}

.point:hover {
    transform: translate(-50%, -105%) scale(1.1);
}

.btn {
    display: inline-block;
    padding: 6px 14px;
    font-size: 15px;
    color: #fff;
    text-shadow: 0 0 5px #000;
    background: rgba(0,0,0,0.4);
    border: 1px solid rgba(212, 175, 55, 0.3);
    border-radius: 4px;
    text-decoration: none;
    transition: 0.3s;
    white-space: nowrap;
    backdrop-filter: blur(2px);
}

.point:hover .btn {
    background: rgba(0,0,0,0.8);
    border-color: #d4af37;
    color: #d4af37;
    box-shadow: 0 0 15px rgba(212, 175, 55, 0.5);
}

/* glow */
.hover-zone {
    position: absolute;
    width: 160px;
    height: 160px;
    top: 50px; /* Aligné avec le bâtiment sous le label */
    left: 50%;
    transform: translateX(-50%);
    border-radius: 50%;
    filter: blur(30px);
    pointer-events: none;
    transition: 0.4s ease;
    opacity: 0;
    z-index: -1;
}

.point:hover .hover-zone {
    opacity: 1;
}

/* Couleurs de glow par bâtiment (glow externe plus naturel) */
.tavern:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(255,180,50,0.5); }
.market:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(255,200,100,0.5); }
.townhall:hover .hover-zone { box-shadow: 0 0 70px 25px rgba(212,175,55,0.6); }
.barracks:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(255,80,80,0.5); }
.bank:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(100,200,255,0.5); }
.map-point:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(100,255,150,0.5); }
.port:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(0,191,255,0.5); }
.forge:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(255,69,0,0.5); }
.temple:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(255,255,255,0.5); }
.academy:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(138,43,226,0.5); }
.druid:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(50,205,50,0.5); }
.mine:hover .hover-zone { box-shadow: 0 0 60px 20px rgba(105,105,105,0.5); }

</style>
</head>

<body>
  
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
    <p>💰 Argent : <?= $user['argent'] ?></p>
    <p>🍗 Faim : <?= $user['faim'] ?></p>
    <p>⭐ Réputation : <?= $user['reputation'] ?></p>
</div>

<div class="map">
    <div class="map-points">

        <?php
        $has_map = false;
        foreach ($points as $p):
            if ($p['class'] === 'map-point') $has_map = true;
        ?>
            <div class="point <?= $p['class'] ?>" 
                 style="top: <?= $p['pos_y'] ?>; left: <?= $p['pos_x'] ?>;">

                <a href="<?= $p['lien'] ?>" class="btn">
                    <?= $p['icon'] ?> <?= $p['nom'] ?>
                </a>

                <div class="hover-zone"></div>
            </div>
        <?php endforeach; ?>

        <?php if (!$has_map): ?>
            <!-- Point Carte automatique s'il n'est pas déjà défini en BDD -->
            <div class="point map-point" style="top: 85%; left: 85%;">
                <a href="../map.php" class="btn">🗺️ Carte</a>
                <div class="hover-zone"></div>
            </div>
        <?php endif; ?>

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