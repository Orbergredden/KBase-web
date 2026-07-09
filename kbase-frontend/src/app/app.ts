import { Component, signal, OnInit, inject } from '@angular/core';
import { RouterOutlet, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import packageInfo from '../../package.json';
import { AuthService } from './services/auth.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  protected readonly authService = inject(AuthService);

  protected readonly title = signal('kbase-frontend');
  protected readonly version = signal(packageInfo.version);
  protected readonly backendVersion = signal<string>('завантаження...');
  protected readonly dbVersion = signal<string>('завантаження...');
  protected readonly dbDate = signal<string>('завантаження...');

  ngOnInit(): void {
    // Відновлення сесії на старті
    this.authService.initAuth().then((isLoggedIn) => {
      if (isLoggedIn) {
        if (this.router.url === '/' || this.router.url === '/login') {
          this.router.navigate(['/dashboard']);
        }
      }
    });

    // Завантаження інформації про версії
    this.http.get<{ backend: string; db: string; dbDate: string }>('http://localhost:8080/api/info')
      .subscribe({
        next: (info) => {
          this.backendVersion.set(info.backend);
          this.dbVersion.set(info.db);
          this.dbDate.set(info.dbDate);
        },
        error: (err) => {
          console.error('Failed to load version info', err);
          this.backendVersion.set('недоступно');
          this.dbVersion.set('недоступно');
          this.dbDate.set('недоступно');
        }
      });
  }

  goToLogin(): void {
    this.router.navigate(['/login']);
  }

  goToHome(): void {
    if (this.authService.isLoggedIn()) {
      this.router.navigate(['/dashboard']);
    } else {
      this.router.navigate(['/']);
    }
  }

  logout(): void {
    this.authService.logout();
  }
}
