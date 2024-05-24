import {Component, OnInit} from '@angular/core';
import { MenuItem } from 'primeng/api';
import {AuthService} from "../../../services/auth.service";

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrl: './header.component.css'
})
export class HeaderComponent implements  OnInit{
  items: MenuItem[] | undefined;
  isLoggedIn = false;  // Tracks the login state


  constructor(private authService: AuthService) {
  }
  ngOnInit(): void {
    this.items = [
      {
        label: 'Home',
        icon: 'pi pi-home'
      },
      {
        label: 'Features',
        icon: 'pi pi-star'
      },
      {
        label: 'Projects',
        icon: 'pi pi-search',
        items: [
          {
            label: 'Components',
            icon: 'pi pi-bolt'
          },
          {
            label: 'Blocks',
            icon: 'pi pi-server'
          },
          {
            label: 'UI Kit',
            icon: 'pi pi-pencil'
          },
          {
            label: 'Templates',
            icon: 'pi pi-palette',
            items: [
              {
                label: 'Apollo',
                icon: 'pi pi-palette'
              },
              {
                label: 'Ultima',
                icon: 'pi pi-palette'
              }
            ]
          }
        ]
      },
      {
        label: 'Contact',
        icon: 'pi pi-envelope'
      }
    ]

    this.authService.streamAuthState().subscribe(user => {
      this.isLoggedIn = !!user;  // Update isLoggedIn based on user presence
    });
  }

  loginOrLogout() {
    if (this.isLoggedIn) {
      this.authService.logout().subscribe();  // Perform logout
    } else {
      this.authService.googleSignIn().subscribe();  // Perform Google sign-in
    }
  }

}
