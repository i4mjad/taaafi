import { Component, OnInit } from '@angular/core';
import { AuthService } from '../../../services/auth.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css'],
})
export class HeaderComponent implements OnInit {
  items: any[] = [];
  isLoggedIn = false; // Tracks the login state

  constructor(private authService: AuthService, private router: Router) {}

  ngOnInit(): void {
    this.authService.streamAuthState().subscribe((user) => {
      this.isLoggedIn = !!user; // Update isLoggedIn based on user presence
      this.updateMenuItems();
    });
  }

  updateMenuItems() {
    if (this.isLoggedIn) {
      this.items = [
        {
          label: 'Dashboard',
          icon: 'pi pi-home',
          routerLink: '/dashboard',
        },
        {
          label: 'Projects',
          icon: 'pi pi-search',
          items: [
            {
              label: 'Components',
              icon: 'pi pi-bolt',
            },
            {
              label: 'Blocks',
              icon: 'pi pi-server',
            },
            {
              label: 'UI Kit',
              icon: 'pi pi-pencil',
            },
            {
              label: 'Templates',
              icon: 'pi pi-palette',
              items: [
                {
                  label: 'Apollo',
                  icon: 'pi pi-palette',
                },
                {
                  label: 'Ultima',
                  icon: 'pi pi-palette',
                },
              ],
            },
          ],
        },
      ];
    } else {
      this.items = [];
    }
  }

  loginOrLogout() {
    if (this.isLoggedIn) {
      this.authService.logout().subscribe({
        next: () => this.router.navigate(['/']), // Optional: navigate to login on logout
        error: (error) => console.error('Logout failed', error),
      });
    } else {
      this.authService.googleSignIn().subscribe({
        error: (error) => console.error('Login failed', error),
      });
    }
  }
}
