import { useState } from 'react';
import {
  LayoutDashboard, Users, BookOpen, Flag, LogOut, Shield, Search,
  Bell, CheckCircle, XCircle, Clock, Eye, Archive, RotateCcw,
  Edit2, X, AlertTriangle, Sparkles, UserX, UserCheck, BookMarked,
  ChevronRight, Feather, TrendingUp, Star
} from 'lucide-react';

interface AdminPageProps {
  onNavigate: (page: string) => void;
}

type Section = 'dashboard' | 'users' | 'catalogue' | 'reports';

// Light violet palette
const C = {
  bg:       '#F5F3FF',
  surface:  '#FFFFFF',
  card:     '#FFFFFF',
  cardHover:'#FAFAFE',
  border:   '#E4DFFF',
  text:     '#1A1040',
  muted:    '#7167A0',
  mutedBg:  '#F0EEFF',
  primary:  '#7C5CFF',
  primaryBg:'#EDE9FF',
  plumora:  '#9B6FD4',
  plumo:    '#A67CFF',
  error:    '#E05252',
  errorBg:  '#FEF2F2',
  success:  '#2EA87A',
  successBg:'#F0FBF6',
  warning:  '#D97706',
  warningBg:'#FFFBEB',
  accent:   '#C9A227',
};

// ─── SHARED ───────────────────────────────────────────────────────────────────

function Badge({ label, color, bg, icon: Icon }: { label: string; color: string; bg?: string; icon?: React.ElementType }) {
  return (
    <span style={{ background: bg ?? color + '18', color, border: `1px solid ${color}30` }}
      className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold whitespace-nowrap">
      {Icon && <Icon size={10} />}{label}
    </span>
  );
}

function Btn({ label, color = C.primary, bg, danger, outline, ghost, onClick, icon: Icon, small, disabled }: {
  label: string; color?: string; bg?: string; danger?: boolean; outline?: boolean; ghost?: boolean;
  onClick?: () => void; icon?: React.ElementType; small?: boolean; disabled?: boolean;
}) {
  const resolvedBg = danger ? C.error : outline || ghost ? 'transparent' : (bg ?? color);
  const fg = outline || ghost ? (danger ? C.error : color) : '#fff';
  const border = outline ? `1.5px solid ${danger ? C.error : color}` : ghost ? 'none' : 'none';
  return (
    <button onClick={onClick} disabled={disabled}
      style={{ background: resolvedBg, color: fg, border, opacity: disabled ? 0.4 : 1, boxShadow: (!outline && !ghost && !danger) ? `0 1px 3px ${color}40` : 'none' }}
      className={`inline-flex items-center gap-1.5 rounded-xl font-semibold transition-all hover:opacity-85 active:scale-95 ${small ? 'px-3 py-1.5 text-xs' : 'px-4 py-2.5 text-sm'}`}>
      {Icon && <Icon size={small ? 11 : 14} />}{label}
    </button>
  );
}

function Modal({ title, onClose, children, width = 'max-w-md' }: {
  title: string; onClose: () => void; children: React.ReactNode; width?: string;
}) {
  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, boxShadow: '0 20px 60px rgba(124,92,255,0.15)' }}
        className={`rounded-2xl w-full ${width} max-h-[90vh] overflow-y-auto`}>
        <div style={{ borderBottom: `1px solid ${C.border}` }} className="flex items-center justify-between px-6 py-4">
          <h3 style={{ color: C.text, fontFamily: "'Playfair Display', serif" }} className="font-bold text-base">{title}</h3>
          <button onClick={onClose} style={{ color: C.muted, background: C.mutedBg }} className="p-1.5 hover:opacity-80 rounded-lg transition-opacity"><X size={15} /></button>
        </div>
        <div className="p-6">{children}</div>
      </div>
    </div>
  );
}

function EmptyState({ icon: Icon, title, sub }: { icon: React.ElementType; title: string; sub?: string }) {
  return (
    <div className="py-16 flex flex-col items-center gap-3">
      <div style={{ background: C.primaryBg }} className="p-4 rounded-2xl">
        <Icon size={24} style={{ color: C.primary }} />
      </div>
      <p style={{ color: C.text }} className="font-semibold text-sm">{title}</p>
      {sub && <p style={{ color: C.muted }} className="text-xs text-center max-w-xs">{sub}</p>}
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-4 py-3" style={{ borderBottom: `1px solid ${C.border}` }}>
      <span style={{ color: C.muted }} className="text-xs font-medium">{label}</span>
      <span style={{ color: C.text }} className="text-xs text-right">{value}</span>
    </div>
  );
}

