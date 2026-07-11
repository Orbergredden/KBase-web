import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-welcome',
  templateUrl: './welcome.html',
  styleUrl: './welcome.scss'
})
export class WelcomeComponent {
  private readonly router = inject(Router);
  protected readonly authService = inject(AuthService);

  goToLogin(): void {
    this.router.navigate(['/login']);
  }

  goToMain(): void {
    this.router.navigate(['/main']);
  }
}
