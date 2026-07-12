import { Component, inject, computed, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Menubar } from 'primeng/menubar';
import { TieredMenu } from 'primeng/tieredmenu';
import { MenuItem } from 'primeng/api';
import { Dialog } from 'primeng/dialog';
import { ButtonDirective } from 'primeng/button';
import { InputText } from 'primeng/inputtext';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { ThemeService } from '../../services/theme.service';

@Component({
  selector: 'app-main',
  imports: [Menubar, TieredMenu, Dialog, ButtonDirective, InputText, FormsModule],
  templateUrl: './main.html',
  styleUrl: './main.scss'
})
export class MainComponent {
  protected readonly authService = inject(AuthService);
  protected readonly themeService = inject(ThemeService);
  private readonly router = inject(Router);

  protected readonly menuItems = computed<MenuItem[]>(() => {
    const role = this.authService.currentUser()?.role;
    return [
      {
        label: 'Articles',
        icon: 'pi pi-file-text',
        command: () => console.log('Articles clicked')
      },
      {
        label: 'Categories',
        icon: 'pi pi-folder-open',
        command: () => console.log('Categories clicked')
      },
      ...(role === 'ROLE_ADMIN' ? [{
        label: 'Users',
        icon: 'pi pi-users',
        command: () => console.log('Users clicked')
      }] : []),
      {
        label: 'Settings',
        icon: 'pi pi-cog',
        command: () => console.log('Settings clicked')
      }
    ];
  });

  protected readonly userMenuItems = computed<MenuItem[]>(() => {
    const currentTheme = this.themeService.currentTheme();
    const isDark = this.themeService.isDarkMode();
    return [
      {
        label: 'Color Scheme',
        icon: 'pi pi-palette',
        items: [
          {
            label: 'Aura',
            icon: currentTheme === 'aura' ? 'pi pi-check' : 'pi pi-fw',
            command: () => this.themeService.setTheme('aura')
          },
          {
            label: 'Lara',
            icon: currentTheme === 'lara' ? 'pi pi-check' : 'pi pi-fw',
            command: () => this.themeService.setTheme('lara')
          },
          {
            label: 'Nora',
            icon: currentTheme === 'nora' ? 'pi pi-check' : 'pi pi-fw',
            command: () => this.themeService.setTheme('nora')
          },
          {
            label: 'Material',
            icon: currentTheme === 'material' ? 'pi pi-check' : 'pi pi-fw',
            command: () => this.themeService.setTheme('material')
          }
        ]
      },
      {
        label: isDark ? 'Light Mode' : 'Dark Mode',
        icon: isDark ? 'pi pi-sun' : 'pi pi-moon',
        command: () => this.themeService.toggleDarkMode()
      },
      {
        label: 'Settings...',
        icon: 'pi pi-user-edit',
        command: () => this.openSettings()
      },
      {
        separator: true
      },
      {
        label: 'Logout',
        icon: 'pi pi-sign-out',
        command: () => this.logout()
      }
    ];
  });

  protected readonly showSettingsDialog = signal(false);
  protected readonly email = signal('');
  protected readonly password = signal('');
  protected readonly roleName = signal('');
  protected readonly privileges = signal<string[]>([]);
  protected readonly savingSettings = signal(false);
  protected readonly loadingSettings = signal(false);
  protected readonly settingsError = signal('');
  protected readonly settingsSuccess = signal(false);

  openSettings(): void {
    this.settingsError.set('');
    this.settingsSuccess.set(false);
    this.password.set('');
    this.loadingSettings.set(true);
    this.showSettingsDialog.set(true);

    this.authService.getCurrentUserProfile().subscribe({
      next: (profile: any) => {
        this.email.set(profile.email || '');
        this.roleName.set(profile.roleName || '');
        this.privileges.set(profile.privileges || []);
        this.loadingSettings.set(false);
      },
      error: (err: any) => {
        console.error('Failed to load user profile', err);
        this.settingsError.set('Не вдалося завантажити профіль користувача');
        this.loadingSettings.set(false);
      }
    });
  }

  saveSettings(): void {
    this.settingsError.set('');
    this.settingsSuccess.set(false);
    this.savingSettings.set(true);

    const payload: any = { email: this.email() };
    if (this.password().trim()) {
      payload.password = this.password();
    }

    this.authService.updateUserSettings(payload).subscribe({
      next: (updatedUser: any) => {
        this.savingSettings.set(false);
        this.settingsSuccess.set(true);
        this.password.set('');
      },
      error: (err: any) => {
        console.error('Failed to update settings', err);
        this.settingsError.set(err.error?.message || 'Не вдалося зберегти налаштування');
        this.savingSettings.set(false);
      }
    });
  }

  logout(): void {
    this.authService.logout();
  }
}
