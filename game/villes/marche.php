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

/* ===== RÉCUP VILLE ===== */
$stmt = $pdo->prepare("SELECT * FROM villes WHERE nom = ?");
$stmt->execute([$user['ville']]);
$ville = $stmt->fetch();

// Simulation d'inventaire du marché
$items = [
    ['nom' => 'Pain de campagne', 'prix' => 5, 'icon' => '🥖', 'description' => 'Un pain frais et croustillant.'],
    ['nom' => 'Pomme rouge', 'prix' => 2, 'icon' => '🍎', 'description' => 'Une pomme juteuse du verger.'],
    ['nom' => 'Épée de bois', 'prix' => 50, 'icon' => '⚔️', 'description' => 'Pour l\'entraînement des jeunes recrues.'],
    ['nom' => 'Potion de soin minor', 'prix' => 75, 'icon' => '🧪', 'description' => 'Guérit les petites blessures.'],
];
?>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Marché de <?= htmlspecialchars($user['ville']) ?> - Les Terres de Couronne</title>

<style>

/* RESET */
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;
    background: url('../../assets/villes/<?= $ville['image'] ?? 'durnar.jpg' ?>') no-repeat center center fixed;
    background-size: cover;
}

body::before {
    content: "";
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.7);
}

/* UI COMPONENTS */
.container {
    position: relative;
    z-index: 2;
    text-align: center;
    margin-top: 50px;
    padding: 20px;
}

h1 {
    color: #d4af37;
    font-size: 50px;
    text-shadow: 0 0 15px black;
    margin-bottom: 30px;
}

.market-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    width: 80%;
    margin: 0 auto;
}

.item-card {
    background: rgba(0, 0, 0, 0.8);
    border: 2px solid #8b5a2b;
    border-radius: 10px;
    padding: 20px;
    text-align: left;
    transition: 0.3s;
}

.item-card:hover {
    border-color: #d4af37;
    transform: translateY(-5px);
}

.item-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;
    border-bottom: 1px solid #8b5a2b;
    padding-bottom: 10px;
}

.item-name {
    font-size: 20px;
    color: #d4af37;
    font-weight: bold;
}

.item-price {
    font-size: 18px;
    color: #fff;
}

.item-desc {
    font-style: italic;
    color: #ccc;
    font-size: 14px;
    margin-bottom: 20px;
}

.btn-buy {
    display: block;
    width: 100%;
    padding: 10px;
    text-align: center;
    background: #8b5a2b;
    color: #fff;
    text-decoration: none;
    border-radius: 5px;
    transition: 0.3s;
}

.btn-buy:hover {
    background: #d4af37;
    color: black;
}

.btn {
    display: inline-block;
    padding: 12px 25px;
    color: #d4af37;
    border: 2px solid #d4af37;
    background: rgba(0,0,0,0.8);
    text-decoration: none;
    border-radius: 8px;
    transition: 0.3s;
    margin: 10px;
}

.btn:hover {
    background: #d4af37;
    color: black;
    box-shadow: 0 0 15px #d4af37;
}

/* HEADER ELEMENTS */
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

</style>
</head>

<body>

<!-- UI COMPONENTS -->
<a href="../../logout.php" class="logout">Déconnexion</a>

<div class="profile-icon" onclick="toggleProfile()">👤</div>

<div class="profile-box" id="profileBox">
    <h3>
        <?= htmlspecialchars($user['username']) ?>
        <?php if ($user['role'] === 'maire'): ?>
            <span style="font-size: 14px; background: #8b5a2b; color: #fff; padding: 2px 6px; border-radius: 4px; margin-left: 5px;">Maire</span>
        <?php endif; ?>
    </h3>
    <p>💰 Argent : <?= $user['argent'] ?></p>
    <p>🍗 Faim : <?= $user['faim'] ?></p>
    <p>⭐ Réputation : <?= $user['reputation'] ?></p>
</div>

<div class="container">

    <h1>🛒 Marché de <?= htmlspecialchars($user['ville']) ?></h1>
    <p style="margin-bottom: 40px; color: #ccc;">Les étals sont remplis de marchandises fraîches venues de tout le royaume.</p>

    <div class="market-grid">
        <?php foreach ($items as $item): ?>
        <div class="item-card">
            <div class="item-header">
                <span class="item-name"><?= $item['icon'] ?> <?= $item['nom'] ?></span>
                <span class="item-price">💰 <?= $item['prix'] ?></span>
            </div>
            <p class="item-desc"><?= $item['description'] ?></p>
            <a href="#" class="btn-buy" onclick="alert('Bientôt disponible !')">Acheter</a>
        </div>
        <?php endforeach; ?>
    </div>

    <br><br>
    <a href="../game.php" class="btn">← Quitter le Marché</a>

</div>

<script>
function toggleProfile() {
    let box = document.getElementById("profileBox");
    box.style.display = (box.style.display === "block") ? "none" : "block";
}
</script>

</body>
</html>
