// Navigation simple entre les pages
function navigateTo(page) {
  window.location.href = page;
}

// Fonction utilitaire pour afficher/masquer des éléments
function toggleVisibility(elementId) {
  const element = document.getElementById(elementId);
  if (element) {
    element.classList.toggle('hidden');
  }
}
