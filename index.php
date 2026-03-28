<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Les Terres de Couronne</title>

<style>
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;
    text-align: center;

    background: 
        linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.8)),
        url('assets/background.jpg');

    background-size: cover;
    background-position: center;
    height: 100vh;
}

/* Titre en haut */
header, .container, footer {
    position: relative;
    z-index: 2;
}
  
header {
    position: absolute;
    top: 40px;
    width: 100%;
    text-align: center;
}

header h1 {
    font-size: 70px;
    color: #d4af37;
    letter-spacing: 2px;
    text-shadow: 
        0 0 10px #000,
        0 0 20px #000,
        0 0 40px #000;
}

/* Contenu central */
.container {
    margin-top: 220px;
}

/* Texte */
.subtitle {
    font-size: 22px;
    color: #ddd;
    margin-bottom: 40px;
}

/* Boutons */
.btn {
    display: inline-block;
    padding: 14px 30px;
    margin: 10px;
    text-decoration: none;
    color: #d4af37;
    border: 2px solid #d4af37;
    border-radius: 8px;
    background-color: rgba(0,0,0,0.7);
    font-size: 18px;
    transition: 0.3s;
}

.btn:hover {
    background-color: #d4af37;
    color: black;
    box-shadow: 0 0 15px #d4af37;
}

/* Texte RP */
.quote {
    font-style: italic;
    margin-top: 30px;
    color: #aaa;
}

/* Overlay sombre */
.overlay {
    position: absolute;
    width: 100%;
    height: 100%;
    background: radial-gradient(circle, transparent 40%, rgba(0,0,0,0.9));
    top: 0;
    left: 0;
}

/* Footer */
footer {
    position: fixed;
    bottom: 0;
    width: 100%;
    text-align: center;
    padding: 10px 0;

    background: rgba(0,0,0,0.6);
    color: #aaa;
    font-size: 13px;
}
</style>
</head>

<body>

<header>
    <h1>Les Terres de Couronne</h1>
</header>

<div class="container">

    <p class="subtitle">
        Un monde médiéval vivant où intrigues, pouvoir et destin s’entrelacent.
    </p>

    <a href="profil/login.php" class="btn">Connexion</a>
    <a href="profil/register.php" class="btn">Inscription</a>

    <p class="quote">
        Le destin des royaumes repose entre vos mains...
    </p>

</div>

<footer>
    © <?= date('Y') ?> - Les Terres de Couronne
</footer>

</body>
</html>