function Toast({ msg }: { msg: string }) {
  if (!msg) return null;
  return (
    <div style={{ background: C.surface, border: `1px solid ${C.success}44`, boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}
      className="fixed top-4 right-4 z-[60] flex items-center gap-2 px-4 py-3 rounded-2xl">
      <CheckCircle size={15} style={{ color: C.success }} />
      <span style={{ color: C.text }} className="text-sm font-medium">{msg}</span>
    </div>
  );
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────

function statusBadge(status: string) {
  const map: Record<string, { color: string; bg: string; icon: React.ElementType; label: string }> = {
    ACTIVE:    { color: C.success, bg: C.successBg, icon: CheckCircle,   label: 'Actif' },
    DISABLED:  { color: C.error,   bg: C.errorBg,   icon: XCircle,       label: 'Désactivé' },
    publié:    { color: C.success, bg: C.successBg, icon: CheckCircle,   label: 'Publié' },
    signalé:   { color: C.error,   bg: C.errorBg,   icon: AlertTriangle, label: 'Signalé' },
    archivé:   { color: C.muted,   bg: C.mutedBg,   icon: Archive,       label: 'Archivé' },
    PENDING:   { color: C.warning, bg: C.warningBg, icon: Clock,         label: 'En attente' },
    IN_REVIEW: { color: C.primary, bg: C.primaryBg, icon: Eye,           label: 'En cours' },
    RESOLVED:  { color: C.success, bg: C.successBg, icon: CheckCircle,   label: 'Résolu' },
    REJECTED:  { color: C.muted,   bg: C.mutedBg,   icon: XCircle,       label: 'Rejeté' },
  };
  const s = map[status] ?? { color: C.muted, bg: C.mutedBg, icon: Clock, label: status };
  return <Badge label={s.label} color={s.color} bg={s.bg} icon={s.icon} />;
}

function roleBadge(role: string) {
  const map: Record<string, { color: string; bg: string }> = {
    ADMIN:       { color: C.error,   bg: C.errorBg },
    AUTHOR:      { color: C.primary, bg: C.primaryBg },
    BETA_READER: { color: C.plumora, bg: '#F5EEFF' },
    USER:        { color: C.muted,   bg: C.mutedBg },
  };
  const s = map[role] ?? { color: C.muted, bg: C.mutedBg };
  return <Badge label={role} color={s.color} bg={s.bg} />;
}

function priorityBadge(p: string) {
  const map: Record<string, { color: string; bg: string }> = {
    HAUTE:  { color: C.error,   bg: C.errorBg },
    MOYENNE:{ color: C.warning, bg: C.warningBg },
    FAIBLE: { color: C.muted,   bg: C.mutedBg },
  };
  const s = map[p] ?? { color: C.muted, bg: C.mutedBg };
  return <Badge label={p} color={s.color} bg={s.bg} />;
}

// ─── DATA ─────────────────────────────────────────────────────────────────────

const USERS_DATA = [
  { id: 1, name: 'Kevin Moreau',    email: 'kevin@plumora.fr',   role: 'AUTHOR',      status: 'ACTIVE',   joined: '12 jan. 2025', books: 3, reports: 0, initials: 'KM' },
  { id: 2, name: 'Amélie Fontaine', email: 'amelie.f@mail.com',  role: 'BETA_READER', status: 'ACTIVE',   joined: '3 fév. 2025',  books: 0, reports: 1, initials: 'AF' },
  { id: 3, name: 'Thomas Leclerc',  email: 'thomas.l@mail.com',  role: 'USER',        status: 'DISABLED', joined: '27 nov. 2024', books: 0, reports: 3, initials: 'TL' },
  { id: 4, name: 'Sarah Benali',    email: 'sarah.b@plumora.fr', role: 'ADMIN',       status: 'ACTIVE',   joined: '5 oct. 2024',  books: 0, reports: 0, initials: 'SB' },
  { id: 5, name: 'Marc Dupont',     email: 'marc.d@mail.com',    role: 'AUTHOR',      status: 'DISABLED', joined: '18 mar. 2025', books: 1, reports: 2, initials: 'MD' },
  { id: 6, name: 'Léa Rousseau',    email: 'lea.r@mail.com',     role: 'USER',        status: 'ACTIVE',   joined: '30 avr. 2025', books: 0, reports: 0, initials: 'LR' },
];

const BOOKS_DATA = [
  { id: 1, title: 'La Nuit Rouge',        author: 'Kevin Moreau', type: 'plumora', status: 'publié',  added: '12 jan.', reports: 0, chapters: 5,  cover: 'from-violet-500 to-indigo-600', summary: "Clara découvre qu'elle est la dernière Gardienne d'un secret vieux de plusieurs siècles." },
  { id: 2, title: 'Les Misérables',       author: 'Victor Hugo',  type: 'public',  status: 'publié',  added: '3 fév.',  reports: 0, chapters: 48, cover: 'from-amber-500 to-orange-600',  summary: "L'histoire de Jean Valjean dans la France du XIXe siècle." },
  { id: 3, title: "Sang d'Encre",         author: 'Kevin Moreau', type: 'plumora', status: 'signalé', added: '18 mar.', reports: 4, chapters: 9,  cover: 'from-rose-500 to-pink-600',     summary: "Deux âmes blessées, une librairie oubliée et des lettres qui traversent le temps." },
  { id: 4, title: 'Don Quichotte',        author: 'Cervantes',    type: 'public',  status: 'publié',  added: '5 avr.',  reports: 0, chapters: 52, cover: 'from-emerald-500 to-teal-600',  summary: "Les aventures d'un chevalier imaginaire." },
  { id: 5, title: 'Ombres Perdues',       author: 'Marc Dupont',  type: 'plumora', status: 'archivé', added: '22 avr.', reports: 6, chapters: 3,  cover: 'from-slate-400 to-gray-500',    summary: "Dans un monde sans lumière, un homme cherche ce qu'il a perdu." },
  { id: 6, title: 'Les Ombres de Minuit', author: 'Kevin Moreau', type: 'plumora', status: 'signalé', added: '7 mai',   reports: 2, chapters: 10, cover: 'from-blue-500 to-indigo-600',   summary: "Un détective reçoit un message anonyme qui bouleverse sa vie." },
];

const REPORTS_DATA = [
  { id: 'RPT-001', content: "Sang d'Encre",     contentType: 'Livre',       reason: 'Contenu inapproprié',    reporter: '@amelie.f',   date: '12 juil.',  status: 'PENDING',   priority: 'HAUTE',   authorContent: 'Kevin Moreau', description: 'Ce livre contient des passages jugés inappropriés pour la plateforme.' },
  { id: 'RPT-002', content: 'Commentaire #4821', contentType: 'Commentaire', reason: 'Contenu haineux',         reporter: '@lecteur_92', date: '11 juil.',  status: 'IN_REVIEW', priority: 'HAUTE',   authorContent: 'thomas.l',    description: 'Propos haineux dirigés contre un autre utilisateur.' },
  { id: 'RPT-003', content: 'Profil @dark_user', contentType: 'Profil',      reason: "Usurpation d'identité",  reporter: '@sara.b',     date: '10 juil.',  status: 'RESOLVED',  priority: 'MOYENNE', authorContent: 'dark_user',   description: "Ce profil usurpe l'identité d'un auteur connu." },
  { id: 'RPT-004', content: 'Réponse IA #1029',  contentType: 'Réponse IA',  reason: 'Information incorrecte', reporter: '@nicolas.v',  date: '9 juil.',   status: 'REJECTED',  priority: 'FAIBLE',  authorContent: 'Plumo IA',    description: 'Réponse de Plumo factuellement incorrecte.' },
  { id: 'RPT-005', content: 'Ombres Perdues',    contentType: 'Livre',       reason: 'Contenu violent',         reporter: '@lea.r',      date: '8 juil.',   status: 'PENDING',   priority: 'MOYENNE', authorContent: 'Marc Dupont', description: 'Scènes de violence explicite non signalées.' },
];

// ─── DASHBOARD ────────────────────────────────────────────────────────────────
function Dashboard({ onNav }: { onNav: (s: Section) => void }) {
  const stats = [
    { label: 'Utilisateurs',   value: '14 820', icon: Users,      color: C.primary, bg: C.primaryBg, sub: '+127 ce mois' },
    { label: 'Livres publiés', value: '3 241',  icon: BookOpen,   color: C.plumora, bg: '#F5EEFF',   sub: 'Œuvres Plumora' },
    { label: 'Domaine public', value: '892',    icon: BookMarked, color: C.success, bg: C.successBg, sub: 'Dans le catalogue' },
    { label: 'Signalements',   value: '23',     icon: Flag,       color: C.error,   bg: C.errorBg,   sub: 'En attente' },
  ];

  const activity = [
    { icon: UserX,       text: '@thomas.l désactivé',               admin: 'Sarah B.', time: 'Il y a 10 min', color: C.error },
    { icon: Edit2,       text: "Rôle @lea.r : USER → AUTHOR",       admin: 'Sarah B.', time: 'Il y a 34 min', color: C.primary },
    { icon: CheckCircle, text: 'Signalement RPT-003 résolu',         admin: 'Sarah B.', time: 'Il y a 1h',     color: C.success },
    { icon: XCircle,     text: 'Signalement RPT-004 rejeté',         admin: 'Sarah B.', time: 'Il y a 2h',     color: C.muted },
    { icon: Archive,     text: '"Ombres Perdues" archivé',           admin: 'Sarah B.', time: 'Hier, 18h42',  color: C.warning },
    { icon: RotateCcw,   text: '"Conte d\'hiver" restauré',          admin: 'Sarah B.', time: 'Hier, 15h10',  color: C.success },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 style={{ color: C.text, fontFamily: "'Playfair Display', serif" }} className="text-3xl font-bold">Administration</h1>
        <p style={{ color: C.muted }} className="text-sm mt-1">Supervision de la plateforme Plumora</p>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
        {stats.map(s => (
          <div key={s.label} style={{ background: C.card, border: `1px solid ${C.border}`, boxShadow: '0 1px 4px rgba(124,92,255,0.06)' }}
            className="rounded-2xl p-5 flex gap-4 items-start hover:shadow-md transition-shadow">
            <div style={{ background: s.bg }} className="p-3 rounded-xl shrink-0">
              <s.icon size={18} style={{ color: s.color }} />
            </div>
            <div className="min-w-0">
              <p style={{ color: C.muted }} className="text-xs font-medium mb-1">{s.label}</p>
              <p style={{ color: C.text }} className="text-2xl font-bold leading-tight">{s.value}</p>
              <p style={{ color: C.muted }} className="text-xs mt-0.5">{s.sub}</p>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Activity feed */}
        <div className="lg:col-span-2">
          <h2 style={{ color: C.text }} className="font-bold text-sm mb-3">Dernières actions administratives</h2>
          <div style={{ background: C.card, border: `1px solid ${C.border}`, boxShadow: '0 1px 4px rgba(124,92,255,0.06)' }} className="rounded-2xl overflow-hidden">
            {activity.map((a, i) => (
              <div key={i} style={{ borderBottom: i < activity.length - 1 ? `1px solid ${C.border}` : undefined }}
                className="flex items-center gap-3 px-5 py-3.5 hover:bg-[#F5F3FF] transition-colors">
                <div style={{ background: a.color + '18', flexShrink: 0 }} className="p-2 rounded-xl">
                  <a.icon size={13} style={{ color: a.color }} />
                </div>
                <div className="flex-1 min-w-0">
                  <p style={{ color: C.text }} className="text-sm font-medium truncate">{a.text}</p>
                  <p style={{ color: C.muted }} className="text-xs">par {a.admin}</p>
                </div>
                <p style={{ color: C.muted }} className="text-xs whitespace-nowrap hidden sm:block">{a.time}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="space-y-4">
          {/* Plumo IA card */}
          <div style={{ background: `linear-gradient(135deg, ${C.primary}18, ${C.plumo}18)`, border: `1px solid ${C.primary}30` }}
            className="rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <div style={{ background: C.primaryBg }} className="p-1.5 rounded-lg">
                <Sparkles size={13} style={{ color: C.primary }} />
              </div>
              <span style={{ color: C.text }} className="text-sm font-bold">Plumo IA</span>
              <Badge label="Actif" color={C.success} bg={C.successBg} icon={CheckCircle} />
            </div>
            <div className="space-y-1.5">
              <p style={{ color: C.muted }} className="text-xs">Fournisseur : <span style={{ color: C.text }} className="font-medium">Gemini 2.5 Flash-Lite</span></p>
              <p style={{ color: C.muted }} className="text-xs">Dernière erreur : <span style={{ color: C.success }} className="font-medium">Aucune</span></p>
            </div>
          </div>

          {/* Quick actions */}
          <h2 style={{ color: C.text }} className="font-bold text-sm">Actions rapides</h2>
          {[
            { label: 'Gérer les utilisateurs', section: 'users'     as Section, icon: Users },
            { label: 'Consulter le catalogue', section: 'catalogue' as Section, icon: BookOpen },
            { label: 'Voir les signalements',  section: 'reports'   as Section, icon: Flag },
          ].map(({ label, section, icon: Icon }) => (
            <button key={section} onClick={() => onNav(section)}
              style={{ background: C.card, border: `1px solid ${C.border}`, boxShadow: '0 1px 3px rgba(124,92,255,0.06)' }}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-[#F0EEFF] transition-colors text-left group">
              <div style={{ background: C.primaryBg }} className="p-2 rounded-lg">
                <Icon size={14} style={{ color: C.primary }} />
              </div>
              <span style={{ color: C.text }} className="text-sm font-medium flex-1">{label}</span>
              <ChevronRight size={14} style={{ color: C.muted }} className="group-hover:translate-x-0.5 transition-transform" />
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── USERS ────────────────────────────────────────────────────────────────────
function UsersScreen() {
  const [search, setSearch]       = useState('');
  const [roleFilter, setRole]     = useState('all');
  const [statusFilter, setStatus] = useState('all');
  const [users, setUsers]         = useState(USERS_DATA);
  const [modal, setModal]         = useState<'detail'|'role'|'disable'|'enable'|null>(null);
  const [sel, setSel]             = useState<typeof USERS_DATA[0]|null>(null);
  const [newRole, setNewRole]     = useState('');
  const [reason, setReason]       = useState('');
  const [toast, setToast]         = useState('');

  const filtered = users.filter(u =>
    (search === '' || u.name.toLowerCase().includes(search.toLowerCase()) || u.email.toLowerCase().includes(search.toLowerCase())) &&
    (roleFilter === 'all' || u.role === roleFilter) &&
    (statusFilter === 'all' || u.status === statusFilter)
  );

  const open = (t: typeof modal, u: typeof USERS_DATA[0]) => { setSel(u); setNewRole(u.role); setReason(''); setModal(t); };
  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000); };

  const applyRole    = () => { if (!sel) return; setUsers(us => us.map(x => x.id === sel.id ? { ...x, role: newRole } : x)); setModal(null); showToast(`Rôle modifié → ${newRole}`); };
  const applyDisable = () => { if (!sel) return; setUsers(us => us.map(x => x.id === sel.id ? { ...x, status: 'DISABLED' } : x)); setModal(null); showToast(`${sel.name} désactivé`); };
  const applyEnable  = () => { if (!sel) return; setUsers(us => us.map(x => x.id === sel.id ? { ...x, status: 'ACTIVE' } : x)); setModal(null); showToast(`${sel.name} réactivé`); };

  return (
    <div className="space-y-5">
      <Toast msg={toast} />
      <div className="flex items-end justify-between gap-4 flex-wrap">
        <div>
          <h1 style={{ color: C.text, fontFamily: "'Playfair Display', serif" }} className="text-3xl font-bold">Utilisateurs</h1>
          <p style={{ color: C.muted }} className="text-sm mt-1">{users.length} comptes inscrits</p>
        </div>
      </div>

      {/* Filters */}
      <div style={{ background: C.card, border: `1px solid ${C.border}` }} className="rounded-2xl p-4 flex flex-wrap gap-3 items-center">
        <div style={{ background: C.mutedBg, border: `1px solid ${C.border}` }}
          className="flex items-center gap-2 px-3 py-2 rounded-xl flex-1 min-w-[180px]">
          <Search size={13} style={{ color: C.muted }} />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Nom ou email..."
            style={{ background: 'transparent', color: C.text, outline: 'none' }}
            className="text-sm flex-1 placeholder:text-[#7167A0]" />
        </div>
        <div className="flex gap-2 flex-wrap">
          {['all','USER','AUTHOR','BETA_READER','ADMIN'].map(r => (
            <button key={r} onClick={() => setRole(r)}
              style={roleFilter === r
                ? { background: C.primary, color: '#fff', boxShadow: `0 2px 8px ${C.primary}40` }
                : { background: C.mutedBg, color: C.muted }}
              className="px-3 py-1.5 rounded-xl text-xs font-semibold transition-all">
              {r === 'all' ? 'Tous' : r}
            </button>
          ))}
        </div>
        <select value={statusFilter} onChange={e => setStatus(e.target.value)}
          style={{ background: C.mutedBg, border: `1px solid ${C.border}`, color: C.text }}
          className="px-3 py-2 rounded-xl text-xs font-medium">
          <option value="all">Tous les statuts</option>
          <option value="ACTIVE">Actif</option>
          <option value="DISABLED">Désactivé</option>
        </select>
      </div>

      {/* Desktop table */}
      <div style={{ background: C.card, border: `1px solid ${C.border}`, boxShadow: '0 1px 4px rgba(124,92,255,0.06)' }}
        className="rounded-2xl overflow-hidden hidden md:block">
        <div style={{ background: C.mutedBg, borderBottom: `1px solid ${C.border}` }}
          className="px-6 py-3 grid items-center gap-4"
          style2={{ gridTemplateColumns: '2fr 2fr 1fr 1fr 1fr 100px' }}>
          {['Nom','Email','Rôle','Statut','Inscription','Actions'].map(h => (
            <span key={h} style={{ color: C.muted }} className="text-xs font-bold uppercase tracking-wider">{h}</span>
          ))}
        </div>
        {filtered.length === 0
          ? <EmptyState icon={Users} title="Aucun utilisateur trouvé" sub="Modifiez vos filtres" />
          : filtered.map((u, i) => (
            <div key={u.id}
              style={{ borderBottom: i < filtered.length - 1 ? `1px solid ${C.border}` : undefined, display: 'grid', gridTemplateColumns: '2fr 2fr 1fr 1fr 1fr 100px', gap: 16, padding: '14px 24px', alignItems: 'center' }}
              className="hover:bg-[#F5F3FF] transition-colors group">
              <div className="flex items-center gap-3 min-w-0">
                <div style={{ background: C.primaryBg, color: C.primary }}
                  className="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold shrink-0">{u.initials}</div>
                <span style={{ color: C.text }} className="text-sm font-semibold truncate">{u.name}</span>
              </div>
              <span style={{ color: C.muted }} className="text-sm truncate">{u.email}</span>
              <div>{roleBadge(u.role)}</div>
              <div>{statusBadge(u.status)}</div>
              <span style={{ color: C.muted }} className="text-xs font-medium">{u.joined}</span>
              <div className="flex items-center gap-1">
                <button title="Voir" onClick={() => open('detail', u)} style={{ color: C.muted }} className="p-1.5 rounded-lg hover:bg-[#EDE9FF] hover:text-[#7C5CFF] transition-colors"><Eye size={14} /></button>
                <button title="Rôle" onClick={() => open('role', u)} style={{ color: C.muted }} className="p-1.5 rounded-lg hover:bg-[#EDE9FF] hover:text-[#7C5CFF] transition-colors"><Edit2 size={14} /></button>
                {u.status === 'ACTIVE'
                  ? <button title="Désactiver" onClick={() => open('disable', u)} style={{ color: C.muted }} className="p-1.5 rounded-lg hover:bg-[#FEF2F2] hover:text-[#E05252] transition-colors"><UserX size={14} /></button>
                  : <button title="Réactiver" onClick={() => open('enable', u)} style={{ color: C.muted }} className="p-1.5 rounded-lg hover:bg-[#F0FBF6] hover:text-[#2EA87A] transition-colors"><UserCheck size={14} /></button>
                }
              </div>
            </div>
          ))
        }
      </div>

      {/* Mobile cards */}
      <div className="md:hidden space-y-3">
        {filtered.length === 0
          ? <EmptyState icon={Users} title="Aucun utilisateur trouvé" />
          : filtered.map(u => (
            <div key={u.id} style={{ background: C.card, border: `1px solid ${C.border}` }} className="rounded-2xl p-4">
              <div className="flex items-start gap-3 mb-3">
                <div style={{ background: C.primaryBg, color: C.primary }} className="w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold shrink-0">{u.initials}</div>
                <div className="flex-1 min-w-0">
                  <p style={{ color: C.text }} className="font-bold text-sm">{u.name}</p>
                  <p style={{ color: C.muted }} className="text-xs truncate">{u.email}</p>
                  <div className="flex flex-wrap gap-1.5 mt-1.5">{roleBadge(u.role)}{statusBadge(u.status)}</div>
                </div>
              </div>
              <div style={{ borderTop: `1px solid ${C.border}` }} className="flex gap-2 pt-3">
                <Btn label="Détail" outline color={C.primary} onClick={() => open('detail', u)} icon={Eye} small />
                <Btn label="Rôle" outline color={C.primary} onClick={() => open('role', u)} icon={Edit2} small />
                {u.status === 'ACTIVE'
                  ? <Btn label="Désactiver" danger onClick={() => open('disable', u)} icon={UserX} small />
                  : <Btn label="Réactiver" bg={C.successBg} color={C.success} onClick={() => open('enable', u)} icon={UserCheck} small />
                }
              </div>
            </div>
          ))
        }
      </div>

      {/* Modals */}
      {modal === 'detail' && sel && (
        <Modal title="Détail utilisateur" onClose={() => setModal(null)}>
          <div className="flex items-center gap-4 mb-5">
            <div style={{ background: C.primaryBg, color: C.primary }} className="w-14 h-14 rounded-full flex items-center justify-center text-xl font-bold">{sel.initials}</div>
            <div><p style={{ color: C.text }} className="font-bold text-base">{sel.name}</p><p style={{ color: C.muted }} className="text-sm">{sel.email}</p><div className="flex gap-2 mt-1.5">{roleBadge(sel.role)}{statusBadge(sel.status)}</div></div>
          </div>
          <div style={{ borderTop: `1px solid ${C.border}` }} className="pt-1">
            <InfoRow label="Inscription" value={sel.joined} />
            <InfoRow label="Livres publiés" value={sel.books} />
            <InfoRow label="Signalements reçus" value={sel.reports} />
          </div>
        </Modal>
      )}
      {modal === 'role' && sel && (
        <Modal title="Modifier le rôle" onClose={() => setModal(null)}>
          <p style={{ color: C.muted }} className="text-sm mb-4">Rôle actuel de <strong style={{ color: C.text }}>{sel.name}</strong> : {roleBadge(sel.role)}</p>
          <label style={{ color: C.muted }} className="text-xs font-medium block mb-1.5">Nouveau rôle</label>
          <select value={newRole} onChange={e => setNewRole(e.target.value)}
            style={{ background: C.mutedBg, border: `1px solid ${C.border}`, color: C.text }}
            className="w-full px-3 py-2.5 rounded-xl text-sm mb-5">
            {['USER','AUTHOR','BETA_READER','ADMIN'].map(r => <option key={r} value={r}>{r}</option>)}
          </select>
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Confirmer" onClick={applyRole} /></div>
        </Modal>
      )}
      {modal === 'disable' && sel && (
        <Modal title="Désactiver le compte" onClose={() => setModal(null)}>
          <div style={{ background: C.errorBg, border: `1px solid ${C.error}30` }} className="rounded-xl p-3 flex gap-2 mb-4">
            <AlertTriangle size={14} style={{ color: C.error }} className="mt-0.5 shrink-0" />
            <p style={{ color: C.error }} className="text-sm"><strong>{sel.name}</strong> ne pourra plus se connecter.</p>
          </div>
          <label style={{ color: C.muted }} className="text-xs font-medium block mb-1.5">Raison (facultatif)</label>
          <textarea value={reason} onChange={e => setReason(e.target.value)} rows={3} placeholder="Motif..."
            style={{ background: C.mutedBg, border: `1px solid ${C.border}`, color: C.text }}
            className="w-full px-3 py-2 rounded-xl text-sm resize-none mb-5 placeholder:text-[#7167A0] outline-none" />
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Désactiver" danger onClick={applyDisable} icon={UserX} /></div>
        </Modal>
      )}
      {modal === 'enable' && sel && (
        <Modal title="Réactiver le compte" onClose={() => setModal(null)}>
          <p style={{ color: C.muted }} className="text-sm mb-5">Voulez-vous réactiver le compte de <strong style={{ color: C.text }}>{sel.name}</strong> ?</p>
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Réactiver" bg={C.success} onClick={applyEnable} icon={UserCheck} /></div>
        </Modal>
      )}
    </div>
  );
}

// ─── CATALOGUE ────────────────────────────────────────────────────────────────
function CatalogueScreen() {
  const [tab, setTab]              = useState('all');
  const [search, setSearch]        = useState('');
  const [books, setBooks]          = useState(BOOKS_DATA);
  const [modal, setModal]          = useState<'detail'|'archive'|'restore'|null>(null);
  const [sel, setSel]              = useState<typeof BOOKS_DATA[0]|null>(null);
  const [archiveReason, setReason] = useState('');
  const [toast, setToast]          = useState('');

  const tabs = [{ key:'all',label:'Tous' },{ key:'plumora',label:'Œuvres Plumora' },{ key:'public',label:'Domaine public' },{ key:'archivé',label:'Archivés' }];

  const filtered = books.filter(b => {
    const matchTab = tab === 'all' || b.type === tab || b.status === tab;
    const matchSearch = b.title.toLowerCase().includes(search.toLowerCase()) || b.author.toLowerCase().includes(search.toLowerCase());
    return matchTab && matchSearch;
  });

  const open = (t: typeof modal, b: typeof BOOKS_DATA[0]) => { setSel(b); setReason(''); setModal(t); };
  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000); };

  const doArchive = () => { if (!sel) return; setBooks(bs => bs.map(x => x.id === sel.id ? { ...x, status: 'archivé' } : x)); setModal(null); showToast(`"${sel.title}" archivé`); };
  const doRestore = () => { if (!sel) return; setBooks(bs => bs.map(x => x.id === sel.id ? { ...x, status: 'publié' } : x)); setModal(null); showToast(`"${sel.title}" restauré`); };

  return (
    <div className="space-y-5">
      <Toast msg={toast} />
      <div>
        <h1 style={{ color: C.text, fontFamily: "'Playfair Display', serif" }} className="text-3xl font-bold">Catalogue</h1>
        <p style={{ color: C.muted }} className="text-sm mt-1">{books.length} œuvres au total</p>
      </div>

      <div style={{ background: C.card, border: `1px solid ${C.border}` }} className="rounded-2xl p-4 flex flex-wrap items-center gap-3">
        <div className="flex gap-2 flex-wrap">
          {tabs.map(t => (
            <button key={t.key} onClick={() => setTab(t.key)}
              style={tab === t.key ? { background: C.primary, color: '#fff', boxShadow: `0 2px 8px ${C.primary}40` } : { background: C.mutedBg, color: C.muted }}
              className="px-3 py-1.5 rounded-xl text-xs font-semibold transition-all">{t.label}</button>
          ))}
        </div>
        <div style={{ background: C.mutedBg, border: `1px solid ${C.border}` }}
          className="flex items-center gap-2 px-3 py-2 rounded-xl ml-auto">
          <Search size={12} style={{ color: C.muted }} />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Rechercher..."
            style={{ background: 'transparent', color: C.text, outline: 'none', width: 130 }}
            className="text-xs placeholder:text-[#7167A0]" />
        </div>
      </div>

      {/* Desktop table */}
      <div style={{ background: C.card, border: `1px solid ${C.border}`, boxShadow: '0 1px 4px rgba(124,92,255,0.06)' }}
        className="rounded-2xl overflow-hidden hidden md:block">
        <div style={{ background: C.mutedBg, borderBottom: `1px solid ${C.border}`, display: 'grid', gridTemplateColumns: 'auto 2fr 1.5fr 1fr 1fr 60px 80px', gap: 12, padding: '10px 24px', alignItems: 'center' }}>
          {['','Titre','Auteur','Type','Statut','Signalements','Actions'].map(h => (
            <span key={h} style={{ color: C.muted }} className="text-xs font-bold uppercase tracking-wider">{h}</span>
          ))}
        </div>
        {filtered.length === 0
          ? <EmptyState icon={BookOpen} title="Aucun livre trouvé" sub="Modifiez vos filtres" />
          : filtered.map((b, i) => (
            <div key={b.id}
              style={{ borderBottom: i < filtered.length - 1 ? `1px solid ${C.border}` : undefined, opacity: b.status === 'archivé' ? 0.55 : 1, display: 'grid', gridTemplateColumns: 'auto 2fr 1.5fr 1fr 1fr 60px 80px', gap: 12, padding: '14px 24px', alignItems: 'center' }}
              className="hover:bg-[#F5F3FF] transition-colors">
              <div className={`w-9 h-12 rounded-lg bg-gradient-to-b ${b.cover} shrink-0 shadow-sm`} />
              <span style={{ color: C.text }} className="text-sm font-semibold truncate">{b.title}</span>
              <span style={{ color: C.muted }} className="text-sm truncate">{b.author}</span>
              <Badge label={b.type === 'plumora' ? 'Plumora' : 'Public'} color={b.type === 'plumora' ? C.plumora : C.primary} bg={b.type === 'plumora' ? '#F5EEFF' : C.primaryBg} />
              <div>{statusBadge(b.status)}</div>
              <span style={{ color: b.reports > 0 ? C.error : C.muted }} className="text-sm font-bold text-center">{b.reports > 0 ? b.reports : '—'}</span>
              <div className="flex items-center gap-1">
                <button title="Détail" onClick={() => open('detail', b)} style={{ color: C.muted }} className="p-1.5 rounded-lg hover:bg-[#EDE9FF] hover:text-[#7C5CFF] transition-colors"><Eye size={14} /></button>
                {b.status !== 'archivé'
                  ? <button title="Archiver" onClick={() => open('archive', b)} style={{ color: C.muted }} className="p-1.5 rounded-lg hover:bg-[#FEF2F2] hover:text-[#E05252] transition-colors"><Archive size={14} /></button>
                  : <button title="Restaurer" onClick={() => open('restore', b)} style={{ color: C.muted }} className="p-1.5 rounded-lg hover:bg-[#F0FBF6] hover:text-[#2EA87A] transition-colors"><RotateCcw size={14} /></button>
                }
              </div>
            </div>
          ))
        }
      </div>

      {/* Mobile cards */}
      <div className="md:hidden space-y-3">
        {filtered.length === 0
          ? <EmptyState icon={BookOpen} title="Aucun livre trouvé" />
          : filtered.map(b => (
            <div key={b.id} style={{ background: C.card, border: `1px solid ${b.status === 'signalé' ? C.error + '50' : C.border}`, opacity: b.status === 'archivé' ? 0.7 : 1 }} className="rounded-2xl p-4 flex gap-3">
              <div className={`w-11 rounded-xl bg-gradient-to-b ${b.cover} shrink-0 shadow-sm`} style={{ height: 62 }} />
              <div className="flex-1 min-w-0">
                <p style={{ color: C.text }} className="font-bold text-sm truncate">{b.title}</p>
                <p style={{ color: C.muted }} className="text-xs mb-2">{b.author}</p>
                <div className="flex flex-wrap gap-1.5 mb-2">
                  <Badge label={b.type === 'plumora' ? 'Plumora' : 'Public'} color={b.type === 'plumora' ? C.plumora : C.primary} bg={b.type === 'plumora' ? '#F5EEFF' : C.primaryBg} />
                  {statusBadge(b.status)}
                  {b.reports > 0 && <Badge label={`${b.reports}`} color={C.error} bg={C.errorBg} icon={Flag} />}
                </div>
                <div className="flex gap-2">
                  <Btn label="Détail" outline color={C.primary} onClick={() => open('detail', b)} icon={Eye} small />
                  {b.status !== 'archivé'
                    ? <Btn label="Archiver" danger onClick={() => open('archive', b)} icon={Archive} small />
                    : <Btn label="Restaurer" bg={C.success} onClick={() => open('restore', b)} icon={RotateCcw} small />
                  }
                </div>
              </div>
            </div>
          ))
        }
      </div>

      {/* Modals */}
      {modal === 'detail' && sel && (
        <Modal title="Détail du livre" onClose={() => setModal(null)}>
          <div className="flex gap-4 mb-4">
            <div className={`w-16 rounded-2xl bg-gradient-to-b ${sel.cover} shrink-0 shadow-md`} style={{ height: 90 }} />
            <div className="flex-1 min-w-0">
              <p style={{ color: C.text }} className="font-bold text-base mb-1">{sel.title}</p>
              <p style={{ color: C.muted }} className="text-sm mb-2">{sel.author}</p>
              <div className="flex flex-wrap gap-1.5"><Badge label={sel.type === 'plumora' ? 'Plumora' : 'Public'} color={sel.type === 'plumora' ? C.plumora : C.primary} bg={sel.type === 'plumora' ? '#F5EEFF' : C.primaryBg} />{statusBadge(sel.status)}</div>
            </div>
          </div>
          <p style={{ color: C.muted }} className="text-sm mb-4 leading-relaxed">{sel.summary}</p>
          <div style={{ borderTop: `1px solid ${C.border}` }} className="pt-1">
            <InfoRow label="Ajouté le" value={sel.added} />
            <InfoRow label="Chapitres" value={sel.chapters} />
            <InfoRow label="Signalements" value={sel.reports > 0 ? <span style={{ color: C.error }}>{sel.reports}</span> : '0'} />
          </div>
        </Modal>
      )}
      {modal === 'archive' && sel && (
        <Modal title="Archiver le livre" onClose={() => setModal(null)}>
          <div className="flex gap-3 items-center mb-4">
            <div className={`w-10 h-14 rounded-xl bg-gradient-to-b ${sel.cover} shrink-0 shadow-sm`} />
            <p style={{ color: C.text }} className="font-semibold">{sel.title}</p>
          </div>
          <div style={{ background: C.errorBg, border: `1px solid ${C.error}30` }} className="rounded-xl p-3 flex gap-2 mb-4">
            <AlertTriangle size={13} style={{ color: C.error }} className="mt-0.5 shrink-0" />
            <p style={{ color: C.error }} className="text-sm">Ce livre ne sera plus visible publiquement.</p>
          </div>
          <label style={{ color: C.muted }} className="text-xs font-medium block mb-1.5">Raison</label>
          <textarea value={archiveReason} onChange={e => setReason(e.target.value)} rows={3} placeholder="Motif..."
            style={{ background: C.mutedBg, border: `1px solid ${C.border}`, color: C.text }}
            className="w-full px-3 py-2 rounded-xl text-sm resize-none mb-5 placeholder:text-[#7167A0] outline-none" />
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Archiver" danger onClick={doArchive} icon={Archive} /></div>
        </Modal>
      )}
      {modal === 'restore' && sel && (
        <Modal title="Restaurer le livre" onClose={() => setModal(null)}>
          <p style={{ color: C.muted }} className="text-sm mb-5">Voulez-vous restaurer <strong style={{ color: C.text }}>"{sel.title}"</strong> ? Il redeviendra visible publiquement.</p>
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Restaurer" bg={C.success} onClick={doRestore} icon={RotateCcw} /></div>
        </Modal>
      )}
    </div>
  );
}

// ─── REPORTS ─────────────────────────────────────────────────────────────────
function ReportsScreen() {
  const [statusFilter, setStatus] = useState('all');
  const [typeFilter, setType]     = useState('all');
  const [reports, setReports]     = useState(REPORTS_DATA);
  const [modal, setModal]         = useState<'detail'|'in-review'|'resolve'|'reject'|'archive-content'|null>(null);
  const [sel, setSel]             = useState<typeof REPORTS_DATA[0]|null>(null);
  const [comment, setComment]     = useState('');
  const [just, setJust]           = useState('');
  const [toast, setToast]         = useState('');

  const statusFilters = ['all','PENDING','IN_REVIEW','RESOLVED','REJECTED'];
  const types = ['all','Livre','Commentaire','Profil','Réponse IA','Bêta-lecture'];
  const label = (f: string) => ({ all:'Tous', PENDING:'En attente', IN_REVIEW:'En cours', RESOLVED:'Résolu', REJECTED:'Rejeté' }[f] ?? f);

  const filtered = reports.filter(r =>
    (statusFilter === 'all' || r.status === statusFilter) &&
    (typeFilter === 'all' || r.contentType === typeFilter)
  );

  const open = (t: typeof modal, r: typeof REPORTS_DATA[0]) => { setSel(r); setComment(''); setJust(''); setModal(t); };
  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000); };
  const updateStatus = (newStatus: string, msg: string) => {
    if (!sel) return;
    setReports(rs => rs.map(x => x.id === sel.id ? { ...x, status: newStatus } : x));
    setModal(null); showToast(msg);
  };

  return (
    <div className="space-y-5">
      <Toast msg={toast} />
      <div>
        <h1 style={{ color: C.text, fontFamily: "'Playfair Display', serif" }} className="text-3xl font-bold">Signalements</h1>
        <p style={{ color: C.muted }} className="text-sm mt-1">{reports.filter(r => r.status === 'PENDING').length} en attente de traitement</p>
      </div>

      <div style={{ background: C.card, border: `1px solid ${C.border}` }} className="rounded-2xl p-4 flex flex-wrap gap-2 items-center">
        {statusFilters.map(f => (
          <button key={f} onClick={() => setStatus(f)}
            style={statusFilter === f ? { background: C.primary, color: '#fff', boxShadow: `0 2px 8px ${C.primary}40` } : { background: C.mutedBg, color: C.muted }}
            className="px-3 py-1.5 rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5">
            {label(f)}
            <span style={{ background: statusFilter === f ? 'rgba(255,255,255,0.25)' : C.border, color: statusFilter === f ? '#fff' : C.text }}
              className="px-1.5 rounded-full text-xs">
              {(f === 'all' ? reports : reports.filter(r => r.status === f)).length}
            </span>
          </button>
        ))}
        <select value={typeFilter} onChange={e => setType(e.target.value)}
          style={{ background: C.mutedBg, border: `1px solid ${C.border}`, color: C.text }}
          className="px-3 py-1.5 rounded-xl text-xs font-medium ml-auto">
          {types.map(t => <option key={t} value={t}>{t === 'all' ? 'Tous types' : t}</option>)}
        </select>
      </div>

      {filtered.length === 0
        ? <div style={{ background: C.card, border: `1px solid ${C.border}` }} className="rounded-2xl"><EmptyState icon={Flag} title="Aucun signalement" sub="Aucun signalement dans cette catégorie" /></div>
        : <div className="space-y-3">
            {filtered.map(r => (
              <div key={r.id}
                style={{ background: C.card, border: `1px solid ${r.status === 'PENDING' ? C.primary + '50' : C.border}`, boxShadow: r.status === 'PENDING' ? `0 2px 12px ${C.primary}15` : '0 1px 3px rgba(124,92,255,0.06)' }}
                className="rounded-2xl p-5">
                <div className="flex items-start gap-3 mb-0">
                  <div className="flex-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-2 mb-2">
                      <span style={{ color: C.muted, background: C.mutedBg }} className="text-xs font-mono px-2 py-0.5 rounded-lg">{r.id}</span>
                      {statusBadge(r.status)}
                      {priorityBadge(r.priority)}
                      <Badge label={r.contentType} color={C.muted} bg={C.mutedBg} />
                    </div>
                    <p style={{ color: C.text }} className="font-bold text-sm">{r.content}</p>
                    <p style={{ color: C.muted }} className="text-xs mt-0.5">Motif : {r.reason}</p>
                    <p style={{ color: C.muted }} className="text-xs mt-0.5">Par {r.reporter} · {r.date}</p>
                  </div>
                  <button title="Consulter" onClick={() => open('detail', r)}
                    style={{ background: C.primaryBg, color: C.primary }} className="p-2 rounded-xl hover:opacity-80 transition-opacity shrink-0">
                    <Eye size={14} />
                  </button>
                </div>
                {r.status === 'PENDING' && (
                  <div style={{ borderTop: `1px solid ${C.border}` }} className="flex flex-wrap gap-2 mt-4 pt-4">
                    <Btn label="Passer en cours" color={C.primary} onClick={() => open('in-review', r)} icon={Clock} small />
                    <Btn label="Résoudre" bg={C.success} onClick={() => open('resolve', r)} icon={CheckCircle} small />
                    <Btn label="Rejeter" outline danger onClick={() => open('reject', r)} icon={XCircle} small />
                  </div>
                )}
                {r.status === 'IN_REVIEW' && (
                  <div style={{ borderTop: `1px solid ${C.border}` }} className="flex flex-wrap gap-2 mt-4 pt-4">
                    <Btn label="Résoudre" bg={C.success} onClick={() => open('resolve', r)} icon={CheckCircle} small />
                    <Btn label="Rejeter" outline danger onClick={() => open('reject', r)} icon={XCircle} small />
                    <Btn label="Archiver le contenu" danger onClick={() => open('archive-content', r)} icon={Archive} small />
                  </div>
                )}
              </div>
            ))}
          </div>
      }

      {/* Modals */}
      {modal === 'detail' && sel && (
        <Modal title={`Signalement ${sel.id}`} onClose={() => setModal(null)} width="max-w-lg">
          <div className="space-y-0 mb-4">
            <InfoRow label="Type" value={<Badge label={sel.contentType} color={C.muted} bg={C.mutedBg} />} />
            <InfoRow label="Contenu" value={sel.content} />
            <InfoRow label="Auteur du contenu" value={sel.authorContent} />
            <InfoRow label="Signalé par" value={sel.reporter} />
            <InfoRow label="Motif" value={sel.reason} />
            <InfoRow label="Priorité" value={priorityBadge(sel.priority)} />
            <InfoRow label="Statut" value={statusBadge(sel.status)} />
            <InfoRow label="Date" value={sel.date} />
          </div>
          <div style={{ background: C.mutedBg, borderRadius: 12 }} className="p-4 mb-3">
            <p style={{ color: C.muted }} className="text-xs font-bold mb-1.5">Description</p>
            <p style={{ color: C.text }} className="text-sm leading-relaxed">{sel.description}</p>
          </div>
          <div style={{ background: C.mutedBg, borderRadius: 12 }} className="p-4">
            <p style={{ color: C.muted }} className="text-xs font-bold mb-1.5">Historique</p>
            <p style={{ color: C.muted }} className="text-xs">• Signalement reçu · {sel.date}</p>
            {sel.status !== 'PENDING' && <p style={{ color: C.muted }} className="text-xs">• Pris en charge · Aujourd'hui</p>}
            {(sel.status === 'RESOLVED' || sel.status === 'REJECTED') && <p style={{ color: C.muted }} className="text-xs">• Clôturé · Aujourd'hui</p>}
          </div>
        </Modal>
      )}
      {modal === 'in-review' && sel && (
        <Modal title="Passer en cours" onClose={() => setModal(null)}>
          <p style={{ color: C.muted }} className="text-sm mb-5">Le signalement <strong style={{ color: C.text }}>{sel.id}</strong> passera en statut <Badge label="En cours" color={C.primary} bg={C.primaryBg} />.</p>
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Confirmer" onClick={() => updateStatus('IN_REVIEW', 'Signalement passé en cours')} icon={Clock} /></div>
        </Modal>
      )}
      {modal === 'resolve' && sel && (
        <Modal title="Résoudre le signalement" onClose={() => setModal(null)}>
          <label style={{ color: C.muted }} className="text-xs font-medium block mb-1.5">Commentaire (facultatif)</label>
          <textarea value={comment} onChange={e => setComment(e.target.value)} rows={3} placeholder="Résumé de la décision..."
            style={{ background: C.mutedBg, border: `1px solid ${C.border}`, color: C.text }}
            className="w-full px-3 py-2 rounded-xl text-sm resize-none mb-5 placeholder:text-[#7167A0] outline-none" />
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Résoudre" bg={C.success} onClick={() => updateStatus('RESOLVED', 'Signalement résolu')} icon={CheckCircle} /></div>
        </Modal>
      )}
      {modal === 'reject' && sel && (
        <Modal title="Rejeter le signalement" onClose={() => setModal(null)}>
          <label style={{ color: C.muted }} className="text-xs font-medium block mb-1.5">Justification <span style={{ color: C.error }}>*</span></label>
          <textarea value={just} onChange={e => setJust(e.target.value)} rows={3} placeholder="Raison du rejet..."
            style={{ background: C.mutedBg, border: `1px solid ${C.border}`, color: C.text }}
            className="w-full px-3 py-2 rounded-xl text-sm resize-none mb-5 placeholder:text-[#7167A0] outline-none" />
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Rejeter" danger disabled={!just.trim()} onClick={() => updateStatus('REJECTED', 'Signalement rejeté')} icon={XCircle} /></div>
        </Modal>
      )}
      {modal === 'archive-content' && sel && (
        <Modal title="Archiver le contenu" onClose={() => setModal(null)}>
          <div style={{ background: C.errorBg, border: `1px solid ${C.error}30` }} className="rounded-xl p-3 flex gap-2 mb-5">
            <AlertTriangle size={13} style={{ color: C.error }} className="mt-0.5 shrink-0" />
            <p style={{ color: C.error }} className="text-sm"><strong>"{sel.content}"</strong> sera archivé et ne sera plus visible publiquement.</p>
          </div>
          <div className="flex gap-3"><Btn label="Annuler" outline color={C.muted} onClick={() => setModal(null)} /><Btn label="Archiver le contenu" danger onClick={() => updateStatus('RESOLVED', 'Contenu archivé')} icon={Archive} /></div>
        </Modal>
      )}
    </div>
  );
}

// ─── NAV CONFIG ───────────────────────────────────────────────────────────────
const NAV: { key: Section; label: string; icon: React.ElementType; badge?: number }[] = [
  { key: 'dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
  { key: 'users',     label: 'Utilisateurs',    icon: Users,    badge: 14820 },
  { key: 'catalogue', label: 'Catalogue',        icon: BookOpen, badge: 3241 },
  { key: 'reports',   label: 'Signalements',     icon: Flag,     badge: 23 },
];

// ─── ROOT ─────────────────────────────────────────────────────────────────────
export function AdminPage({ onNavigate }: AdminPageProps) {
  const [section, setSection] = useState<Section>('dashboard');

  const renderSection = () => {
    switch (section) {
      case 'dashboard': return <Dashboard onNav={setSection} />;
      case 'users':     return <UsersScreen />;
      case 'catalogue': return <CatalogueScreen />;
      case 'reports':   return <ReportsScreen />;
    }
  };

  return (
    <div style={{ background: C.bg, minHeight: '100vh' }} className="flex">

      {/* ── DESKTOP SIDEBAR (lg+) ─────────────────────────── */}
      <aside
        style={{ background: C.surface, borderRight: `1px solid ${C.border}`, width: 240, boxShadow: '1px 0 16px rgba(124,92,255,0.06)' }}
        className="hidden lg:flex flex-col shrink-0 h-screen sticky top-0">

        {/* Logo area */}
        <div style={{ borderBottom: `1px solid ${C.border}` }} className="px-5 py-5">
          <div className="flex items-center gap-2.5 mb-3">
            <div style={{ background: `linear-gradient(135deg, ${C.primary}, ${C.plumora})`, boxShadow: `0 4px 12px ${C.primary}40` }}
              className="w-8 h-8 rounded-xl flex items-center justify-center">
              <Feather size={14} color="#fff" />
            </div>
            <span style={{ color: C.text, fontFamily: "'Playfair Display', serif" }} className="font-bold text-xl">Plumora</span>
          </div>
          <div style={{ background: C.errorBg, border: `1px solid ${C.error}30` }}
            className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl">
            <Shield size={10} style={{ color: C.error }} />
            <span style={{ color: C.error }} className="text-xs font-bold">Espace Administration</span>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 py-4 px-3 overflow-y-auto space-y-1">
          {NAV.map(item => {
            const active = section === item.key;
            return (
              <button key={item.key} onClick={() => setSection(item.key)}
                style={active
                  ? { background: C.primaryBg, color: C.primary, boxShadow: `inset 3px 0 0 ${C.primary}` }
                  : { background: 'transparent', color: C.muted }}
                className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition-all hover:bg-[#F0EEFF] hover:text-[#7C5CFF] text-left">
                <item.icon size={16} />
                <span className="flex-1">{item.label}</span>
                {item.badge && (
                  <span style={{ background: active ? C.primary + '25' : C.border, color: active ? C.primary : C.muted }}
                    className="text-xs px-2 py-0.5 rounded-full font-medium">
                    {item.badge >= 1000 ? `${Math.round(item.badge / 1000)}k` : item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>

        {/* User profile + logout */}
        <div style={{ borderTop: `1px solid ${C.border}` }} className="p-3">
          <div style={{ background: C.mutedBg, borderRadius: 16 }} className="p-3 mb-2 flex items-center gap-3">
            <div style={{ background: `linear-gradient(135deg, ${C.plumora}, ${C.primary})` }}
              className="w-9 h-9 rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0">SA</div>
            <div className="min-w-0 flex-1">
              <p style={{ color: C.text }} className="text-xs font-bold truncate">Sarah Benali</p>
              <p style={{ color: C.muted }} className="text-xs">Administrateur</p>
            </div>
          </div>
          <button onClick={() => onNavigate('home')}
            style={{ color: C.muted }}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-medium hover:bg-[#F0EEFF] hover:text-[#7C5CFF] transition-colors">
            <LogOut size={13} /> Quitter l'administration
          </button>
        </div>
      </aside>

      {/* ── MAIN CONTENT ──────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 min-h-screen">

        {/* Top header */}
        <header
          style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, boxShadow: '0 1px 8px rgba(124,92,255,0.06)' }}
          className="sticky top-0 z-30 flex items-center gap-3 px-5 py-3.5">
          <span style={{ color: C.text, fontFamily: "'Playfair Display', serif" }} className="font-bold text-base flex-1 truncate">
            {NAV.find(n => n.key === section)?.label}
          </span>
          <button style={{ background: C.mutedBg, color: C.muted }} className="p-2 rounded-xl hover:bg-[#EDE9FF] hover:text-[#7C5CFF] transition-colors relative">
            <Bell size={15} />
            <span style={{ background: C.error }} className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full border-2 border-white" />
          </button>
          <div style={{ background: `linear-gradient(135deg, ${C.plumora}, ${C.primary})` }}
            className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold cursor-pointer">SA</div>
        </header>

        {/* Page content — extra bottom padding on mobile for bottom tab bar */}
        <main className="flex-1 p-4 lg:p-8 overflow-auto pb-24 lg:pb-8">
          {renderSection()}
        </main>
      </div>

      {/* ── MOBILE BOTTOM TAB BAR (< lg) ──────────────────── */}
      <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-40 flex"
        style={{
          background: C.surface,
          borderTop: `1px solid ${C.border}`,
          boxShadow: '0 -4px 16px rgba(124,92,255,0.08)',
          paddingBottom: 'env(safe-area-inset-bottom)',
        }}>
        {NAV.map(item => {
          const active = section === item.key;
          return (
            <button key={item.key} onClick={() => setSection(item.key)}
              className="flex-1 flex flex-col items-center gap-1 py-2.5 transition-colors relative"
              style={{ color: active ? C.primary : C.muted }}>
              {/* Active bar at top */}
              {active && (
                <span style={{ background: C.primary, position: 'absolute', top: 0, left: '50%', transform: 'translateX(-50%)', width: 28, height: 3, borderRadius: '0 0 4px 4px' }} />
              )}
              {/* Icon with badge */}
              <span className="relative">
                <item.icon size={20} />
                {item.key === 'reports' && (
                  <span style={{ background: C.error, color: '#fff', position: 'absolute', top: -5, right: -7 }}
                    className="text-[9px] w-4 h-4 rounded-full flex items-center justify-center font-bold">23</span>
                )}
              </span>
              <span className="text-[10px] font-bold leading-none">
                {item.key === 'dashboard' ? 'Dashboard' : item.label.split(' ')[0]}
              </span>
            </button>
          );
        })}
      </nav>

    </div>
  );
}
