# Projet Application Mobile - WeFun

Application développée pour proposer des activités à réaliser en groupe, conçue avec Flutter. Ce document résume les étapes du développement achevées en fonction des User Stories et les fonctionnalités supplémentaires implémentées.

Important : L'application tourne avec Node.js qui communique avec MongoDB en fond. Le back est déjà host sur render.com (https://mobileapp-aversa.onrender.com), cependant il est possible de modifier le code de l'application (ici : https://github.com/raversa001/MobileApp_Front/blob/main/lib/main.dart#L14) pour que le back de l'application tourne en local.
Le cas échéant, le repository du back est ici : https://github.com/raversa001/MobileApp_Back

## Étapes du Développement (User Stories)

- [x] US#1 : [MVP] Interface de login : Permet à l'utilisateur de se connecter à l'app.
- [x] US#2 : [MVP] Liste des activités : Affiche toutes les activités disponibles.
- [x] US#3 : [MVP] Détail d'une activité : Montre les détails d'une activité sélectionnée.
- [x] US#4 : [MVP] Le panier : Permet à l'utilisateur de voir son panier.
- [x] US#5 : [MVP] Profil utilisateur : Affiche et permet la modification du profil utilisateur.
- [x] US#6 : Filtrer sur la liste des activités : Ajoute une fonction de filtrage par catégorie pour les activités.

## Fonctionnalités Supplémentaires (US#7)

- **Thème dynamique** : Implémente un switch entre un thème clair et sombre, améliorant l'expérience utilisateur en fonction de leurs préférences ou de l'environnement.
- **Gestion des sessions utilisateur** : Utilisation de `SharedPreferences` pour maintenir l'état de la session utilisateur, permettant une expérience utilisateur fluide avec une connexion persistante.
- **Navigation améliorée** : Mise en place d'une navigation fluide entre les différentes pages de l'application, y compris une gestion optimisée du retour à la page précédente et du passage à la page principale après la connexion.
- **Inscription utilisateur** : Ajout de la fonctionnalité d'inscription pour permettre aux nouveaux utilisateurs de créer un compte et de participer aux activités proposées.
- **Barre de recherche sur les activités** : Ajout d'une barre de recherche dans le menu des activités afin de pouvoir effectuer une recherche textuelle sur le nom de n'importe laquelle de celles-ci.

Ce projet a été développé avec l'objectif de respecter les principes du MVP (Produit Minimum Viable) tout en ajoutant des fonctionnalités supplémentaires pour enrichir l'expérience utilisateur et encourager l'engagement avec l'application.
