import { Component, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  imports: [FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.scss'
})
export class LoginComponent {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);

  protected readonly username = signal<string>(this.authService.getRememberedUsername());
  protected readonly password = signal<string>('');
  protected readonly rememberMe = signal<boolean>(this.authService.getRememberedUsername() !== '');
  protected readonly errorMessage = signal<string>('');
  protected readonly isLoading = signal<boolean>(false);

  onSubmit(event: Event): void {
    event.preventDefault();
    if (!this.username() || !this.password()) {
      this.errorMessage.set("Please fill in all fields");
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set('');

    this.authService.login(this.username(), this.password(), this.rememberMe()).subscribe({
      next: () => {
        this.isLoading.set(false);
        this.router.navigate(['/main']);
      },
      error: (err) => {
        this.isLoading.set(false);
        this.errorMessage.set("Invalid username or password");
        console.error('Login error', err);
      }
    });
  }

  updateUsername(value: string): void {
    this.username.set(value);
  }

  updatePassword(value: string): void {
    this.password.set(value);
  }

  toggleRememberMe(): void {
    this.rememberMe.set(!this.rememberMe());
  }
}
