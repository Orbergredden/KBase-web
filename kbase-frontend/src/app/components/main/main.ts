import { Component, inject, computed } from '@angular/core';
import { Router } from '@angular/router';
import { Menubar } from 'primeng/menubar';
import { MenuItem } from 'primeng/api';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-main',
  imports: [Menubar],
  templateUrl: './main.html',
  styleUrl: './main.scss'
})
export class MainComponent {
  protected readonly authService = inject(AuthService);
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

  logout(): void {
    this.authService.logout();
  }
}
