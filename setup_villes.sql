-- SQL Script for PHP Game Database Setup
-- Cities and Buildings

SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------
-- Table Structure: villes
-- ---------------------------------------------------------
DROP TABLE IF EXISTS `villes`;
CREATE TABLE `villes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) NOT NULL,
  `emoji` varchar(10) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------
-- Table Structure: batiments
-- ---------------------------------------------------------
DROP TABLE IF EXISTS `batiments`;
CREATE TABLE `batiments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ville_id` int(11) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `icon` varchar(10) DEFAULT NULL,
  `pos_x` varchar(10) NOT NULL DEFAULT '50%',
  `pos_y` varchar(10) NOT NULL DEFAULT '50%',
  `lien` varchar(255) DEFAULT '#',
  `class` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_ville` (`ville_id`),
  CONSTRAINT `fk_ville` FOREIGN KEY (`ville_id`) REFERENCES `villes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------
-- Data Insertion: villes
-- ---------------------------------------------------------
INSERT INTO `villes` (`id`, `nom`, `emoji`, `image`) VALUES
(1, 'Durnar', '🏰', 'durnar.jpg'),
(2, 'Gryceval', '🏔️', 'gryceval.jpg'),
(3, 'Greshorn', '🌿', 'greshorn.jpg'),
(4, 'Aulelve', '🌊', 'aulelve.jpg'),
(5, 'Melrad', '🧙', 'melrad.jpg');

-- ---------------------------------------------------------
-- Data Insertion: batiments
-- ---------------------------------------------------------
INSERT INTO `batiments` (`ville_id`, `nom`, `icon`, `pos_x`, `pos_y`, `lien`, `class`) VALUES
-- Durnar (Capitale Royale)
(1, 'Taverne Royale', '🍺', '30%', '38%', '../taverne/', 'tavern'),
(1, 'Banque Centrale', '🏦', '57%', '72%', '#', 'bank'),
(1, 'Caserne d''Elite', '⚔️', '70%', '48%', '#', 'barracks'),
(1, 'Grand Marché', '🛒', '34%', '62%', '#', 'market'),
(1, 'Hôtel de Ville', '🏛️', '52%', '45%', '#', 'townhall'),
(1, 'Carte du Monde', '🗺️', '75%', '79%', '../map.php', 'map-point'),

-- Gryceval (Forteresse de Montagne)
(2, 'Citadelle de Fer', '🏰', '50%', '35%', '#', 'townhall'),
(2, 'Forge des Anciens', '⚒️', '32%', '65%', '#', 'forge'),
(2, 'Mine de Mythril', '⛏️', '72%', '68%', '#', 'mine'),
(2, 'Caserne du Pic', '⚔️', '22%', '40%', '#', 'barracks'),
(2, 'Poste de Guet', '🏹', '82%', '15%', '#', 'barracks'),

-- Greshorn (Cité Sylvestre)
(3, 'Bosquet de l''Eveil', '🌳', '48%', '32%', '#', 'druid'),
(3, 'Cercle des Archers', '🏹', '68%', '52%', '#', 'barracks'),
(3, 'Scierie du Val', '🪓', '28%', '72%', '#', 'forge'),
(3, 'Taverne de la Forêt', '🍺', '58%', '68%', '#', 'tavern'),
(3, 'Sanctuaire de Gaïa', '✨', '52%', '18%', '#', 'temple'),

-- Aulelve (Port de l''Ouest)
(4, 'Amirauté', '⚓', '52%', '78%', '#', 'port'),
(4, 'Quai des Navigateurs', '🏗️', '28%', '68%', '#', 'port'),
(4, 'Marché à la Criée', '🐟', '72%', '62%', '#', 'market'),
(4, 'Phare d''Argent', '🕯️', '88%', '28%', '#', 'townhall'),
(4, 'Taverne de l''Océan', '🍺', '42%', '52%', '#', 'tavern'),

-- Melrad (Cité des Arcanes)
(5, 'Haute Académie', '🔮', '52%', '28%', '#', 'academy'),
(5, 'Bibliothèque Infinie', '📜', '32%', '48%', '#', 'academy'),
(5, 'Cercle Alchimique', '⚗️', '72%', '48%', '#', 'academy'),
(5, 'Astrolabe', '🔭', '52%', '8%', '#', 'townhall'),
(5, 'Ziggourat de Lumière', '⛪', '52%', '62%', '#', 'temple');

SET FOREIGN_KEY_CHECKS = 1;
