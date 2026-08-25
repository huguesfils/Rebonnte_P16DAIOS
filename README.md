# MediStock

Application iOS de gestion des stocks de médicaments : suivi par rayon, mouvements de stock et historique d'audit des modifications.

## Prérequis

- Xcode 16 ou supérieur (le projet utilise les dossiers synchronisés, `objectVersion 70`)
- iOS 18 minimum
- Swift 6, **mode langage strict** : la cible compile sans erreur ni avertissement de concurrence
- [SwiftLint](https://github.com/realm/SwiftLint) pour le lint local : `brew install swiftlint`

## Démarrer

```sh
git clone https://github.com/huguesfils/Rebonnte_P16DAIOS.git
cd Rebonnte_P16DAIOS
open MediStock.xcodeproj
```

Le projet **compile et les tests passent sans configuration supplémentaire**. Aucune étape d'installation n'est nécessaire pour contribuer ou lancer la suite de tests.

## Configuration Firebase

`GoogleService-Info.plist` n'est **pas versionné** — il contient les identifiants du projet Firebase. Il est nécessaire uniquement pour **exécuter** l'application, pas pour la compiler ni pour lancer les tests.

Pour l'obtenir : console Firebase → projet `medistock-8b739` → Paramètres du projet → application iOS `com.rebonnte.MediStock` → télécharger `GoogleService-Info.plist`, puis le déposer dans `MediStock/`.

Sans ce fichier, la compilation et les tests fonctionnent ; le lancement de l'application échoue au démarrage sur une erreur Firebase explicite.

### Pourquoi les tests n'en ont pas besoin

Les ViewModels ne connaissent que des protocoles (`MedicineRepository`, `HistoryRepository`, `AuthService`) et reçoivent des doubles en test. La cible de test est liée à l'application hôte pour des raisons d'édition de liens, mais `AppEnvironment.isRunningUnitTests` empêche celle-ci d'initialiser Firebase pendant la suite : aucun appel réseau n'a lieu.

## Commandes

```sh
# Compiler
xcodebuild -project MediStock.xcodeproj -scheme MediStock \
  -destination 'generic/platform=iOS Simulator' build

# Tests unitaires
xcodebuild test -project MediStock.xcodeproj -scheme MediStock \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'

# Lint
swiftlint lint
```

## Architecture

```
MediStock/
├── App/          point d'entrée, DIContainer, SessionManager, routage
├── Features/     un dossier par périmètre fonctionnel (Auth, Aisles, Medicines, Profile)
├── Network/
│   ├── Protocols/            frontière testable
│   └── Services/Firebase/    seuls fichiers important le SDK Firebase
└── Shared/       modèles de domaine et vues réutilisables
```

Le `DIContainer` est construit une fois dans `MediStockApp.init()` et détient les services sous forme de protocoles. Les ViewModels sont injectés par constructeur, sans valeur par défaut, ce qui les rend instanciables avec des doubles en test.

Les modèles de domaine ne dépendent pas du SDK : le mapping Firestore est manuel, dans les implémentations de repository.

`MedicineStore` est l'unique propriétaire de la collection `medicines` en mémoire : il porte la lecture gardée, les mutations et l'écriture du journal d'audit, et propage ses erreurs. Chaque écran a son propre ViewModel, qui ne porte que sa dérivation — tri et filtre pour la liste, regroupement pour les rayons, historique pour le détail — et son propre message d'erreur.

## Stratégie de lecture des données

La collection `medicines` est lue **intégralement, une fois par session** (`MedicineStore.loadIfNeeded()`), puis triée et filtrée en mémoire. Le store est détenu par le `DIContainer` et s'invalide de lui-même au changement d'utilisateur (`loadedForUserId`) : une reconnexion sous un autre compte repart d'une collection vide et relit. Ce choix est délibéré ; il est documenté ici parce qu'il porte une limite de montée en charge.

### Pourquoi pas de pagination

`medicines` alimente les trois écrans à partir d'une seule source, et deux d'entre eux en dérivent des agrégats **globaux** :

- l'onglet Rayons construit sa liste avec `Set(medicines.map(\.aisle))`. Paginé, il n'afficherait que les rayons rencontrés dans les pages déjà chargées — un rayon entier resterait invisible tant que l'utilisateur n'aurait pas fait défiler l'autre onglet ;
- la recherche est un `localizedCaseInsensitiveContains` en mémoire. Paginée, elle ne porterait plus que sur les pages chargées, et renverrait « aucun résultat » pour un médicament qui existe. Le déport côté serveur n'est pas une option de repli : Firestore n'a pas d'opérateur `contains`, seulement des plages de préfixes ;
- le tri par stock sur des données partielles désigne le plus petit stock *chargé*, pas le plus petit stock réel.

Préserver ces trois comportements sous pagination imposerait une seconde source pour les rayons — donc **davantage** de lectures que le chargement complet, à rebours de l'objectif de sobriété. Le coût de lecture a par ailleurs déjà été traité : le passage d'une lecture par écran à une lecture par session a divisé les lectures facturées par trois.

### Limite assumée et seuil de révision

Un document `medicines` porte trois champs courts (`name`, `stock`, `aisle`) ; avec le chemin du document et les métadonnées, il pèse de l'ordre de **300 octets** sur le réseau.

| Contrainte | Plafond | Documents correspondants |
|---|---|---|
| Taille maximale d'une réponse d'API Firestore | 10 Mio | ~35 000 |
| Empreinte mémoire côté app | négligeable | ~150 o par `Medicine` en mémoire |
| Lectures facturées | N par session et par utilisateur | facteur limitant réel |

La limite dure n'est donc pas le mur : bien avant elle, ce sont les **lectures facturées** et le **temps d'affichage initial** qui se dégradent. Ordre de grandeur retenu : le chargement complet reste confortable jusqu'à quelques milliers de références, ce qui couvre le catalogue d'une pharmacie hospitalière.

**À revoir au-delà d'environ 5 000 médicaments**, ou si le premier affichage dépasse la seconde sur le réseau cible. La bascule ne consiste alors pas à paginer la liste telle quelle, mais à sortir les agrégats de la liste : rayons persistés dans leur propre collection, et recherche confiée à un index externe.

Hypothèse de volume à confirmer avec le PO : le dimensionnement ci-dessus suppose un catalogue de l'ordre du millier de références par site.

## Sécurité Firestore

Les règles sont versionnées dans `firestore.rules` et se déploient avec :

```sh
firebase deploy --only firestore:rules
```

`medicines` est accessible en lecture et écriture à tout utilisateur authentifié. `history` est un journal d'audit : lisible et alimentable une fois connecté, jamais modifiable ni supprimable depuis un client, et une entrée ne peut porter que l'identifiant de son auteur.

## Compte et suppression

L'onglet **Profil** expose l'adresse du compte, la version de l'application et la suppression du compte. Cette dernière répond à la directive App Store **5.1.1(v)** : une application qui permet la création de compte doit permettre sa suppression en son sein.

La suppression demande le mot de passe et **réauthentifie avant de supprimer**. Ce n'est pas un excès de prudence : `user.delete()` échoue avec `requiresRecentLogin` dès que la session n'est plus récente, et l'application persistant la session, le cas est la règle plutôt que l'exception. Réauthentifier systématiquement évite à l'utilisateur un refus sans issue, et vaut confirmation d'identité sur une action irréversible.

### Ce que la suppression ne touche pas

Seul l'enregistrement Firebase Authentication est supprimé. **Ni la collection `medicines`, ni le journal `history`.** C'est une conséquence de la nature de l'application, pas une limite d'implémentation :

- MediStock est un **outil professionnel partagé** : plusieurs opérateurs d'un même établissement travaillent sur le même stock. `Medicine` ne comporte aucun champ d'auteur — la donnée décrit l'officine, pas la personne connectée. Le départ d'un opérateur ne doit pas effacer les données de ses collègues ;
- `history` est un journal d'audit, rendu non modifiable et non supprimable par les règles Firestore ci-dessus. C'est la condition de sa valeur probante : un journal réinscriptible ne prouve rien. Ses entrées portent l'e-mail et l'identifiant de leur auteur, qui subsistent donc après la suppression du compte.

Ce dernier point est une donnée personnelle conservée : l'écran de confirmation l'annonce à l'utilisateur **avant** qu'il ne valide, et la politique de confidentialité doit le déclarer et fixer une durée de conservation. Une anonymisation différée — substituer une valeur neutre à l'e-mail au terme de cette durée, en gardant la trace de l'action — suppose une fonction serveur, hors du périmètre d'une application cliente.

## Tests

Suite en Swift Testing (`@Suite` / `@Test` / `#expect`). Les doubles vivent dans `MediStockTests/Mocks/`, avec une propriété `errorToThrow` permettant de piloter les chemins d'erreur.
