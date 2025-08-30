function selectNextWindow(direction) {
  const windowList = workspace.windowList();
  const desktop = workspace.currentDesktop;
  let currentIdx = -1;

  // Trouver l'index de la fenêtre active actuelle
  for (let i = 0; i < windowList.length; i++) {
    if (windowList[i].active) {
      currentIdx = i;
      break;
    }
  }

  // Trouver la prochaine fenêtre dans la direction spécifiée
  for (let i = currentIdx + direction; (i >= 0 && i < windowList.length); i += direction) {
    if (!windowList[i].desktopWindow && windowList[i].desktops.includes(desktop)) {
      workspace.activeWindow = windowList[i];
      return;
    }
  }

  // Si aucune fenêtre trouvée dans la direction, revenir au début ou à la fin
  for (let i = direction > 0 ? 0 : windowList.length - 1; (i >= 0 && i < windowList.length); i += direction) {
    if (!windowList[i].desktopWindow && windowList[i].desktops.includes(desktop)) {
      workspace.activeWindow = windowList[i];
      return;
    }
  }
}

// Enregistrer les raccourcis
registerShortcut('nextWindow', 'Select next window', 'Meta+I', () => selectNextWindow(1));
registerShortcut('prevWindow', 'Select previous window', 'Meta+H', () => selectNextWindow(-1));
