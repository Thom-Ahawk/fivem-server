-- SQL Script to setup cities and buildings
-- Table: villes (id, nom, emoji, image)
-- Table: batiments (ville_id, nom, icon, pos_x, pos_y, lien, class)

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE batiments;
TRUNCATE TABLE villes;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO villes (id, nom, emoji, image) VALUES
(1, 'Durnar', '🏰', 'durnar.jpg'),
(2, 'Gryceval', '🏔️', 'gryceval.jpg'),
(3, 'Greshorn', '🌿', 'greshorn.jpg'),
(4, 'Aulelve', '🌊', 'aulelve.jpg'),
(5, 'Melrad', '🧙', 'melrad.jpg');

INSERT INTO batiments (ville_id, nom, icon, pos_x, pos_y, lien, class) VALUES
-- Durnar (Capitale Classique)
(1, 'Taverne', '🍺', '30%', '38%', '../taverne/', 'tavern'),
(1, 'Banque', '🏦', '57%', '72%', '#', 'bank'),
(1, 'Caserne', '⚔️', '70%', '48%', '#', 'barracks'),
(1, 'Marché', '🛒', '34%', '62%', '#', 'market'),
(1, 'Mairie', '🏛️', '52%', '45%', '#', 'townhall'),
(1, 'Carte', '🗺️', '75%', '79%', '../map.php', 'map-point'),

-- Gryceval (Montagne & Militaire)
(2, 'Grand Hall', '🏰', '50%', '40%', '#', 'townhall'),
(2, 'Forge d''Acier', '⚒️', '30%', '60%', '#', 'forge'),
(2, 'Mine Profonde', '⛏️', '70%', '65%', '#', 'mine'),
(2, 'Caserne Nord', '⚔️', '25%', '35%', '#', 'barracks'),
(2, 'Tour de Guet', '🏹', '80%', '20%', '#', 'barracks'),
(2, 'Carte', '🗺️', '85%', '85%', '../map.php', 'map-point'),

-- Greshorn (Forêt & Nature)
(3, 'Bosquet Druidique', '🌳', '45%', '35%', '#', 'druid'),
(3, 'Archerie', '🏹', '65%', '50%', '#', 'barracks'),
(3, 'Scierie', '🪓', '30%', '70%', '#', 'forge'),
(3, 'Taverne de la Sève', '🍺', '55%', '65%', '#', 'tavern'),
(3, 'Autel Ancien', '✨', '50%', '15%', '#', 'temple'),
(3, 'Carte', '🗺️', '85%', '85%', '../map.php', 'map-point'),

-- Aulelve (Cotière & Port)
(4, 'Port Royal', '⚓', '50%', '75%', '#', 'port'),
(4, 'Chantier Naval', '🏗️', '25%', '65%', '#', 'port'),
(4, 'Marché aux Poissons', '🐟', '70%', '60%', '#', 'market'),
(4, 'Phare', '🕯️', '85%', '30%', '#', 'townhall'),
(4, 'Le Vieux Marin', '🍺', '40%', '50%', '#', 'tavern'),
(4, 'Carte', '🗺️', '85%', '85%', '../map.php', 'map-point'),

-- Melrad (Savante & Magie)
(5, 'Académie de Magie', '🔮', '50%', '30%', '#', 'academy'),
(5, 'Grande Bibliothèque', '📜', '30%', '45%', '#', 'academy'),
(5, 'Labo d''Alchimie', '⚗️', '70%', '45%', '#', 'academy'),
(5, 'Observatoire', '🔭', '50%', '10%', '#', 'townhall'),
(5, 'Temple Stellaire', '⛪', '50%', '60%', '#', 'temple'),
(5, 'Carte', '🗺️', '85%', '85%', '../map.php', 'map-point');
