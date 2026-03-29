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

/* ===== RÉCUP POPULATION (Exemple RP) ===== */
$stmt = $pdo->prepare("SELECT COUNT(*) as pop FROM users WHERE ville = ?");
$stmt->execute([$user['ville']]);
$pop = $stmt->fetch();

/* ===== RÉCUP MAIRE DE LA VILLE ===== */
// On cherche l'utilisateur qui a le rôle 'maire' dans cette ville précise
$stmt = $pdo->prepare("SELECT username FROM users WHERE ville = ? AND role = 'maire' LIMIT 1");
$stmt->execute([$user['ville']]);
$maire = $stmt->fetch();

$is_maire = ($user['role'] === 'maire' && $user['ville'] === $ville['nom']);
?>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Mairie de <?= htmlspecialchars($user['ville']) ?> - Les Terres de Couronne</title>

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

.paper {
    background: #f4e4bc;
    color: #3b2b1a;
    width: 60%;
    margin: 0 auto;
    padding: 40px;
    border: 8px double #8b5a2b;
    border-radius: 4px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.8);
    position: relative;
}

.paper::before {
    content: "";
    position: absolute;
    inset: 0;
    background: url('https://www.transparenttextures.com/patterns/old-map.png');
    opacity: 0.1;
    pointer-events: none;
}

h2 {
    border-bottom: 2px solid #8b5a2b;
    padding-bottom: 10px;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
    margin-top: 30px;
}

.stat-card {
    background: rgba(139, 90, 43, 0.1);
    padding: 15px;
    border: 1px solid #8b5a2b;
    border-radius: 8px;
}

.stat-val {
    font-size: 24px;
    font-weight: bold;
    color: #5c3b1e;
}

.actions {
    margin-top: 40px;
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
    transform: translateY(-2px);
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

    <h1>🏛️ Mairie de <?= htmlspecialchars($user['ville']) ?></h1>

    <div class="paper">
        <h2>📜 Registres de la Ville</h2>

        <p>Bienvenue, honorable citoyen <strong><?= htmlspecialchars($user['username']) ?></strong>.</p>
        <p>Ici sont consignés les édits de la cité et les registres de population.</p>

        <div class="stats-grid">
            <div class="stat-card">
                <div>Population Totale</div>
                <div class="stat-val">👥 <?= $pop['pop'] ?> Âmes</div>
            </div>
            <div class="stat-card">
                <div>Maire de la Cité</div>
                <div class="stat-val">👑 <?= $maire ? htmlspecialchars($maire['username']) : "Aucun" ?></div>
            </div>
            <div class="stat-card">
                <div>Taxes Actuelles</div>
                <div class="stat-val">💰 0%</div>
            </div>
            <div class="stat-card">
                <div>Édits en vigueur</div>
                <div class="stat-val">🛡️ Aucun</div>
            </div>
        </div>

        <?php if ($is_maire): ?>
            <div style="margin-top: 40px; border-top: 2px solid #8b5a2b; padding-top: 20px;">
                <h2 style="color: #8b5a2b;">👑 Bureau du Maire</h2>
                <p>En tant que maire de <strong><?= htmlspecialchars($user['ville']) ?></strong>, vous avez accès aux outils d'administration.</p>

                <div class="actions">
                    <a href="#" class="btn" style="background: #8b5a2b; color: #fff;">📢 Publier un Édit</a>
                    <a href="#" class="btn" style="background: #8b5a2b; color: #fff;">💸 Modifier les Taxes</a>
                    <a href="#" class="btn" style="background: #8b5a2b; color: #fff;">⚔️ Lever l'armée</a>
                </div>
            </div>
        <?php endif; ?>

        <div class="actions">
            <a href="#" class="btn">Changer de Nom (100💰)</a>
            <a href="#" class="btn">Demander une Audience</a>
        </div>
    </div>

    <br><br>
    <a href="../game.php" class="btn">← Quitter la Mairie</a>

</div>

<script>
function toggleProfile() {
    let box = document.getElementById("profileBox");
    box.style.display = (box.style.display === "block") ? "none" : "block";
}
</script>

</body>
</html>
