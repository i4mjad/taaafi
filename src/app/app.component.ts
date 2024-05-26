import { Component, OnInit } from '@angular/core';
import { AuthService } from './services/auth.service';
import { Router } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent implements OnInit {
  items: any[] = [];
  isLoggedIn = false; // Tracks the login state

  currentLanguage: string = 'ar';

  constructor(
    private authService: AuthService,
    private router: Router,
    private translate: TranslateService
  ) {
    this.translate.setDefaultLang('ar');
    document.documentElement.dir = 'rtl';

    this.currentLanguage = this.translate.currentLang;
    this.translate.onLangChange.subscribe((event) => {
      this.currentLanguage = event.lang;
      document.documentElement.dir = event.lang === 'ar' ? 'rtl' : 'ltr';
    });
  }

  ngOnInit(): void {
    document.documentElement.dir === 'ar';
    this.authService.streamAuthState().subscribe((user) => {
      this.isLoggedIn = !!user; // Update isLoggedIn based on user presence
    });

    this.currentLanguage = this.translate.currentLang;
    // Listen to language change events
    this.translate.onLangChange.subscribe((langChangeEvent) => {
      this.currentLanguage = langChangeEvent.lang;
    });
  }

  toggleLanguage() {
    const newLang = this.currentLanguage === 'en' ? 'ar' : 'en';
    this.translate.use(newLang);
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
