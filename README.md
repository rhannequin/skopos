# Skopos

Skopos calcule, pour une station d'observation et une période donnée, les
fenêtres pendant lesquelles des cibles astronomiques sont observables :
élévation, nuit astronomique, Lune et magnitude limite.

## Prérequis

- Ruby 4.0.10
- SQLite3

## Installation

```
git clone git@github.com:rhannequin/skopos.git
cd skopos
bin/setup
```

`bin/setup` crée le fichier `.env` à partir de `.env.example`, prépare la base
de données puis lance le serveur de développement.

## Développement

Lancer le serveur de développement :

```
bin/dev
```

## Tests

Skopos utilise RSpec :

```
bundle exec rspec
```

## CI locale

Pour lancer en local les mêmes vérifications que la CI (style, sécurité,
tests) :

```
bin/ci
```

## Licence

Skopos est distribué sous licence [MIT](LICENSE).
