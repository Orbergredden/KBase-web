import { Injectable, signal, computed, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, throwError, BehaviorSubject } from 'rxjs';
import { tap, catchError, switchMap, filter, take } from 'rxjs/operators';

interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  username: string;
  role: string;
  privileges: string[];
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);

  private readonly API_URL = 'http://localhost:8080/api/auth';
  private readonly USERS_API_URL = 'http://localhost:8080/api/users';

  readonly currentUser = signal<any | null>(null);
  readonly accessToken = signal<string | null>(null);
  readonly isLoggedIn = computed(() => this.currentUser() !== null);

  getCurrentUserProfile(): Observable<any> {
    return this.http.get<any>(`${this.USERS_API_URL}/me`);
  }

  updateUserSettings(settings: any): Observable<any> {
    return this.http.put<any>(`${this.USERS_API_URL}/me`, settings);
  }

  private isRefreshing = false;
  private refreshTokenSubject = new BehaviorSubject<string | null>(null);

  login(username: string, password: string, rememberMe: boolean): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.API_URL}/login`, { username, password, rememberMe }).pipe(
      tap(response => {
        this.handleAuthSuccess(response, rememberMe);
      })
    );
  }

  logout(): void {
    const refreshToken = this.getRefreshToken();
    if (refreshToken) {
      this.http.post(`${this.API_URL}/logout`, { refreshToken }).subscribe({
        next: () => {},
        error: (err) => console.error('Logout error on backend', err)
      });
    }
    this.clearSession();
    this.router.navigate(['/login']);
  }

  refreshToken(): Observable<AuthResponse> {
    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      return throwError(() => new Error('No refresh token available'));
    }

    return this.http.post<AuthResponse>(`${this.API_URL}/refresh`, { refreshToken }).pipe(
      tap(response => {
        const rememberMe = localStorage.getItem('kbase_refresh_token') !== null;
        this.handleAuthSuccess(response, rememberMe);
      }),
      catchError(err => {
        this.clearSession();
        return throwError(() => err);
      })
    );
  }

  handle401Error(request: any, next: any): Observable<any> {
    if (!this.isRefreshing) {
      this.isRefreshing = true;
      this.refreshTokenSubject.next(null);

      return this.refreshToken().pipe(
        switchMap((response) => {
          this.isRefreshing = false;
          this.refreshTokenSubject.next(response.accessToken);
          return next(request.clone({
            headers: request.headers.set('Authorization', `Bearer ${response.accessToken}`)
          }));
        }),
        catchError((err) => {
          this.isRefreshing = false;
          this.logout();
          return throwError(() => err);
        })
      );
    } else {
      return this.refreshTokenSubject.pipe(
        filter(token => token !== null),
        take(1),
        switchMap(jwt => {
          return next(request.clone({
            headers: request.headers.set('Authorization', `Bearer ${jwt}`)
          }));
        })
      );
    }
  }

  private handleAuthSuccess(response: AuthResponse, rememberMe: boolean): void {
    this.accessToken.set(response.accessToken);
    this.currentUser.set({
      username: response.username,
      role: response.role,
      privileges: response.privileges
    });

    if (rememberMe) {
      localStorage.setItem('kbase_refresh_token', response.refreshToken);
      localStorage.setItem('kbase_username', response.username);
      sessionStorage.removeItem('kbase_refresh_token');
    } else {
      sessionStorage.setItem('kbase_refresh_token', response.refreshToken);
      localStorage.removeItem('kbase_refresh_token');
    }
  }

  initAuth(): Promise<boolean> {
    return new Promise((resolve) => {
      const refreshToken = this.getRefreshToken();
      if (!refreshToken) {
        resolve(false);
        return;
      }

      this.refreshToken().subscribe({
        next: () => resolve(true),
        error: () => resolve(false)
      });
    });
  }

  getRefreshToken(): string | null {
    return localStorage.getItem('kbase_refresh_token') || sessionStorage.getItem('kbase_refresh_token');
  }

  getRememberedUsername(): string {
    return localStorage.getItem('kbase_username') || '';
  }

  private clearSession(): void {
    this.accessToken.set(null);
    this.currentUser.set(null);
    localStorage.removeItem('kbase_refresh_token');
    sessionStorage.removeItem('kbase_refresh_token');
  }
}
