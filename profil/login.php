<?php
session_start();
require '../config.php';

$message = "";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];

    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password'])) {
        $_SESSION['user_id'] = $user['id'];
        header("Location: ../game/game.php");
        exit;
    } else {
        $message = "Identifiants incorrects";
    }
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Connexion - Les Terres de Couronne</title>

<style>
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;
    text-align: center;

    background: 
        linear-gradient(rgba(0,0,0,0.6), rgba(0,0,0,0.9)),
        url('../assets/background.jpg');

    background-size: cover;
    background-position: center;
    height: 100vh;
}

/* Titre */
header {
    position: absolute;
    top: 40px;
    width: 100%;
}

header h1 {
    font-size: 60px;
    color: #d4af37;
    text-shadow: 0 0 20px #000;
}

/* Bloc */
.form-box {
    margin-top: 180px;
    display: inline-block;
    padding: 40px;
    background: rgba(0,0,0,0.7);
    border: 2px solid #d4af37;
    border-radius: 10px;
}

/* Inputs */
input {
    display: block;
    width: 250px;
    padding: 10px;
    margin: 15px auto;
    border: 1px solid #d4af37;
    background: #111;
    color: #fff;
    border-radius: 5px;
}

/* Bouton */
button {
    padding: 12px 25px;
    margin-top: 10px;
    background: transparent;
    color: #d4af37;
    border: 2px solid #d4af37;
    border-radius: 5px;
    cursor: pointer;
    transition: 0.3s;
}

button:hover {
    background: #d4af37;
    color: black;
}

/* Message */
.message {
    margin-top: 15px;
    color: #ffcc00;
}

/* Lien */
.back {
    display: block;
    margin-top: 20px;
    color: #aaa;
    text-decoration: none;
}

.back:hover {
    color: #fff;
}

/* Footer */
footer {
    position: fixed;
    bottom: 0;
    width: 100%;
    padding: 10px;
    background: linear-gradient(transparent, rgba(0,0,0,0.8));
    color: #777;
}
</style>
</head>

<body>

<header>
    <h1>Connexion</h1>
</header>

<div class="form-box">

    <form method="POST">
        <input type="text" name="username" placeholder="Nom du personnage">
        <input type="password" name="password" placeholder="Mot de passe">
        <button type="submit">Entrer dans le royaume</button>
    </form>

    <div class="message"><?= $message ?></div>

    <a href="../index.php" class="back">← Retour</a>

</div>

<footer>
    © <?= date('Y') ?> - Les Terres de Couronne
</footer>

</body>
</html>