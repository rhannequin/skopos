# Skopos

Skopos calcule, pour une station d'observation et une période donnée, les
fenêtres pendant lesquelles des cibles astronomiques sont observables :
élévation, nuit astronomique, Lune et magnitude limite.

Il s'adresse aux observateurs du réseau [RAPAS](https://rapas.imcce.fr), qui
suivent chaque semaine des alertes (supernovae, sursauts gamma, transitoires)
et des astéroïdes.

## Utilisation

Le formulaire demande :

- la station, par son code d'observatoire du MPC (par exemple `511` pour
  l'Observatoire de Haute-Provence) ou par ses coordonnées
- le diamètre de l'instrument et sa magnitude limite
- la semaine, par défaut celle qui commence le lundi suivant
- jusqu'à 20 cibles à coordonnées fixes, une par ligne

Pour chaque nuit de la semaine, Skopos affiche la nuit astronomique (Soleil
sous −18°) et la phase de la Lune. Pour chaque cible, il affiche :

- le temps passé au-dessus de 20° et de 30°, sur une bande qui va du
  crépuscule à l'aube
- l'élévation maximale, son heure et l'airmass minimale
- la distance à la Lune et la hauteur de la Lune à ce moment
- un verdict : _faisable_ si la cible est au moins une magnitude plus brillante
  que la limite, _limite_ dans la magnitude suivante, _hors de portée_ au-delà,
  _trop basse_ si elle ne passe pas au-dessus de 20°.

Les heures sont en temps universel (UT). Les paramètres sont dans l'URL, donc
un résultat se partage par simple lien. La semaine peut aussi être téléchargée
en CSV.

### Liste de cibles

Une cible par ligne, avec son nom, son ascension droite, sa déclinaison
(J2000) et sa magnitude. Le nom peut contenir des espaces.

```
SN 2026abc 03:12:45.6 -05:30:00 17.2
M1 05:34:31.94 +22:00:52.2 8.4
```

Quand les champs sont séparés par des espaces, les coordonnées s'écrivent en
sexagésimal (`hh:mm:ss` et `±dd:mm:ss`). Les degrés décimaux demandent une
tabulation, une virgule ou un point-virgule entre les champs.

```
EP240315a;150.25;+2.5;16.8
```

Sans magnitude, le verdict devient _magnitude inconnue_. Le signe moins
typographique (−) est accepté. La liste est limitée à 20 cibles et 2 000
caractères.

### Export CSV

Le fichier a une ligne par nuit et par cible, avec les colonnes `date`,
`crepuscule_ut`, `aube_ut`, `lune_eclairee_pct`, `cible`, `magnitude`,
`minutes_au_dessus_20`, `minutes_au_dessus_30`, `hauteur_max_deg`,
`hauteur_max_ut`, `airmass_min`, `distance_lune_deg`, `hauteur_lune_deg` et
`verdict`.

Les champs sont séparés par des virgules et les décimales par des points. Les
heures sont en ISO 8601 UTC. Le fichier commence par une marque d'ordre des
octets (BOM) pour qu'Excel lise les accents. Une nuit sans nuit astronomique
a le verdict _pas de nuit astronomique_, avec des heures et des mesures vides.

## Données

### Éphémérides

Les positions du Soleil et de la Lune viennent de l'éphéméride planétaire
[INPOP21a](https://www.imcce.fr/inpop) de l'[IMCCE](https://www.imcce.fr),
lue par la gem [astronoby](https://github.com/rhannequin/astronoby).

> A. Fienga, P. Deram, A. Di Ruscio, V. Viswanathan, J.I.B. Camargo,
> L. Bernus, M. Gastineau et J. Laskar, « INPOP21a planetary ephemerides »,
> 2021.

Le fichier (environ 22 Mo, de 1897 à 2102) n'est pas versionné, car les
[mentions légales de l'IMCCE](https://www.imcce.fr/mentions-legales) demandent
une autorisation pour reproduire ses données. Il est téléchargé depuis
[ftp.imcce.fr](https://ftp.imcce.fr/pub/ephem/planets/inpop21a/) dans
`storage/ephemerides/`.

```
bin/rails ephemeris:download
```

`bin/setup`, le conteneur de production au démarrage et la CI le téléchargent
s'il manque.

### Codes d'observatoire

Les stations viennent de la
[liste des codes d'observatoire](https://minorplanetcenter.net/iau/lists/ObsCodes.html)
du [Minor Planet Center](https://minorplanetcenter.net). Seuls les
observatoires terrestres sont importés, avec leur longitude et leurs
constantes de parallaxe. Aucune donnée personnelle d'observateur n'est
stockée.

```
bin/rails observatories:import
```

`bin/setup` lance l'import. En production, il se lance avec :

```
bin/kamal app exec "bin/rails observatories:import"
```

### Calculs

Les calculs astronomiques passent par
[astronoby](https://github.com/rhannequin/astronoby) : crépuscules, passages
à une altitude, culminations, positions de la Lune, airmass et coordonnées
géodésiques. Skopos convertit lui-même les constantes de parallaxe du MPC en
position terrestre, et la longitude en décalage de temps solaire moyen pour
découper les nuits.

## Prérequis

- Ruby 4.0.10
- SQLite3
- Un accès réseau à [ftp.imcce.fr](https://ftp.imcce.fr) et à
  [minorplanetcenter.net](https://minorplanetcenter.net) pendant
  l'installation

## Installation

```
git clone git@github.com:rhannequin/skopos.git
cd skopos
bin/setup
```

`bin/setup` crée le fichier `.env` à partir de `.env.example`, prépare la base
de données, télécharge l'éphéméride, importe les codes d'observatoire, puis
lance le serveur de développement.

## Développement

Lancer le serveur de développement :

```
bin/dev
```

L'interface est en français. Tous les textes sont dans
`config/locales/fr.yml`, et une traduction manquante lève une erreur en
développement et en test.

## Tests

Skopos utilise RSpec. Les tests ont besoin de l'éphéméride.

```
bundle exec rspec
```

Les heures de crépuscule et les élévations de référence ont été vérifiées avec
[JPL Horizons](https://ssd.jpl.nasa.gov/horizons/) et
[astropy](https://www.astropy.org).

## CI locale

Pour lancer en local les mêmes vérifications que la CI (style, sécurité,
tests) :

```
bin/ci
```

## Licence

Skopos est distribué sous licence [MIT](LICENSE). Les données INPOP et les
codes d'observatoire restent soumis aux conditions de l'IMCCE et du Minor
Planet Center.
