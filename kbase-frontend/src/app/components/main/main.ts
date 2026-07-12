import { Component, inject, computed } from '@angular/core';
import { Router } from '@angular/router';
import { Menubar } from 'primeng/menubar';
import { TieredMenu } from 'primeng/tieredmenu';
import { MenuItem } from 'primeng/api';
import { AuthService } from '../../services/auth.service';
import { ThemeService } from '../../services/theme.service';

@Component({
  selector: 'app-main',
  imports: [Menubar, TieredMenu],
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
    return [
      {
        label: 'Колірна схема',
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
        separator: true
      },
      {
        label: 'Вихід',
        icon: 'pi pi-sign-out',
        command: () => this.logout()
      }
    ];
  });

  logout(): void {
    this.authService.logout();
  }
}
