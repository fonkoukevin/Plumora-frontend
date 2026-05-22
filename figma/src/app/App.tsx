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

export default function App() {
  const [currentPage, setCurrentPage] = useState<string>('landing');

  const handleNavigate = (page: string) => {
    setCurrentPage(page);
  };

  const renderPage = () => {
    switch (currentPage) {
      case 'landing':
        return <LandingPage onNavigate={handleNavigate} />;
      case 'login':
        return <LoginPage onNavigate={handleNavigate} />;
      case 'signup':
        return <SignupPage onNavigate={handleNavigate} />;
      case 'role-selection':
        return <RoleSelectionPage onNavigate={handleNavigate} />;
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
      case 'book-reader':
        return <BookReaderPage onNavigate={handleNavigate} />;
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
      default:
        return <LandingPage onNavigate={handleNavigate} />;
    }
  };

  return <div className="size-full">{renderPage()}</div>;
}