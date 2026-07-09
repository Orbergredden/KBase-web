import { Component, inject, signal, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss'
})
export class DashboardComponent implements OnInit {
  protected readonly authService = inject(AuthService);
  private readonly http = inject(HttpClient);

  protected readonly usersCount = signal<number>(0);
  protected readonly settingsCount = signal<number>(0);
  protected readonly isLoaderActive = signal<boolean>(false);

  protected readonly articles = signal<any[]>([
    { id: 1, title: 'Початок роботи з системою KBase', category: 'Інструкції', author: 'admin', date: '08.07.2026', views: 124 },
    { id: 2, title: 'Налаштування інтеграції з PostgreSQL', category: 'Технічна документація', author: 'Igor Makarevich', date: '05.07.2026', views: 89 },
    { id: 3, title: 'Політика безпеки та керування токенами', category: 'Безпека', author: 'admin', date: '09.07.2026', views: 42 }
  ]);

  ngOnInit(): void {
    if (this.authService.currentUser()?.role === 'ROLE_ADMIN') {
      this.loadAdminStats();
    }
  }

  private loadAdminStats(): void {
    this.isLoaderActive.set(true);
    
    this.http.get<any[]>('http://localhost:8080/api/users').subscribe({
      next: (users) => {
        this.usersCount.set(users.length);
        this.isLoaderActive.set(false);
      },
      error: (err) => {
        console.error('Failed to load users for dashboard stats', err);
        this.isLoaderActive.set(false);
      }
    });

    this.http.get<any[]>('http://localhost:8080/api/settings').subscribe({
      next: (settings) => {
        this.settingsCount.set(settings.length);
      },
      error: (err) => console.error('Failed to load settings stats', err)
    });
  }
}
