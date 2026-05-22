import { useState } from 'react';
import { Button } from '../components/Button';
import {
  LayoutDashboard,
  BookOpen,
  PenTool,
  MessageSquare,
  Upload,
  TrendingUp,
  Settings,
  Save,
  Eye,
  MoreVertical,
  ChevronDown,
  FileText,
  Sparkles,
} from 'lucide-react';

interface EditorPageProps {
  onNavigate: (page: string) => void;
}

export function EditorPage({ onNavigate }: EditorPageProps) {
  const [activeChapter, setActiveChapter] = useState('Chapitre 3');
  const [content, setContent] = useState(
    `Il faisait nuit noire lorsque Clara franchit le seuil de la vieille bibliothèque. Les ombres dansaient sur les murs tapissés de livres anciens, créant une atmosphère à la fois mystérieuse et envoûtante.\n\nElle savait qu'elle ne devrait pas être là. Les rumeurs parlaient d'esprits hantant ces lieux depuis des siècles, gardiens éternels d'un savoir oublié. Mais Clara n'avait pas le choix. Quelque part dans ces rayonnages se cachait la clé de son passé.\n\nSes pas résonnaient sur le parquet grinçant alors qu'elle s'avançait entre les étagères...`
  );

  const chapters = [
    'Prologue',
    'Chapitre 1',
    'Chapitre 2',
    'Chapitre 3',
    'Chapitre 4',
  ];

  return (
    <div className="h-screen bg-background flex">
      {/* Sidebar */}
      <div className="w-64 bg-card border-r border-border flex flex-col">
        <div className="p-6 border-b border-border">
          <h2 className="font-bold text-xl text-primary">La Nuit Rouge</h2>
          <p className="text-sm text-muted-foreground mt-1">Roman - Fantasy</p>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          <button
            onClick={() => onNavigate('author-dashboard')}
            className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-muted-foreground hover:bg-muted transition-colors"
          >
            <LayoutDashboard className="w-5 h-5" />
            Tableau de bord
          </button>
          <button
            onClick={() => onNavigate('author-dashboard')}
            className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-muted-foreground hover:bg-muted transition-colors"
          >
            <BookOpen className="w-5 h-5" />
            Mes manuscrits
          </button>
          <button className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl bg-primary text-primary-foreground">
            <PenTool className="w-5 h-5" />
            Éditeur
          </button>
          <button
            onClick={() => onNavigate('beta-feedback')}
            className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-muted-foreground hover:bg-muted transition-colors"
          >
            <MessageSquare className="w-5 h-5" />
            Bêta-retours
          </button>
          <button
            onClick={() => onNavigate('beta-submission')}
            className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-muted-foreground hover:bg-muted transition-colors"
          >
            <Upload className="w-5 h-5" />
            Envoyer en bêta-test
          </button>
          <button className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-muted-foreground hover:bg-muted transition-colors">
            <TrendingUp className="w-5 h-5" />
            Royalties
          </button>
        </nav>

        <div className="p-4 border-t border-border">
          <button className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-muted-foreground hover:bg-muted transition-colors">
            <Settings className="w-5 h-5" />
            Paramètres
          </button>
        </div>
      </div>

      {/* Chapter List */}
      <div className="w-64 bg-muted/30 border-r border-border flex flex-col">
        <div className="p-4 border-b border-border flex items-center justify-between">
          <h3 className="font-semibold">Chapitres</h3>
          <button className="p-2 hover:bg-muted rounded-lg transition-colors">
            <MoreVertical className="w-4 h-4" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-2 space-y-1">
          {chapters.map((chapter) => (
            <button
              key={chapter}
              onClick={() => setActiveChapter(chapter)}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-colors ${
                activeChapter === chapter
                  ? 'bg-primary text-primary-foreground'
                  : 'hover:bg-muted text-foreground'
              }`}
            >
              <FileText className="w-4 h-4" />
              <span>{chapter}</span>
            </button>
          ))}
        </div>

        <div className="p-4 border-t border-border">
          <Button variant="outline" className="w-full">
            + Nouveau chapitre
          </Button>
        </div>
      </div>

      {/* Editor */}
      <div className="flex-1 flex flex-col">
        {/* Toolbar */}
        <div className="bg-card border-b border-border px-6 py-3 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button className="flex items-center gap-2 px-4 py-2 rounded-lg hover:bg-muted transition-colors">
              <span className="font-medium">{activeChapter}</span>
              <ChevronDown className="w-4 h-4" />
            </button>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onNavigate('mukeme')}
              className="text-primary"
            >
              <Sparkles className="w-4 h-4" />
              Mukeme
            </Button>
            <Button variant="ghost" size="sm">
              <Eye className="w-4 h-4" />
              Prévisualiser
            </Button>
            <Button size="sm">
              <Save className="w-4 h-4" />
              Enregistrer
            </Button>
          </div>
        </div>

        {/* Editor Content */}
        <div className="flex-1 overflow-y-auto p-8">
          <div className="max-w-4xl mx-auto">
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              className="w-full min-h-[600px] bg-transparent border-none focus:outline-none resize-none leading-relaxed text-foreground"
              placeholder="Commencez à écrire votre histoire..."
              style={{ fontSize: '18px', lineHeight: '1.8' }}
            />
          </div>
        </div>

        {/* Stats Bar */}
        <div className="bg-card border-t border-border px-6 py-3 flex items-center gap-8 text-sm text-muted-foreground">
          <div>
            <span className="font-medium">{content.split(' ').length}</span> mots
          </div>
          <div>
            <span className="font-medium">{content.length}</span> caractères
          </div>
          <div>
            <span className="font-medium">5</span> min de lecture
          </div>
          <div className="ml-auto">Dernière sauvegarde : il y a 2 minutes</div>
        </div>
      </div>
    </div>
  );
}
