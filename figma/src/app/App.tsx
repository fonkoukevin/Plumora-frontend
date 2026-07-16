import { useState } from 'react';
import { LandingPage } from './screens/LandingPage';
import { LoginPage } from './screens/LoginPage';
import { SignupPage } from './screens/SignupPage';
import { RoleSelectionPage } from './screens/RoleSelectionPage';
import { HomePage } from './screens/HomePage';
import { WritePage } from './screens/WritePage';
import { AuthorDashboard } from './screens/AuthorDashboard';
import { CreateBookPage } from './screens/CreateBookPage';
import { EditorPage } from './screens/EditorPage';
import { MobileEditorPage } from './screens/MobileEditorPage';
import { DiscoverPage } from './screens/DiscoverPage';
import { LibraryPage } from './screens/LibraryPage';
import { RoyaltiesPage } from './screens/RoyaltiesPage';
import { ProfilePage } from './screens/ProfilePage';
import { BookReaderPage } from './screens/BookReaderPage';
import { MukemeAssistantPage } from './screens/MukemeAssistantPage';
import { BetaTestPage } from './screens/BetaTestPage';
import { BetaSubmissionPage } from './screens/BetaSubmissionPage';
import { BetaReadingPage } from './screens/BetaReadingPage';
import { BetaFeedbackPage } from './screens/BetaFeedbackPage';
import { PublicationPrepPage } from './screens/PublicationPrepPage';
import { AdminPublicationPage } from './screens/AdminPublicationPage';
import { MukemeRecommendationPage } from './screens/MukemeRecommendationPage';
import { MukemeResultsPage } from './screens/MukemeResultsPage';
import { BookDetailPage } from './screens/BookDetailPage';
import { BookReviewPage } from './screens/BookReviewPage';
import { MyBookDetailPage } from './screens/MyBookDetailPage';
import { AdminPage } from './screens/AdminPage';
import { AppLayout } from './components/AppLayout';
import { STORIES } from './data/stories';

// Pages that get the app sidebar layout
const APP_PAGES = new Set([
  'home', 'write', 'author-dashboard', 'create-book', 'editor', 'mobile-editor',
  'discover', 'library', 'royalties', 'profile', 'mukeme', 'beta-tests',
  'beta-submission', 'beta-reading', 'beta-feedback', 'publication-prep',
  'admin-publication', 'mukeme-recommendation', 'mukeme-results',
  'book-detail', 'book-review',
  'my-book-detail-1', 'my-book-detail-2', 'my-book-detail-3',
]);

export default function App() {
  const [currentPage, setCurrentPage] = useState<string>('home');

  const handleNavigate = (page: string) => {
    setCurrentPage(page);
  };

  const renderInner = () => {
    switch (currentPage) {
      case 'home':
        return <HomePage onNavigate={handleNavigate} />;
      case 'write':
        return <WritePage onNavigate={handleNavigate} />;
      case 'author-dashboard':
        return <AuthorDashboard onNavigate={handleNavigate} />;
      case 'create-book':
        return <CreateBookPage onNavigate={handleNavigate} />;
      case 'editor':
        return <EditorPage onNavigate={handleNavigate} />;
      case 'mobile-editor':
        return <MobileEditorPage onNavigate={handleNavigate} />;
      case 'discover':
        return <DiscoverPage onNavigate={handleNavigate} />;
      case 'library':
        return <LibraryPage onNavigate={handleNavigate} />;
      case 'royalties':
        return <RoyaltiesPage onNavigate={handleNavigate} />;
      case 'profile':
        return <ProfilePage onNavigate={handleNavigate} />;
      case 'mukeme':
        return <MukemeAssistantPage onNavigate={handleNavigate} />;
      case 'beta-tests':
        return <BetaTestPage onNavigate={handleNavigate} />;
      case 'beta-submission':
        return <BetaSubmissionPage onNavigate={handleNavigate} />;
      case 'beta-reading':
        return <BetaReadingPage onNavigate={handleNavigate} />;
      case 'beta-feedback':
        return <BetaFeedbackPage onNavigate={handleNavigate} />;
      case 'publication-prep':
        return <PublicationPrepPage onNavigate={handleNavigate} />;
      case 'admin-publication':
        return <AdminPublicationPage onNavigate={handleNavigate} />;
      case 'mukeme-recommendation':
        return <MukemeRecommendationPage onNavigate={handleNavigate} />;
      case 'mukeme-results':
        return <MukemeResultsPage onNavigate={handleNavigate} />;
      case 'book-detail':
        return <BookDetailPage onNavigate={handleNavigate} />;
      case 'book-review':
        return <BookReviewPage onNavigate={handleNavigate} />;
      case 'my-book-detail-1':
        return <MyBookDetailPage book={STORIES[0]} onNavigate={handleNavigate} />;
      case 'my-book-detail-2':
        return <MyBookDetailPage book={STORIES[1]} onNavigate={handleNavigate} />;
      case 'my-book-detail-3':
        return <MyBookDetailPage book={STORIES[2]} onNavigate={handleNavigate} />;
      default:
        return null;
    }
  };

  // Full-screen pages (no sidebar/nav)
  if (!APP_PAGES.has(currentPage)) {
    switch (currentPage) {
      case 'admin':
        return <AdminPage onNavigate={handleNavigate} />;
      case 'book-reader':
        return <BookReaderPage onNavigate={handleNavigate} />;
      case 'landing':
        return <LandingPage onNavigate={handleNavigate} />;
      case 'login':
        return <LoginPage onNavigate={handleNavigate} />;
      case 'signup':
        return <SignupPage onNavigate={handleNavigate} />;
      case 'role-selection':
        return <RoleSelectionPage onNavigate={handleNavigate} />;
      default:
        return <LandingPage onNavigate={handleNavigate} />;
    }
  }

  return (
    <AppLayout currentPage={currentPage} onNavigate={handleNavigate}>
      {renderInner()}
    </AppLayout>
  );
}
