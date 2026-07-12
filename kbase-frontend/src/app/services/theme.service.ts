import { Injectable, effect, inject, signal } from '@angular/core';
import { usePreset } from '@primeuix/themes';
import Aura from '@primeuix/themes/aura';
import Lara from '@primeuix/themes/lara';
import Nora from '@primeuix/themes/nora';
import Material from '@primeuix/themes/material';
import { AuthService } from './auth.service';

export type ThemePreset = 'aura' | 'lara' | 'nora' | 'material';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private readonly authService = inject(AuthService);
  readonly currentTheme = signal<ThemePreset>('aura');
  readonly isDarkMode = signal<boolean>(false);

  constructor() {
    // Automatically apply theme when user logs in/out or changes preference
    effect(() => {
      const user = this.authService.currentUser();
      const savedTheme = this.getSavedTheme(user?.username);
      this.applyThemePreset(savedTheme);

      const savedDarkMode = this.getSavedDarkMode(user?.username);
      this.applyDarkMode(savedDarkMode);
    });
  }

  private getSavedTheme(username?: string): ThemePreset {
    if (username) {
      const userTheme = localStorage.getItem(`kbase_theme_${username}`);
      if (userTheme) return userTheme as ThemePreset;
    }
    const globalTheme = localStorage.getItem('kbase_theme_default');
    return (globalTheme as ThemePreset) || 'aura';
  }

  private getSavedDarkMode(username?: string): boolean {
    if (username) {
      const userMode = localStorage.getItem(`kbase_dark_mode_${username}`);
      if (userMode !== null) return userMode === 'true';
    }
    const globalMode = localStorage.getItem('kbase_dark_mode_default');
    return globalMode === 'true';
  }

  setTheme(theme: ThemePreset): void {
    const user = this.authService.currentUser();
    if (user?.username) {
      localStorage.setItem(`kbase_theme_${user.username}`, theme);
    } else {
      localStorage.setItem('kbase_theme_default', theme);
    }
    this.applyThemePreset(theme);
  }

  toggleDarkMode(): void {
    const nextMode = !this.isDarkMode();
    const user = this.authService.currentUser();
    if (user?.username) {
      localStorage.setItem(`kbase_dark_mode_${user.username}`, String(nextMode));
    } else {
      localStorage.setItem('kbase_dark_mode_default', String(nextMode));
    }
    this.applyDarkMode(nextMode);
  }

  private applyDarkMode(isDark: boolean): void {
    this.isDarkMode.set(isDark);
    const element = document.documentElement;
    if (isDark) {
      element.classList.add('p-dark');
    } else {
      element.classList.remove('p-dark');
    }
  }

  private applyThemePreset(theme: ThemePreset): void {
    this.currentTheme.set(theme);
    switch (theme) {
      case 'aura':
        usePreset(Aura);
        break;
      case 'lara':
        usePreset(Lara);
        break;
      case 'nora':
        usePreset(Nora);
        break;
      case 'material':
        usePreset(Material);
        break;
    }
  }
}
