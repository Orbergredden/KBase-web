import { Component, signal, OnInit, inject } from '@angular/core';
import { RouterOutlet, Router, NavigationEnd } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { toSignal } from '@angular/core/rxjs-interop';
import { filter, map } from 'rxjs/operators';
import packageInfo from '../../package.json';
import { AuthService } from './services/auth.service';
import { ThemeService } from './services/theme.service';

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
  protected readonly themeService = inject(ThemeService);

  protected readonly title = signal('kbase-frontend');
  protected readonly version = signal(packageInfo.version);
  protected readonly backendVersion = signal<string>('завантаження...');
  protected readonly dbVersion = signal<string>('завантаження...');
  protected readonly dbDate = signal<string>('завантаження...');

  protected readonly isMainPage = toSignal(
    this.router.events.pipe(
      filter((e): e is NavigationEnd => e instanceof NavigationEnd),
      map((e) => e.urlAfterRedirects.startsWith('/main'))
    ),
    { initialValue: this.router.url.startsWith('/main') }
  );

  ngOnInit(): void {
    // Відновлення сесії на старті
    this.authService.initAuth().then((isLoggedIn) => {
      if (isLoggedIn) {
        if (this.router.url === '/' || this.router.url === '/login') {
          this.router.navigate(['/main']);
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
      this.router.navigate(['/main']);
    } else {
      this.router.navigate(['/']);
    }
  }

  logout(): void {
    this.authService.logout();
  }
}
