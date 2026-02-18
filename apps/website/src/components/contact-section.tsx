"use client"

import { Mail, Instagram, Twitter, MessageCircle } from "lucide-react"

interface ContactProps {
  dict?: {
    contactUs: string
    contactUsDescription: string
    emailLabel?: string
    emailDescription?: string
    email?: string
    socialLabel?: string
    socialDescription?: string
    whatsappLabel?: string
    whatsappDescription?: string
    whatsapp?: string
  }
}

const Contact = ({
  dict = {
    contactUs: "Contact Us",
    contactUsDescription: "Contact the support team at CloudMaster.",
    emailLabel: "Email",
    emailDescription: "We respond to all emails within 24 hours.",
    email: "admin@cloudmaster.com",
    socialLabel: "Social Media",
    socialDescription: "Follow us on social media for updates and support.",
    whatsappLabel: "WhatsApp",
    whatsappDescription: "Chat with us on WhatsApp.",
    whatsapp: "+968 7745 1200",
  },
}: ContactProps) => {
  return (
    <section className="container mx-auto px-4 py-16" id="contact">
      <div className="container">
        <div className="mb-14">
          <h1 className="mt-2 mb-3 text-3xl font-semibold text-balance md:text-4xl">{dict.contactUs}</h1>
          <p className="max-w-xl text-lg text-muted-foreground">{dict.contactUsDescription}</p>
        </div>
        <div className="grid gap-10 md:grid-cols-3">
          <div>
            <span className="mb-3 flex size-12 flex-col items-center justify-center rounded-full bg-accent">
              <Mail className="h-6 w-auto" />
            </span>
            <p className="mb-2 text-lg font-semibold">{dict.emailLabel}</p>
            <p className="mb-3 text-muted-foreground">{dict.emailDescription}</p>
            <a href={`mailto:${dict.email}`} className="font-semibold hover:underline">
              {dict.email}
            </a>
          </div>
          <div>
            <span className="mb-3 flex size-12 flex-col items-center justify-center rounded-full bg-accent">
              <Instagram className="h-6 w-auto" />
            </span>
            <p className="mb-2 text-lg font-semibold">{dict.socialLabel}</p>
            <p className="mb-3 text-muted-foreground">{dict.socialDescription}</p>
            <div className="flex gap-4">
              <a 
                href="https://instagram.com/ta3afi" 
                target="_blank" 
                rel="noopener noreferrer" 
                className="flex items-center justify-center size-10 rounded-full bg-accent hover:bg-accent/80 transition-colors"
                aria-label="Instagram"
              >
                <Instagram className="h-5 w-5" />
              </a>
              <a 
                href="https://twitter.com/ta3afi" 
                target="_blank" 
                rel="noopener noreferrer" 
                className="flex items-center justify-center size-10 rounded-full bg-accent hover:bg-accent/80 transition-colors"
                aria-label="X (Twitter)"
              >
                <Twitter className="h-5 w-5" />
              </a>
            </div>
          </div>
          <div>
            <span className="mb-3 flex size-12 flex-col items-center justify-center rounded-full bg-accent">
              <MessageCircle className="h-6 w-auto" />
            </span>
            <p className="mb-2 text-lg font-semibold">{dict.whatsappLabel}</p>
            <p className="mb-3 text-muted-foreground">{dict.whatsappDescription}</p>
            <a 
              href={`https://wa.me/${dict.whatsapp?.replace(/\D/g, '')}`} 
              target="_blank" 
              rel="noopener noreferrer" 
              className="font-semibold hover:underline"
            >
              {dict.whatsapp}
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Contact
