"use client"

import { Mail, MapPin, Phone } from "lucide-react"

interface ContactProps {
  title?: string
  description?: string
  emailLabel?: string
  emailDescription?: string
  email?: string
  officeLabel?: string
  officeDescription?: string
  officeAddress?: string
  phoneLabel?: string
  phoneDescription?: string
  phone?: string
}

const Contact = ({
  title = "Contact Us",
  description = "Contact the support team at CloudMaster.",
  emailLabel = "Email",
  emailDescription = "We respond to all emails within 24 hours.",
  email = "support@cloudmaster.com",
  officeLabel = "Office",
  officeDescription = "Drop by our office for a chat.",
  officeAddress = "1 Eagle St, Brisbane, QLD, 4000",
  phoneLabel = "Phone",
  phoneDescription = "We're available Mon-Fri, 9am-5pm.",
  phone = "+123 456 7890",
}: ContactProps) => {
  return (
    <section className="container mx-auto px-4 py-16" id="contact">
      <div className="container">
        <div className="mb-14">
          <h1 className="mt-2 mb-3 text-3xl font-semibold text-balance md:text-4xl">{title}</h1>
          <p className="max-w-xl text-lg text-muted-foreground">{description}</p>
        </div>
        <div className="grid gap-10 md:grid-cols-3">
          <div>
            <span className="mb-3 flex size-12 flex-col items-center justify-center rounded-full bg-accent">
              <Mail className="h-6 w-auto" />
            </span>
            <p className="mb-2 text-lg font-semibold">{emailLabel}</p>
            <p className="mb-3 text-muted-foreground">{emailDescription}</p>
            <a href={`mailto:${email}`} className="font-semibold hover:underline">
              {email}
            </a>
          </div>
          <div>
            <span className="mb-3 flex size-12 flex-col items-center justify-center rounded-full bg-accent">
              <MapPin className="h-6 w-auto" />
            </span>
            <p className="mb-2 text-lg font-semibold">{officeLabel}</p>
            <p className="mb-3 text-muted-foreground">{officeDescription}</p>
            <a href="#" className="font-semibold hover:underline">
              {officeAddress}
            </a>
          </div>
          <div>
            <span className="mb-3 flex size-12 flex-col items-center justify-center rounded-full bg-accent">
              <Phone className="h-6 w-auto" />
            </span>
            <p className="mb-2 text-lg font-semibold">{phoneLabel}</p>
            <p className="mb-3 text-muted-foreground">{phoneDescription}</p>
            <a href={`tel:${phone}`} className="font-semibold hover:underline">
              {phone}
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Contact
