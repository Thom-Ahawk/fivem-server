# bs_taxi_job (QBCore)

Job taxi avec:
- Missions PNJ (prise en charge + destination)
- Garage entreprise avec tablette jaune (NUI)
- Véhicule unique d'entreprise achetable uniquement par le patron
- Liste des véhicules par plaque avec dégâts restants + essence

## Installation

1. Copier `bs_taxi_job` dans vos `resources`.
2. Importer `sql/bs_taxi_fleet.sql`.
3. Ajouter dans `server.cfg`:

```cfg
ensure bs_taxi_job
```

## Dépendances
- `qb-core`
- `oxmysql`

## Notes
- Le patron est détecté par `job.grade.name == "boss"` ou grade `>= 4`.
- Le véhicule unique est configurable via `Config.UniqueGarageVehicle`.
- La tablette s'ouvre au marker garage.
- Si la tablette affiche une liste vide / `vehicles: null`, vérifiez que la table `bs_taxi_fleet` est bien importée.
- Les markers garage/mission sont visibles pour tous, mais les actions restent restreintes au job taxi côté serveur.
- Si un véhicule reste bloqué en `En circulation` après reboot/crash, le script resynchronise automatiquement l'état au prochain refresh du garage.
- Le patron peut aussi forcer la récupération via le bouton tablette `Récupérer bloqués`.
- Si un véhicule reste `En circulation` malgré tout, le patron peut utiliser le bouton `Forcer retour` sur la ligne du véhicule.
- Si `Config.Blips` est cassé/mal chargé, le script utilise un fallback pour les points Garage/Mission et log un avertissement serveur.
- Après action tablette (sortie/rangement/récupération), la liste flotte se rafraîchit automatiquement.
- Le backend normalise et caste `stored` (0/1/true/false/string) pour éviter les états incohérents selon la config MySQL.
- La sortie véhicule verrouille immédiatement l'état en base (`stored=0`) pour empêcher les doubles sorties et donne automatiquement les clés (qb-vehiclekeys).
- L'attribution des clés tente plusieurs hooks QBCore (`SetOwner`, `AddKeys`, `AcquireVehicleKeys`) pour compatibilité selon votre version de `qb-vehiclekeys`.
- L'attribution des clés est tentée côté client **et** côté serveur après spawn pour maximiser la compatibilité.
- Le véhicule est également déverrouillé côté client au spawn (fallback) pour éviter le blocage d'entrée si votre script de clés est custom.
- Une série de retries (2s env.) est effectuée après le spawn pour couvrir les délais d'initialisation réseau de `qb-vehiclekeys`.
- Avec `qb-vehiclekeys` stock, la voie principale utilisée est `qb-vehiclekeys:server:AcquireVehicleKeys` avec la plaque lue sur le véhicule spawn.
- Le lock state est aussi forcé en `unlock` au spawn via `qb-vehiclekeys:server:setVehLockState` et les clés sont re-sync via `GetVehicleKeys`.