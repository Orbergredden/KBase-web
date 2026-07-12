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

  constructor() {
    // Automatically apply theme when user logs in/out or changes preference
    effect(() => {
      const user = this.authService.currentUser();
      const savedTheme = this.getSavedTheme(user?.username);
      this.applyThemePreset(savedTheme);
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

  setTheme(theme: ThemePreset): void {
    const user = this.authService.currentUser();
    if (user?.username) {
      localStorage.setItem(`kbase_theme_${user.username}`, theme);
    } else {
      localStorage.setItem('kbase_theme_default', theme);
    }
    this.applyThemePreset(theme);
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
