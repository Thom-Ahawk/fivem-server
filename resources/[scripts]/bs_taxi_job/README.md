# bs_taxi_job (ESX)

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
- `es_extended`
- `oxmysql`

## Notes
- Le patron est détecté par `job.grade_name == "boss"` ou grade `>= 3`.
- Le véhicule unique est configurable via `Config.UniqueGarageVehicle`.
- La tablette s'ouvre au marker garage.
- Les markers garage/mission sont visibles pour tous, mais les actions restent restreintes au job taxi.
- Après action tablette (sortie/rangement/récupération), la liste flotte se rafraîchit automatiquement.
- La sortie véhicule verrouille immédiatement l'état en base (`stored=0`) pour empêcher les doubles sorties.
- Attribution des clés : Déclenche l'événement `bs_taxi:client:giveKeys` (à adapter selon votre script de clés).

## Structure
Le script est préparé pour recevoir des extensions :
- `OpenGarage()` : Stub pour un menu de sélection de véhicule.
- `OpenBossMenu()` : Stub pour intégration avec `esx_society`.
- `StartAdvancedMission(tier)` : Stub pour missions complexes.
