# Plumora - Export HTML/CSS

Export HTML/CSS statique de l'application Plumora - 4 pages principales.

## 🚀 Démarrage rapide

Ouvrez **start.html** dans votre navigateur pour accéder à toutes les pages exportées.

## 📁 Fichiers exportés

### Pages HTML (4 pages)
1. **index.html** - Page d'accueil/Landing page
2. **login.html** - Page de connexion
3. **signup.html** - Page d'inscription (register)
4. **home.html** - Page d'accueil utilisateur (après connexion)

### Fichiers de support
- **styles.css** - Styles CSS complets avec variables de thème
- **navigation.js** - Fonctions JavaScript pour la navigation
- **start.html** - Page de navigation pour accéder facilement aux 4 pages

## 🎨 Palette de couleurs

L'application utilise une palette brun doré / camel :
- Primaire : #A88A54 (brun doré)
- Fond : #F8F4EE (ivoire clair)
- Cartes : #FFFFFF (blanc doux)
- Secondaire : #EADFCF (crème)
- Accent : #8FA889 (vert sauge)

## 💡 Comment utiliser

1. Ouvrez `start.html` dans un navigateur web
2. Cliquez sur une page pour la voir
3. Naviguez entre les pages avec les boutons et liens
4. Toutes les pages sont entièrement statiques (pas de backend)

## 🔧 Personnalisation

Pour modifier les couleurs, éditez les variables CSS dans `styles.css` :

```css
:root {
  --primary: #A88A54;    /* Couleur principale */
  --background: #F8F4EE; /* Fond */
  --foreground: #2B241B; /* Texte */
  /* etc. */
}
```

## 📝 Notes techniques

- Les formulaires ne sont pas connectés à un backend
- Navigation par liens HTML simples
- Icônes SVG inline (pas de dépendances externes)
- Compatible avec tous les navigateurs modernes
- Responsive design (mobile et desktop)

## 🎯 Pages détaillées

### 1. index.html - Landing Page
- Logo Plumora avec icône plume
- Slogan "Écris. Publie. Lis. Partage."
- Citation de Victor Hugo
- Boutons connexion/inscription
- 3 cartes de présentation des fonctionnalités

### 2. login.html - Connexion
- Logo avec icône plume dans un cercle brun
- Formulaire email + mot de passe
- Lien "Mot de passe oublié"
- Bouton "Se connecter"
- Bouton "Continuer avec Google" (avec logo Google)
- Lien vers inscription

### 3. signup.html - Inscription
- Logo Plumora
- Formulaire avec champs séparés :
  - Prénom
  - Nom
  - Email
  - Mot de passe
  - Confirmation mot de passe
- Bouton "Créer mon compte"
- Lien vers connexion

### 4. home.html - Accueil utilisateur
- Header avec logo et salutation personnalisée
- Bouton notifications et profil
- Citation du jour
- Section "Vos manuscrits" avec :
  - Carte "Continuer à écrire" (avec barre de progression 35%)
  - Carte "Découvrir un livre"
- Actions rapides
- Navigation footer

## ✅ Structure du projet

```
html-export/
├── start.html          # Point d'entrée - Navigation
├── index.html          # Landing page
├── login.html          # Connexion
├── signup.html         # Inscription
├── home.html           # Home utilisateur
├── styles.css          # CSS principal
├── navigation.js       # JavaScript
└── README.md           # Ce fichier
```

---

**Plumora** - La plateforme qui accompagne les auteurs de l'écriture à la publication 📚✨
