export type StoryStatus = 'draft' | 'beta' | 'published';
export type Visibility = 'private' | 'beta' | 'public';

export interface Chapter {
  id: number;
  title: string;
  words: number;
  published: boolean;
  modifiedAt: string;
  content?: string;
}

export interface Story {
  id: number;
  title: string;
  genre: string;
  language: string;
  status: StoryStatus;
  visibility: Visibility;
  cover: string;
  synopsis: string;
  tags: string[];
  mature: boolean;
  createdAt: string;
  lastModified: string;
  words: number;
  betaCount: number;
  views: number;
  rating: number | null;
  chapters: Chapter[];
}

export const STORIES: Story[] = [
  {
    id: 1,
    title: 'La Nuit Rouge',
    genre: 'Fantasy',
    language: 'Français',
    status: 'draft',
    visibility: 'private',
    cover: 'from-violet-600 via-purple-700 to-indigo-800',
    synopsis: "Clara, dix-sept ans, découvre qu'elle est la dernière Gardienne d'un secret vieux de plusieurs siècles. Pourchassée par des forces qu'elle ne comprend pas encore, elle doit apprendre à maîtriser ses pouvoirs tout en cherchant la vérité sur son passé.\n\nEntre révélations troublantes et rencontres inattendues, elle devra choisir entre sa vie d'avant et son destin.",
    tags: ['magie', 'fantasy', 'mystère', 'jeunesse', 'aventure'],
    mature: false,
    createdAt: '12 mai 2025',
    lastModified: "Aujourd'hui, 14h32",
    words: 8400,
    betaCount: 0,
    views: 0,
    rating: null,
    chapters: [
      { id: 1, title: 'Prologue', words: 620, published: true, modifiedAt: 'Il y a 5 jours', content: "Le monde avait changé depuis la nuit des temps. Les anciens le savaient, eux qui portaient encore les cicatrices de la Grande Rupture sur leurs âmes épuisées.\n\nClara n'avait que dix-sept ans quand elle comprit qu'elle n'était pas comme les autres." },
      { id: 2, title: "Chapitre 1 — L'éveil", words: 1840, published: true, modifiedAt: 'Il y a 4 jours', content: "La bibliothèque de l'université fermait à vingt-deux heures, mais Clara était encore là à minuit passé.\n\n— Vous devriez partir, dit une voix derrière elle." },
      { id: 3, title: 'Chapitre 2 — La fuite', words: 2100, published: true, modifiedAt: 'Il y a 3 jours', content: "Ils coururent pendant ce qui semblait des heures à travers les ruelles du vieux Montmartre, le souffle court." },
      { id: 4, title: 'Chapitre 3 — La rencontre', words: 847, published: false, modifiedAt: "Aujourd'hui", content: "Il faisait nuit noire lorsque Clara franchit le seuil de la vieille bibliothèque." },
      { id: 5, title: 'Chapitre 4', words: 0, published: false, modifiedAt: '—', content: '' },
    ],
  },
  {
    id: 2,
    title: 'Les Ombres de Minuit',
    genre: 'Thriller',
    language: 'Français',
    status: 'beta',
    visibility: 'beta',
    cover: 'from-blue-600 via-indigo-700 to-slate-800',
    synopsis: "Un détective désabusé reçoit un message anonyme qui va bouleverser sa vie. Au cœur de Paris, il découvre un réseau de mensonges qui remonte aux plus hautes sphères du pouvoir.\n\nChaque vérité révèle une nouvelle couche de trahison. Jusqu'où ira-t-il pour trouver la justice ?",
    tags: ['thriller', 'policier', 'paris', 'conspiration'],
    mature: true,
    createdAt: '3 mars 2025',
    lastModified: 'Hier, 09h15',
    words: 24600,
    betaCount: 12,
    views: 0,
    rating: null,
    chapters: [
      { id: 1, title: 'Prologue', words: 890, published: true, modifiedAt: 'Il y a 2 semaines', content: "La nuit était tombée sur Paris comme un voile de deuil." },
      { id: 2, title: 'Chapitre 1 — Le message', words: 3100, published: true, modifiedAt: 'Il y a 10 jours', content: "Il était 23h quand le message arriva sur le vieux téléphone de Marceau." },
      { id: 3, title: 'Chapitre 2 — La piste', words: 2800, published: true, modifiedAt: 'Il y a 8 jours', content: "La piste menait au 7e arrondissement." },
      { id: 4, title: 'Chapitre 3 — Le témoin', words: 3200, published: true, modifiedAt: 'Il y a 6 jours', content: "Elle s'appelait Isabelle Renard." },
      { id: 5, title: 'Chapitre 4 — La confrontation', words: 2900, published: true, modifiedAt: 'Il y a 4 jours', content: "Le bureau du ministre était glacial." },
      { id: 6, title: 'Chapitre 5 — Le piège', words: 3100, published: true, modifiedAt: 'Il y a 3 jours', content: "Marceau comprit qu'il avait été suivi." },
      { id: 7, title: 'Chapitre 6 — Révélations', words: 3400, published: true, modifiedAt: 'Il y a 2 jours', content: "La vérité était bien pire que ce qu'il imaginait." },
      { id: 8, title: 'Chapitre 7 — La chute', words: 3200, published: true, modifiedAt: 'Il y a 1 jour', content: "Il n'y avait plus de retour en arrière possible." },
      { id: 9, title: 'Chapitre 8 — Épilogue', words: 2010, published: true, modifiedAt: 'Hier', content: "Six mois plus tard, Paris bruissait toujours de rumeurs." },
      { id: 10, title: 'Bonus — Notes de l\'auteur', words: 0, published: false, modifiedAt: '—', content: '' },
    ],
  },
  {
    id: 3,
    title: "Sang d'Encre",
    genre: 'Romance',
    language: 'Français',
    status: 'published',
    visibility: 'public',
    cover: 'from-rose-500 via-red-600 to-orange-700',
    synopsis: "Deux âmes blessées, une librairie oubliée et des lettres qui traversent le temps. Lina et Alexis ne devaient jamais se rencontrer. Pourtant, les mots ont choisi pour eux.\n\nUne romance douce-amère sur l'amour, la perte et le pouvoir des histoires qu'on se raconte.",
    tags: ['romance', 'livres', 'amour', 'émotion', 'drame'],
    mature: false,
    createdAt: '15 janvier 2025',
    lastModified: 'Il y a 3 jours',
    words: 42000,
    betaCount: 8,
    views: 2500,
    rating: 4.7,
    chapters: [
      { id: 1, title: 'Chapitre 1 — La librairie', words: 2800, published: true, modifiedAt: 'Il y a 2 mois', content: "La librairie sentait la vanille et le papier ancien." },
      { id: 2, title: 'Chapitre 2 — La première lettre', words: 3100, published: true, modifiedAt: 'Il y a 2 mois', content: "Chère inconnue..." },
      { id: 3, title: 'Chapitre 3 — Le rendez-vous', words: 2900, published: true, modifiedAt: 'Il y a 2 mois', content: "Elle avait hésité avant d'entrer." },
      { id: 4, title: 'Chapitre 4 — Les mots manquants', words: 3200, published: true, modifiedAt: 'Il y a 6 semaines', content: "Certaines choses ne peuvent pas s'écrire." },
      { id: 5, title: 'Chapitre 5 — La tempête', words: 2700, published: true, modifiedAt: 'Il y a 6 semaines', content: "L'été s'était achevé sans prévenir." },
      { id: 6, title: 'Chapitre 6 — Séparation', words: 3000, published: true, modifiedAt: 'Il y a 5 semaines', content: "Le train partait à l'aube." },
      { id: 7, title: 'Chapitre 7 — Le retour', words: 2800, published: true, modifiedAt: 'Il y a 4 semaines', content: "Deux ans. Deux ans sans nouvelles." },
      { id: 8, title: 'Chapitre 8 — Le dernier chapitre', words: 2900, published: true, modifiedAt: 'Il y a 3 semaines', content: "Cette fois, elle avait pris sa décision." },
      { id: 9, title: 'Épilogue', words: 1800, published: true, modifiedAt: 'Il y a 2 semaines', content: "La librairie existait toujours." },
    ],
  },
];
