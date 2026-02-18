"use client"

import * as React from "react"
import { useIsMobile } from "@/hooks/use-mobile"
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogFooter, 
  DialogHeader, 
  DialogTitle 
} from "./dialog"
import { 
  Sheet, 
  SheetContent, 
  SheetDescription, 
  SheetFooter, 
  SheetHeader, 
  SheetTitle 
} from "./sheet"
import { cn } from "@/lib/utils"

interface ResponsiveDialogProps {
  children: React.ReactNode
  open?: boolean
  onOpenChange?: (open: boolean) => void
}

interface ResponsiveDialogContentProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode
  className?: string
  side?: "top" | "right" | "bottom" | "left"
}

interface ResponsiveDialogHeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode
  className?: string
}

interface ResponsiveDialogFooterProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode
  className?: string
}

interface ResponsiveDialogTitleProps extends React.HTMLAttributes<HTMLHeadingElement> {
  children: React.ReactNode
  className?: string
}

interface ResponsiveDialogDescriptionProps extends React.HTMLAttributes<HTMLParagraphElement> {
  children: React.ReactNode
  className?: string
}

const ResponsiveDialog = ({ children, ...props }: ResponsiveDialogProps) => {
  const isMobile = useIsMobile()
  
  if (isMobile) {
    return <Sheet {...props}>{children}</Sheet>
  }
  
  return <Dialog {...props}>{children}</Dialog>
}

const ResponsiveDialogContent = React.forwardRef<
  HTMLDivElement,
  ResponsiveDialogContentProps
>(({ children, className, side = "bottom", ...props }, ref) => {
  const isMobile = useIsMobile()
  
  if (isMobile) {
    return (
      <SheetContent
        ref={ref}
        side={side}
        className={cn(
          "flex flex-col gap-4 p-6",
          side === "bottom" && "max-h-[85vh]",
          side === "top" && "max-h-[85vh]",
          side === "left" && "w-[85vw] sm:w-[400px]",
          side === "right" && "w-[85vw] sm:w-[400px]",
          className
        )}
        {...props}
      >
        {children}
      </SheetContent>
    )
  }
  
  return (
    <DialogContent ref={ref} className={cn("", className)} {...props}>
      {children}
    </DialogContent>
  )
})
ResponsiveDialogContent.displayName = "ResponsiveDialogContent"

const ResponsiveDialogHeader = ({ className, ...props }: ResponsiveDialogHeaderProps) => {
  const isMobile = useIsMobile()
  
  if (isMobile) {
    return <SheetHeader className={className} {...props} />
  }
  
  return <DialogHeader className={className} {...props} />
}

const ResponsiveDialogFooter = ({ className, ...props }: ResponsiveDialogFooterProps) => {
  const isMobile = useIsMobile()
  
  if (isMobile) {
    return <SheetFooter className={className} {...props} />
  }
  
  return <DialogFooter className={className} {...props} />
}

const ResponsiveDialogTitle = React.forwardRef<
  HTMLHeadingElement,
  ResponsiveDialogTitleProps
>(({ className, ...props }, ref) => {
  const isMobile = useIsMobile()
  
  if (isMobile) {
    return <SheetTitle ref={ref} className={className} {...props} />
  }
  
  return <DialogTitle ref={ref} className={className} {...props} />
})
ResponsiveDialogTitle.displayName = "ResponsiveDialogTitle"

const ResponsiveDialogDescription = React.forwardRef<
  HTMLParagraphElement,
  ResponsiveDialogDescriptionProps
>(({ className, ...props }, ref) => {
  const isMobile = useIsMobile()
  
  if (isMobile) {
    return <SheetDescription ref={ref} className={className} {...props} />
  }
  
  return <DialogDescription ref={ref} className={className} {...props} />
})
ResponsiveDialogDescription.displayName = "ResponsiveDialogDescription"

export {
  ResponsiveDialog,
  ResponsiveDialogContent,
  ResponsiveDialogHeader,
  ResponsiveDialogFooter,
  ResponsiveDialogTitle,
  ResponsiveDialogDescription,
} 